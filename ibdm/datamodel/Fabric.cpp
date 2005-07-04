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
 * $Id: Fabric.cpp,v 1.17 2005/07/04 07:16:21 eitan Exp $
 */

/*
IB Fabric Data Model
This file holds implementation of the data model classes and methods

*/

//////////////////////////////////////////////////////////////////////////////

#include "Fabric.h"
#include "SysDef.h"
#include "Regexp.h"
#include <iomanip>

// Track verbosity:
uint8_t FabricUtilsVerboseLevel = 0x1;

//////////////////////////////////////////////////////////////////////////////
//
// CLASS IBPort:
//

// constructor
IBPort::IBPort(IBNode *p_nodePtr, int number) {
  p_node = p_nodePtr;
  num = number;
  p_sysPort = NULL;
  p_remotePort = NULL;
  base_lid = IB_LID_UNASSIGNED;
  memset(&guid,0,sizeof(uint64_t));
}

// destructor
IBPort::~IBPort() {
  if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE) {
    cout << "-I- Destructing Port:" << p_node->name << "/" << num << endl;
  }
  
  // if was connected - remove the connection:
  if (p_remotePort)
    p_remotePort->p_remotePort = NULL;
  
  // if has a system port - delete it too.
  if (p_sysPort) {
    p_sysPort->p_nodePort = NULL;
    delete p_sysPort;
  }
}

// Set the guid in the fabric too:
void IBPort::guid_set(uint64_t g) {
  if (p_node && p_node->p_fabric) {
    p_node->p_fabric->PortByGuid[g] = this;
    guid = g;
  }
}

// Get the port name. 
// If connects to a system port - use the system port name.
string 
IBPort::getName() {
  string name;
  if (p_sysPort) {
    name = p_sysPort->p_system->name + string("/") + p_sysPort->name;
  } else {
    if (! p_node) {
      cerr << "Got a port with no node" << endl;
      abort();
    }
    char buff[8];
    sprintf(buff,"/P%u", num);
    name = p_node->name + string(buff);
  }
  return name;
}

// connect the port to another node port
void 
IBPort::connect (IBPort *p_otherPort,
                 IBLinkWidth w,
                 IBLinkSpeed s)
{
  // we can not simply override existing connections
  if (p_remotePort) {
    // we only do care if not the requested remote previously conn.
    if (p_remotePort != p_otherPort) {
      cout << "-W- Disconnecting: "
           << p_remotePort->getName() << " previously connected to:"
           << p_remotePort->getName()
           << " while connecting:" << p_otherPort->getName() << endl;
      // the other side should be cleaned only if points here
      if (p_remotePort->p_remotePort == this) {
        p_remotePort->p_remotePort = NULL;
      }
    }
  } 
  p_remotePort = p_otherPort;

  // Check the other side was not previously connected
  if (p_otherPort->p_remotePort) {
    if (p_otherPort->p_remotePort != this) {
      // it was connected to a wrong port so disconnect
      cout << "-W- Disconnecting: " << p_otherPort->getName()
           << " previously connected to:"
           << p_otherPort->p_remotePort->getName()
           << " while connecting:" << this->getName() << endl;
      // the other side should be cleaned only if points here
      if (p_otherPort->p_remotePort->p_remotePort == p_otherPort) {
        p_otherPort->p_remotePort->p_remotePort = NULL;
      }
    }
  } 
  p_otherPort->p_remotePort = this;

  p_remotePort->speed = speed = s;
  p_remotePort->width = width = w;
}

//////////////////////////////////////////////////////////////////////////////
//
// CLASS IBNode:
//

// Constructor:
IBNode::IBNode(string n, 
               IBFabric *p_fab, 
               IBSystem *p_sys, 
               IBNodeType t, int np) {
  name = n;
  p_fabric = p_fab;
  p_system = p_sys;
  type = t;
  numPorts = np;
  guid = 0;
  attributes = string("");
  appData1.ptr = NULL;
  appData2.ptr = NULL;
  for (unsigned int i = 0; i < numPorts; i++)
    Ports.push_back((IBPort *)NULL);
  
  p_system->NodeByName[name] = this;
  p_fabric->NodeByName[name] = this;
}

// Delete the node cleaning up all it's connections
IBNode::~IBNode() {
  if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE) {
    cout << "-I- Destructing Node:" << name << endl;
  }
  // delete all the node ports:
  unsigned int p;
  for (p = 0; p < numPorts; p++) {
    IBPort *p_port = Ports[p];
    if (p_port) {
      delete p_port;
    }
  }

  // remove from the system NodesByName:
  if (p_system) {
    map_str_pnode::iterator nI = p_system->NodeByName.find(name);
    if (nI != p_system->NodeByName.end()) {
      p_system->NodeByName.erase(nI);
    }
  }
  
  // remove from the fabric NodesByName:
  if (p_fabric) {
    map_str_pnode::iterator nI = p_fabric->NodeByName.find(name);
    if (nI != p_fabric->NodeByName.end()) {
      p_fabric->NodeByName.erase(nI);
    }
  }
}

void 
IBNode::guid_set(uint64_t g) {
  if (p_fabric) {
    p_fabric->NodeByGuid[g] = this;
    guid = g;
  }
}

// Set the min hop for the given port (* is all) lid pair
void 
IBNode::setHops (IBPort *p_port, unsigned int lid, int hops) {
  if (MinHopsTable.empty()) {
    if (lid > p_fabric->maxLid) {
      cout << "-W- We got a bigget lid:" << lid
           << " then maxLid:" << p_fabric->maxLid << endl;
      p_fabric->maxLid = lid;
    }

    // we allocate the complete table upfront
    MinHopsTable.resize(p_fabric->maxLid + 1);
    for(unsigned int l = 0; l < p_fabric->maxLid + 1; l++) { 
      MinHopsTable[l].resize(numPorts + 1);     
      for(unsigned int i = 0; i <= numPorts; i++) 
        MinHopsTable[l][i] = IB_HOP_UNASSIGNED; 
    }
  }

  // now do the job
  // if we were not passed a port do it for all!
  // only if lid is legal , otherwise the user meant ,just to init the table with IB_HOP_UNASSIGNED
  if (lid != 0) {
    if (p_port == NULL) {
      // set it for all ports
      for(unsigned int i = 0; i <= numPorts; i++) 
        MinHopsTable[lid][i] = hops;
    } else {
      MinHopsTable[lid][p_port->num] = hops;
    }
  } else {
    for (unsigned int l = 0; l < MinHopsTable.size(); l++) 
      for(unsigned int i = 0; i <= numPorts; i++) 
        MinHopsTable[l][i] = hops;
  }

  // keep track about the min hops per node:
  if (MinHopsTable[lid][0] > hops) 
    MinHopsTable[lid][0] = hops;
} // method setHops

