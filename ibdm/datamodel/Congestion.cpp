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
#include "SubnMgt.h"
#include "TraceRoute.h"
#include <iomanip>
#include <fstream>
#include <sstream>
#include <map>
using namespace std;

/*
 * This file provides an API for analyzing congestion on the fabric
 * Link over subscription statistics are being provided as follows:
 * 
 * CongInit(p_fabric) - initialize the data structures
 * CongZero(p_fabric) - zero out the paths per link counter
 * CongTrackPath(p_fabric, srcLid, dstLid) - trace one path
 * CongReport(p_fabric, stream &out) - report histogram
 * CongDump(p_fabric, fileName) - dump out the paths
 * CongCleanup(p_fabric) - cleanup
 *
 * The implemented algorithm is based on availablity of the FDBs
 */

// the main data structure we keeo is the list if paths going out
// on every out port of every node.
typedef list< pair< uint16_t, uint16_t> > list_src_dst;
typedef map< IBPort *, list_src_dst, less<IBPort * > > map_pport_paths;

// for each fabric we keep:
class CongFabricData {
public:
  map_pport_paths portPaths;
  long            numPaths;
  int             stageWorstCase;
  list<int>       stageWorstCases;
  vec_int         numPathsHist;
  IBPort         *p_worstPort;
  CongFabricData() { stageWorstCase = 0; p_worstPort = NULL; numPaths = 0;};
};

typedef map< IBFabric*, CongFabricData, less< IBFabric *> > map_pfabric_cong;

map_pfabric_cong CongFabrics;

// Initialize the congestion tracking for the fabric.
int  CongInit(IBFabric *p_fabric)
{
  if (CongFabrics.find(p_fabric) != CongFabrics.end())
  {
    cout << "-E- Congestion Tracker already initialized" << endl;
    return(1);
  }

  CongFabrics[p_fabric] = CongFabricData();
  map_pport_paths &portPaths = CongFabrics[p_fabric].portPaths;

  // init the vector for each connected port of the fabric:
  IBNode *p_node;
  IBPort *p_port;
  for( map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
       nI != p_fabric->NodeByName.end();
       nI++) 
  {
    p_node = (*nI).second;
    
    for( unsigned int pn = 1; pn <= p_node->numPorts; pn++)
    {
      p_port = p_node->getPort(pn);
      if (!p_port || ! p_port->p_remotePort) continue;

      portPaths[p_port] = list_src_dst();
    }
  }
  return(0);
}

// Cleanup...
int 
CongCleanup(IBFabric *p_fabric) 
{
  // get the reference to the actual data structure:
  map_pfabric_cong::iterator cI = CongFabrics.find(p_fabric);
  if (cI == CongFabrics.end())
  {
    cout << "-E- Congestion Tracker not previously initialized" << endl;
    return(1);
  }
  
  // remove the entry should delete the entire structure:
  CongFabrics.erase(cI);
  return(0);
}

// initialize new set of congestion tracking for the given fabric
// error if invoked without an init 
int 
CongZero(IBFabric *p_fabric) 
{
  // get the reference to the actual data structure:
  map_pfabric_cong::iterator cI = CongFabrics.find(p_fabric);
  if (cI == CongFabrics.end())
  {
    cout << "-E- Congestion Tracker not previously initialized" << endl;
    return(1);
  }

  CongFabricData &congData = (*cI).second;

  // store out worst case
  congData.stageWorstCases.push_back(congData.stageWorstCase);
  congData.stageWorstCase = 0;

  // update the histogram before cleanup
  for (map_pport_paths::iterator pI = congData.portPaths.begin();
       pI != congData.portPaths.end();
       pI++)
  {
    for(unsigned int i = congData.numPathsHist.size();
        i <= (*pI).second.size(); i++)
      congData.numPathsHist.push_back(0);

	int numPaths = (*pI).second.size();
    congData.numPathsHist[numPaths]++;

	if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE)
	{
	   if (numPaths > 1)
	   {
		  cout << "-V- port:" << (*pI).first->getName() << " coliding:";
		  for (list_src_dst::iterator lI = (*pI).second.begin();
				lI != (*pI).second.end();
				lI++)
			 cout << (*lI).first << "," << (*lI).second << " ";
		  cout << endl;
	   }
	}
    (*pI).second.clear();
  }
  return(0);
}

