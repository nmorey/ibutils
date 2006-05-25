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
 
#define RT_NOT_USED 0
#define RT_USED     1
#define RT_VISITED  2
#define RT_LOOP_TRACED 4

//////////////////////////////////////////////////////////////////////////////

// Allocate the tables on the switches
int 
CrdLoopInitRtTbls(IBFabric *p_fabric) {
  IBNode *p_node;

  // Go over all SW nodes in the fabric and build a table 
  // of input to output ports links. Each element should track
  // effect and traversal flags.
  for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
		 nI != p_fabric->NodeByName.end();
		 nI++) {
	 
	 p_node = (*nI).second;
	 if (p_node->type != IB_SW_NODE) continue;
	
	 uint8_t *p_tbl = 
		new uint8_t[p_node->numPorts*p_node->numPorts];

	 memset(p_tbl, RT_NOT_USED, 
			  sizeof(uint8_t)*p_node->numPorts*p_node->numPorts);

	 if (! p_tbl) {
		cout << "-F- Fail to allocate memory for port routing table" << endl;
		exit(2);
	 }

	 // We use the appData1 of the node to store the routing links
	 // info
	 if (p_node->appData1.ptr) {
		cout << "-W- Application Data Pointer already set for node:" 
			  << p_node->name << endl;
		delete [] p_tbl;
	 } else {
		p_node->appData1.ptr = (void *)p_tbl;
	 }
  }
  return 0;
}

//////////////////////////////////////////////////////////////////////////////

// Trace a route from slid to dlid by LFT
int CrdLoopMarkRouteByLFT (
  IBFabric *p_fabric, 
  unsigned int sLid , unsigned int dLid
  ) {
  
  IBPort *p_port = p_fabric->getPortByLid(sLid);
  IBNode *p_node;
  IBPort *p_remotePort;
  unsigned int lidStep = 1 << p_fabric->lmc;
  int inPortNum = 0, outPortNum = 0;
  uint8_t *p_tbl;
  int hopCnt = 0;
  
  // make sure:
  if (! p_port) {
	 cout << "-E- Provided source:" << sLid
			<< " lid is not mapped to a port!" << endl;
	 return(1);
  }  

  // if the port is not a switch - go to the next switch:
  if (p_port->p_node->type != IB_SW_NODE) {
	 // try the next one:
	 if (!p_port->p_remotePort) {
		cout << "-E- Provided starting point is not connected !"
			  << "lid:" << sLid << endl;
		return 1;
	 }
	 inPortNum = p_port->p_remotePort->num;
	 p_node = p_port->p_remotePort->p_node;
  } else {
	 // it is a switch :
	 p_node = p_port->p_node;
  }


  // verify we are finally of a switch:
  if (p_node->type != IB_SW_NODE) {
	 cout << "-E- Provided starting point is not connected to a switch !"
			<< "lid:" << sLid << endl;
	 return 1;
  }

  // traverse:
  int done = 0;
  while (!done) {
	 // calc next node:
	 outPortNum = p_node->getLFTPortForLid(dLid);
	 if (outPortNum == IB_LFT_UNASSIGNED) {
		cout << "-E- Unassigned LFT for lid:" << dLid << " Dead end at:" << p_node->name << endl;
		return 1;
	 }
	 
	 // get the port on the other side
	 p_port = p_node->getPort(outPortNum);

	 if (! (p_port && 
			  p_port->p_remotePort && 
			  p_port->p_remotePort->p_node)) {
		cout << "-E- Dead end at:" << p_node->name << endl;
		return 1;
	 }

	 // Track it please:
	 p_tbl = (uint8_t *)p_node->appData1.ptr;
	 if (! p_tbl) {
		cout << "-F- Got a non initialized routing table pointer!" << endl;
		exit(2);
	 }

	 // cout << "-V- Add usage Node:" << p_node->name 
	 //		<< " In:" << inPortNum << " to:" << outPortNum <<  endl;

	 p_tbl[(inPortNum - 1)*p_node->numPorts + outPortNum - 1] = RT_USED;

	 p_remotePort = p_port->p_remotePort;
	 inPortNum = p_remotePort->num;

	 // check if we are done:
	 done = ((p_remotePort->base_lid <= dLid) && 
				(p_remotePort->base_lid+lidStep - 1 >= dLid));

	 p_node = p_remotePort->p_node;
	 if (hopCnt++ > 256) {
		cout << "-E- Aborting after 256 hops - loop in LFT?" << endl;
		return 1;
	 }
  }

  return 0;
}

