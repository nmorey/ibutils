/*
 * Copyright (c) 2004 Mellanox Technologies LTD. All rights reserved.
 *
 * This software is available to you under a choice of one of two
 * licenses.  You may choose to be licensed under the terms of the GNU
 * General Public License (GPL) Version 2, available from the file
 * COPYING in the main directory of this source tree, or the
 * OpenIB.org BSD license below:
 *
 *     Redistribution and use in source and binary forms, with or
 *     without modification, are permitted provided that the following
 *     conditions are met:
 *
 *      - Redistributions of source code must retain the above
 *        copyright notice, this list of conditions and the following
 *        disclaimer.
 *
 *      - Redistributions in binary form must reproduce the above
 *        copyright notice, this list of conditions and the following
 *        disclaimer in the documentation and/or other materials
 *        provided with the distribution.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * $Id: dispatcher.cpp,v 1.11 2005/03/20 11:26:16 eitan Exp $
 */

#include "dispatcher.h"
#include "server.h"
#include "msgmgr.h"

//////////////////////////////////////////////////////////////
//
// CLASS  IBMSDispatcher
//

/* constructor */
IBMSDispatcher::IBMSDispatcher(
  int numWorkers, 
  uint64_t dAvg_usec,
  uint64_t dStdDev_usec)
{
  MSG_ENTER_FUNC;  
  avgDelay_usec = dAvg_usec;
  stdDevDelay_usec = dStdDev_usec;

  /* init the spinlock */
  cl_spinlock_construct(&lock);
  cl_spinlock_init(&lock);

  /* construct and init the timer object */
  cl_timer_construct(&timer);
  cl_timer_init(&timer, IBMSDispatcher::timerCallback, this);

  /* construct and init the thread pool */
  cl_thread_pool_construct(&workersPool);
  cl_thread_pool_init(&workersPool, 
                      numWorkers, 
                      IBMSDispatcher::workerCallback,
                      this,
                      "ibms_worker");
  MSG_EXIT_FUNC;  
}

/* distructor */
IBMSDispatcher::~IBMSDispatcher()
{
  MSG_ENTER_FUNC;  
  cl_thread_pool_destroy(&workersPool);
  cl_spinlock_destroy(&lock);
  cl_timer_destroy(&timer);
  MSG_EXIT_FUNC;  
}

/* sets the average delay for a mad on the wire */
int IBMSDispatcher::setDelayAvg(uint64_t dAvg_usec)
{
  avgDelay_usec = dAvg_usec;
  return 0;
}

/* sets the deviation of the delay for a mad on the wire */
int IBMSDispatcher::setDelayStdDev(uint64_t dStdDev_usec)
{
  stdDevDelay_usec = dStdDev_usec;
  return 0;
}

/* introduce a new mad to the dispatcher */
int IBMSDispatcher::dispatchMad(
  IBMSNode *pFromNode, 
  uint8_t fromPort, 
  ibms_mad_msg_t &msg)
{
  MSG_ENTER_FUNC;  

  MSGREG(inf1, 'V', "Queued a mad to expire in $ msec", "dispatcher");

  /* obtain a lock on the Q */
  cl_spinlock_acquire(&lock);

  /* randomize the time we want the mad wait the event wheel */
  uint64_t waitTime_usec =
    llrintl((2.0 * rand()) / RAND_MAX * stdDevDelay_usec) + (avgDelay_usec - stdDevDelay_usec);
  
  madItem item;
  item.pFromNode = pFromNode;
  item.fromPort = fromPort;
  item.madMsg = msg;

  uint64_t wakeupTime_up = cl_get_time_stamp() + waitTime_usec;

  /* store the mad in the sorted by wakeup map */
  madQueueByWakeup[wakeupTime_up] = item;
  
  /* set the timer to the next event - trim to max delay of the current mad */
  uint32_t waitTime_msec = waitTime_usec/1000;

  MSGSND(inf1, waitTime_msec, waitTime_usec);

  if (madQueueByWakeup.size() > 1) 
    cl_timer_trim(&timer, waitTime_msec);
  else
    cl_timer_start(&timer, waitTime_msec);
  
  /* release the lock */
  cl_spinlock_release(&lock);
  MSG_EXIT_FUNC;  
  return 0;
}

