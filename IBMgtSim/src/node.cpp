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
 * $Id: node.cpp,v 1.10 2005/03/20 11:24:14 eitan Exp $
 */

/****h* IBMS/Node
* NAME
*	IB Management Simulator Node object and acompany Mad Processor
*
* DESCRIPTION
*	The simulator routes mad messages to the target node. This node 
*  stores the device state (PM Counters, CR Space, etc). Pure virtual 
*  MadProcessor class is provided to define the interface of mad processors.
*
* AUTHOR
*	Eitan Zahavi, Mellanox
*
*********/

#include "msgmgr.h"
#include "node.h"
#include "sim.h"

//////////////////////////////////////////////////////////////
//
// CLASS  IBMSPortErrProfile
//

/* This class holds the variables defining statistical behaviour of the
   port counters */

/* checks if needs to drop current packet - also increases the 
   packet count */
boolean_t IBMSPortErrProfile::isDropped() 
{
  /* we are given a rate for dropping packets and the deviation for it */
  /*
    as we can evenly randomize integers in the range 0 - RAND_MAX we
    need to reflect that into a binary descission for dropping the packets
    such that infinately we will have a drop ratio as defined
    
    TODO: Apply a filter on the random data to simulate reduced spectrum.
  */
  static unsigned int seed = 62871;
  float r = rand_r(&seed) / RAND_MAX;
  if (r < packetDropRate)
  {
    return TRUE;
  }
  else
  {
    return FALSE;
  }
}


//////////////////////////////////////////////////////////////
//
// CLASS  IBMSMadProcessor
//

/* Mad proccessor class is a pure virtual class that 
   supports handling of mads of specific class        */


/* add a single mad proccessor to a node */
void IBMSMadProcessor::addProcToNode(uint16_t mgtClass)
{
  MSGREG(inf1, 'V', "Registered mad processor of class:$ on node:$", "server");
  
  /* we cannot simply push in the new mad processor */
  /* need to make sure the vector has this entry */
  if (pSimNode->madProccessors.size() <= mgtClass)
    pSimNode->madProccessors.resize(mgtClass+1);
  
  (pSimNode->madProccessors[mgtClass]).push_back(this);
  MSGSND(inf1, mgtClass, pSimNode->getIBNode()->name);
}

/* constructor handles the registration of the new processor */
IBMSMadProcessor::IBMSMadProcessor(
  class IBMSNode *pSNode, 
  list_uint16 &mgtClassesList)
{

  /* we need to have a lock here */
  pSimNode = pSNode;
  mgtClasses = mgtClassesList;

  pthread_mutex_lock(&pSimNode->lock);
  
  for (list_uint16::iterator lI = mgtClasses.begin();
       lI != mgtClasses.end(); lI++)
    addProcToNode(*lI);

  pthread_mutex_unlock(&pSimNode->lock);
}

/* single class constructor */
IBMSMadProcessor::IBMSMadProcessor(class IBMSNode *pSNode, uint16_t mgtClass)
{
  /* we need to have a lock here */
  pSimNode = pSNode;
  mgtClasses.push_back(mgtClass);

  pthread_mutex_lock(&pSimNode->lock);
  addProcToNode(mgtClass);
  pthread_mutex_unlock(&pSimNode->lock);
}

/* destructor must clean from node list */
IBMSMadProcessor::~IBMSMadProcessor()
{
  MSGREG(err1, 'E', "Could not find the processor management class:$ in its node list?", "server");
  MSGREG(err2, 'E', "Could not find the processor in its node list?", "server");
  MSGREG(inf1, 'V', "Removed mad processor of class:$ from its node", "server");
  
  for (list_uint16::iterator lI = mgtClasses.begin();
       lI != mgtClasses.end(); lI++)
  {
    uint16_t mgtClass = *lI;
    /* the class must have an entry */
    if (pSimNode->madProccessors.size() <= mgtClass)
    {
      MSGSND(err1, mgtClass);
    }
    else
    {
      list_mad_processor::iterator lI = 
        find(pSimNode->madProccessors[mgtClass].begin(), 
             pSimNode->madProccessors[mgtClass].end(), this);
      if (lI == pSimNode->madProccessors[mgtClass].end())
      {
        MSGSND(err2);
      }
      else
      {
        pSimNode->madProccessors[mgtClass].erase(lI);
        MSGSND(inf1, mgtClass);
      }
    }
  }
}