// Report Min Hop Table of the current Node
void 
IBNode::repHopTable () {
  cout << "-I- MinHopTable for Node:" << name << "\n" << "=========================\n" <<endl;
  if (MinHopsTable.empty()) {
    cout << "\tEmpty" << endl;
  } else {
    cout << "  " << setw(3) << "MIN" << " ";
    // Lid/Port header line
    for (int i=1; i <= Ports.size(); i++)
      cout << setw(2) << i << " " ;
    cout << endl;
    for (int i = 1; i <= 3*Ports.size()+5; i++) cout << "-";
    cout << endl;
    for (int l = 1; l <= p_fabric->maxLid; l++) 
    {
      cout << setw(2) << l << "|";
      for (int i=0; i <= Ports.size(); i++)
      {
        int val=(int)MinHopsTable[l][i];
        if (val != 255) 
          cout << setw(2) << val << " " ;
        else
          cout << setw(2) << "-" << " " ;
      }
      IBPort *p_port = p_fabric->getPortByLid(l);
      if (p_port) 
        cout << " " << p_port->p_node->name;
      cout << endl;
    }
    cout << endl;
  }
} // Method repHopTable
    



//////////////////////////////////////////////////////////////////////////////

// Get the min number of hops defined for the given port or all
int 
IBNode::getHops (IBPort *p_port, unsigned int lid) {
  // make sure it is initialized:
  if (MinHopsTable.empty() || (MinHopsTable.size() < lid + 1)) return IB_HOP_UNASSIGNED;
  if (MinHopsTable[lid].empty()) return IB_HOP_UNASSIGNED;
  if (p_port == NULL) return MinHopsTable[lid][0];
  return MinHopsTable[lid][p_port->num];
}

//////////////////////////////////////////////////////////////////////////////

// Scan the node ports and find the first port 
// with min hop to the lid
IBPort *
IBNode::getFirstMinHopPort(unsigned int lid) {
  
  // make sure it is a SW:
  if (type != IB_SW_NODE) {
    cout << "-E- Get best hop port must be run on SW nodes!" << endl;
    return NULL;
  }
  
  if (MinHopsTable.empty() || (MinHopsTable.size() < lid + 1))
    return NULL;
  
  // the best hop is stored in port 0:
  int minHop = MinHopsTable[lid][0];
  for (unsigned int i = 1; i <=  numPorts; i++) 
    if (MinHopsTable[lid][i] == minHop)
      return getPort(i);
  return NULL;
}

//////////////////////////////////////////////////////////////////////////////

// Set the Linear Forwarding Table:
void
IBNode::setLFTPortForLid (unsigned int lid, unsigned int portNum) {
  unsigned int origSize = LFT.empty() ? 0 : LFT.size();
  // make sur the vector is init
  if (origSize < lid + 1) {
    LFT.resize(lid + 100);
    // initialize
    for(unsigned int i = origSize; i < LFT.size(); i++) 
      LFT[i] = IB_LFT_UNASSIGNED; 
  }

  // now do the job
  LFT[lid] = portNum;
}

//////////////////////////////////////////////////////////////////////////////

// Get the LFT for a given lid
int 
IBNode::getLFTPortForLid (unsigned int lid) {
  // make sure it is initialized:
  if (LFT.empty() || (LFT.size() < lid + 1)) return IB_LFT_UNASSIGNED;
  return ( LFT[lid] );
}

//////////////////////////////////////////////////////////////////////////////
// Set the Multicast FDB table 
void 
IBNode::setMFTPortForMLid(
  unsigned int lid,
  unsigned int portNum)
{
  if ((portNum > numPorts) || (portNum >= 32)) {
    cout << "-E- setMFTPortForMLid : Given port:" << portNum
         << " is too high!" << endl;
    return;
  } 
  
  // make sure the mlid is in range:
  if ((lid < 0xc000) || (lid > 0xffff)) {
    cout << "-E- setMFTPortForMLid : Given lid:" << lid
         << " is out of range" << endl;
    return;
  }
  
  int idx = lid - 0xc000;
  
  // make sure we have enough vector:
  int prevSize = MFT.size();
  if (prevSize <= idx) {
    MFT.resize(idx + 10);
    for( int i = prevSize; i < idx + 10; i++) 
      MFT[i]=0;
  }
  
  MFT[idx] |= (1 << portNum);

  // we track all Groups:
  p_fabric->mcGroups.insert(lid);

}
  
//////////////////////////////////////////////////////////////////////////////
// Get the list of ports for the givan MLID from the MFT
list_int 
IBNode::getMFTPortsForMLid(
  unsigned int lid)
{
  list_int res;
  // make sure the mlid is in range:
  if ((lid < 0xc000) || (lid > 0xffff)) {
    cout << "-E- getMFTPortsForMLid : Given lid:" << lid
         << " is out of range" << endl;
    return res;
  }
  
  int idx = lid - 0xc000;
  if (MFT.size() <= idx) 
    return res;
  

  int mftVal = MFT[idx];
  for(unsigned int pn = 0; pn <= numPorts; pn++)
    if (mftVal & (1 << pn)) res.push_back(pn);

  return res;
}

//////////////////////////////////////////////////////////////////////////////
//
// CLASS IBSysPort:
//

// Connect two system ports. This will update both sides pointers
void 
IBSysPort::connect (IBSysPort *p_otherSysPort,   
                    IBLinkWidth width,
                    IBLinkSpeed speed
                    ) {
  // we can not simply override existing connections
  if (p_remoteSysPort) {
    // we only do care if not the requested remote previously conn.
    if (p_remoteSysPort != p_otherSysPort) {
      cout << "-W- Disconnecting: " << p_system->name << "-/" 
           << this->name << " previously connected to:"
           << p_remoteSysPort->p_system->name << "-/" 
           << p_remoteSysPort->name 
           << " while connecting:" << p_otherSysPort->p_system->name
           << "-/" << p_otherSysPort->name << endl;
      // the other side should be cleaned only if points here
      if (p_remoteSysPort->p_remoteSysPort == this) {
        p_remoteSysPort->p_remoteSysPort = NULL;
      }
    }
  } 
  p_remoteSysPort = p_otherSysPort;

  // Check the other side was not previously connected
  if (p_otherSysPort->p_remoteSysPort) {
    if (p_otherSysPort->p_remoteSysPort != this) {
      // it was connected to a wrong port so disconnect
      cout << "-W- Disconnecting back: " 
           << p_otherSysPort->p_system->name << "-/" 
           << p_otherSysPort->name << " previously connected to:"
           << p_otherSysPort->p_remoteSysPort->p_system->name << "-/" 
           << p_otherSysPort->p_remoteSysPort->name
           << " while connecting:" << this->p_system->name
           << "-/" << this->name << endl;
      // the other side should be cleaned only if points here
      if (p_otherSysPort->p_remoteSysPort->p_remoteSysPort == p_otherSysPort) {
        p_otherSysPort->p_remoteSysPort->p_remoteSysPort = NULL;
      }
    }
  } 
  p_otherSysPort->p_remoteSysPort = this;
  
  // there should be a lower level port to connect too:
  if (p_remoteSysPort->p_nodePort && p_nodePort)
    p_nodePort->connect(p_remoteSysPort->p_nodePort, width, speed);
  else
    cout << "-E- Connected sys ports but no nodes ports:" 
         << p_system->name << "/" << name << " - " 
         << p_remoteSysPort->p_system->name << "/" 
         << p_remoteSysPort->name << endl;
}