/*
  The callback function for the threads 
  Loop to handle all outstanding MADs (those expired their wakeup time)
*/
void 
IBMSDispatcher::workerCallback(void *context)
{
  MSG_ENTER_FUNC;  
  IBMSDispatcher *pDisp = (IBMSDispatcher *)context;

  MSGREG(inf1,'V',"Popping mad message with wakeup: $","dispatcher");
  MSGREG(inf2,'V',"Entered workerCallback","dispatcher");

  MSGSND(inf2);

  int done = 0;
  madItem curMadMsgItem;
  map_uint64_mad::iterator mI;

  while (!done) 
  {
    /* get the first message in the waiting map */
    cl_spinlock_acquire(&pDisp->lock);
  
    mI = pDisp->madQueueByWakeup.begin();

    uint64_t curTime_usec = cl_get_time_stamp();
    done = (mI == pDisp->madQueueByWakeup.end()) || 
      ((*mI).first > curTime_usec);

    if (! done)
    {
      curMadMsgItem = (*mI).second;
      MSGSND(inf1,(*mI).first);
      pDisp->madQueueByWakeup.erase(mI);

      cl_spinlock_release(&pDisp->lock);

      /* handle the mad */
      pDisp->routeMadToDest(curMadMsgItem);
    }
  }

  cl_spinlock_release(&pDisp->lock);
  MSG_EXIT_FUNC;  
}

/* 
   The callback function for the timer - should signal the threads 
   if there is an outstanding mad - and re-set the timer next event 
*/
void 
IBMSDispatcher::timerCallback(void *context)
{
  MSG_ENTER_FUNC;  
  IBMSDispatcher *pDisp = (IBMSDispatcher *)context;

  MSGREG(inf1, 'V', "Schedule next timer callback in $ [msec]", "dispatcher");
  MSGREG(inf2, 'V', "Signaling worker threads", "dispatcher");
  
  /* obtain a lock on the Q */
  cl_spinlock_acquire(&pDisp->lock);
  
  /* search for the next wakeup time on the list */
  uint32_t nextWakeUp_msec = 0;
  map_uint64_mad::iterator mI = pDisp->madQueueByWakeup.begin();
  while ((mI != pDisp->madQueueByWakeup.end()) && !nextWakeUp_msec)
  {
    uint64_t curTime_usec = cl_get_time_stamp();
    uint64_t wakeUpTime_usec = (*mI).first;
    /* we are looking for an entry further down the road */
    if (curTime_usec < wakeUpTime_usec)
      nextWakeUp_msec = (wakeUpTime_usec - curTime_usec)/1000 + 1;
    
    /* get next entry */
    mI++;
  }

  if (nextWakeUp_msec)
  {
    /* restart the timer on the current time - the key */
    cl_timer_start(&pDisp->timer, nextWakeUp_msec);
    MSGSND(inf1, nextWakeUp_msec);
  }
    /* TODO : cleanup this dead code */
//   else
//   {

    /* just in case restart the timer in 50msec */
//     nextWakeUp_msec = 500;
//     cl_timer_start(&pDisp->timer, nextWakeUp_msec);
//     MSGSND(inf1, nextWakeUp_msec);
//   }
  
  cl_spinlock_release(&pDisp->lock);

  /* signal the workers threads */
  MSGSND(inf2);
  cl_thread_pool_signal(&pDisp->workersPool);
  MSG_EXIT_FUNC;  
}