//////////////////////////////////////////////////////////////
//
// CLASS  IBMSNode
//

/* Every IB node have this simulator node attached */

/* constructor */
IBMSNode::IBMSNode(class IBMgtSim *pS, class IBNode *pN)
{
  pSim = pS;
  pNode = pN;

  /* initialize the node lock */
  pthread_mutex_init(&lock, NULL);

  /* initialize all port counters */
  ib_pm_counters_t zeroCounters;
  memset(&zeroCounters, 0, sizeof(ib_pm_counters_t));

  phyPortCounters.insert(phyPortCounters.begin(), 
                         pNode->numPorts+1, zeroCounters);
  
  /* initialize default error statistics (constructed with zeros) */
  for (unsigned int pn = 0; pn <= pNode->numPorts; pn++)
  {
    IBMSPortErrProfile errosProfile;
    phyPortErrProfiles.push_back(errosProfile);
  }
}

/* handle incoming mad by sending it to the processMad of every 
   IBMSMadProcessor on the node.                            */
int IBMSNode::processMad(uint8_t inPort, ibms_mad_msg_t &madMsg)
{
  /* get the registered IBMSMadProcessor's of this class */
  uint8_t mgtClass = madMsg.header.mgmt_class;
  MSGREG(err1, 'E', "No processor registered for class:$", "simnode");
  
  if (madProccessors.size() <= mgtClass)
  {
    MSGSND(err1, mgtClass);
    return 1;
  }
  
  if (madProccessors[mgtClass].empty())
  {
    MSGSND(err1, mgtClass);
    return 1;
  }

  pthread_mutex_lock(&lock);

  /* ok we got some processors - so call them */
  for (list_mad_processor::iterator lI = madProccessors[mgtClass].begin();
       lI != madProccessors[mgtClass].end();
       lI++)
  {
    (*lI)->processMad(inPort, madMsg);
  }

  pthread_mutex_unlock(&lock);
  return 0;
}

  /* set a particular port err profile */
int IBMSNode::setPhyPortErrProfile(
  uint8_t portNum, IBMSPortErrProfile &errProfile)
{
  if (portNum > pNode->numPorts)
    return 1;

  if (phyPortErrProfiles.size() <= portNum)
    for (unsigned int pn = phyPortErrProfiles.size();
         pn <= portNum;
         pn++)
    {
      IBMSPortErrProfile newProfile;
      phyPortErrProfiles.push_back(newProfile);
    }
  
  phyPortErrProfiles[portNum] = errProfile;
  return 0;
}  

/* get a particular port err profile */
int IBMSNode::getPhyPortErrProfile(
  uint8_t portNum, IBMSPortErrProfile &errProfile)
{
  
  if (portNum > pNode->numPorts)
    return 1;

  errProfile = phyPortErrProfiles[portNum];
  return 0;
}

/* set a specific port counter */
int IBMSNode::setPhyPortPMCounter(
  uint8_t portNum, uint32_t counterSelect, 
  ib_pm_counters_t &countersVal)
{
  if (portNum > pNode->numPorts) return 1;
  phyPortCounters[portNum] = countersVal;
  return 0;
}    

/* get a specific port counter */
/* set a specific port counter */
ib_pm_counters_t*
IBMSNode::getPhyPortPMCounter(
  uint8_t portNum, uint32_t counterSelect)
{
  if (portNum > pNode->numPorts) return 0;
  
  return &(phyPortCounters[portNum]);
}

/* set CR Space Value */
int IBMSNode::setCrSpace(uint32_t addr, uint32_t &data)
{
  return 0;
}    

/* get CR Space Value */
int IBMSNode::getCrSpace(uint32_t addr, uint32_t &data)
{
  return 0;
}    