// Track a single path 
int 
CongTrackPath(IBFabric *p_fabric, uint16_t srcLid, uint16_t dstLid)
{
  // get the reference to the actual data structure:
  map_pfabric_cong::iterator cI = CongFabrics.find(p_fabric);
  if (cI == CongFabrics.end())
  {
    cout << "-E- Congestion Tracker not previously initialized" << endl;
    return(1);
  }

  CongFabricData &congData = (*cI).second;

  // find the source and destination ports:
  IBPort *p_srcPort = p_fabric->getPortByLid(srcLid);
  if (! p_srcPort)
  {
    cout << "-E- Fail to find port by source LID:" << srcLid << endl;
    return(1);
  }
  
  IBPort *p_dstPort = p_fabric->getPortByLid(dstLid);
  if (! p_dstPort)
  {
    cout << "-E- Fail to find port by destination LID:" << dstLid << endl;
    return(1);
  }

  pair< uint16_t, uint16_t> pathPair(srcLid, dstLid);

  IBNode *p_node;
  IBPort *p_port = p_srcPort;
  IBPort *p_remotePort = NULL;
  int hopCnt = 0;

  if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE)
  {
    cout << "-V-----------------------------------------------------" << endl;
    cout << "-V- Tracing from lid:" << srcLid << " to lid:"
         << dstLid << endl;
  }
 
  // if the port is not a switch - go to the next switch:
  if (p_port->p_node->type != IB_SW_NODE)
  {
    // try the next one:
    if (!p_port->p_remotePort)
    {
      cout << "-E- Provided starting point is not connected !"
           << "lid:" << srcLid << endl;
      return 1;
    }

    p_remotePort = p_port->p_remotePort;
    p_node = p_remotePort->p_node;
    hopCnt++;
    if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE)
      cout << "-V- Arrived at Node:" << p_node->name
           << " Port:" << p_port->p_remotePort->num << endl;
  }
  else
  {
    // it is a switch :
    p_node = p_port->p_node;
  }

  // verify we are finally on a switch:
  if (p_node->type != IB_SW_NODE)
  {
    cout << "-E- Provided starting point is not connected to a switch !"
         << "lid:" << srcLid << endl;
    return 1;
  }

  // traverse:
  int done = 0;
  while (!done) {   

    // we need to store this info for marking later
    list_src_dst &lst = congData.portPaths[p_port];
    lst.push_back(pathPair);
    if (lst.size() > congData.stageWorstCase)
    {
      congData.stageWorstCase = lst.size();
      congData.p_worstPort = p_port;
    }

    // calc next node:
    int pn = p_node->getLFTPortForLid(dstLid);
    if (pn == IB_LFT_UNASSIGNED)
    {
      cout << "-E- Unassigned LFT for lid:" << dstLid
           << " Dead end at:" << p_node->name << endl;
      return 1;
    }
   
    // if the port number is 0 we must have reached the target node.
    // simply try see that p_remotePort of last step == p_dstPort
    if (pn == 0)
    {
      if (p_dstPort != p_remotePort)
      {
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
    if (hopCnt++ > 256)
    {
      cout << "-E- Aborting after 256 hops - loop in LFT?" << endl;
      return 1;
    }
  }

  congData.numPaths++;
  return(0);
}

// Report the worst usage and a histogram of link usage
int 
CongReport(IBFabric *p_fabric, ostringstream &out)
{
  int worstWorstPath = 0;
  map<int, int, less<int> > stageWorstCaseHist;

  // get the reference to the actual data structure:
  map_pfabric_cong::iterator cI = CongFabrics.find(p_fabric);
  if (cI == CongFabrics.end())
  {
    cout << "-E- Congestion Tracker not previously initialized" << endl;
    return(1);
  }

  CongFabricData &congData = (*cI).second;

  // collect the histogram of stage worst paths
  for(list<int>::iterator lI = congData.stageWorstCases.begin();
      lI != congData.stageWorstCases.end();
      lI++)
  {
    stageWorstCaseHist[*lI]++;
    if (worstWorstPath < *lI) worstWorstPath = (*lI);
  }
  
  out << "---------------------------------------------------------------------------\n" << endl;
  out << "-I- Traced total:" << congData.numPaths << " paths" << endl;

  out << "-I- Worst link over subscrition:" << worstWorstPath
      << " port:" << congData.p_worstPort->getName() << endl;

  out << "---------------------- TOTAL CONGESTION HISTOGRAM ------------------------" << endl;
  out << "Describes distribution of oversubscription of paths per port." << endl;
  out << "NUM-PATHS NUM-OUT-PORTS" << endl; 
  for (int b = 0; b < congData.numPathsHist.size() ; b++)
    if (congData.numPathsHist[b])
      out << setw(4) << b << "   " << congData.numPathsHist[b] << endl;
  out << "---------------------------------------------------------------------------\n" << endl;

  out << "---------------------- STAGE CONGESTION HISTOGRAM ------------------------" << endl;
  out << "Describes distribution of worst oversubscription of paths per stage." << endl;
  out << "WORST-CONG NUM-STAGES" << endl; 
  for (map<int, int, less<int> >::iterator bI = stageWorstCaseHist.begin();
       bI != stageWorstCaseHist.end(); 
       bI++)
    out << setw(4) << (*bI).first << "   " << (*bI).second << endl;
  out << "---------------------------------------------------------------------------\n" << endl;
  return(0);
}

// Dump out all link usages and details if available into
// the given ostream
int 
CongDump(IBFabric *p_fabric, ostringstream &out)
{
  // get the reference to the actual data structure:
  map_pfabric_cong::iterator cI = CongFabrics.find(p_fabric);
  if (cI == CongFabrics.end())
  {
    cout << "-E- Congestion Tracker not previously initialized" << endl;
    return(1);
  }

  CongFabricData &congData = (*cI).second;

  // go over all ports and dump out their paths...
  for (map_pport_paths::iterator pI = congData.portPaths.begin();
       pI != congData.portPaths.end();
       pI++)
  {
    out << "PORT:" << (*pI).first->getName() << endl;
    for ( list_src_dst::iterator lI = (*pI).second.begin();
          lI != (*pI).second.end();
          lI++)
      out << (*lI).first << " " << (*lI).second << endl;
  }
  return(0);
}