/* do LID routing */
int
IBMSDispatcher::routeMadToDestByLid(
  madItem &item)
{
  MSG_ENTER_FUNC;  
  IBMSNode *pCurNode = NULL;
  IBMSNode *pRemNode = item.pFromNode;
  IBPort   *pRemIBPort; /* stores the incoming remote port */
  uint16_t lid = item.madMsg.addr.dlid;
  int hops = 0;
  
  MSGREG(inf0, 'I', "Routing MAD tid:$ to lid:$ from:$ port:$", "dispatcher");
  MSGREG(inf1, 'I', "Got to dead-end routing to lid:$ at node:$", 
         "dispatcher");
  MSGREG(inf2, 'I', "Arrived at lid $ = node $ after $ hops", "dispatcher");
  MSGREG(inf3, 'I', "Got to dead-end routing to lid:$ at node:$ port:$", 
         "dispatcher");
  MSGREG(inf4, 'I', "Got to dead-end routing to lid:$ at HCA node:$ port:$ lid:$", 
         "dispatcher");
  MSGREG(inf5, 'V', "Got node:$ through port:$", "dispatcher");
  
  MSGREG(err1, 'F', "Should never got here with null !", "dispatcher");

  MSGSND(inf0, cl_ntoh64(item.madMsg.header.trans_id), 
         lid, item.pFromNode->getIBNode()->name, item.fromPort);

  int isVl15 = (item.madMsg.header.mgmt_class == IB_MCLASS_SUBN_LID);
  
  /* we will stop when we are done or stuck */
  while (pRemNode && (pCurNode != pRemNode))
  {
    /* take the step */
    pCurNode = pRemNode;

    /* this sim node function is handling both HCA and SW under lock ... */
    if (pCurNode->getIBNode()->type == IB_CA_NODE)
    {
      /* HCA node - we are either done or get out from the client port num */
      if (hops == 0)
      {
        // catch cases where the lid is our own lid - use the port info for that
        if (cl_ntoh16(pCurNode->nodePortsInfo[item.fromPort].base_lid) == lid)
        {
          pRemNode = pCurNode;
          pRemIBPort = pCurNode->getIBNode()->getPort(item.fromPort);
        } 
        else
        {
          if (pCurNode->getRemoteNodeByOutPort(
                item.fromPort, &pRemNode, &pRemIBPort, isVl15))
          {
            MSGSND(inf3, lid, pCurNode->getIBNode()->name, item.fromPort);
            MSG_EXIT_FUNC;  
            return 1;
          }
          if (pRemIBPort)
            MSGSND(inf5, pRemNode->getIBNode()->name, pRemIBPort->num);
        }
      }
      else 
      {
        /* we mark the fact we are done */
        pRemNode = pCurNode;
      }
    }
    else
    {
      /* Switch node */
      if (pCurNode->getRemoteNodeByLid(lid, &pRemNode, &pRemIBPort, isVl15))
      {
        MSGSND(inf1, lid, pCurNode->getIBNode()->name);
        MSG_EXIT_FUNC;
        return 1;
      }
      if (pRemIBPort)
        MSGSND(inf5, pRemNode->getIBNode()->name, pRemIBPort->num);
    }
    hops++;
  }

  /* validate we reached the target node */
  if (! pRemNode) return(1);
  if (! pRemIBPort) return(1);

  /* check the lid of the target port we reach - it must match target */
  /* TODO: Support LMC in checking if LID routing target reached */
  if (lid == cl_ntoh16(pRemNode->nodePortsInfo[pRemIBPort->num].base_lid))
  {
    MSGSND(inf2, lid, pRemNode->getIBNode()->name, hops);
    int res = pRemNode->processMad(pRemIBPort->num, item.madMsg);
    MSG_EXIT_FUNC;  
    return(res);
  }
  else
  {
    /* we did not get to the target */
    MSGSND(inf4, lid, pRemNode->getIBNode()->name, pRemIBPort->num,
           cl_ntoh16(pRemNode->nodePortsInfo[pRemIBPort->num].base_lid));
    MSG_EXIT_FUNC;  
    return 1;
  }
  MSG_EXIT_FUNC;  
}

