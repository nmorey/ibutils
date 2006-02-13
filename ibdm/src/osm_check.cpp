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
 * $Id: osm_check.cpp,v 1.9 2005/06/01 20:19:07 eitan Exp $
 */

#include "Fabric.h" 
#include "SubnMgt.h"
#include "CredLoops.h"
#include <getopt.h>
#include <fstream>

using namespace std;

void
show_usage() {
  cout << "Usage: there are two modes: Design/Verify" << endl;
  cout << "  Design: ibdmchk [-v][-h][-e][-u][-l <lmc>][-r <roots file>] -t <topology file> -n <SM Node> -p <SM Port>" << endl;
  cout << "  Verify: ibdmchk [-v][-h][-l <lmc>][-r <roots file>] [-s <subnet file>] [-f <fdb file>] [-m <mcfdb file>]" << endl;
}

void 
show_help() {
  cout 
    << " IBDM Topology - Checker\n"
    << "--------------------------\n"
    << "\n"
    << "Usage: \n"
    << " ibdmchk has two operation modes: cluster design and verification.\n"
    << "\n"
    << "  CLUSTER DESIGN:\n"
    << "  Usage:\n"
    << "   ibdmchk [-v][-h][-u][-a <roots file>] -t <topology file> -n <SM Node> -p <SM Port> [-e] [-l <lmc>]\n\n" 
    << "  Description:\n"
    << "   The Design mode is intended to be used before the cluster is built. It provides \n"
    << "   basic checks of the specified network as described by a topology file.\n"
    << "   After simulating the SM LID assignment and routing algorithms it provides reports\n"
    << "   of the CA to CA paths depth histogram and credit deadlock potential \n"
    << "   in the resulting routing scheme.\n\n"
    << "  Arguments (required):\n"
    << "  -t|--topo <topo file> = the topology file specifying the fabric.\n"
    << "  -n|--node <SM Node> = the name of the Subnet Manager node (syntax: <Topo-File-System>/U1)\n"
    << "  -p|--port <SM Port> = the port number by which the SM nodes is attached to the fabric.\n"
    << "\n"
    << "  Options:\n"
    << "  -v|--verbose = verbsoe mode\n"
    << "  -h|--help = provide this help message\n"
    << "  -l|--lmc <lmc> = LMC value > 0 means assigning 2^lmc lids to each port.\n"
    << "  -e|--enh = use enhanced routing algorithm when LMC > 0 and report the resulting paths\n"
    << "       correlation (using same system/node) histogram\n"
    << "  -u|--updn = use up/down routing algorithm instead of OpenSM min-hop.\n"
    << "  -r|--roots <roots file> = a file with all the roots node names (one on each line).\n"
    << "\n"
    << "  CLUSTER VERIFICATION:\n"
    << "  Usage:\n"    
    << "   ibdmchk [-v][-h][-r <roots file>] [-s <subnet file>] [-f <fdb file>] [-l <lmc>]\n\n"
    << "  Description:\n"
    << "   After the cluster is built and OpenSM is run (using flag -D 0x43) it reports the\n"
    << "   subnet and FDB tables into the files /tmp/subnet.lst and /tmp/osm.fdbs.\n"
    << "   Based on these files the utility checks all CA to CA connectivity. Further analysis\n"
    << "   for credit deadlock potential is performed and reported. \n"
    << "   In case of an LMC > 0 it reports histograms for how many systems and nodes\n"
    << "   are common between the different paths for the same port pairs.\n"
    << "\n"
    << "  Arguments (required):\n"
    << "  -l|--lmc <lmc> = The LMC value used while running OpenSM. Mandatory if not the default 0.\n"
    << "\n"
    << "  Options:\n"
    << "  -v|--verbose = verbsoe mode\n"
    << "  -h|--help = provide this help message\n"
    << "  -s|--subnet <file> = OpenSM subnet.lst file (default is /tmp/subnet.lst)\n"
    << "  -f|--fdb <file> = OpenSM dump of Ucast LFDB. Use -D 0x41 to generate it.\n"
    << "     (default is /tmp/osm.fdbs).\n"
    << "  -m|--mcfdb <file> = OpenSM dump of Multicast LFDB. Use -D 0x41 to generate it.\n"
    << "     (default is /tmp/osm.mcfdbs).\n"
    << "  -r|--roots <roots file> = a file holding all root nodes guids (one per line).\n"
    << "\n"
    << "Author: Eitan Zahavi, Mellanox Technologies LTD.\n"
    << endl;
}