// Constructor:
IBSysPort::IBSysPort(string n, class IBSystem *p_sys)
{
  p_system = p_sys;
  name = n;
  p_nodePort = NULL;
  p_remoteSysPort = NULL;
  p_system->PortByName[name] = this;
}

// Distractor
IBSysPort::~IBSysPort() {
  if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE) {
    cout << "-I- Destructing SysPort:" << name << endl;
  }

  // if connected to another side remove the connection
  if (p_remoteSysPort)
    p_remoteSysPort->p_remoteSysPort = NULL;

  // remove from the map of the parent system
  if (p_system) {
    map_str_psysport::iterator pI = p_system->PortByName.find(name);
    if (pI != p_system->PortByName.end()) {
      p_system->PortByName.erase(pI);
    }
  }
}

//////////////////////////////////////////////////////////////////////////////
//
// CLASS IBSystem:
//

// Destructor
IBSystem::~IBSystem() {
  if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE) 
    cout << "-I- Destructing System:" << name << endl;
  
  // cleanup all allocated sysPorts:
  while (!PortByName.empty()) {
    map_str_psysport::iterator pI = PortByName.begin();
    // deleting a SysPort should cleanup the table
    IBSysPort *p_sysPort = (*pI).second;
    if (p_sysPort) {
      delete p_sysPort;
    }
  }

  // cleanup from parent fabric table of systems:
  if (p_fabric) {
    map_str_psys::iterator sI = p_fabric->SystemByName.find(name);
    if (sI != p_fabric->SystemByName.end()) 
      p_fabric->SystemByName.erase(sI);
  }
}

// make sure we got the port defined
IBSysPort *
IBSystem::makeSysPort (string pName) {
  IBSysPort *p_port;
  map_str_psysport::iterator pI = PortByName.find(pName);
  if (pI == PortByName.end()) {
    p_port = new IBSysPort(pName, this);
    if (!p_port) return NULL;
    PortByName[pName] = p_port;
  } else {
    p_port = (*pI).second;
  }
  // connect the SysPort to the lower level nodes
  IBPort *p_nodePort = getSysPortNodePortByName(pName);
  if (! p_nodePort) return NULL;
  p_nodePort->p_sysPort = p_port;
  p_port->p_nodePort = p_nodePort;
  return p_port;
}

//////////////////////////////////////////////////////////////////////////////
void
IBSystem::guid_set(uint64_t g) {
  if (p_fabric) {
    p_fabric->SystemByGuid[g] = this;
    guid = g;
  }
}

//////////////////////////////////////////////////////////////////////////////

IBSysPort *
IBSystem::getSysPort(string name) {
  IBSysPort *p_sysPort = NULL;
  map_str_psysport::iterator nI = PortByName.find(name);
  if (nI != PortByName.end()) {
    p_sysPort = (*nI).second;
  }
  return p_sysPort;
}

//////////////////////////////////////////////////////////////////////////////

// constructor:
IBSystem::IBSystem(string n, class IBFabric *p_fab, string t) {
  if (p_fab->getSystem(n)) {
    cerr << "Can't deal with double allocation of same system!" << endl;
    abort();
  }
  name = n;
  type = t;
  guid = 0;
  p_fabric = p_fab;
  p_fabric->SystemByName[n] = this;
}

//////////////////////////////////////////////////////////////////////////////

// Get a string with all the System Port Names (even if not connected)
list_str 
IBSystem::getAllSysPortNames() {
  list_str portNames;
  for (map_str_psysport::iterator pI = PortByName.begin();
       pI != PortByName.end();
       pI++) {
    portNames.push_back((*pI).first);
  }
  return portNames;
}

//////////////////////////////////////////////////////////////////////////////

// get the node port for the given sys port by name
IBPort *
IBSystem::getSysPortNodePortByName (string sysPortName) {
  map_str_psysport::iterator pI = PortByName.find(sysPortName);
  if (pI != PortByName.end()) {
    return ((*pI).second)->p_nodePort;
  }
  return NULL;
}
//////////////////////////////////////////////////////////////////////////////

// Split the given cfg into a vector of board cfg codes
void 
IBSystem::cfg2Vector(const string& cfg,
                     vector<string>& boardCfgs,
                     int numBoards)
{
  unsigned int i;
  int b = 0;
  unsigned int prevDelim = 0;
  const char *p_str = cfg.c_str();
  char bcfg[16];

  // skip leading spaces:
  for (i = 0; (i < strlen(p_str)) && (
         (p_str[i] == '\t') || (p_str[i] == ' ')); i++);
  prevDelim = i;

  // scan each character:
  for (; (i < strlen(p_str)) && (b < numBoards); i++) {
    // either a delimiter or not:
    if (p_str[i] == ',') {
      strncpy(bcfg, p_str + prevDelim, i - prevDelim);
      bcfg[i - prevDelim] = '\0';
      boardCfgs.push_back(string(bcfg));
      prevDelim = i + 1;
      b++;
    } 
  }

  if (prevDelim != i) {
      strncpy(bcfg, p_str + prevDelim, i - prevDelim);
      bcfg[i - prevDelim] = '\0';
      boardCfgs.push_back(string(bcfg));
      b++;
  }

  for (;b < numBoards; b++) {
    boardCfgs.push_back("");
  }
}

//////////////////////////////////////////////////////////////////////////////

// Remove a system board
int
IBSystem::removeBoard (string boardName) {
  list <IBNode *> matchedNodes;
  // we assume system name is followed by "/" by board to get the node name:
  string sysNodePrefix = name + string("/") + boardName + string("/");
  
  // go through all the system nodes.
  for (map_str_pnode::iterator nI = p_fabric->NodeByName.begin();
       nI != p_fabric->NodeByName.end();
       nI++) {
    // if node name start matches the module name - we need to remove it.
    if (!strncmp((*nI).first.c_str(), sysNodePrefix.c_str(), strlen(sysNodePrefix.c_str()))) {
      matchedNodes.push_back((*nI).second);
    }
  }

  // Warn if no match:
  if (matchedNodes.empty()) {
    cout << "-W- removeBoard : Fail to find any node in:"
         << sysNodePrefix << " while removing:" << boardName << endl;
    return 1;
  }

  // go through the list of nodes and delete them
  list <IBNode *>::iterator lI = matchedNodes.begin();
  while (lI != matchedNodes.end()) {
    // cleanup the node from the fabric node by name:
    IBNode *p_node = *lI;
    // cout << "Removing node:" << p_node->name.c_str()  << endl;
    p_fabric->NodeByName.erase(p_node->name);
    delete p_node;
    matchedNodes.erase(lI);
    lI = matchedNodes.begin();
  }

  return 0;
}

//////////////////////////////////////////////////////////////////////////////
//
// CLASS IBFabric:
//

