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
 * $Id: mads.i,v 1.1 2005/03/22 15:30:49 eitan Exp $
 */

/*
 * MADS INTERFACE: Provide means for dispatching mads into the simulator
 */

%{
  /* the following code will place the mad into the dispatcher */
  int
    send_mad(
      IBMSNode *pFromNode, 
      uint8_t   fromPort, 
      uint16_t  destLid,
      uint8_t   mgmt_class, 
      uint8_t   method, 
      uint16_t  attr,
      uint32_t  attr_mod,
      uint8_t  *data,
      size_t    size)
    {
      ibms_mad_msg_t msg;
      IBPort *pPort;
      static uint64_t tid = 19927;
      
      /* initialize the message address vector */
      msg.addr.sl = 0;
      msg.addr.pkey_index = 0;
      msg.addr.dlid = destLid;
      msg.addr.sqpn = 0;
      msg.addr.dqpn = 0;

      pPort = pFromNode->getIBNode()->getPort(fromPort);
      if (! pPort)
      {
        cout << "-E- Given port:" << fromPort << " is down." << endl;
        return 1;
      }
      msg.addr.slid = pPort->base_lid;
      
      /* initialize the mad header */
      msg.header.base_ver = 1;
      msg.header.mgmt_class = mgmt_class;
      msg.header.class_ver = 1;
      msg.header.method = method;
      msg.header.status = 0;
      msg.header.class_spec = 0;
      msg.header.trans_id = tid++;
      msg.header.attr_id = cl_hton16(attr);
      msg.header.attr_mod = cl_hton32(attr_mod);
     
      memcpy(msg.payload, data, size);
      IBMSDispatcher *pDispatcher = Simulator.getDispatcher();
      if (! pDispatcher )
        return TCL_ERROR;
      
      return pDispatcher->dispatchMad(pFromNode, fromPort, msg);
    }

  int send_sa_mad(
    IBMSNode *pFromNode, 
    uint8_t   fromPort, 
    uint16_t  destLid,
    uint8_t   mgmt_class, 
    uint8_t   method,
    uint16_t  attr,
    uint64_t  comp_mask,
    uint8_t  *sa_data,
    size_t    sa_data_size)
    {
      ib_sa_mad_t mad = {0}; /* includes std header and rmpp header */
      
      mad.attr_offset = ib_get_attr_offset(sa_data_size);
      mad.comp_mask = cl_hton64(comp_mask);
      memcpy(mad.data, sa_data, sa_data_size);

      return send_mad(
        pFromNode, 
        fromPort, 
        destLid,
        mgmt_class, 
        method, 
        attr,
        0,
        &mad.rmpp_version, 
        MAD_RMPP_DATA_SIZE + 12);
    }

%}

%{
#define madMcMemberRec ib_member_rec_t
%}

struct madMcMemberRec
{
  madMcMemberRec();
  ~madMcMemberRec();

  ib_gid_t				mgid;
  ib_gid_t				port_gid;
  ib_net32_t			qkey;
  ib_net16_t			mlid;
  uint8_t				mtu;
  uint8_t				tclass;
  ib_net16_t			pkey;
  uint8_t				rate;
  uint8_t				pkt_life;
  ib_net32_t			sl_flow_hop;
  uint8_t				scope_state;
  //  uint8_t				proxy_join;  hard to get as it is defined as bit field
}

%addmethods madMcMemberRec {
  int send_set(
    IBMSNode *pFromNode,
    uint8_t   fromPort,  
    uint16_t  destLid,
    uint64_t  comp_mask)
    {
      return( send_sa_mad(
                pFromNode, 
                fromPort, 
                destLid,
                IB_MCLASS_SUBN_ADM,
                IB_MAD_METHOD_SET,
                cl_ntoh16(IB_MAD_ATTR_MCMEMBER_RECORD),
                comp_mask,
                (uint8_t*)self,
                sizeof(madMcMemberRec)
                )
              );
    }
  
  int send_get(
    IBMSNode *pFromNode,
    uint8_t   fromPort,  
    uint16_t  destLid,
    uint64_t  comp_mask)
    {
      return( send_sa_mad(
                pFromNode, 
                fromPort, 
                destLid,
                IB_MCLASS_SUBN_ADM,
                IB_MAD_METHOD_GET,
                cl_ntoh16(IB_MAD_ATTR_MCMEMBER_RECORD),
                comp_mask,
                (uint8_t*)self,
                sizeof(madMcMemberRec)
                )
              );
    }

  int send_del(
    IBMSNode *pFromNode,
    uint8_t   fromPort,  
    uint16_t  destLid,
    uint64_t  comp_mask)
    {
      return( send_sa_mad(
                pFromNode, 
                fromPort, 
                destLid,
                IB_MCLASS_SUBN_ADM,
                IB_MAD_METHOD_DELETE,
                cl_ntoh16(IB_MAD_ATTR_MCMEMBER_RECORD),
                comp_mask,
                (uint8_t*)self,
                sizeof(madMcMemberRec)
                )
              );
    }
}