/*
  Get remote node by given port number. 
  Handle both HCA and SW.
  
  Return either 0 if step could be made or 1 if failed.
  
  Updated both output pointers:
  remNode - to the Sim Node of the other side 
  remIBPort - to the remote side IB Fabric Port object on teh other side.
  isVl15 - if > 0 - requires the port state to be init otherwise active
*/
int
IBMSNode::getRemoteNodeByOutPort(
  uint8_t outPortNum,
  IBMSNode **ppRemNode,
  IBPort **ppRemIBPort,
  int isVl15)
{

  MSGREG(inf1, 'V', "No Remote connection on node:$ port:$", "node");
  MSGREG(inf2, 'V', "Link is not ACTIVE on node:$ port:$ it is:$", "node");
  MSGREG(inf3, 'V', "MAD is dropped on node:$ port:$", "node");
  
  if (ppRemNode) *ppRemNode = NULL;
  if (ppRemIBPort) *ppRemIBPort = NULL;
  
  /* obtain the node lock */
  pthread_mutex_lock(&lock);

  /* get the other side on IBNode ... */
  IBPort *pPort = pNode->getPort(outPortNum);
  if (! pPort || !pPort->p_remotePort) 
  {
    MSGSND(inf1, pNode->name, outPortNum);
    pthread_mutex_unlock(&lock);
    return 1;
  }

  /* ok we can update the returned variables */
  if (ppRemIBPort != NULL) *ppRemIBPort = pPort->p_remotePort;

  /* get the remote node if any */
  IBNode *pRemIBNode = NULL;
  IBMSNode *pRemSimNode = NULL;
  if (pPort->p_remotePort)
  {
    pRemIBNode = pPort->p_remotePort->p_node;
    pRemSimNode = ibmsGetIBNodeSimNode(pRemIBNode);
  }

  if (ppRemNode != NULL) *ppRemNode = pRemSimNode;

  /* is the port active */
  int linkStatus = getLinkStatus(outPortNum);
  
  if (!((isVl15 && (linkStatus > IB_LINK_DOWN)) || (linkStatus == IB_LINK_ACTIVE)))
  {
    MSGSND(inf2, pNode->name, outPortNum, linkStatus);
    pthread_mutex_unlock(&lock);
    return 1;
  }

  /* do we want to drop this mad ? */
  if (phyPortErrProfiles[outPortNum].isDropped()) 
  {
    // TODO: double check the register and also randomally 
    // increase the remote node rcv dropped.
    // Update port counters of dropped mad.
    phyPortCounters[outPortNum].port_xmit_discard++;
    pRemSimNode->phyPortCounters[pPort->p_remotePort->num].port_rcv_errors++;
    pRemSimNode->phyPortCounters[pPort->p_remotePort->num].port_rcv_remote_physical_errors++;

    MSGSND(inf3, pNode->name, outPortNum);
    pthread_mutex_unlock(&lock);
    return 1;
  }
  
  // Update port counters of sent mad and received mads
  phyPortCounters[outPortNum].port_xmit_pkts++;
  phyPortCounters[outPortNum].port_xmit_data += 256;
  pRemSimNode->phyPortCounters[pPort->p_remotePort->num].port_rcv_pkts++;
  pRemSimNode->phyPortCounters[pPort->p_remotePort->num].port_rcv_data += 256;
  
  /* release the lock */
  pthread_mutex_unlock(&lock);

  return 0;
}