// Destructor:
IBFabric::~IBFabric() {
  // cleanup all Systems and Nodes:

  // starting with nodes since they point back to their systems
  while (! NodeByName.empty()) {
    map_str_pnode::iterator nI = NodeByName.begin();
    // note this will cleanup the node from the table...
    IBNode *p_node = (*nI).second;
    delete p_node;
  }

  // now we do the systems
  while (!SystemByName.empty()) {
    map_str_psys::iterator sI = SystemByName.begin();
    // note this will cleanup the system from the table...
    IBSystem *p_sys = (*sI).second;
    delete p_sys;
  }
}

//////////////////////////////////////////////////////////////////////////////
//
// CLASS IBFabric:
//

// make a new node if can not find it by name
IBNode *
IBFabric::makeNode (string n, IBSystem *p_sys, IBNodeType type, unsigned int numPorts) {
  IBNode *p_node;
  map_str_pnode::iterator nI = NodeByName.find(n);
  if (nI == NodeByName.end()) {
    p_node = new IBNode(n, this, p_sys, type, numPorts);
    NodeByName[n] = p_node;
    // if the node is uniq by name in the fabric it must be uniq in the sys
    p_sys->NodeByName[n] = p_node;
  } else {
    p_node = (*nI).second;
  }

  // if the fabric require all ports to be declared do it:
  if (defAllPorts) 
    for (unsigned int i = 1; i <= numPorts; i++) 
      p_node->makePort(i);

  return p_node;
}
      
//////////////////////////////////////////////////////////////////////////////

// Look for the node by its name
IBNode *
IBFabric::getNode (string name) {
  IBNode *p_node = NULL;
  map_str_pnode::iterator nI = NodeByName.find(name);
  if (nI != NodeByName.end()) {
    p_node = (*nI).second;
  }
  return p_node;
}

///////////////////////////////////////////////////////////////////////////// 

IBPort *
IBFabric::getPortByGuid (uint64_t guid) {
  IBPort *p_port = NULL;
  map_guid_pport::iterator nI = PortByGuid.find(guid);
  if (nI != PortByGuid.end()) {
    p_port = (*nI).second;
  }
  return p_port;  
}

IBNode *
IBFabric::getNodeByGuid (uint64_t guid) {
  IBNode *p_node = NULL;
  map_guid_pnode::iterator nI = NodeByGuid.find(guid);
  if (nI != NodeByGuid.end()) {
    p_node = (*nI).second;
  }
  return p_node;  
}

IBSystem *
IBFabric::getSystemByGuid (uint64_t guid) {
  IBSystem *p_system = NULL;
  map_guid_psys::iterator nI = SystemByGuid.find(guid);
  if (nI != SystemByGuid.end()) {
    p_system = (*nI).second;
  }
  return p_system;  
}

///////////////////////////////////////////////////////////////////////////// 

// return the list of node pointers matching the required type
list_pnode *
IBFabric::getNodesByType (IBNodeType type) {
      
  list_pnode *res = new list_pnode;
  for (map_str_pnode::iterator nI = NodeByName.begin(); nI != NodeByName.end(); nI++) {
    if ((type == IB_UNKNOWN_NODE_TYPE) || (type == ((*nI).second)->type)) {
      res->push_back(((*nI).second));
    }
  }
  return res;
}

//////////////////////////////////////////////////////////////////////////////
// convert the given configuration string to modifiers list
// The syntax of the modifier string is comma sep board=modifier pairs
static int
cfgStrToModifiers(string cfg, map_str_str &mods) {
  unsigned int i;
  unsigned int prevDelim = 0;
  const char *p_str = cfg.c_str();
  char bcfg[64];

  // skip leading spaces:
  for (i = 0; (i < strlen(p_str)) && (
         (p_str[i] == '\t') || (p_str[i] == ' ')); i++);
  prevDelim = i;
  
  // scan each character:
  for (;i < strlen(p_str); i++) {
    // either a delimiter or not:
    if (p_str[i] == ',') {
      strncpy(bcfg, p_str + prevDelim, i - prevDelim);
      bcfg[i - prevDelim] = '\0';
      char *eqSign = strchr(bcfg, '=');
      if (eqSign) {
        eqSign[0] = '\0';
        string key = bcfg;
        string val = ++eqSign;
        mods[key] = val;
      } else {
        cout << "-E- Bad modifier syntax:" << bcfg
             << "expected: board=modifier" << endl;
      }
      prevDelim = i + 1;
    }
  }

  if (prevDelim != i) {
      strncpy(bcfg, p_str + prevDelim, i - prevDelim);
      bcfg[i - prevDelim] = '\0';
      char *eqSign = strchr(bcfg, '=');
      if (eqSign) {
        eqSign[0] = '\0';
        string key = bcfg;
        string val = ++eqSign;
        mods[key] = val;
      } else {
        cout << "-E- Bad modifier syntax:" << bcfg
             << "expected: board=modifier" << endl;
      }
  }
  return(0);
}

//////////////////////////////////////////////////////////////////////////////

// crate a new generic system - basically an empty contaner for nodes...
IBSystem *
IBFabric::makeGenericSystem (string name) {
  
  IBSystem *p_sys;
  
  // make sure we do not previoulsy have this system defined.
  map_str_psys::iterator sI = SystemByName.find(name);
  if (sI == SystemByName.end()) {
    p_sys = new IBSystem(name,this,"Generic");
  } else {
    p_sys = (*sI).second;
  }
  return p_sys;
}

//////////////////////////////////////////////////////////////////////////////
// crate a new system - the type must have a predefined sysdef
IBSystem *
IBFabric::makeSystem (string name, string type, string cfg) {

  IBSystem *p_sys;

  // make sure we do not previoulsy have this system defined.
  map_str_psys::iterator sI = SystemByName.find(name);
  if (sI == SystemByName.end()) {

    // We base our system building on the system definitions:
    map_str_str mods;
    
    // convert the given configuration string to modifiers map
    cfgStrToModifiers(cfg, mods);    

    p_sys = theSysDefsCollection()->makeSystem(this, name, type, mods);
    
    if (!p_sys) {
      cout << "-E- Fail to find System class:" << type 
           << endl;
      return NULL;     
    }
    
    SystemByName[name] = p_sys;
      
    // if the fabric require all ports to be declared do it:
    if (defAllPorts) {
      list_str portNames = p_sys->getAllSysPortNames();
      for (list_str::const_iterator pnI = portNames.begin();
           pnI != portNames.end();
           pnI++) {
        p_sys->makeSysPort(*pnI);
      }
    }
  }  else {
    p_sys = (*sI).second;
  }
  return p_sys;
}

//////////////////////////////////////////////////////////////////////////////

// Look for the system by its name
IBSystem *
IBFabric::getSystem (string name) {
  IBSystem *p_system = NULL;
  map_str_psys::iterator nI = SystemByName.find(name);
  if (nI != SystemByName.end()) {
    p_system = (*nI).second;
  }
  return p_system;
}

//////////////////////////////////////////////////////////////////////////////

