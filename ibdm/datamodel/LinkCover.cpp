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
 * $Id: TraceRoute.cpp,v 1.5 2005/05/29 15:33:05 eitan Exp $
 */

#include "Fabric.h"
#include "TraceRoute.h"
#include <iomanip>
#include <fstream>
#include <map>
using namespace std;

/*
 * The purpose of this file is to provide an algorithm that will 
 * provide back a minimal set of paths to execrsize every link on the fabric
 * 
 * The implemented algorithm is based on availablity of the FDBs
 * it will create and fill a table for each switch which will track
 * foreach Input-port and target-LID if there is a path that goes through
 */

// Data structure: we keep the pin/dLid table as int array.
// The first index is the port number and the second is the dLid.
typedef map< IBNode *, short int*, less< IBNode * > > map_pnode_p_sint;

// Track which src/dst lid pairs were going through each port:
typedef pair< short int, short int > src_dst_lid_pair;
typedef list< src_dst_lid_pair > src_dst_lid_pairs;
typedef map< IBPort *, src_dst_lid_pairs, less< IBPort * > > map_pport_src_dst_lid_pairs;

int getPinTargetLidTableIndex(IBFabric *p_fabric, 
                              int portNum, unsigned int dLid) {
  if (dLid == 0 || dLid > p_fabric->maxLid) {
    cout << "-F- Got dLid which is > maxLid or 0" << endl;
    exit(1);
  }
  return ((p_fabric->maxLid)*(portNum - 1)+ dLid - 1);
}

// simply dump out the content for debug ...
void 
dumpInPortTargetLidTable(IBNode *p_node, 
                         map_pnode_p_sint &switchInRtTbl,
                         map_pnode_p_sint &switchInPortPaths
                         ) {

  IBFabric *p_fabric = p_node->p_fabric;
  map_pnode_p_sint::iterator I = switchInRtTbl.find(p_node);
  if (I == switchInRtTbl.end()) {
    cout << "-E- fail to find input routing table for"
         << p_node->name << endl;
    return;
  }

  short int *tbl = (*I).second;
  cout << "--------------- IN PORT ROUTE TABLE -------------------------" 
       << endl;
  cout << "SWITCH:" << p_node->name << endl;
  cout << "LID   |";

  for (int pn = 1; pn <= p_node->numPorts; pn++) 
    cout << " P" << setw(2) << pn << " |";
  cout << " FDB |" << endl;
  for (int lid = 1; lid <= p_fabric->maxLid; lid++) {
    cout << setw(5) << lid << " |";
    for (int pn = 1; pn <= p_node->numPorts; pn++) {
      int val = tbl[getPinTargetLidTableIndex(p_fabric,pn,lid)];
      if (val)
      {
        cout << " " << setw(3) << val << " |";
      }
      else
        cout << "     |";
    }
    cout << setw(3) << p_node->getLFTPortForLid(lid) << " |" << endl;
  }

  I = switchInPortPaths.find(p_node);
  if (I == switchInPortPaths.end()) {
    cout << "-E- fail to find input paths table for"
         << p_node->name << endl;
    return;
  }

  short int *vec = (*I).second;
  cout << "TOTAL:|";
  for (int pn = 0; pn < p_node->numPorts; pn++) 
    cout << " " << setw(3) << vec[pn] << " |";
  cout << endl;
}

// dump out the node name and how many paths go into each port
void 
dumpInPortNumPaths(
  ostream &s, 
  IBNode *p_node, 
  map_pnode_p_sint &switchInRtTbl,
  vec_int &numInPathsHist)
{
  IBFabric *p_fabric = p_node->p_fabric;
  map_pnode_p_sint::iterator I = switchInRtTbl.find(p_node);
  if (I == switchInRtTbl.end()) {
    cout << "-E- fail to find input routing table for"
         << p_node->name << endl;
    return;
  }

  short int *vec = (*I).second;
  for (int pn = 0; pn < p_node->numPorts; pn++)
  { 
    s << p_node->name << " P" << pn << " " << vec[pn] << endl;
    if (numInPathsHist.size() <= vec[pn]) {
      numInPathsHist.resize(vec[pn]+1);
    }
    numInPathsHist[vec[pn]]++;
  }
}