//////////////////////////////////////////////////////////////////////////////

// Go over all CA to CA paths and mark the output links
// input links connections on these paths in the routing tables.
int 
CrdLoopPopulateRtTbls(IBFabric *p_fabric) {
  unsigned int lidStep = 1 << p_fabric->lmc;
  int anyError = 0, paths = 0;
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
		for (unsigned int l = 0; l < lidStep; l++) {
		  paths++;
		  
		  // Trace the path but record the input to output ports used.
		  if (CrdLoopMarkRouteByLFT(p_fabric, sLid + l, dLid + l)) {
			 cout << "-E- Fail to find a path from:" 
					<< p_srcPort->p_node->name << "/" << p_srcPort->num
					<< " to:" << p_dstPort->p_node->name << "/" << p_dstPort->num
					<< endl;
			 anyError++;
		  } 
		} // all LMC lids
	 } // all targets
  } // all sources

  if (anyError) {
	 cout << "-E- Fail to traverse:" << anyError << " CA to CA paths" << endl;
	 return 1;
  }
  
  cout << "-I- Marked " << paths << " CA to CA Paths" << endl;
  return 0;
} 

//////////////////////////////////////////////////////////////////////////////

// BFS from all CA's and require all inputs for an
// output node to be marked visited to go through it.
int 
CrdLoopBfsFromCAs(IBFabric *p_fabric) {
  int loops = 0;
  list< IBPort *> thisStepPorts, nextStepPorts;
  
  // go over all CA nodes and track the input ports for next step
  IBNode *p_node;
  IBPort *p_port;

  for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
		 nI != p_fabric->NodeByName.end();
		 nI++) {
	 
	 p_node = (*nI).second;
	 if (p_node->type != IB_CA_NODE) continue;
	
	 // get the remote input port
	 for (unsigned int pn = 1; pn <= p_node->numPorts; pn++) {
		p_port = p_node->getPort(pn);
		
		if (p_port && p_port->p_remotePort) {
		  // add to the list
		  thisStepPorts.push_back(p_port->p_remotePort);
		}
	 }
  }

  // while you have next step ports
  while ( ! thisStepPorts.empty()) {
	 loops++;

	 nextStepPorts.clear();

	 // go over all this step ports
	 while (! thisStepPorts.empty()) {
		p_port = thisStepPorts.front();
		thisStepPorts.pop_front();
		
		p_node = p_port->p_node ;

		if (p_node->type != IB_SW_NODE) continue;

		uint8_t *p_tbl = (uint8_t *)p_node->appData1.ptr;
		int inPortNum = p_port->num;

		// go over all the out ports marked by this input port:
		for (unsigned int outPortNum = 1;
           outPortNum <= p_node->numPorts; outPortNum++) {
		  int idx = (inPortNum - 1)*p_node->numPorts + outPortNum - 1;
		  // check if port was marked as used:
		  if (p_tbl[idx] == RT_USED) {
			 // zero the port USED:
			 p_tbl[idx] = (RT_USED | RT_VISITED);

			 // now check if all the effecting ports are cleard:
			 int foundUnVisited = 0;
			 for (unsigned int pn = 0; !foundUnVisited && (pn < p_node->numPorts);
               pn++) {
				idx = pn*p_node->numPorts + outPortNum - 1;
				if (p_tbl[idx] == RT_USED) foundUnVisited = 1;
			 }

			 // only when we do not have a marked but not visited  we
			 // can progress to next port:
			 if (!foundUnVisited) {
				// we only add ports if the are now unvisited:
				IBPort *p_oPort = p_node->getPort(outPortNum);
				if (p_oPort && p_oPort->p_remotePort) {
				  nextStepPorts.push_back(p_oPort->p_remotePort);
				}
			 }
		  }
		}
	 } // all this step ports

	 // Copy next step ports to cur ports:
	 thisStepPorts = nextStepPorts;
  }

  cout << "-I- Propagted ranking through Fabric in:" 
		 << loops << " BFS steps" << endl;
  return 0;
}

//////////////////////////////////////////////////////////////////////////////