// Add a cable connection
int
IBFabric::addCable (string t1, string n1, string p1, 
                    string t2, string n2, string p2,
                    IBLinkWidth width, IBLinkSpeed speed) {
  // make sure the nodes exists:
  IBSystem *p_sys1 = makeSystem(n1,t1);
  IBSystem *p_sys2 = makeSystem(n2,t2);

  // check please:
  if (! (p_sys1 && p_sys2)) {
    cout << "-E- Fail to make either systems:" << n1 << " or:" << n2 << endl;
    return 1; 
  }

  // check types 
  if (p_sys1->type != t1) {
    cout << "-W- Provided System1 Type:" << t1 
         << " does not match pre-existing system:" << n1
         << " type:" << p_sys1->type << endl;
  }

  if (p_sys2->type != t2) {
    cout << "-W- Provided System1 Type:" << t2 
         << " does not match pre-existing system:" << n2
         << " type:" << p_sys2->type << endl;
  }

  // make sure the sys ports exists
  IBSysPort *p_port1 = p_sys1->makeSysPort(p1);
  IBSysPort *p_port2 = p_sys2->makeSysPort(p2);
  if (! (p_port1 && p_port2)) return 1;

  // make sure they are not previously connected otherwise
  if (p_port1->p_remoteSysPort && (p_port1->p_remoteSysPort != p_port2)) {
    cout << "-E- Port:" 
         << p_port1->p_system->name << "/"
         << p_port1->name 
         << " already connected to:"
         << p_port1->p_remoteSysPort->p_system->name << "/"
         << p_port1->p_remoteSysPort->name <<endl;
    return 1;
  }

  if (p_port2->p_remoteSysPort && (p_port2->p_remoteSysPort != p_port1)) {
    cout << "-E- Port:"
         << p_port2->p_system->name << "/"
         << p_port2->name 
         << " already connected to:" 
         << p_port2->p_remoteSysPort->p_system->name << "/"
         << p_port2->p_remoteSysPort->name << endl;
    return 1;
  }
  
  // connect them 
  p_port1->connect(p_port2, width, speed);
  p_port2->connect(p_port1, width, speed);
  return 0;
}
   
//////////////////////////////////////////////////////////////////////////////

// Parse the cabling definition file
int 
IBFabric::parseCables (string fn) {
  ifstream f(fn.c_str());
  char sLine[1024];
  string n1, t1, p1, n2, t2, p2;
  regExp cablingLine("[ \t]*([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]*");
  regExp ignoreLine("^[ \t]*(#|[ \t]*$)");
  rexMatch *p_rexRes;
  IBLinkSpeed speed = IB_UNKNOWN_LINK_SPEED;
  IBLinkWidth width = IB_UNKNOWN_LINK_WIDTH;

  if (! f) {
    cout << "-E- Fail to open file:" << fn.c_str() << endl;
    return 1;
  }

  cout << "-I- Parsing cabling definition:" << fn.c_str() << endl;

  int numCables = 0;
  int lineNum = 0;
  while (f.good()) {
    lineNum++;
    f.getline(sLine,1024);
    // <SysType1> <sysName1> <portName1> <SysType2> <sysName2> <portName2> 
    p_rexRes = cablingLine.apply(sLine);
     
    if (p_rexRes) {
      t1 = p_rexRes->field(1);
      n1 = p_rexRes->field(2);
      p1 = p_rexRes->field(3);
      t2 = p_rexRes->field(4);
      n2 = p_rexRes->field(5);
      p2 = p_rexRes->field(6);
      if (addCable(t1, n1, p1, t2, n2, p2, width, speed)) {
        cout << "-E- Fail to make cable"
             << " (line:" << lineNum << ")"
             << endl; 
        delete p_rexRes;  
        return 1;
      }
      numCables++;
      delete p_rexRes;  
      continue;
    }
     
    // check if leagel ignored line
    p_rexRes = ignoreLine.apply(sLine);
    if (p_rexRes) {
      delete p_rexRes; 
    } else {
      cout << "-E- Bad syntax on line:" << sLine << endl;
    }
  }

  cout << "-I- Defined " << SystemByName.size() << "/" << NodeByName.size() <<
    " systems/nodes " << endl;
  f.close();
  return 0;
}

//////////////////////////////////////////////////////////////////////////////

// Parse the topology definition file
int 
IBFabric::parseTopology (string fn) {
  ifstream f(fn.c_str());
  char sLine[1024];
  string n1 = string(""), t1, p1, n2, t2, p2, cfg = string("");
  regExp sysLine("^[ \t]*([^/ \t]+)[ \t]+([^/ \t]+)[ \t]*( CFG:(.*))?$");
  regExp sysModule("([^ \t,]+)(.*)");
  regExp portLine("^[ \t]+([^ \t]+)[ \t]+-((1|4|8|12)[xX]-)?((2.5|5|10)G-)?[>]"
                  "[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]*$");
  regExp ignoreLine("^[ \t]*#");
  regExp emptyLine("^[ \t]*$");
  rexMatch *p_rexRes;
  IBSystem *p_system = NULL;
  IBLinkSpeed speed;
  IBLinkWidth width;

  if (! f.is_open()) {
    cout << "-E- Fail to open file:" << fn.c_str() << endl;
    return 1;
  }

  cout << "-I- Parsing topology definition:" << fn.c_str() << endl;

  // we need two passes since we only get system configuration
  // on a system definition line.
  int lineNum = 0;
  while (f.good()) {
    lineNum++;
    f.getline(sLine,1024);
    
    // check if legal ignored line
    p_rexRes = ignoreLine.apply(sLine);
    if (p_rexRes) {
      delete p_rexRes; 
      continue;
    } 

    // First look for system line:
    p_rexRes = sysLine.apply(sLine);
     
    if (p_rexRes) {
      t1 = p_rexRes->field(1);
      n1 = p_rexRes->field(2);
      cfg = p_rexRes->field(4);
      p_system = makeSystem(n1,t1,cfg);

      // check please:
      if (! p_system) {
        cout << "-E- Fail to make system:" << n1
             << " of type:" <<  t1 
             << " (line:" << lineNum << ")"
             << endl;
        delete p_rexRes;  
        return 1;
      }
      delete p_rexRes;  
      continue;
    } 
  }

  lineNum = 0;
  f.close();
  f.clear();
  f.open(fn.c_str());

  if (! f.is_open()) {
    cout << "-E- Fail to re open file:" << fn.c_str() << endl;
    return 1;
  }

  int numCables = 0;

  while (f.good()) {
    lineNum++;
    f.getline(sLine,1024);
    
    // check if legal ignored line
    p_rexRes = ignoreLine.apply(sLine);
    if (p_rexRes) {
      delete p_rexRes; 
      continue;
    } 

    // look for system line:
    p_rexRes = sysLine.apply(sLine);
     
    if (p_rexRes) {
      t1 = p_rexRes->field(1);
      n1 = p_rexRes->field(2);
      cfg = p_rexRes->field(4);
      p_system = makeSystem(n1,t1,cfg);

      // check please:
      if (! p_system) {
        cout << "-E- Fail to make system:" << n1
             << " of type:" <<  t1 
             << " (line:" << lineNum << ")"
             << endl;
        delete p_rexRes;  
        return 1;
      }
      delete p_rexRes;  
      continue;
    } 
     
    // is it a port line:
    p_rexRes = portLine.apply(sLine);
    if (p_rexRes) {
      if (p_system) {
        p1 = p_rexRes->field(1);
        width = char2width((p_rexRes->field(3) + "x").c_str());
        speed = char2speed((p_rexRes->field(5)).c_str());
        // supporting backward compatibility and default 
        // we define both speed and width:
        if (width == IB_UNKNOWN_LINK_WIDTH) width = IB_LINK_WIDTH_4X;
        if (speed == IB_UNKNOWN_LINK_SPEED) speed = IB_LINK_SPEED_2_5;

        t2 = p_rexRes->field(6);
        n2 = p_rexRes->field(7);
        p2 = p_rexRes->field(8);
        if (addCable(t1, n1, p1, t2, n2, p2, width, speed)) {
          cout << "-E- Fail to make cable"
               << " (line:" << lineNum << ")"
               << endl; 
          delete p_rexRes;  
          return 1;
        }
        numCables++;
      } else {
        cout << "-E- Fail to make connection as local system not defined"
             << " (line:" << lineNum << ")"
             << endl; 
        delete p_rexRes;  
        return 1;
      }
      delete p_rexRes;  
      continue;
    } 
     
    // check if empty line - marking system end:
    p_rexRes = emptyLine.apply(sLine);
    if (p_rexRes) {
      p_system = NULL;
      delete p_rexRes;  
      continue;
    }

    cout << "-W- Ignoring '" << sLine << "'"
         << " (line:" << lineNum << ")" << endl;
  }

  cout << "-I- Defined " << SystemByName.size() << "/" << NodeByName.size() <<
    " systems/nodes " << endl;
  f.close();
  return 0;
}