// Trace a route from slid to dlid by LFT marking each input-port,dst-lid
// with the number of hops through
int traceRouteByLFTAndMarkInPins (
  IBFabric *p_fabric, 
  IBPort *p_srcPort,
  IBPort *p_dstPort,
  unsigned int dLid,
  map_pnode_p_sint &switchPinTargetLidTableMap,
  map_pnode_p_sint &switchPinNumPathsMap,
  map_pport_src_dst_lid_pairs &switchInPortPairsMap
  ) {

  IBNode *p_node;
  IBPort *p_port = p_srcPort;
  IBPort *p_remotePort = NULL;
  unsigned int sLid = p_srcPort->base_lid;
  int hopCnt = 0;

  if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE) {
    cout << "-V-----------------------------------------------------" << endl;
    cout << "-V- Tracing from lid:" << sLid << " to lid:"
         << dLid << endl;
  }
  
  
  // if the port is not a switch - go to the next switch:
  if (p_port->p_node->type != IB_SW_NODE) {
    // try the next one:
    if (!p_port->p_remotePort) {
      cout << "-E- Provided starting point is not connected !"
           << "lid:" << sLid << endl;
      return 1;
    }
	 // we need gto store this info for marking later
	 p_remotePort = p_port->p_remotePort;
    p_node = p_remotePort->p_node;
	 hopCnt++;
    if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE) 
      cout << "-V- Arrived at Node:" << p_node->name
           << " Port:" << p_port->p_remotePort->num << endl;
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
	 if (p_remotePort) {
		IBNode *p_remoteNode = p_remotePort->p_node;
		if (p_remoteNode->type == IB_SW_NODE) {
		  // mark the input port p_remotePort we got to:
		  map_pnode_p_sint::iterator I = 
			 switchPinTargetLidTableMap.find(p_remoteNode);
		  if (I == switchPinTargetLidTableMap.end()) {
			 cout << "-E- No entry for node:" << p_remoteNode->name 
					<< " in switchPinTargetLidTableMap" << endl;
			 return 1;
		  }
		  int idx = getPinTargetLidTableIndex(p_fabric, p_remotePort->num, dLid);
		  (*I).second[idx] = hopCnt;
		  if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE) {
			 cout << "-I- Marked node:" << p_remoteNode->name
					<< " port:" << p_remotePort->num << " dlid:" << dLid 
					<< " with hops:" << hopCnt << endl;
		  }

        // now just count:
        I = switchPinNumPathsMap.find(p_remoteNode);
		  if (I == switchPinNumPathsMap.end()) {
			 cout << "-E- No entry for node:" << p_remoteNode->name 
					<< " in switchPinNumPathsMap" << endl;
			 return 1;
		  }
        short int *vec = (*I).second;
        vec[p_remotePort->num - 1]++;

        // now go track all pairs for that port
        pair< short int, short int > tmpPair(sLid,dLid);
        switchInPortPairsMap[p_remotePort].push_back(tmpPair);
		}
	 }
    
    // calc next node:
    int pn = p_node->getLFTPortForLid(dLid);
    if (pn == IB_LFT_UNASSIGNED) {
      cout << "-E- Unassigned LFT for lid:" << dLid
           << " Dead end at:" << p_node->name << endl;
      return 1;
    }
    
    // if the port number is 0 we must have reached the target node.
    // simply try see that p_remotePort of last step == p_dstPort
    if (pn == 0) {
      if (p_dstPort != p_remotePort) {
        cout << "-E- Dead end at port 0 of node:" << p_node->name << endl;
        return 1;
      }
      return 0;
    }

    // get the port on the other side
    p_port = p_node->getPort(pn);
    if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE)
      cout << "-V- Going out on port:" << pn << endl;
    
    if (! (p_port && 
           p_port->p_remotePort && 
           p_port->p_remotePort->p_node)) {
      cout << "-E- Dead end at:" << p_node->name << endl;
      return 1;
    }
    
    if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE)
      cout << "-V- Arrived at Node:" << p_port->p_remotePort->p_node->name
           << " Port:" << p_port->p_remotePort->num << endl;
    
    p_remotePort = p_port->p_remotePort;

    // check if we are done:
    done = (p_remotePort == p_dstPort);
    
    p_node = p_remotePort->p_node;
    if (hopCnt++ > 256) {
      cout << "-E- Aborting after 256 hops - loop in LFT?" << endl;
      return 1;
    }
  }

  if (done) 
  {
    // ok we got there so track it
    pair< short int, short int > tmpPair(sLid,dLid);
    switchInPortPairsMap[p_remotePort].push_back(tmpPair);
  }

  return 0;
}

