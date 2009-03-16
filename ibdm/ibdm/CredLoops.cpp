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
 * $Id$
 */

#include "Fabric.h"
#include "TraceRoute.h"
#include <set>
#include <algorithm>
#include <iomanip>

/*
 * Build a graph linked to the SW devices for input to output
 * links. We use the appData1 available on the nodes to ref the tables.
 * Based on this graph provide analysis on loops available on the
 * fabric
 *
 */

//////////////////////////////////////////////////////////////////////////////

// Apply DFS on a dependency graph

int CrdLoopDFS(VChannel* ch) {
  // Already been there
  if (ch->getFlag() == Closed)
    return 0;
  // Credit loop
  if (ch->getFlag() == Open) {
    return 1;
  }
  // Mark as open
  ch->setFlag(Open);
  // Make recursive steps
  for (int i=0; i<ch->getDependSize();i++) {
    VChannel* next = ch->getDependency(i);
    if (next) {
      if (CrdLoopDFS(next))
	return 1;
    }
  }
  // Mark as closed
  ch->setFlag(Closed);
  return 0;
}

//////////////////////////////////////////////////////////////////////////////

// Go over CA's apply DFS on the dependency graphs starting from CA's port

int CrdLoopFindLoops(IBFabric* p_fabric) {
  unsigned int lidStep = 1 << p_fabric->lmc;

  // go over all CA ports in the fabric
  for (int i = p_fabric->minLid; i <= p_fabric->maxLid; i += lidStep) {
	 IBPort *p_Port = p_fabric->PortByLid[i];
	 if (!p_Port || (p_Port->p_node->type == IB_SW_NODE)) continue;
	 // Go over all CA's channels and find untouched one
	 for (int j=0;j < p_fabric->getNumSLs(); j++) {
	   dfs_t state = p_Port->channels[j]->getFlag();
	   if (state == Open) {
	     cout << "-E- open channel outside of DFS" << endl;
	     return 1;
	   }
	   // Already processed, continue
	   if (state == Closed)
	     continue;
	   // Found starting point
	   if (CrdLoopDFS(p_Port->channels[j]))
	     return 1;
	 }
  }
  return 0;
}


//////////////////////////////////////////////////////////////////////////////

// Trace a route from slid to dlid by LFT
// Add dependency edges
int CrdLoopMarkRouteByLFT (
  IBFabric *p_fabric,
  unsigned int sLid , unsigned int dLid
  ) {

  IBPort *p_port = p_fabric->getPortByLid(sLid);
  IBNode *p_node;
  IBPort *p_portNext;
  unsigned int lidStep = 1 << p_fabric->lmc;
  int outPortNum = 0, inputPortNum = 0, hopCnt = 0;
  bool done;

  // make sure:
  if (!p_port) {
	 cout << "-E- Provided source:" << sLid
			<< " lid is not mapped to a port!" << endl;
	 return(1);
  }

  // Retrieve the relevant SL
  uint8_t SL, VL;
  SL = VL = p_port->p_node->getPSLForLid(dLid);

  if (!p_port->p_remotePort) {
    cout << "-E- Provided starting point is not connected !"
	 << "lid:" << sLid << endl;
    return 1;
  }

  if (SL == IB_SLT_UNASSIGNED) {
    cout << "-E- SL to destination is unassigned !"
         << "slid: " << sLid << "dlid:" << dLid << endl;
    return 1;
  }

  // check if we are done:
  done = ((p_port->p_remotePort->base_lid <= dLid) &&
	  (p_port->p_remotePort->base_lid+lidStep - 1 >= dLid));
  while (!done) {
    // Get the node on the remote side
    p_node = p_port->p_remotePort->p_node;
    // Get remote port's number
    inputPortNum = p_port->p_remotePort->num;
    // Get number of ports on the remote side
    int numPorts = p_node->numPorts;
    // Init vchannel's number of possible dependencies
    p_port->channels[VL]->setDependSize((numPorts+1)*p_fabric->getNumVLs());

    // Get port num of the next hop
    outPortNum = p_node->getLFTPortForLid(dLid);
    // Get VL of the next hop
    int nextVL = p_node->getSLVL(inputPortNum,outPortNum,SL);

    if (outPortNum == IB_LFT_UNASSIGNED) {
      cout << "-E- Unassigned LFT for lid:" << dLid << " Dead end at:" << p_node->name << endl;
      return 1;
    }

    if (nextVL == IB_SLT_UNASSIGNED) {
      cout << "-E- Unassigned SL2VL entry, iport: "<< inputPortNum<<", oport:"<<outPortNum<<", SL:"<<(int)SL<< endl;
      return 1;
    }

      // get the next port on the other side
    p_portNext = p_node->getPort(outPortNum);

    if (! (p_portNext &&
	   p_portNext->p_remotePort &&
	   p_portNext->p_remotePort->p_node)) {
      cout << "-E- Dead end at:" << p_node->name << endl;
      return 1;
    }
    // Now add an edge
    p_port->channels[VL]->setDependency(outPortNum*p_fabric->getNumVLs()+nextVL,p_portNext->channels[nextVL]);
    // Advance
    p_port = p_portNext;
    VL = nextVL;
    if (hopCnt++ > 256) {
      cout << "-E- Aborting after 256 hops - loop in LFT?" << endl;
      return 1;
    }
    //Check if done
    done = ((p_port->p_remotePort->base_lid <= dLid) &&
	    (p_port->p_remotePort->base_lid+lidStep - 1 >= dLid));
  }

  return 0;
}