//////////////////////////////////////////////////////////////////////////////

// Create a new link in the fabric. 
// create the node and the system if required.
// NOTE that for LMC > 0 we do not get the multiple lid 
// assignments - just the base lid.
// so we need to assign them ourselves (for CAs) if we have LMC
// Also note that if we provide a description for the device
// it is actually means the device is a CA and that is the system name ...
int 
IBFabric::addLink(string type1, int numPorts1, 
                  uint64_t sysGuid1, uint64_t nodeGuid1,  uint64_t portGuid1, 
                  int vend1, int devId1, int rev1, string desc1, int lid1, 
                  int portNum1,
                  string type2, int numPorts2,
                  uint64_t sysGuid2, uint64_t nodeGuid2,  uint64_t portGuid2, 
                  int vend2, int devId2, int rev2, string desc2, int lid2, 
                  int portNum2,
                  IBLinkWidth width, IBLinkSpeed speed
                  ) {
  
  char buf[32];
  IBSystem *p_sys1, *p_sys2;
  IBNode *p_node1, *p_node2;
    
  // make sure the system1 exists
  if (!desc1.size()) {
    sprintf(buf, "system:%016" PRIx64, sysGuid1);
    string sysName1 = string(buf);
    p_sys1 = makeGenericSystem(sysName1);
  } else {
    p_sys1 = makeGenericSystem(desc1);
  }

  if (!desc2.size()) {
    sprintf(buf, "system:%016" PRIx64, sysGuid2);
    string sysName2 = string(buf);
    p_sys2 = makeGenericSystem(sysName2);
  } else {
    p_sys2 = makeGenericSystem(desc2);
  }

  // make sure the nodes exists
  sprintf(buf,"node:%016" PRIx64, nodeGuid1);
  if (type1 == "SW") {
    p_node1 = makeNode(buf, p_sys1, IB_SW_NODE, numPorts1);
  } else {
    if (desc1.size()) 
      sprintf(buf,"%s/U1", desc1.c_str());
    p_node1 = makeNode(buf, p_sys1, IB_CA_NODE, numPorts1);
  }

  sprintf(buf,"node:%016" PRIx64, nodeGuid2);
  if (type2 == "SW") {
    p_node2 = makeNode(buf, p_sys2, IB_SW_NODE, numPorts2);
  } else {
    if (desc2.size()) 
      sprintf(buf,"%s/U1", desc2.c_str());
    
    p_node2 = makeNode(buf, p_sys2, IB_CA_NODE, numPorts2);
  }

  // we want to use the host names if they are defined:
  if (desc1.size()) 
    p_node1->attributes = string("host=") + desc1;
  
  if (desc2.size()) 
    p_node2->attributes = string("host=") + desc2;

  IBSysPort *p_sysPort1 = 0, *p_sysPort2 = 0;
  
  // create system ports if required
  if (sysGuid1 != sysGuid2) {
    if (type1 == "SW") {
      sprintf(buf,"%s/P%u", p_node1->name.c_str(), portNum1);
    } else {
      sprintf(buf,"P%u", portNum1);
    }
    p_sysPort1 = p_sys1->getSysPort(buf);
    if (p_sysPort1 == NULL)
      p_sysPort1 = new IBSysPort(buf, p_sys1);

    if (type2 == "SW") {    
      sprintf(buf,"%s/P%u", p_node2->name.c_str(), portNum2);
    } else {
      sprintf(buf,"P%u", portNum2);
    }
    p_sysPort2 = p_sys2->getSysPort(buf);
    if (p_sysPort2 == NULL)
      p_sysPort2 = new IBSysPort(buf, p_sys2);
  }

  // make sure the ports exits
  IBPort *p_port1 = p_node1->makePort(portNum1);
  IBPort *p_port2 = p_node2->makePort(portNum2);

  // we know the guids so set them
  p_sys1->guid_set(sysGuid1);
  p_sys2->guid_set(sysGuid2);

  p_node1->guid_set(nodeGuid1);
  p_node2->guid_set(nodeGuid2);
  p_port1->guid_set(portGuid1);
  p_port2->guid_set(portGuid2);

  // copy some data...
  p_node1->devId  = devId1;
  p_node1->revId  = rev1;
  p_node1->vendId = vend1;

  p_node2->devId  = devId2;
  p_node2->revId  = rev2;
  p_node2->vendId = vend2;

  // handle LMC :
  int numLidsPerPort = 1 << lmc;
  p_port1->base_lid = lid1;
  for (int l = lid1; l < lid1 + numLidsPerPort; l++)
    setLidPort(l, p_port1);
  p_port2->base_lid = lid2;
  for (int l = lid2; l < lid2 + numLidsPerPort; l++)
    setLidPort(l, p_port2);

  // connect
  if (p_sysPort1) {
    p_sysPort1->p_nodePort = p_port1;
    p_sysPort2->p_nodePort = p_port2;
    p_port1->p_sysPort = p_sysPort1;
    p_port2->p_sysPort = p_sysPort2;
    p_sysPort1->connect(p_sysPort2, width, speed);
    p_sysPort2->connect(p_sysPort1, width, speed);
  } else {
    p_port1->connect(p_port2, width, speed);
    p_port2->connect(p_port1, width, speed);
  }

  if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE) 
    cout << "-V- Connecting Lid:" << lid1 << " Port:" << portNum1
         << " to Lid:" << lid2 << " Port:" << portNum2 << endl;
  return 0;
}