int
cleanupFdbForwardPortLidTables(IBFabric *p_fabric, 
                               map_pnode_p_sint &switchPinTargetLidTableMap,
                               map_pnode_p_sint &switchOutPortCoveredMap,
                               map_pnode_p_sint &switchPinNumPathsMap
                               )
{
  IBNode *p_node;

  for( map_pnode_p_sint::iterator I = switchPinTargetLidTableMap.begin();
       I != switchPinTargetLidTableMap.end();
       I++) {

    short int *pinPassThroughLids = (*I).second;
    free(pinPassThroughLids);
  }

  for( map_pnode_p_sint::iterator I = switchOutPortCoveredMap.begin();
       I != switchOutPortCoveredMap.end();
       I++) {

    short int *outPortCovered = (*I).second;
    free(outPortCovered);
  }

  for( map_pnode_p_sint::iterator I = switchPinNumPathsMap.begin();
       I != switchPinNumPathsMap.end();
       I++) {

    short int *vec = (*I).second;
    free(vec);
  }
}

// filter some illegal chars in name
string
getPortLpName(IBPort *p_port)
{
  string res = p_port->getName();
  string::size_type s;
  
  while ((s = res.find('-')) != string::npos) {
    res.replace(s, 1, "_");
  }
  return (res);
}


// dump out the linear programming matrix in LP format for covering all links:
// a target line - we want to maximize the number of links excersized
// Link1 + Link2 + Link3  ....
// Per link we want only one pair...
// Link1: 0 = Link1 + Pslid-dlid + ...
// finally declare all Pslid-dlid <= 1 and all Links <= 1
int 
dumpLinearProgram(IBFabric *p_fabric, 
                  map_pport_src_dst_lid_pairs &switchInPortPairsMap)
{
  set< string > vars;
  int numLinks = 0;
  IBNode *p_node;
  ofstream linProgram("/tmp/ibdmchk.lp");

  // we need a doubel path - first collect all in ports and 
  // dump out the target - maximize number of links covered
  for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
       nI != p_fabric->NodeByName.end();
       nI++) {
    p_node = (*nI).second;
    
    // go over all the input ports of the node and if has paths 
    // add to the program target
    for (int pn = 1; pn <= p_node->numPorts; pn++)
    {
      IBPort *p_port = p_node->getPort(pn);
      if (p_port)
      {
        if (switchInPortPairsMap[p_port].size()) 
        {
          string varName = string("L") + getPortLpName(p_port);
          vars.insert(varName);
          if (numLinks) linProgram << "+ " ;
          if (numLinks && (numLinks % 8 == 0)) linProgram << endl;
          linProgram << varName << " ";
          numLinks++;
        }
      }
    }
  }

  linProgram << ";" << endl;

  // second pass we write down each link equation:
  for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
       nI != p_fabric->NodeByName.end();
       nI++) {
    p_node = (*nI).second;
    
    // go over all the input ports of the node and if has paths 
    // add to the program target
    for (int pn = 1; pn <= p_node->numPorts; pn++)
    {
      IBPort *p_port = p_node->getPort(pn);
      if (p_port)
      {
        if (switchInPortPairsMap[p_port].size()) 
        {
          string varName = string("L") + getPortLpName(p_port);
          linProgram << varName;
          for (src_dst_lid_pairs::iterator lI = switchInPortPairsMap[p_port].begin();
               lI != switchInPortPairsMap[p_port].end();
               lI++)
          {
            char buff[128];
            sprintf(buff, "P%u_%u", (*lI).first,  (*lI).second); 
            string pName = string(buff);
            vars.insert(pName);
            linProgram << " -" << pName ;
          }
          linProgram << " = 0;" << endl;
        }
      }
    }
  }
  
  // now dump out the int and bounds for each variable
  for (set<string>::iterator sI = vars.begin(); sI != vars.end(); sI++) 
  {
    linProgram << *sI << " <= 1;" << endl;
  }
  
  for (set<string>::iterator sI = vars.begin(); sI != vars.end(); sI++) 
  {
    linProgram << "int " << *sI << " ;" << endl;
  }
  linProgram.close();  
}