list <IBNode *> 
ParseRootNodeNamesFile( IBFabric *p_fabric, string fileName)
{
  ifstream namesFile;
  namesFile.open(fileName.c_str(), ifstream::in);
  if (!namesFile.is_open())
  {
    cout << "-F- Given roots file could not be opened!" << endl;
    exit(1); 
  }
  
  char name[256];
  list <IBNode *> roots;
  cout << "-I- Parsing Root Node Names from file:" << fileName << endl;
  namesFile.getline(name,256);
  while (namesFile.good())
  {
    IBNode *pNode = p_fabric->getNode(string(name));
    if (!pNode) 
    {
      cout << "-E- Fail to find node:" << name << endl;
    }
    else
    {
      roots.push_back(pNode);
    }
    namesFile.getline(name,256);
  }
  cout << "-I- Defined " << roots.size() << " root nodes" << endl;
  namesFile.close();
  return roots;
}

list <IBNode *> 
ParseRootNodeGuidsFile( IBFabric *p_fabric, string fileName)
{
  ifstream guidsFile;
  guidsFile.open(fileName.c_str(), ifstream::in);
  if (!guidsFile.is_open())
  {
    cout << "-F- Given roots file could not be opened!" << endl;
    exit(1); 
  }

  uint64_t guid;
  list <IBNode *> roots;

  guidsFile >> guid;
  while (guidsFile.good())
  {
    IBNode *pNode = p_fabric->getNodeByGuid(guid);
    if (!pNode) 
    {
      char g[20];
      sprintf(g,"%016" PRIx64, guid);
      cout << "-E- Fail to find node guid:" << g << endl;
    }
    else
    {
      roots.push_back(pNode);
    }
    guidsFile >> guid;

  }
  
  guidsFile.close();
  return roots;  
}