// Dump Routing Tables:
int 
CrdLoopDumpRtTbls(IBFabric *p_fabric) {
  // go over all switches in the fabric 
  IBNode *p_node;

  // Go over all SW nodes in the fabric and build a table 
  // of input to output ports links. Each element should track
  // effect and traversal flags.
  for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
		 nI != p_fabric->NodeByName.end();
		 nI++) {
	 
	 p_node = (*nI).second;
	 if (p_node->type != IB_SW_NODE) continue;

	 cout << "---- RT TBL DUMP -----" << endl;
	 cout << "SW:" << p_node->name << endl;

	 uint8_t *p_tbl = (uint8_t*)p_node->appData1.ptr;

	 // header
	 cout << "I\\O ";
	 for (unsigned int outPortNum = 1; outPortNum <= p_node->numPorts; 
         outPortNum++) 
		cout << setw(3) << outPortNum << " ";
	 cout << endl;

	 // Now go over all out ports and check all input port.
	 for (unsigned int inPortNum = 1; inPortNum <= p_node->numPorts; 
         inPortNum++) {
		cout << setw(3) << inPortNum <<  " ";
		// go over all the out ports marked by this input port:
		for (unsigned int outPortNum = 1; outPortNum <= p_node->numPorts; 
           outPortNum++) {
		  int idx = (inPortNum - 1)*p_node->numPorts + outPortNum - 1;
		  if (p_tbl[idx] == RT_USED)
			 cout << setw(3) << "USE ";
		  else if (p_tbl[idx] == (RT_USED | RT_VISITED)) 
			 cout << setw(3) << "VIS ";
		  else {
			 cout << setw(3) << "   ";			 
		  } 
		}
		cout << endl;
	 }
  }  
  return(0);
}

//////////////////////////////////////////////////////////////////////////////

// Trace a loop through a given node ports pair
// We DFS fowrard and report all nodes of all the loops found.
int 
CrdLoopTraceLoop(IBFabric *p_fabric, 
					  IBNode *p_endNode,  
					  int inPortNum, 
					  IBNode *p_startNode, 
					  int outPortNum,
					  string path = string(""),
					  int hops = 0,
                 int doNotPrintPath = 0
					  ) {
  
  // find the other end of the link if any
  IBPort *p_port = p_startNode->getPort(outPortNum);

  // we need to have a port and remote port
  if (! p_port || !p_port->p_remotePort) return 0;

  IBNode *p_remNode = p_port->p_remotePort->p_node;

  // we never go through CAs
  if (p_remNode->type != IB_SW_NODE) return 0;
	
  uint8_t *p_tbl = (uint8_t*)p_remNode->appData1.ptr;
  
  // if it is the target end node and port 
  if (p_remNode == p_endNode && p_port->p_remotePort->num == inPortNum) {
	 // print the path
	 cout << "--------------------------------------------" << endl;
	 cout << "-E- Found a credit loop on:" << p_endNode->name
			<< " from port:" << inPortNum << " to port:" 
			<< outPortNum << endl;
    if (! doNotPrintPath) {
      cout << path << endl;
      cout << p_endNode->name << " " << inPortNum << endl;
    }
	 return(1);
  } else {
	 // track the number of downwards paths found.
	 int numPaths = 0; 
	 static char buf[128];

	 // we will track where we come from
	 sprintf(buf, "%s %u -> ", 
				p_remNode->name.c_str(),p_port->p_remotePort->num);
	 
	 // it is possible we already visited this node since we trace a 
	 // loop that is different then our own.
	 if (path.find(buf) != string::npos) {
      if (! doNotPrintPath) 
        cout << "-W- Marking a 'scroll' side loop at:" 
             << p_remNode->name << "/" << p_port->p_remotePort->num << endl;
		
		// to avoid going into this scroll again
		// we encode a return code that should mark the
		// path as a scroll:
		return -1;
	 }
	 
	 // abort if hops count is bigger then 1000
	 if (hops > 1000) {
      if (! doNotPrintPath)       
        cout << "-W- Aborting path:" << path << endl;
		return 0;
	 }
		
	 // add yourself to the path
	 string fwdPath = path + string("\n") + string(buf);

	 // go over all out ports not aleady marked routed from this in port
	 for (unsigned int pn = 1; pn <= p_remNode->numPorts; pn++) {
		int idx = (p_port->p_remotePort->num - 1)*p_remNode->numPorts + pn - 1;
		
		// do we have a used but not visited connection:
		if (p_tbl[idx] == RT_USED) {
		  // traverse forward
		  sprintf(buf, "%u", pn);
		  int foundPaths = 
			 CrdLoopTraceLoop(p_fabric, p_endNode, inPortNum,
									p_remNode, pn, fwdPath + string(buf), hops++,
                           doNotPrintPath);
		  
		  // we might have encountered a scroll (return value < 0)
		  // so we sould ignore it in the global count.
		  if (foundPaths > 0) numPaths += foundPaths;

		  // if found a loop or a scroll downwards mark the local port pair.
		  if (foundPaths) {
			 p_tbl[idx] = RT_LOOP_TRACED & RT_USED;
		  }
		}
	 }
	 return(numPaths);
  }
}