int
initFdbForwardPortLidTables(IBFabric *p_fabric, 
                            map_pnode_p_sint &switchPinTargetLidTableMap,
                            map_pnode_p_sint &switchOutPortCoveredMap,
                            map_pnode_p_sint &switchPinNumPathsMap,
                            map_pport_src_dst_lid_pairs &switchInPortPairsMap
									 )
{
  IBNode *p_node;
  int anyError = 0;
  int numPaths = 0;

  // check the given map is empty or return error
  if (!switchPinTargetLidTableMap.empty()) {
    cout << "-E- initFdbForwardPortLidTables: provided non empty map" << endl;
    return 1;
  }

  // go over all switches and allocate and initialize the "pin target lids"
  // table
  for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
       nI != p_fabric->NodeByName.end();
       nI++) {
    p_node = (*nI).second;
    
    // we should not assign hops for non SW nodes:
    if (p_node->type != IB_SW_NODE) continue;
    
    // allocate a new table by the current fabric max lid ...
    int tableSize = p_fabric->maxLid * p_node->numPorts;
    short int *pinPassThroughLids = 
      (short int *)calloc(sizeof(short int), tableSize);
    if (! pinPassThroughLids) {
      cout << "-E- initFdbForwardPortLidTables: fail to allocate table" 
           << endl;
      return 1;
    }
    switchPinTargetLidTableMap[p_node] = pinPassThroughLids;

	 short int *outPortCovered = 
      (short int *)calloc(sizeof(short int), p_node->numPorts);
    if (! outPortCovered) {
      cout << "-E- initFdbForwardPortLidTables: fail to allocate table" 
           << endl;
      return 1;
    }
	 switchOutPortCoveredMap[p_node] = outPortCovered;

	 short int *inPortPaths = 
      (short int *)calloc(sizeof(short int), p_node->numPorts);
    if (! inPortPaths) {
      cout << "-E- initFdbForwardPortLidTables: fail to allocate table" 
           << endl;
      return 1;
    }
    switchPinNumPathsMap[p_node] = inPortPaths;
  }
  
  // go from all HCA to all other HCA and mark the input pin target table
  // go over all ports in the fabric 
  IBPort *p_srcPort, *p_dstPort;
  unsigned int sLid, dLid;
  int hops; // dummy - but required by the LFT traversal
  int res; // store result of traversal
  for (sLid = p_fabric->minLid; sLid <= p_fabric->maxLid; sLid++) {
    IBPort *p_srcPort = p_fabric->PortByLid[sLid];
         
    if (!p_srcPort || (p_srcPort->p_node->type == IB_SW_NODE)) continue;
    
    // go over all the rest of the ports:
    for (dLid = p_fabric->minLid; dLid <= p_fabric->maxLid; dLid++ ) {
      IBPort *p_dstPort = p_fabric->PortByLid[dLid]; 
      
      // Avoid tracing to itself
      if ((dLid == sLid) || (! p_dstPort) || 
          (p_dstPort->p_node->type == IB_SW_NODE)) continue;
      
      numPaths++;

      // Get the path from source to destination
      res = traceRouteByLFTAndMarkInPins(p_fabric, p_srcPort, p_dstPort, dLid, 
                                         switchPinTargetLidTableMap,
                                         switchPinNumPathsMap, 
                                         switchInPortPairsMap);
      if (res) {
        cout << "-E- Fail to find a path from:" 
             << p_srcPort->p_node->name << "/" << p_srcPort->num
             << " to:" << p_dstPort->p_node->name << "/" << p_dstPort->num
             << endl;
        anyError++;
      } 
    } // each dLid
  } // each sLid

  // Dump out what we found for each switch
  if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE) {
    for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
         nI != p_fabric->NodeByName.end();
         nI++) {
      p_node = (*nI).second;
      
      if (p_node->type != IB_SW_NODE) continue;
      dumpInPortTargetLidTable(
        p_node, switchPinTargetLidTableMap, switchPinNumPathsMap);
    }
  } // verbose

  