//////////////////////////////////////////////////////////////////////////////

// Parse a single subnet line using strtok for simplicity...
int 
IBFabric::parseSubnetLine(char *line) {

  string type1, desc1;
  unsigned int  numPorts1, vend1, devId1, rev1, lid1, portNum1;
  uint64_t sysGuid1, nodeGuid1, portGuid1;
  
  string type2, desc2;
  unsigned int  numPorts2, vend2, devId2, rev2, lid2, portNum2;
  uint64_t sysGuid2, nodeGuid2, portGuid2;
  IBLinkSpeed speed;
  IBLinkWidth width;

  char *pch;

  // do the first Port...
  pch = strtok(line, " ");
  if (!pch || pch[0] != '{') return(1);
  
  pch = strtok(NULL, " ");
  if (!pch || (strncmp(pch,"CA",2) && strncmp(pch,"SW",2))) return(2);

  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"Ports:",6)) return(3);
  numPorts1 = strtol(pch+6, NULL,16);
  
  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"SystemGUID:",11)) return(4);
  sysGuid1 = strtoull(pch+11, NULL, 16);
  
  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"NodeGUID:",9)) return(5);
  nodeGuid1 = strtoull(pch+9, NULL, 16);
  
  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"PortGUID:",9)) return(6);
  portGuid1 = strtoull(pch+9, NULL, 16);

  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"VenID:",6)) return(7);
  vend1 = strtol(pch+6, NULL, 16);

  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"DevID:",6)) return(8);
  devId1 = strtol(pch+6, NULL, 16);
  
  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"Rev:",4)) return(9);
  rev1 = strtol(pch+4, NULL, 16);

  // on some installations the desc of the node holds the 
  // name of the hosts:
  if (subnCANames && (numPorts1 <= 2)) {
    // the first word in the description please.
    pch = strtok(NULL, " ");
    // but now we must find an "HCA-" ...
    if (!strncmp("HCA-", pch + strlen(pch) + 1, 4)) {
      desc1 = string(pch+1);
    }
  }
  // on some reare cases there is no space in desc:
  if (!strchr(pch,'}')) {
    pch = strtok(NULL, "}");
    if (!pch ) return(10);
  }
  
  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"LID:", 4)) return(11);
  lid1 = strtol(pch+4, NULL, 16);

  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"PN:", 3)) return(12);
  portNum1 = strtol(pch+3, NULL, 16);

   pch = strtok(NULL, " ");
  if (!pch || pch[0] != '}') return(13);
 
  pch = strtok(NULL, " ");
  if (!pch || pch[0] != '{') return(14);

  // second port
  pch = strtok(NULL, " ");
  if (!pch || (strncmp(pch,"CA",2) && strncmp(pch,"SW",2))) return(15);

  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"Ports:",6)) return(16);
  numPorts2 = strtol(pch+6, NULL,16);
  
  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"SystemGUID:",11)) return(17);
  sysGuid2 = strtoull(pch+11, NULL, 16);
  
  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"NodeGUID:",9)) return(18);
  nodeGuid2 = strtoull(pch+9, NULL, 16);
  
  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"PortGUID:",9)) return(19);
  portGuid2 = strtoull(pch+9, NULL, 16);

  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"VenID:",6)) return(20);
  vend2 = strtol(pch+6, NULL, 16);

  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"DevID:",6)) return(21);
  devId2 = strtol(pch+6, NULL, 16);
  
  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"Rev:",4)) return(22);
  rev2 = strtol(pch+4, NULL, 16);

  if (subnCANames && (numPorts2 <= 2)) {
    // the first word in the description please.
    pch = strtok(NULL, " ");
    // but now we must find an "HCA-" ...
    if (!strncmp("HCA-", pch + strlen(pch) + 1, 4))
      desc2 = string(pch+1);
  }
  // on some reare cases there is no space in desc:
  if (!strchr(pch,'}')) {
    pch = strtok(NULL, "}");
    if (!pch ) return(23);
  }

  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"LID:", 4)) return(24);
  lid2 = strtol(pch+4, NULL, 16);

  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"PN:", 3)) return(25);
  portNum2 = strtol(pch+3, NULL, 16);

  pch = strtok(NULL, " ");
  if (!pch || pch[0] != '}') return(26);

  // PHY=8x LOG=ACT SPD=5
  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"PHY=",4)) return(27);
  width = char2width(pch+4);
  
  pch = strtok(NULL, " ");
  if (!pch || strncmp(pch,"LOG=",4)) return(28);

  // for now we require the state to be ACTIVE ...
  if (strncmp(pch+4, "ACT",3)) return(0);

  // speed is optional ... s
  pch = strtok(NULL, " ");
  if (pch && !strncmp(pch,"SPD=",4)) {
    speed = char2speed(pch+4);
  } else if (!pch) {
    speed = IB_LINK_SPEED_2_5;
  } else {
    return(29);
  }
  
  if (numPorts1 > 2) type1 = "SW"; else type1 = "CA";
  if (numPorts2 > 2) type2 = "SW"; else type2 = "CA";
  
  if (addLink(type1, numPorts1, sysGuid1, nodeGuid1, portGuid1, 
                  vend1, devId1, rev1, desc1, lid1, portNum1,
                  type2, numPorts2, sysGuid2, nodeGuid2, portGuid2, 
                  vend2, devId2, rev2, desc2, lid2, portNum2,
                  width, speed
              )) return (30);
  return(0);
}

// Parse an OpenSM Subnet file and build the fabric accordingly
int 
IBFabric::parseSubnetLinks (string fn) {
  ifstream f(fn.c_str());

  char sLine[1024];
  int status;

  if (! f) {
    cout << "-E- Fail to open file:" << fn.c_str() << endl;
    return 1;
  }
  
  cout << "-I- Parsing OpenSM Subnet file:" << fn.c_str() << endl;
  
  int lineNum = 0;
  while (f.good()) {
    lineNum++;
    
    f.getline(sLine,1024);
    if (!strlen(sLine)) continue;

    status = parseSubnetLine(sLine);
    if (status) {
      cout << "-W- Wrong syntax code:" << status << " in line:"
           << lineNum << endl;
    }
  }
  
  cout << "-I- Defined " << SystemByName.size() << "/" << NodeByName.size() 
       << " systems/nodes " << endl;
  f.close();
  return 0;
}

//////////////////////////////////////////////////////////////////////////////

