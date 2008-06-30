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

/*
 * Abstract:
 *    Implementation of ibsm_t.
 * This object represents the Subnet Management Packets Interface
 * This object is part of the IBIS family of objects.
 *
 * Environment:
 *    Linux User Mode
 *
 * $Revision: 1.8 $
 */

#include <string.h>
#include <complib/cl_qmap.h>
#include <complib/cl_passivelock.h>
#include <complib/cl_debug.h>
#include <iba/ib_types.h>
#include "ibsm.h"
#include <opensm/osm_madw.h>
#include <opensm/osm_log.h>
#include <opensm/osm_mad_pool.h>
#include <opensm/osm_msgdef.h>

/**********************************************************************
 **********************************************************************/

ibsm_t*
ibsm_construct()
{
  ibsm_t* p_ibsm;

  OSM_LOG_ENTER(&(IbisObj.log));

  p_ibsm = malloc(sizeof(ibsm_t));
  if (p_ibsm == NULL)
  {
    goto Exit;
  }

  memset (p_ibsm, 0, sizeof(ibsm_t));
  Exit :
    OSM_LOG_EXIT(&(IbisObj.log));
  return(p_ibsm);
}

/**********************************************************************
 **********************************************************************/
void
ibsm_destroy(
  IN ibsm_t* const p_ibsm )
{
  OSM_LOG_ENTER(&(IbisObj.log));

  p_ibsm->state = IBSM_STATE_INIT;
  OSM_LOG_EXIT( &(IbisObj.log) );
}

/**********************************************************************
 **********************************************************************/
ib_api_status_t
ibsm_init(
  IN ibsm_t* const p_ibsm )
{
  ib_api_status_t status = IB_SUCCESS;

  OSM_LOG_ENTER(&(IbisObj.log));
  p_ibsm->state = IBSM_STATE_INIT;

  OSM_LOG_EXIT( &(IbisObj.log) );
  return( status );
}

/**********************************************************************
 **********************************************************************/

ib_api_status_t
ibsm_bind(
  IN ibsm_t *p_ibsm )
{
  ib_api_status_t status = IB_SUCCESS;

  OSM_LOG_ENTER(&(IbisObj.log));

  /* no need to bind the Directed Route class as it will automatically
     be handled by the osm_vendor_bind if asked for LID route */
  status = ibis_gsi_mad_ctrl_bind(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID, 1,
    &p_ibsm->lid_route_bind
    );

  if( status != IB_SUCCESS )
  {
    goto Exit;
  }

  /* now register every class/attr pair we have: */
  status = ibis_gsi_mad_ctrl_set_class_attr_cb(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID ,
    CL_NTOH16(IB_MAD_ATTR_NODE_INFO) ,
    ibis_gsi_sync_mad_batch_callback,
    (void *)p_ibsm);

  status = ibis_gsi_mad_ctrl_set_class_attr_cb(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID,
    CL_NTOH16(IB_MAD_ATTR_PORT_INFO),
    ibis_gsi_sync_mad_batch_callback,
    (void *)p_ibsm);

  status = ibis_gsi_mad_ctrl_set_class_attr_cb(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID,
    CL_NTOH16(IB_MAD_ATTR_SWITCH_INFO),
    ibis_gsi_sync_mad_batch_callback,
    (void *)p_ibsm);

  status = ibis_gsi_mad_ctrl_set_class_attr_cb(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID,
    CL_NTOH16(IB_MAD_ATTR_LIN_FWD_TBL),
    ibis_gsi_sync_mad_batch_callback,
    (void *)p_ibsm);

  status = ibis_gsi_mad_ctrl_set_class_attr_cb(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID,
    CL_NTOH16(IB_MAD_ATTR_MCAST_FWD_TBL),
    ibis_gsi_sync_mad_batch_callback,
    (void *)p_ibsm);

  status = ibis_gsi_mad_ctrl_set_class_attr_cb(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID,
    CL_NTOH16(IB_MAD_ATTR_GUID_INFO),
    ibis_gsi_sync_mad_batch_callback,
    (void *)p_ibsm);

  status = ibis_gsi_mad_ctrl_set_class_attr_cb(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID,
    CL_NTOH16(IB_MAD_ATTR_P_KEY_TABLE),
    ibis_gsi_sync_mad_batch_callback,
    (void *)p_ibsm);

  status = ibis_gsi_mad_ctrl_set_class_attr_cb(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID,
    CL_NTOH16(IB_MAD_ATTR_SLVL_TABLE),
    ibis_gsi_sync_mad_batch_callback,
    (void *)p_ibsm);

  status = ibis_gsi_mad_ctrl_set_class_attr_cb(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID,
    CL_NTOH16(IB_MAD_ATTR_VL_ARBITRATION),
    ibis_gsi_sync_mad_batch_callback,
    (void *)p_ibsm);

  status = ibis_gsi_mad_ctrl_set_class_attr_cb(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID,
    CL_NTOH16(IB_MAD_ATTR_NODE_DESC),
    ibis_gsi_sync_mad_batch_callback,
    (void *)p_ibsm);

  status = ibis_gsi_mad_ctrl_set_class_attr_cb(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID,
    CL_NTOH16(IB_MAD_ATTR_SM_INFO),
    ibis_gsi_sync_mad_batch_callback,
    (void *)p_ibsm);

  status = ibis_gsi_mad_ctrl_set_class_attr_cb(
    &(IbisObj.mad_ctrl),
    IB_MCLASS_SUBN_LID,
    CL_NTOH16(IB_MAD_ATTR_NOTICE),
    ibis_gsi_sync_mad_batch_callback,
    (void *)p_ibsm);

  Exit :
    OSM_LOG_EXIT( &(IbisObj.log) );
  return( status );
}