#if 0 // we already provided this info during all to all traversal check

  // collect the input paths histogram
  vec_int numInPathsHist(50,0);

  // Dump out a file of the number of paths going each input port
  ofstream linkUsage("/tmp/ibdmchk.linkutil");
  for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
       nI != p_fabric->NodeByName.end();
       nI++) {
    p_node = (*nI).second;
    
    if (p_node->type != IB_SW_NODE) continue;
    dumpInPortNumPaths(linkUsage, p_node, switchPinNumPathsMap, 
                       numInPathsHist);
  }
  linkUsage.close();
  cout << "------------------ NUM INPUT PATHS PER PORTS HISTOGRAM --------------------" << endl;
  cout << "This histogram provides the actual number of paths going through eahc switch port." << endl;
  cout << "A normal fabric should have few big bins - one for each switch level." << endl;
  cout << "-I- Traced:" << numPaths << " HCA to HCA Paths through LFT" << endl;
  cout << "IN-PATHS NUM-SW-PORTS" << endl; 
  for (int b = 0; b < numInPathsHist.size() ; b++) 
    if (numInPathsHist[b])
      cout << setw(4) << b << "   " << numInPathsHist[b] << endl;
  cout << "---------------------------------------------------------------------------\n" << endl;
#endif
  dumpLinearProgram(p_fabric, switchInPortPairsMap);

  return(anyError);
}

//////////////////////////////////////////////////////////////////////////////
int
LinkCoverageAnalysis(IBFabric *p_fabric)
{
  // map switch nodes to a table of hop(in pin, dlid)
  map_pnode_p_sint switchPinTargetLidTableMap;
  // map switch nodes to a vector for each out port that tracks if covered
  map_pnode_p_sint switchOutPortCoveredMap;
  // map switch nodes to a vector of number of paths entering each port
  map_pnode_p_sint switchPinNumPathsMap;
  // map switch input ports to a list of slid dlid pairs
  map_pport_src_dst_lid_pairs switchInPortPairsMap;

  // initialize the data structures
  if (initFdbForwardPortLidTables(p_fabric, 
											 switchPinTargetLidTableMap, 
											 switchOutPortCoveredMap,
                                  switchPinNumPathsMap,
                                  switchInPortPairsMap
                                  )) {
    return(1);
  }

  // do the magic...
#if 0 
  // sort all switches by the max distance from HCA
  
  // go over all switches and treat their output ports
  for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
       nI != p_fabric->NodeByName.end();
       nI++) {
    IBNode *p_node = (*nI).second;
    
    // we should not assign hops for non SW nodes:
    if (p_node->type != IB_SW_NODE) continue;
	 
	 map_pnode_p_sint::iterator cI = switchOutPortCoveredMap.find(p_node);
	 if (cI == switchOutPortCoveredMap.end()) {
		cout << "-E- How come we do not have an initialized table?" << endl;
		return 1;
	 }

	 short int *outPortCovered = (*cI).second;

	 for (int pn = 1; pn <= p_node->numPorts; pn++) {
		// was this port covered?
		if (outPortCovered[pn - 1]) continue;
		
		// get the first dlid that will go through this port and has the min 
		// in-port hop
		// is there any path going through that port?
		int found = 0;
		for (unsigned int lid = 1; lid <= p_fabric->maxLid; lid++) {
		  if (p_node->getLFTPortForLid(lid) == pn) {
			 found = 1;
			 break;
		  }
		}

		// also we want to make sure the 
		for (int lid 
	 }
  }
#endif

  // cleanup
  cleanupFdbForwardPortLidTables(
    p_fabric, switchPinTargetLidTableMap, 
    switchOutPortCoveredMap, switchPinNumPathsMap);
  
  return(0);
}