/////////////////////////////////////////////////////////////////////////////

// Go over all CA to CA paths and connect dependant vchannel by an edge

int
CrdLoopConnectDepend(IBFabric* p_fabric)
{
  unsigned int lidStep = 1 << p_fabric->lmc;
  int anyError = 0;
  unsigned int i,j;

  // go over all ports in the fabric
  for ( i = p_fabric->minLid; i <= p_fabric->maxLid; i += lidStep) {
	 IBPort *p_srcPort = p_fabric->PortByLid[i];

	 if (!p_srcPort || (p_srcPort->p_node->type == IB_SW_NODE)) continue;

	 unsigned int sLid = p_srcPort->base_lid;

	 // go over all the rest of the ports:
	 for ( j = p_fabric->minLid; j <= p_fabric->maxLid; j += lidStep ) {
		IBPort *p_dstPort = p_fabric->PortByLid[j];

		// Avoid tracing to itself
		if (i == j) continue;

		if (! p_dstPort) continue;

		if (p_dstPort->p_node->type == IB_SW_NODE) continue;
		unsigned int dLid = p_dstPort->base_lid;
		// go over all LMC combinations:
		for (unsigned int l1 = 0; l1 < lidStep; l1++) {
		  for (unsigned int l2 = 0; l2 < lidStep; l2++) {
		    // Trace the path but record the input to output ports used.
		    if (CrdLoopMarkRouteByLFT(p_fabric, sLid + l1, dLid + l2)) {
		      cout << "-E- Fail to find a path from:"
			   << p_srcPort->p_node->name << "/" << p_srcPort->num
			   << " to:" << p_dstPort->p_node->name << "/" << p_dstPort->num
			   << endl;
		      anyError++;
		    }
		  }// all LMC lids 2 */
		} // all LMC lids 1 */
	 } // all targets
  } // all sources

  if (anyError) {
	 cout << "-E- Fail to traverse:" << anyError << " CA to CA paths" << endl;
	 return 1;
  }

  return 0;
}

//////////////////////////////////////////////////////////////////////////////

// Prepare the data model
int
CrdLoopPrepare(IBFabric *p_fabric) {
  unsigned int lidStep = 1 << p_fabric->lmc;

  // go over all ports in the fabric
  for (int i = p_fabric->minLid; i <= p_fabric->maxLid; i += lidStep) {
    IBPort *p_Port = p_fabric->PortByLid[i];
    if (!p_Port) continue;
    IBNode *p_node = p_Port->p_node;
    int nL;
    if (p_node->type == IB_CA_NODE)
      nL = p_fabric->getNumSLs();
    else
      nL = p_fabric->getNumVLs();
    // Go over all node's ports
    for (int k=0;k<p_node->Ports.size();k++) {
      IBPort* p_Port = p_node->Ports[k];
      // Init virtual channel array
      p_Port->channels.resize(nL);
      for (int j=0;j<nL;j++)
	p_Port->channels[j] = new VChannel;
    }
  }
  return 0;
}

// Cleanup the data model
int
CrdLoopCleanup(IBFabric *p_fabric) {
  unsigned int lidStep = 1 << p_fabric->lmc;

  // go over all ports in the fabric
  for (int i = p_fabric->minLid; i <= p_fabric->maxLid; i += lidStep) {
    IBPort *p_Port = p_fabric->PortByLid[i];
    if (!p_Port) continue;
    IBNode *p_node = p_Port->p_node;
    int nL;
    if (p_node->type == IB_CA_NODE)
      nL = p_fabric->getNumSLs();
    else
      nL = p_fabric->getNumVLs();
    // Go over all node's ports
    for (int k=0;k<p_node->Ports.size();k++) {
      IBPort* p_Port = p_node->Ports[k];
      for (int j=0;j<nL;j++)
	delete p_Port->channels[j];
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

// Top Level Subroutine:
int
CrdLoopAnalyze(IBFabric *p_fabric) {
  int res=0;

  cout << "-I- Analyzing Fabric for Credit Loops "<<(int)p_fabric->getNumSLs()<<" SLs, "<<(int)p_fabric->getNumVLs()<< " VLs used..." << endl;
  // Init data structures
  if (CrdLoopPrepare(p_fabric)) {
    cout << "-E- Fail to prepare data structures." << endl;
    return(1);
  }
  // Create the dependencies
  if (CrdLoopConnectDepend(p_fabric)) {
    cout << "-E- Fail to build dependency graphs." << endl;
    return(1);
  }
  // Find the loops if exist
  res = CrdLoopFindLoops(p_fabric);
  if (!res)
    cout << "-I- No credit loops found" << endl;
  else
    cout << "-E- credit loops in routing"<<endl;

  // cleanup:
  CrdLoopCleanup(p_fabric);

  return res;
}