// Parse an OpenSM FDBs file and set teh LFT table accordingly
int
IBFabric::parseFdbFile(string fn) {
  ifstream f(fn.c_str());
  int switches = 0, fdbLines=0;
  char sLine[1024];
  // osm_ucast_mgr_dump_ucast_routes: Switch 0x2c90000213700
  // 0x0001 : 006  : 01   : yes
  regExp switchLine("osm_ucast_mgr_dump_ucast_routes: Switch 0x([0-9a-z]+)");
  regExp lidLine("0x([0-9a-zA-Z]+) : ([0-9]+)");
  rexMatch *p_rexRes;
  
  if (! f) {
    cout << "-E- Fail to open file:" << fn.c_str() << endl;
    return 1;
  }
  
  cout << "-I- Parsing OpenSM FDBs file:" << fn.c_str() << endl;
  
  IBNode *p_node;
  int anyErr = 0;

  while (f.good()) {
    f.getline(sLine,1024);

    p_rexRes = switchLine.apply(sLine);
    if (p_rexRes) {
      // Got a new switch - find the node:
      uint64_t guid;
      guid = strtoull(p_rexRes->field(1).c_str(), NULL, 16);
      p_node = getNodeByGuid(guid);
      if (!p_node) {
        cout << "-E- Fail to find node with guid:" << p_rexRes->field(1) << endl;
        anyErr++;
      } else {
        switches++;
      }
      delete p_rexRes;
      continue;
    } 
    
    p_rexRes = lidLine.apply(sLine);
    if (p_rexRes) {
      // Got a new lid port pair
      if (p_node) {
        unsigned int lid = strtol((p_rexRes->field(1)).c_str(), NULL, 16);
        unsigned int port = strtol((p_rexRes->field(2)).c_str(), NULL, 10);
        if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE) 
          cout << "-V- Setting FDB for:" << p_node->name
               << " lid:" << lid << " port:" << port << endl;
          
        p_node->setLFTPortForLid(lid,port);
        fdbLines++;
      }
      delete p_rexRes;
      continue;
    }
    
    // is it an ignore line ?
    //cout << "-W- Ignoring line:" << sLine << endl;
  }

  cout << "-I- Defined " << fdbLines << " fdb entries for:"
       << switches << " switches" << endl;
  f.close();
  return anyErr;
}

///////////////////////////////////////////////////////////////////////////

// Parse an OpenSM MCFDBs file and set the MFT table accordingly
int
IBFabric::parseMCFdbFile(string fn) {
  ifstream f(fn.c_str());
  int switches = 0, fdbLines=0;
  char sLine[1024];
  // Switch 0x0002c9010bb90090
  // LID    : Out Port(s) 
  // 0xC000 : 0x007 
  // 0xC001 : 0x007 
  regExp switchLine("Switch 0x([0-9a-z]+)");
  regExp lidLine("0x([0-9a-zA-Z]+) :(.*)");
  rexMatch *p_rexRes;
  
  if (! f) {
    cout << "-E- Fail to open file:" << fn.c_str() << endl;
    return 1;
  }
  
  cout << "-I- Parsing OpenSM Multicast FDBs file:" << fn.c_str() << endl;
  
  IBNode *p_node;
  int anyErr = 0;

  while (f.good()) {
    f.getline(sLine,1024);

    p_rexRes = switchLine.apply(sLine);
    if (p_rexRes) {
      // Got a new switch - find the node:
      p_node = getNode("node:" + p_rexRes->field(1));
      if (!p_node) {
        cout << "-E- Fail to find switch: node:" << p_rexRes->field(1) << endl;
        anyErr++;
      } else {
        switches++;
      }
      delete p_rexRes;
      continue;
    } 
    
    p_rexRes = lidLine.apply(sLine);
    if (p_rexRes) {
      // Got a new lid port pair
      if (p_node) {
        unsigned int lid = strtol((p_rexRes->field(1)).c_str(), NULL, 16);
        
        char buff[(p_rexRes->field(2)).size() + 1];
        strcpy(buff, p_rexRes->field(2).c_str());
        
        char *pPortChr = strtok(buff, " ");
        while (pPortChr) {
          unsigned int port = strtol(pPortChr, NULL, 16);
          
          if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE) 
            cout << "-V- Setting Multicast FDB for:" << p_node->name
                 << " lid:" << lid << " port:" << port << endl;
          
          p_node->setMFTPortForMLid(lid,port);
          pPortChr = strtok(NULL, " ");
          fdbLines++;
        }
      }
      delete p_rexRes;
      continue;
    }
    
    // is it an ignore line ?
    //cout << "-W- Ignoring line:" << sLine << endl;
  }

  cout << "-I- Defined " << fdbLines << " Multicast Fdb entries for:"
       << switches << " switches" << endl;
  f.close();
  return anyErr;
}

///////////////////////////////////////////////////////////////////////////
// dump out the contents of the entire fabric
void 
IBFabric::dump(ostream &sout) {
  sout << "--------------- FABRIC DUMP ----------------------" << endl;
  // we start with all systems at top level:
  for (map_str_psys::iterator sI = SystemByName.begin();
       sI != SystemByName.end();
       sI++) {
    IBSystem *p_system = (*sI).second;
    sout << "\nSystem:" << p_system->name << " (" << p_system->type
         << "," << guid2str(p_system->guid_get()) << ")" << endl;
    for (map_str_psysport::iterator pI = p_system->PortByName.begin();
         pI != p_system->PortByName.end();
         pI++) {
      IBSysPort *p_port = (*pI).second;
      IBLinkWidth width = IB_UNKNOWN_LINK_WIDTH;
      IBLinkSpeed speed = IB_UNKNOWN_LINK_SPEED;
      
      if (! p_port) continue;

      // node port
      sout << "  " << p_port->name;
      if ( p_port->p_nodePort) {
        sout << " (" << p_port->p_nodePort->p_node->name << "/" 
             << p_port->p_nodePort->num << ")";
        width = p_port->p_nodePort->width;
        speed = p_port->p_nodePort->speed;
      } else {
        sout << " (ERR: NO NODE PORT?)";
      }
        
      // remote sys port?
      if ( p_port->p_remoteSysPort) {
        sout << " -" << width2char(width) << "-" << speed2char(speed) << "G-> "
             << p_port->p_remoteSysPort->p_system->name << "/" 
             << p_port->p_remoteSysPort->name << endl;
      } else {
        sout << endl;
      }
    }
  }

  // Now dump system internals:
  for (map_str_psys::iterator sI = SystemByName.begin();
       sI != SystemByName.end();
       sI++) {
    IBSystem *p_system = (*sI).second;
    sout << "--------------- SYSTEM " << (*sI).first
         << " DUMP ----------------------" << endl;
    
    // go over all nodes of the system:
    for (map_str_pnode::iterator nI = p_system->NodeByName.begin();
         nI != p_system->NodeByName.end();
         nI++) {
      IBNode *p_node = (*nI).second;
      
      sout << "\nNode:" << p_node->name << " (" << p_node->type
           << "," << guid2str(p_node->guid_get()) << ")" << endl;

      for (unsigned int pn = 1; pn <= p_node->numPorts; pn++) {
        IBPort *p_port = p_node->getPort(pn);
        
        if (! p_port) continue;
        
        // we do not report cross system connections:
        if (p_port->p_sysPort) {
          sout << "   " << pn << " => SysPort:"
               << p_port->p_sysPort->name << endl;
        } else if (p_port->p_remotePort) {
          sout << "   "  << pn << " -" << width2char(p_port->width)
               << "-" << speed2char(p_port->speed) << "G-> "
               << p_port->p_remotePort->getName() << endl;
        }
      }
    }
  }

}