/* Set port state */
int IBMSNode::setLinkStatus(
    uint8_t portNum, 
    uint8_t newState)
{
    uint8_t                 modifyedState = 0;
    uint8_t                 oldState;
    ib_smp_t                noticeMad;
    ib_mad_notice_attr_t*   pTrapMadData;
    ibms_mad_msg_t          trapMadMsg;
    ib_pm_counters_t*       pPortCounters;
    uint32_t                counterSelect;

    if (nodeInfo.num_ports < portNum) return IB_LINK_NO_CHANGE; 

    oldState = ib_port_info_get_port_state( &nodePortsInfo[portNum]);
    if ((oldState == IB_LINK_INIT) && 
        ((newState != IB_LINK_DOWN) && (newState != IB_LINK_ARMED)))
    {
        return IB_LINK_NO_CHANGE;
    }
    else if ((oldState == IB_LINK_ARMED) && 
             ((newState != IB_LINK_DOWN) && (newState != IB_LINK_ACTIVE)))
    {
        return IB_LINK_NO_CHANGE;
    }
    else if ((oldState == IB_LINK_ACTIVE) && 
             ((newState != IB_LINK_DOWN) && (newState != IB_LINK_ARMED)))
    {
        return IB_LINK_NO_CHANGE;
    }

    //after checks are done:
    //  1. change portInfo link state - Node DB
    ib_port_info_set_port_state( &nodePortsInfo[portNum], newState);
    //  2. change link counters of the port 
    //          0x2=LinkErrorRecoveryCounter;
    //          0x4=LinkDownCounter
    counterSelect = 0x2 | 0x4;
    pPortCounters = getPhyPortPMCounter(portNum, counterSelect);
    pPortCounters->link_error_recovery_counter++;
    pPortCounters->link_down_counter++;
    setPhyPortPMCounter(portNum, counterSelect, *pPortCounters);

    if (nodeInfo.node_type == IB_NODE_TYPE_CA)
    {
        return newState;
    }
    
    if ((newState == IB_LINK_DOWN) && 
        ((oldState == IB_LINK_INIT) || 
         (oldState == IB_LINK_ARMED) || 
         (oldState == IB_LINK_ACTIVE)))
    {
        //  3. if node is a switch update the portStateChange
        ib_switch_info_set_state_change(&switchInfo);
        //  4. if node is a switch send a trap
        ib_mad_init_new( (ib_mad_t*)&noticeMad, 
                         IB_MCLASS_SUBN_LID,
                         1,
                         IB_MAD_METHOD_TRAP,
                         0x12345678,
                         IB_MAD_ATTR_NOTICE,
                         0);
        pTrapMadData = (ib_mad_notice_attr_t *)(&(noticeMad.data[0]));

        //TODO add support to other traps then 128 (only supported for now)
        {
            uint32_t prodType;

            prodType = (IB_NOTICE_TYPE_URGENT | (IB_NODE_TYPE_SWITCH << 8));
            ib_notice_set_prod_type( pTrapMadData, CL_HTON32(prodType));
        }
        
        pTrapMadData->g_or_v.generic.trap_num = CL_NTOH16(128);
        pTrapMadData->issuer_lid = nodePortsInfo[portNum].base_lid;
        pTrapMadData->toggle_count = 0;
        pTrapMadData->data_details.ntc_128.sw_lid = nodePortsInfo[portNum].base_lid;

        memcpy( (void*)&(trapMadMsg.header), (void*)&noticeMad, sizeof(ib_mad_t));
        trapMadMsg.addr.sl = 15;
        trapMadMsg.addr.pkey_index = 0;
        trapMadMsg.addr.slid = nodePortsInfo[portNum].base_lid;
        trapMadMsg.addr.dlid = nodePortsInfo[portNum].master_sm_base_lid;
        trapMadMsg.addr.sqpn = 0;
        trapMadMsg.addr.dqpn = 0;

        //send trap
        //ibms_dump_mad( trapMadMsg, SND);
        pSim->getDispatcher()->dispatchMad(this, 0, trapMadMsg);
    }
    return newState;
}


/* Get remote node by lid. Handle both HCA and SW */
int IBMSNode::getRemoteNodeByLid(
  uint16_t lid, 
  IBMSNode **ppRemNode,
  IBPort **ppRemIBPort,
  int isVl15)
{
  uint8_t portNum;
  MSGREG(inf1, 'V', "No FDB Entry for lid:$ node:$", "node");

  /* obtain the node lock */
  pthread_mutex_lock(&lock);

  /* just look at the FDB for that lid */
  portNum = pNode->getLFTPortForLid(lid);
  if (portNum == IB_LFT_UNASSIGNED)
  {
    MSGSND(inf1, lid, pNode->name);
    pthread_mutex_unlock(&lock);
    return 1;
  }
  
  /* release the node lock */
  pthread_mutex_unlock(&lock);

  /* if the port number is 0 - westay on this node */
  if (portNum == 0) 
  {
    *ppRemNode = this;
    *ppRemIBPort = pNode->getPort(0);
    return 0;
  }
  else 
    return getRemoteNodeByOutPort(portNum, ppRemNode , ppRemIBPort, isVl15);
}