/**********************************************************************
 *   ibsm_send_mad_by_lid(p_ibsm, p_data, data_size, lid, attr, mod, meth)
 *   Note that all values are in host order.
 **********************************************************************/
ib_api_status_t
ibsm_send_mad_by_lid (
  ibsm_t   *p_ibsm,
  uint8_t  *p_data,
  size_t    data_size,
  uint16_t  lid,
  uint16_t  attr,
  uint32_t  mod,
  uint16_t  meth)
{
  osm_mad_addr_t        mad_addr;
  osm_madw_t           *p_madw;
  ib_smp_t              response_mad = {0};
  ib_api_status_t       status;

  OSM_LOG_ENTER(&(IbisObj.log));

  osm_log(&(IbisObj.log), OSM_LOG_DEBUG,
          "ibsm_send_mad_by_lid: "
          " Sending to lid:0x%04X method:0x%02X attr:0x%04X mod:0x%08x\n",
          lid, meth, attr, mod);

  mad_addr.dest_lid = cl_hton16(lid);
  mad_addr.path_bits = 0;
  mad_addr.static_rate = 0;

  p_madw = osm_mad_pool_get(
    &(IbisObj.mad_pool), p_ibsm->lid_route_bind, MAD_BLOCK_SIZE, &mad_addr);
  p_madw->resp_expected = TRUE;

  memset((char*)p_madw->p_mad, 0, MAD_BLOCK_SIZE);
  ((ib_mad_t *)p_madw->p_mad)->method = meth;
  ((ib_mad_t *)p_madw->p_mad)->class_ver = 1;
  ((ib_mad_t *)p_madw->p_mad)->mgmt_class = IB_MCLASS_SUBN_LID;
  ((ib_mad_t *)p_madw->p_mad)->base_ver = 1;
  ((ib_smp_t *)p_madw->p_mad)->m_key = cl_hton64(IbisObj.p_opt->m_key);
  ((ib_mad_t *)p_madw->p_mad)->attr_id = cl_hton16(attr);
  ((ib_mad_t *)p_madw->p_mad)->attr_mod = cl_hton32(mod);
  ((ib_mad_t *)p_madw->p_mad)->trans_id = ibis_get_tid();

  /* copy over the user attribute data */
  memcpy(&((ib_smp_t*)p_madw->p_mad)->data, p_data, data_size);

  /* send and wait */
  status = ibis_gsi_send_sync_mad_batch(
    &(IbisObj.mad_ctrl),
    p_ibsm->lid_route_bind,
    1,
    &p_madw,
    sizeof(ib_smp_t),
    (uint8_t*)&response_mad);

  if (!response_mad.method)
    status = IB_TIMEOUT;

  if (status == IB_SUCCESS)
  {
    memcpy(p_data, &response_mad.data, data_size);

    if (cl_ntoh16(response_mad.status) & 0x7fff)
    {
      status = cl_ntoh16(response_mad.status);
    }
  }

  OSM_LOG_EXIT(&(IbisObj.log));
  return (status);
}

/**********************************************************************
 *   ibsm_send_mad_by_dr(p_ibsm, p_mad, dr[], attr, mod, meth)
 *   Note that all values are in network order.
 **********************************************************************/
ib_api_status_t
ibsm_send_mad_by_dr(
  ibsm_t   *p_ibsm,
  uint8_t  *p_data,
  size_t    data_size,
  ibsm_dr_path_t *dr,
  uint16_t  attr,
  uint32_t  mod,
  uint16_t  meth)
{
  osm_mad_addr_t        mad_addr;
  osm_madw_t           *p_madw;
  ib_smp_t              response_mad = {0};
  ib_smp_t             *p_smp;
  ib_api_status_t       status;

  OSM_LOG_ENTER(&(IbisObj.log));

  osm_log(&(IbisObj.log), OSM_LOG_DEBUG,
          "ibsm_send_mad_by_dr: "
          " Sending to DR method:0x%02X attr:0x%04X mod:0x%08x\n",
          meth, attr, mod);

  mad_addr.path_bits = 0;
  mad_addr.static_rate = 0;

  p_madw = osm_mad_pool_get(
    &(IbisObj.mad_pool), p_ibsm->lid_route_bind, MAD_BLOCK_SIZE, &mad_addr);
  p_madw->resp_expected = TRUE;

  p_smp = (ib_smp_t*)p_madw->p_mad;
  memset((char*)p_madw->p_mad, 0, MAD_BLOCK_SIZE);

  ib_smp_init_new(
    p_smp,
    meth,
    ibis_get_tid(),
    cl_hton16(attr),
    cl_hton32(mod),
    dr->count,
    cl_hton64(IbisObj.p_opt->m_key), /* mkey */
    dr->path,
    0xffff,
    0xffff);

  /* copy over the user attribute data */
  memcpy(&((ib_smp_t*)p_madw->p_mad)->data, p_data, data_size);

  /* verbose ... */
  osm_dump_dr_smp(&(IbisObj.log), p_smp, OSM_LOG_FRAMES);

  /* send and wait */
  status = ibis_gsi_send_sync_mad_batch(
    &(IbisObj.mad_ctrl),
    p_ibsm->lid_route_bind,
    1,
    &p_madw,
    sizeof(ib_smp_t),
    (uint8_t*)&response_mad);

  if (!response_mad.method)
    status = IB_TIMEOUT;

  if (status == IB_SUCCESS)
  {
    memcpy(p_data, &response_mad.data, data_size);

    if (cl_ntoh16(response_mad.status) & 0x7fff)
    {
      status = cl_ntoh16(response_mad.status);
    }
  }

  OSM_LOG_EXIT(&(IbisObj.log));
  return (status);
}
