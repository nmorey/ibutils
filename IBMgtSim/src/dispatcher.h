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
 * $Id: dispatcher.h,v 1.3 2005/02/23 20:43:49 eitan Exp $
 */

#ifndef IBMS_WORKER_H
#define IBMS_WORKER_H

/****h* IBMS/Worker
* NAME
*	IB Management Simulator MAD Dispatcher: Worker Threads and MAD Queue
*
* DESCRIPTION
*	The simulator stores incoming mads in a speacial queue that provides 
*  randomization of transport time. A group of worker threads is responsible
*  to pop mad messages from the queue, route them to the destination nodes 
*  and call their mad processor.
*
* AUTHOR
*	Eitan Zahavi, Mellanox
*
*********/

#include "simmsg.h"
#include <complib/cl_threadpool.h>
#include <complib/cl_timer.h>
#include <map>

class IBMSDispatcher {

  struct madItem {
    class IBMSNode *pFromNode; /* the node the mad was injected from */
    uint8_t fromPort;          /* the port number the mad was injected from */
    ibms_mad_msg_t  madMsg;    /* the mad message */
  };

  typedef std::map<uint64_t, struct madItem > map_uint64_mad;

  /* the event wheel times when an incoming message becomes accessible */
  cl_timer_t timer;

  /* the queue of mads waiting for processing */
  map_uint64_mad madQueueByWakeup;
  
  /* the pool of worker threads to route the mads and hand to the node 
     mad processors */
  cl_thread_pool_t workersPool;
  
  /* lock to synchronize poping up and pushing into the madQueue */
  cl_spinlock_t lock;

  /* avarage delay from introducing the mad to when it appear on the queue */
  uint64_t avgDelay_usec;
  
  /* deviation on the delay */
  uint64_t stdDevDelay_usec;

  /* route the mad to the destination by direct route */ 
  int routeMadToDestByDR(madItem &item);

  /* route the mad to teh destination by dest lid */ 
  int routeMadToDestByLid(madItem &item);

  /* route a mad to the destination node. On the way can drop mads by 
     statistics and update the relevant port counters on the actual node. */
  int routeMadToDest(madItem &item);
  
  /* The callback function for the threads */
  static void workerCallback(void *context);
  
  /* The callback function for the timer - should signal the threads 
     if there is an outstanding mad - and re-set the timer next event */
  static void timerCallback(void *context);

 public:
  /* constructor */
  IBMSDispatcher(int numWorkers, 
                 uint64_t delayAvg_usec, uint64_t delayStdDev_usec);

  ~IBMSDispatcher();

  /* sets the average delay for a mad on the wire */
  int	setDelayAvg(uint64_t delayAvg_usec);
  
  /* sets the deviation of the delay for a mad on the wire */
  int	setDelayStdDev(uint64_t delayStdDev_usec);
  
  /* introduce a new mad to the dispatcher */
  int dispatchMad(IBMSNode *pFromNode, uint8_t fromPort, ibms_mad_msg_t &msg);
  
};

#endif /* IBMS_WORKER_H */