//////////////////////////////////////////////////////////////////////////////

// Report all Switch ports that are still marked as not 
// fully visited.  
int
CrdLoopReportLoops(IBFabric *p_fabric, int doNotPrintPath) {
  int anyError = 0;

  // go over all switches in the fabric looking for used link to link
  // that was not marked as visited.
  IBNode *p_node;

  // Go over all SW nodes in the fabric and build a table 
  // of input to output ports links. Each element should track
  // effect and traversal flags.
  for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
		 nI != p_fabric->NodeByName.end();
		 nI++) {
	 
	 p_node = (*nI).second;
	 if (p_node->type != IB_SW_NODE) continue;
	
	 uint8_t *p_tbl = (uint8_t*)p_node->appData1.ptr;
	 
	 // Now go over all out ports and check all input port.
	 for (unsigned int inPortNum = 1; inPortNum <= p_node->numPorts;
         inPortNum++) {
		// go over all the out ports marked by this input port:
		for (unsigned int outPortNum = 1; outPortNum <= p_node->numPorts; 
           outPortNum++) {
		  int idx = (inPortNum - 1)*p_node->numPorts + outPortNum - 1;
		  
		  if (p_tbl[idx] == RT_USED) {
			 char buf[16];
			 sprintf(buf, " %u", outPortNum);
			 int loops = CrdLoopTraceLoop(p_fabric, p_node, inPortNum, 
                                       p_node, outPortNum,
													p_node->name + string(buf),
                                       0, doNotPrintPath
													);
			 anyError += loops;
		  }
		}
	 }
  } 
  if (anyError) cout << "--------------------------------------" << endl;
  return anyError;
}

//////////////////////////////////////////////////////////////////////////////

// Prepare the data model 
int 
CrdLoopPrepare(IBFabric *p_fabric) {
  IBNode *p_node;

  // Go over all SW nodes in the fabric and cleanup
  for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
		 nI != p_fabric->NodeByName.end();
		 nI++) {
	 
	 p_node = (*nI).second;
	 if (p_node->type != IB_SW_NODE) continue;
	
	 if (p_node->appData1.ptr) {
		p_node->appData1.ptr = NULL;
	 }
  }
  return 0;
}

// Cleanup the data model 
int 
CrdLoopCleanup(IBFabric *p_fabric) {
  IBNode *p_node;

  // Go over all SW nodes in the fabric and cleanup
  for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
		 nI != p_fabric->NodeByName.end();
		 nI++) {
	 
	 p_node = (*nI).second;
	 if (p_node->type != IB_SW_NODE) continue;
	
	 if (p_node->appData1.ptr) {
		uint8_t *p_tbl = (uint8_t *)p_node->appData1.ptr;
		delete [] p_tbl;
		p_node->appData1.ptr = NULL;
	 }
  }
  return 0;
}

//////////////////////////////////////////////////////////////////////////////

// Top Level Subroutine:
int
CrdLoopAnalyze(IBFabric *p_fabric) {
  
  cout << "-I- Analyzing Fabric for Credit Loops (one VL used)." << endl;

  CrdLoopPrepare(p_fabric);

  // Allocate routing tables on all switches (appData1.ptr)
  CrdLoopInitRtTbls(p_fabric);
  
  // Go over all CA to CA paths and mark the output links
  // input links connections on these paths
  if (CrdLoopPopulateRtTbls(p_fabric)) {
	 cout << "-E- Fail to populate the Routing Tables." << endl;
	 return(1);
  }
  
  // CrdLoopDumpRtTbls(p_fabric);

  // Start BFS from all CA's and require all inputs for an
  // output node to be marked visited to go through it.
  if (CrdLoopBfsFromCAs(p_fabric)) {
	 cout << "-E- Fail to BFS from all CA nodes through the Routing Tables." << endl;
	 return(1);
  }
  
  // Report all Switch ports that are still marked as not 
  // fully visited.  
  int numLoopPorts;
  int doNotPrintPath = 1;
  if ((numLoopPorts = CrdLoopReportLoops(p_fabric, doNotPrintPath))) {
	 cout << "-E- Found:" << numLoopPorts
			<< " Credit Loops" << endl;
  } else {
	 cout << "-I- No credit loops found." << endl;
  }

  // cleanup:
  CrdLoopCleanup(p_fabric);
  
  return 0;
}