/* do Direct Routing */
int
IBMSDispatcher::routeMadToDestByDR(
  madItem &item)
{
  MSG_ENTER_FUNC;  
  IBMSNode *pCurNode = NULL;
  IBMSNode *pRemNode = item.pFromNode;
  IBPort   *pRemIBPort = NULL; /* stores the incoming remote port */
  uint8_t   inPortNum = item.fromPort;
  int hop_delta;        /* 1 for query -1 for response */
  int hops = 0;         /* just for debug */

  /* we deal only with SMP with DR sections */
  ib_smp_t *p_mad = (ib_smp_t *)(&(item.madMsg.header));
  uint8_t *initialPath = p_mad->initial_path;
  uint8_t *returnPath = p_mad->return_path;
  
  MSGREG(inf0, 'I', "Routing MAD tid:$ by DR", "dispatcher");
  MSGREG(inf1, 'I', "Got to dead-end routing by MAD tid:$ at node:$ hop:$", 
         "dispatcher");
  MSGREG(inf2, 'I', "MAD tid:$ to node:$ after $ hops", "dispatcher");
  MSGREG(err1, 'E', "Commbination of direct and lid route is not supported by the simulator!", "dispatcher");

  MSGSND(inf0, cl_ntoh64(item.madMsg.header.trans_id));

  /* check that no srdlid or drdlid are set */
  if ((p_mad->dr_slid != 0xffff) || (p_mad->dr_slid != 0xffff) )
  {
    MSGSND(err1);
    MSG_EXIT_FUNC;  
    return(1);
  }

  /* the direction of the hop pointer dec / inc is by the return bit */
  if (ib_smp_is_d(p_mad))
  {
    MSGREG(inf1, 'V', "hop pointer is $ and hop count is $ !", "dispatcher");
    MSGSND(inf1, p_mad->hop_ptr, p_mad->hop_count);

    // TODO implement direct route return algorithm
    p_mad->hop_ptr--;

    while(p_mad->hop_ptr > 0)
    {
      pCurNode = pRemNode;
      hops++;
      MSGREG(inf2, 'V', "hops is $", "dispatcher");
      MSGSND(inf2, hops);

      if (pCurNode->getRemoteNodeByOutPort(
            p_mad->return_path[p_mad->hop_ptr--], &pRemNode, &pRemIBPort, 1))
      {
        MSGSND(inf1, cl_ntoh64(p_mad->trans_id), 
               pCurNode->getIBNode()->name, hops);
        MSG_EXIT_FUNC;  
        return 1;
      }
    }
  }
  else
  {
    /* travel out the path - updating return path port num */

    /* we should start with 1 (init should be to zero) */
    p_mad->hop_ptr++;
    
    while(p_mad->hop_ptr <= p_mad->hop_count)
    {
      pCurNode = pRemNode;
      hops++;

      if (pCurNode->getRemoteNodeByOutPort(
            p_mad->initial_path[p_mad->hop_ptr], &pRemNode, &pRemIBPort, 1))
      {
        MSGSND(inf1, cl_ntoh64(p_mad->trans_id), 
               pCurNode->getIBNode()->name, hops);
        MSG_EXIT_FUNC;  
        return 1;
      }

      /* update the return path */
      p_mad->return_path[p_mad->hop_ptr] = pRemIBPort->num;
      
      p_mad->hop_ptr++;
    }
  }
  
  /* validate we reached the target node */
  if (! pRemNode) return(1);
  //if (! pRemIBPort) return(1);
  if (pRemIBPort) inPortNum = pRemIBPort->num;
  MSGSND(inf2, cl_ntoh64(p_mad->trans_id), pRemNode->getIBNode()->name, hops);

  int res = pRemNode->processMad(inPortNum, item.madMsg);
  MSG_EXIT_FUNC;  
  return(res);
}

int
IBMSDispatcher::routeMadToDest(
  madItem &item)
{
  MSG_ENTER_FUNC;  

  MSGREG(inf1, 'V', "Routing mad to lid: $", "dispatcher");
  MSGSND(inf1, item.madMsg.addr.dlid);

  /* 
     the over all routing algorithm is the same - go from current node to 
     next node, but the method used to get the next node is based on the 
     routing types. 

     Since the traversal involves all node connectivity, port status and 
     packet loss statistics - the dispatcher calls the nodes methods for 
     obtaining the remote nodes:
     getRemoteNodeByOutPort(outPort, &pRemNode, &remPortNum)
     getRemoteNodeByLid(lid, &pRemNode, &remPortNum)

     These fucntions can return 1 if the routing was unseccessful, including
     port state, fdb missmatch, packet drop, etc.

  */
  int res;
  if (item.madMsg.header.mgmt_class == 0x81)
    res = routeMadToDestByDR(item);
  else
    res = routeMadToDestByLid(item);

  MSG_EXIT_FUNC;  
  return res;
}

  