int main (int argc, char **argv) {

  FabricUtilsVerboseLevel = FABU_LOG_ERROR;
  string subnetFile = string("/tmp/subnet.lst");
  string fdbFile = string("/tmp/osm.fdbs");
  string mcFdbFile = string("/tmp/osm.mcfdbs");
  string TopoFile = string("");
  string SmNodeName = string("");
  string RootsFileName = string("");
  int EnhancedRouting = 0;
  int lmc = 0;
  int SmPortNum  = -1;
  int UseUpDown = 0;
  int AllPaths = 0;

  /*
	* Parseing of Command Line 
	*/

  char next_option;
  const char * const short_option = "vhl:s:f:m:el:t:p:n:uar:";
  /*
	 In the array below, the 2nd parameter specified the number
	 of arguments as follows:
	 0: no arguments
	 1: argument
	 2: optional
  */
  const option long_option[] =
	 {
		{	"verbose",	1,	NULL,	'v'},
		{	"help",		1,	NULL,	'h'},
		{	"lmc",		1,	NULL,	'l'},
		{	"subnet",	1,	NULL,	's'},
		{	"fdb",	   1,	NULL,	'f'},
		{	"mcfdb",	   1,	NULL,	'm'},
		{	"topology",	1,	NULL,	't'},
      {  "node",     1, NULL, 'n'}, 
  		{	"port",	   1,	NULL,	'p'},
      {  "enh",      0, NULL, 'e'},
      {  "updn",     0, NULL, 'u'},
      {  "roots",    1, NULL, 'r'},
      {  "all",      0, NULL, 'a'},
		{	NULL,		0,	NULL,	 0 }	/* Required at the end of the array */
	 };
  
  printf("-------------------------------------------------\n");
  do
  {
	 next_option = getopt_long(argc, argv, short_option,long_option, NULL);
	 switch(next_option)
	 {
	 case 'h':
		show_help();
		return 0;
		break;

	 case 'v':
		/*
		  Verbose Mode
		*/
		FabricUtilsVerboseLevel |= FABU_LOG_VERBOSE;
		printf(" Verbose Mode\n");
		break;
		
	 case 'l':
		/*
		  Specifies lmc
		*/
		lmc = atoi(optarg);
		break;
			
	 case 'f':
		/*
		  Specifies FDB
		*/
		fdbFile = string(optarg);
		break;

	 case 'm':
		/*
		  Specifies Multicast FDB
		*/
		mcFdbFile = string(optarg);
		break;

	 case 's':
		/*
		  Specifies Subnet
		*/
		subnetFile = string(optarg);
		break;

	 case 't':
		/*
		  Specifies Topology
		*/
		TopoFile = string(optarg);
		break;
      
	 case 'n':
		/*
		  Specifies SM Node
		*/
		SmNodeName = string(optarg);
		break;
      
 	 case 'p':
		/*
		  Specifies SM Port Num
		*/
		SmPortNum = atoi(optarg);
		break;

	 case 'e':
		/*
		  Enhanced Routing
		*/
		EnhancedRouting = 1;
		break;
      
	 case 'r':
		/*
		  Use Roots File
		*/
		RootsFileName = string(optarg);
		break;

	 case 'u':
		/*
		  Use Up Down Routing
		*/
		UseUpDown = 1;
		break;

	 case 'a':
		/*
		  Use Up Down Routing
		*/
		AllPaths = 1;
		break;

	 case -1:
		break; /* done with option */
	 default: /* something wrong */
		show_usage();
		exit(1);
	 }
  }
  while(next_option != -1);

  int status = 0;
  IBFabric fabric;	
    
  /* based on the topology file we decide what mode we are: */
  if (TopoFile.size()) {
    printf("IBDMCHK Cluster Design Mode:\n");
    printf(" Topology File .. %s\n", TopoFile.c_str());
    printf(" SM Node ........ %s\n", SmNodeName.c_str());
    printf(" SM Port ........ %u\n", SmPortNum);
    printf(" LMC ............ %u\n", lmc);
    if (EnhancedRouting && lmc > 0) 
      printf(" Using Enhanced Routing\n");
    if (RootsFileName.size())
      printf(" Roots File ..... %s\n", RootsFileName.c_str());
    
    if (fabric.parseTopology(TopoFile)) {
      cout << "-E- Fail to parse topology file:" << TopoFile << endl;
      exit(1);
    }
    
	// get the SM Port
	IBNode *p_smNode = fabric.getNode(SmNodeName);
	if (! p_smNode ) {
	  cout << "-E- Fail to find SM node:" << SmNodeName << endl;
	  exit(1);
	}

	IBPort *p_smPort = p_smNode->getPort(SmPortNum);
	if (! p_smPort) {
	  cout <<  "-E- Fail to find SM Port: " << SmNodeName 
			 << "/" << SmPortNum << endl;
	  exit(1);
	}
	
	// assign lids
	if (SubnMgtAssignLids(p_smPort,lmc)) {
	  cout << "-E- Fail to assign LIDs." << endl;
	  exit(1);
	}
   
   // we need to run min hop calculation anyway
   if (SubnMgtCalcMinHopTables(&fabric)) {
     cout << "-E- Fail to update Min Hops Tables." << endl;
     exit(1);
   }
   
   if (UseUpDown) {
     list <IBNode *> rootNodes;
     if (RootsFileName.size())
     {
       rootNodes = ParseRootNodeNamesFile(&fabric, RootsFileName);
     }
     else
     {
       rootNodes = SubnMgtFindRootNodesByMinHop(&fabric);
     }
     
     if (!rootNodes.empty()) {
       cout << "-I- Recognized " << rootNodes.size() << " root nodes:" << endl;
       for (list <IBNode *>::iterator nI = rootNodes.begin();
            nI != rootNodes.end(); nI++) {
         cout << " " << (*nI)->name << endl;
       }
       cout << "---------------------------------------------------------------------------\n" << endl;
       
       map_pnode_int nodesRank;
       SubnRankFabricNodesByRootNodes(&fabric, rootNodes, nodesRank);

       if (SubnMgtCalcUpDnMinHopTbls(&fabric, nodesRank)) {
         cout << "-E- Fail to update Min Hops Tables." << endl;
         exit(1);
       }
     } else {
       cout << "-E- Fail to recognize any root nodes. Up/Down is not active!" << endl;
     }
   }

	if (!EnhancedRouting) {
	  
	  if (SubnMgtOsmRoute(&fabric)) {
		 cout << "-E- Fail to update LFT Tables." << endl;
		 exit(1);
	  }
	} else {
	  if (SubnMgtOsmEnhancedRoute(&fabric)) {
		 cout << "-E- Fail to update LFT Tables." << endl;
		 exit(1);
	  }
	}
   
  } else {
    printf(" IBDMCHK OpenSM Routing Verification Mode:\n");
    printf(" FDB File = %s\n", fdbFile.c_str());
    printf(" MCFDB File = %s\n", mcFdbFile.c_str());
    printf(" Subnet File = %s\n", subnetFile.c_str());
    printf(" LMC = %u\n", lmc);
    printf("-------------------------------------------------\n");

    fabric.lmc = lmc;
    
    if (fabric.parseSubnetLinks(subnetFile)) {
      cout << "-E- Fail to parse subnet file:" << subnetFile << endl;
      exit(1);
    }
    
    if (fabric.parseFdbFile(fdbFile)) {
      cout << "-E- Fail to parse fdb file:" << fdbFile << endl;
      exit(1);
    }
    
    if (fabric.parseMCFdbFile(mcFdbFile)) {
      cout << "-E- Fail to parse multicast fdb file:" << mcFdbFile << endl;
      exit(1);
    }

    // propagate lid hop count matrix:
    if (SubnMgtCalcMinHopTables(&fabric)) {
      cout << "-E- Fail to update Min Hops Tables." << endl;
      exit(1);
    }
  } 
  
  if (SubnMgtVerifyAllCaToCaRoutes(&fabric)) {
    cout << "-E- Some Point to Point Traversals Failed." << endl;
    exit(1);
  }
    
  if (AllPaths && SubnMgtVerifyAllRoutes(&fabric)) {
    cout << "-E- Some Point to Point Traversals Failed." << endl;
    exit(1);
  }

  if (SubnMgtCheckFabricMCGrps(&fabric)) {
    cout << "-E- Some Multicast Groups Routing Check Failed." << endl;
    exit(1);
  }
    
  list <IBNode *> rootNodes;
  int anyErr = 0;

  if (RootsFileName.size())
  {
    if (TopoFile.size()) 
    {
      rootNodes = ParseRootNodeNamesFile(&fabric, RootsFileName);
    }
    else
    {
      rootNodes = ParseRootNodeGuidsFile(&fabric, RootsFileName);
    }
  }
  else
  {
    rootNodes = SubnMgtFindRootNodesByMinHop(&fabric);
  }

  if (!rootNodes.empty()) {
    cout << "-I- Recognized " << rootNodes.size() << " root nodes:" << endl;
    for (list <IBNode *>::iterator nI = rootNodes.begin();
         nI != rootNodes.end(); nI++) {
      cout << " " << (*nI)->name << endl;
    }
    cout << "---------------------------------------------------------------------------\n" << endl;
    
    // rank the fabric by these roots
    map_pnode_int nodesRank;
    SubnRankFabricNodesByRootNodes(&fabric, rootNodes, nodesRank);
    ofstream rankFile("/tmp/ibdmchk.node_ranking");
    rankFile << "-I- Node Ranking:" << endl;
    for(map_pnode_int::iterator nI = nodesRank.begin();
        nI != nodesRank.end(); nI++)
    {
      rankFile << (*nI).first->name << " rank:" << (*nI).second << endl;
    }
    rankFile.close();
    
    // report non up down paths:
    anyErr |= SubnReportNonUpDownCa2CaPaths(&fabric, nodesRank);
    
    // report non up down Multicast Groups
    anyErr |= SubnMgtCheckFabricMCGrpsForCreditLoopPotential(&fabric, nodesRank);

    // Analyze the fabric links to generate a list of src,dst pairs list 
    // to cover all fabric links
    LinkCoverageAnalysis(&fabric, rootNodes);

  } else {
    cout << "-I- Fail to recognize any root nodes. Using full credit loop check." << endl;
    anyErr |= CrdLoopAnalyze(&fabric);
  }
  
  exit(anyErr);
}
