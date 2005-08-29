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
 * $Id: Makefile.am,v 1.14 2005/05/24 11:59:20 eitan Exp $
 */

%title "IBIS Tcl Extension"

%module ibis
%{
#undef panic
#include "stdio.h"
#include <stdlib.h>
#include <getopt.h>
#include <opensm/osm_log.h>
#include <complib/cl_qmap.h>
#include <complib/cl_map.h>
#include <complib/cl_debug.h>
#include "ibis.h"
#include "ibcr.h"
#include "ibpm.h"
#include "ibvs.h"
#include "ibbbm.h"
#include "ibsm.h"

/**********************************************************************
 **********************************************************************/
boolean_t
ibisp_is_debug(void)
{
#if defined( _DEBUG_ )
  return TRUE;
#else
  return FALSE;
#endif /* defined( _DEBUG_ ) */
}

%}

//
// TYPE MAPS:
// 
%include ibis_typemaps.i

//
// exception handling wrapper based on the MsgMgr interfaces 
//
%{

  static char ibis_tcl_error_msg[1024];
  static int  ibis_tcl_error;

  void ibis_set_tcl_error(char *err) {
    if (strlen(err) < 1024)
      strcpy(ibis_tcl_error_msg, err);
    else 
      strncpy(ibis_tcl_error_msg, err, 1024);
    ibis_tcl_error = 1;
  }

%}
// it assumes we do not send the messages to stderr
%except(tcl8) {
  /* we can check if IBIS was initialized here */
  if (!IbisObj.initialized)
  {
    Tcl_SetStringObj(
      Tcl_GetObjResult(interp), 
      "ibis was not yet initialized. please use ibis_init and then ibis_set_port before.", -1);
    return TCL_ERROR;
  }
  
  if (! IbisObj.port_guid)
  {
    Tcl_SetStringObj(
      Tcl_GetObjResult(interp), 
      " ibis was not yet initialized. please use ibis_set_port before.", -1);
    return TCL_ERROR;
  }

  ibis_tcl_error = 0;
  $function; 
  if (ibis_tcl_error) { 
	 Tcl_SetStringObj(Tcl_GetObjResult(interp), ibis_tcl_error_msg, -1);
 	 return TCL_ERROR; 
  }
}

//
// IBCR Interfaces and C Code
//
%include ibcr.i

//
// IBCR Interfaces and C Code
//
%include ibpm.i

//
// IBVS Interfaces and C Code
//
%include ibvs.i

//
// IBBBM Interfaces and C Code
//
%include ibbbm.i

//
// IBSAC Interfaces and C Code
//
%include ibsac.i

//
// IBSM Interfaces and C Code
//
%include ibsm.i

%{
  /* globals */
  ibis_t    IbisObj;
  static ibis_opt_t  *ibis_opt_p;
  ibis_opt_t IbisOpts;

  /* initialize the ibis object - is not done during init so we 
     can play with the options ... */
  int ibis_ui_init(void) 
  {
    ib_api_status_t status;
	 status = ibis_init( &IbisOpts, IbisOpts.log_flags );
	 if( status != IB_SUCCESS ) {
		printf("-E- Error from ibis_init: %s.\n",
				 ib_get_err_str( status ));
		ibis_destroy();
		exit(1);
	 }

    status = ibcr_init(p_ibcr_global);
    if( status != IB_SUCCESS )
    {
      printf("-E- fail to init ibcr_init.\n");
      ibcr_destroy( p_ibcr_global );
      exit(1);
    }	
	
    status = ibpm_init(p_ibpm_global);
    if( status != IB_SUCCESS )
    {
      printf("-E- fail to init ibpm_init.\n");
      ibpm_destroy( p_ibpm_global );
      exit(1);
    }

    status = ibvs_init(p_ibvs_global);
    if( status != IB_SUCCESS )
    {
      printf("-E- Fail to init ibvs_init.\n");
      ibvs_destroy( p_ibvs_global );
      exit(1);
    }	

    status = ibbbm_init(p_ibbbm_global);
    if( status != IB_SUCCESS )
    {
      printf("-E- Fail to init ibbbm_init.\n");
      ibbbm_destroy( p_ibbbm_global );
      exit(1);
    }	

    status = ibsm_init(gp_ibsm);
    if( status != IB_SUCCESS )
    {
      printf("-E- Fail to init ibbbm_init.\n");
      ibsm_destroy( gp_ibsm );
      exit(1);
    }	

    return 0;
  }

  /* destroy the osm object and close the complib.
     This function is called from by the Tcl_CreateExitHandler - meaning
     it will be called when calling 'exit' in the osm shell. */
  void
    ibis_exit( ClientData clientData ) {
    ibcr_destroy(p_ibcr_global);
    ibpm_destroy(p_ibpm_global);
    ibvs_destroy(p_ibvs_global);
    ibbbm_destroy(p_ibbbm_global);
    ibsm_destroy(gp_ibsm);

    ibis_destroy();
    usleep(100);
    complib_exit();
  }

  int ibis_ui_destroy(void)
  {
    ibis_exit(NULL);
    return TCL_OK;
  }


  /* simply return the active port guid ibis is binded to */
  uint64_t ibis_get_port(void)
  {
    return (IbisObj.port_guid); 
  }

  /* set the port we bind to and initialize sub packages */
  int ibis_set_port(uint64_t port_guid)
  { 
    ib_api_status_t status;

    if (! IbisObj.initialized) {
      ibis_set_tcl_error("ibis was not initialized! Please use ibis_init before any call to ibis_*");
      ibis_tcl_error = 1;
      return 1;
    }

    IbisObj.port_guid = port_guid;
    
    status = ibcr_bind(p_ibcr_global);
    if( status != IB_SUCCESS )
    {
      printf("-E- Fail to ibcr_bind.\n");
      ibcr_destroy( p_ibcr_global );
      exit(1);
    }

    status = ibpm_bind(p_ibpm_global);
    if( status != IB_SUCCESS )
    {
      printf("-E- Fail to ibpm_bind.\n");
      ibpm_destroy( p_ibpm_global );
      exit(1);
    }

    status = ibvs_bind(p_ibvs_global);
    if( status != IB_SUCCESS )
    {
      printf("-E- Fail to ibvs_bind.\n");
      ibvs_destroy( p_ibvs_global );
      exit(1);
    }		
    
    status = ibbbm_bind(p_ibbbm_global);
    if( status != IB_SUCCESS )
    {
      printf("-E- Fail to ibbbm_bind.\n");
      ibbbm_destroy( p_ibbbm_global );
      exit(1);
    }		

    status = ibsm_bind(gp_ibsm);
    if( status != IB_SUCCESS )
    {
      printf("-E- Fail to ibsm_bind.\n");
      ibsm_destroy( gp_ibsm );
      exit(1);
    }		

    if (ibsac_bind(&IbisObj)) 
    {
      printf("-E- Fail to ibsac_bind.\n");
      exit(1);
    }

    return 0;
  }

  int ibis_set_verbosity(int level) {
    if (IbisObj.initialized)
      osm_log_set_level( &(IbisObj.log), level );
    else
      IbisOpts.log_flags = level;

	 return TCL_OK;
  }

  int ibis_puts( osm_log_level_t verbosity, char *msg) {
	 osm_log(&(IbisObj.log), verbosity, msg );
	 return TCL_OK;
  }

  int ibis_set_transaction_timeout( uint32_t timeout_ms ) {
	 osm_log(&(IbisObj.log), 
				OSM_LOG_VERBOSE,
				" Setting timeout to:%u[msec]\n", timeout_ms);
	 IbisOpts.transaction_timeout = timeout_ms;
	 return TCL_OK;
  }

  /* return the list of port guids and their status etc */
  static int ibis_get_local_ports_info (ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]) {
    Tcl_Obj * tcl_result;
	 ibis_t *p_ibis = &IbisObj;
	 uint32_t i;
	 ib_api_status_t status;
	 uint32_t num_ports = GUID_ARRAY_SIZE;
	 ib_port_attr_t attr_array[GUID_ARRAY_SIZE];
	 static char res[128];
	 Tcl_Obj *p_obj;

    if (!IbisObj.initialized)
    { 
      Tcl_SetStringObj(
        Tcl_GetObjResult(interp), 
        "ibis was not yet initialized. please use ibis_init before.", -1);
      return TCL_ERROR;
    }
 
	 /* command options */
    tcl_result = Tcl_GetObjResult(interp);
	 
    if ((objc < 1) || (objc > 1)) {
        Tcl_SetStringObj(tcl_result,"Wrong # args. ibis_get_local_ports_info ",-1);
        return TCL_ERROR;
    }

	 /*
		Call the transport layer for a list of local port
		GUID values.
	 */
    status = osm_vendor_get_all_port_attr(
      p_ibis->p_vendor,
      attr_array,
      &num_ports );
    if( status != IB_SUCCESS )
    {
      sprintf(ibis_tcl_error_msg,"-E- fail status:%x\n", status);
      ibis_tcl_error = 1;
      return( TCL_ERROR );
    }

	 /* 
		 Go over all ports and build the return  value 
	 */
	 for( i = 0; i < num_ports; i++ )
    {
      
      // start with 1 on host channel adapters.
      sprintf(res, "0x%016" PRIx64 " 0x%04X %s",
              cl_ntoh64( attr_array[i].port_guid ),
              attr_array[i].lid,
              ib_get_port_state_str( attr_array[i].link_state ) );
      
      p_obj = Tcl_NewStringObj(res, strlen(res));
      Tcl_ListObjAppendElement(interp, tcl_result, p_obj);
    }
	 
    return TCL_OK;
  }

%}



//
// INTERFACE DEFINITION (~copy of h file)
// 

%section "IBIS Constants"
/* These constants are provided by IBIS: */

%subsection "Log Verbosity Flags",before,pre
/* To be or'ed and used as the "level" argument of ibis_set_verbosity */
%readonly
#define IBIS_LOG_NONE			   0x00
#define IBIS_LOG_ERROR			0x01
#define IBIS_LOG_INFO			   0x02
#define IBIS_LOG_VERBOSE			0x04
#define IBIS_LOG_DEBUG			0x08
#define IBIS_LOG_FUNCS			0x10
#define IBIS_LOG_FRAMES			0x20

%section "IBIS Execution Flags",before,pre
/* These flags are updated by IBIS at run time to reflect internal state: */

%readonly

%readwrite

%section "IBIS Functions",pre
/* IBIS UI functions */
%text %{
This section provide the details about the functions IBIS exposes.
They all return 0 on succes.
%}

int ibis_puts( uint8_t verbosity, char *msg);
/* Append a message to the OpenSM log */

/* prevent any exceptions on the following */
%except(tcl8);

typedef struct _ibis_opt {
/* IBIS Options:
   The IBIS options are available through the predefined object: ibis_opts.
   It can be manipulated using the standard Tcl methods: cget and configure.
   Examples: ibis_opts cget -force_log_flush
             ibis_opts configure -force_log_flush TRUE */
  // uint32_t transaction_timeout;
  // /* The maximal time for a GetResp to be waited on before retry (100ms). */
  boolean_t single_thread;
  /* run single threaded */
  boolean_t force_log_flush;
  /* If TRUE - forces flash after each log message (TRUE). */
  uint8_t log_flags;
  /* The log levels to be used */
  char log_file[1024]; 
  /* The name of the log file used (read only) */
} ibis_opt_t;

%name(ibis_init) int ibis_ui_init();
/* Initialize ibis object */
int ibis_set_verbosity(int level);
/* Change the log verbosity */
int ibis_set_port(uint64_t guid);
/* Set the port IBIS is attached to and initialize all sub packages */
new_uint64_t ibis_get_port();
/* Provide the GUID of the port IBIS is attached to */
int ibis_set_transaction_timeout(uint32_t timeout_ms);
/* Set the transaction time out in [msec] */
%name(ibis_exit) int ibis_ui_destroy();
/* Exit IBIS. */

%text %{
ibis_get_local_ports_info
   [return list]
   Return the list of available IB ports with GUID, LID and State.  
%}

//
// INIT CODE
//
%init %{

  /* Make sure that the osmv, complib and ibisp use
     same modes (debug/free) */
  if ( osm_is_debug() != cl_is_debug()    || 
       osm_is_debug() != ibisp_is_debug() || 
       ibisp_is_debug() != cl_is_debug() )
  {
    fprintf(stderr, "-E- OSMV, Complib and Ibis were compiled using different modes\n");
    fprintf(stderr, "-E- OSMV debug:%d Complib debug:%d IBIS debug:%d \n", 
            osm_is_debug(), cl_is_debug(), ibisp_is_debug() );
    exit(1);
  }

  /* sub block required for declarations .... */
  {
    static int notFirstTime = 0;

    /* we initialize the structs etc only once. */
    if (0 == notFirstTime++) {
      Tcl_StaticPackage(interp, "ibis", Ibis_Init, NULL);
      
      /* Default Options  */
      cl_memclr(&IbisOpts,sizeof(ibis_opt_t));
      IbisOpts.transaction_timeout = 4*OSM_DEFAULT_TRANS_TIMEOUT_MILLISEC;
      IbisOpts.single_thread = TRUE;
      IbisOpts.force_log_flush = TRUE;
      IbisOpts.log_flags = OSM_LOG_ERROR;
      strcpy(IbisOpts.log_file,"/tmp/ibis.log");

    
      /* we want all exists to cleanup */
      Tcl_CreateExitHandler(ibis_exit, NULL);
      
      /* ------------------ IBCR ---------------------- */
      p_ibcr_global = ibcr_construct();
      
      if (p_ibcr_global == NULL) {
        printf("-E- Error from ibcr_construct.\n");
        exit(1);
      }	
      
      /* ------------------ IBPM ---------------------- */
      p_ibpm_global = ibpm_construct();
      
      if (p_ibpm_global == NULL) {
        printf("-E- Error from ibpm_construct.\n");
        exit(1);
      }	
      
      /* ------------------ IBVS ---------------------- */
		p_ibvs_global = ibvs_construct();
	
  		if (p_ibvs_global == NULL) {
			printf("-E- Error from ibvs_construct.\n");
         exit(1);
  		}	

      /* ------------------ IBBBM ---------------------- */
		p_ibbbm_global = ibbbm_construct();
	
  		if (p_ibbbm_global == NULL) {
			printf("-E- Error from ibbbm_construct.\n");
         exit(1);
  		} 

      /* ------------------ IBSM ---------------------- */
		gp_ibsm = ibsm_construct();
	
  		if (gp_ibsm == NULL) {
			printf("-E- Error from ibsm_construct.\n");
         exit(1);
  		}

      /* Initialize global records */
      cl_memclr(&ibsm_node_info_obj, sizeof(ib_node_info_t));
      cl_memclr(&ibsm_port_info_obj, sizeof(ib_port_info_t));
      cl_memclr(&ibsm_switch_info_obj, sizeof(ib_switch_info_t));
      cl_memclr(&ibsm_lft_block_obj, sizeof(ibsm_lft_block_t));
      cl_memclr(&ibsm_mft_block_obj, sizeof(ibsm_mft_block_t));
      cl_memclr(&ibsm_guid_info_obj, sizeof(ib_guid_info_t));
      cl_memclr(&ibsm_pkey_table_obj, sizeof(ib_pkey_table_t));
      cl_memclr(&ibsm_sm_info_obj, sizeof(ib_sm_info_t));

      /* ------------------ IBSAC ---------------------- */
      
      /* Initialize global records */
      cl_memclr(&ibsac_node_rec,sizeof(ibsac_node_rec));
      cl_memclr(&ibsac_portinfo_rec,sizeof(ibsac_portinfo_rec));
      cl_memclr(&ibsac_sminfo_rec, sizeof(ib_sminfo_record_t));
      cl_memclr(&ibsac_swinfo_rec, sizeof(ib_switch_info_record_t));
      cl_memclr(&ibsac_link_rec, sizeof(ib_link_record_t));
      cl_memclr(&ibsac_path_rec, sizeof(ib_path_rec_t));
      cl_memclr(&ibsac_lft_rec, sizeof(ib_lft_record_t));
      cl_memclr(&ibsac_mcm_rec, sizeof(ib_member_rec_t));
      
      /* 
       * A1 Supported features:
       * 
       * Query:                Rec/Info Types    Done
       *
       * NodeRecord            (nr, ni)           Y
       * PortInfoRecord        (pir, pi)          Y
       * SwitchInfoRecord      (swir, swi)        Y
       * SMInfoRecord          (smir, smi)        Y
       * PathRecord            (path)             Y
       * LinkRecord            (link)             Y
       * LinFwdTblRecord       (lft)              Y
       * MulticastFwdTblRecord (mftr, mft)        N - Not supported by OSM
       *
       * B Supported features:
       * MCMemberRecord        (mcm)              Y
       * ClassPortInfo         (cpi)              Y
       * InformInfo            (info)             Y
       * ServiceRecord         (svc)              Y
       * SL2VLTableRecord      (slvr, slvt)       Y
       * VLArbTableRecord      (vlarb)            Y
       * PKeyTableRecord       (pkr, pkt)         Y
       */
      
      /* We use alternate SWIG Objects mangling */
      SWIG_AltMnglInit();
      SWIG_AltMnglRegTypeToPrefix("_sacNodeInfo_p", "ni");
      SWIG_AltMnglRegTypeToPrefix("_sacNodeRec_p", "nr");
      SWIG_AltMnglRegTypeToPrefix("_sacPortInfo_p", "pi");
      SWIG_AltMnglRegTypeToPrefix("_sacPortRec_p", "pir");
      SWIG_AltMnglRegTypeToPrefix("_sacSmInfo_p", "smi");
      SWIG_AltMnglRegTypeToPrefix("_sacSmRec_p", "smir");
      SWIG_AltMnglRegTypeToPrefix("_sacSwInfo_p", "swi");
      SWIG_AltMnglRegTypeToPrefix("_sacSwRec_p", "swir");
      SWIG_AltMnglRegTypeToPrefix("_sacLinkRec_p", "link");
      SWIG_AltMnglRegTypeToPrefix("_sacPathRec_p", "path");
      SWIG_AltMnglRegTypeToPrefix("_sacLFTRec_p", "lft");
      SWIG_AltMnglRegTypeToPrefix("_sacMCMRec_p", "mcm");
      SWIG_AltMnglRegTypeToPrefix("_sacClassPortInfo_p", "cpi");
      SWIG_AltMnglRegTypeToPrefix("_sacInformInfo_p", "info");
      SWIG_AltMnglRegTypeToPrefix("_sacServiceRec_p", "svc");
      SWIG_AltMnglRegTypeToPrefix("_sacSlVlTbl_p", "slvt");
      SWIG_AltMnglRegTypeToPrefix("_sacSlVlRec_p", "slvr");
      SWIG_AltMnglRegTypeToPrefix("_sacVlArbRec_p", "vlarb");
      SWIG_AltMnglRegTypeToPrefix("_sacPKeyTbl_p", "pkt");
      SWIG_AltMnglRegTypeToPrefix("_sacPKeyRec_p", "pkr");
      
      // register the pre-allocated objects
      SWIG_AltMnglRegObj("ni",&(ibsac_node_rec.node_info));
      SWIG_AltMnglRegObj("nr",&(ibsac_node_rec));
      
      SWIG_AltMnglRegObj("pi", &(ibsac_portinfo_rec.port_info));
      SWIG_AltMnglRegObj("pir",&(ibsac_portinfo_rec));
	 
      SWIG_AltMnglRegObj("smi", &(ibsac_sminfo_rec.sm_info));
      SWIG_AltMnglRegObj("smir",&(ibsac_sminfo_rec));
      
      SWIG_AltMnglRegObj("swi", &(ibsac_swinfo_rec.switch_info));
      SWIG_AltMnglRegObj("swir",&(ibsac_swinfo_rec));

      SWIG_AltMnglRegObj("path",&(ibsac_path_rec));
      
      SWIG_AltMnglRegObj("link",&(ibsac_link_rec));
      
      SWIG_AltMnglRegObj("lft",&(ibsac_lft_rec));

      SWIG_AltMnglRegObj("mcm",&(ibsac_mcm_rec));

      SWIG_AltMnglRegObj("cpi",&(ibsac_class_port_info));
      SWIG_AltMnglRegObj("info",&(ibsac_inform_info));
      SWIG_AltMnglRegObj("svc",&(ibsac_svc_rec));
      
      SWIG_AltMnglRegObj("slvt", &(ibsac_slvl_rec.slvl_tbl));
      SWIG_AltMnglRegObj("slvr", &(ibsac_slvl_rec));
      
      SWIG_AltMnglRegObj("vlarb", &(ibsac_vlarb_rec));
      
      SWIG_AltMnglRegObj("pkt", &(ibsac_pkey_rec.pkey_tbl));
      SWIG_AltMnglRegObj("pkr", &(ibsac_pkey_rec));
      
      usleep(1000);
    }
    
    /* we defined this as a native command so declare it in here */
    Tcl_CreateObjCommand(interp, "ibis_get_local_ports_info",
                         ibis_get_local_ports_info, NULL, NULL);

	 /* this will declare an object osm_opts */
	 ibis_opt_p = &IbisOpts;
	 Tcl_CreateObjCommand(interp,"ibis_opts", Tclibis_opt_tMethodCmd,
									 (ClientData)ibis_opt_p, 0);

    /* add commands for accessing the global query records */
    Tcl_CreateObjCommand(interp,"smNodeInfoMad", 
                         TclsmNodeInfoMethodCmd,
                         (ClientData)&ibsm_node_info_obj, 0);
    
    Tcl_CreateObjCommand(interp,"smPortInfoMad", 
                         TclsmPortInfoMethodCmd,
                         (ClientData)&ibsm_port_info_obj, 0);
    
    Tcl_CreateObjCommand(interp,"smSwitchInfoMad", 
                         TclsmSwInfoMethodCmd,
                         (ClientData)&ibsm_switch_info_obj, 0);
    
    Tcl_CreateObjCommand(interp,"smLftBlockMad", 
                         TclsmLftBlockMethodCmd,
                         (ClientData)&ibsm_lft_block_obj, 0);
    
    Tcl_CreateObjCommand(interp,"smMftBlockMad", 
                         TclsmMftBlockMethodCmd,
                         (ClientData)&ibsm_mft_block_obj, 0);

    Tcl_CreateObjCommand(interp,"smGuidInfoMad", 
                         TclsmGuidInfoMethodCmd,
                         (ClientData)&ibsm_guid_info_obj, 0);

    Tcl_CreateObjCommand(interp,"smPkeyTableMad", 
                         TclsmPkeyTableMethodCmd,
                         (ClientData)&ibsm_pkey_table_obj, 0);

    Tcl_CreateObjCommand(interp,"smSlVlTableMad", 
                         TclsmSlVlTableMethodCmd,
                         (ClientData)&ibsm_slvl_table_obj, 0);

    Tcl_CreateObjCommand(interp,"smVlArbTableMad", 
                         TclsmVlArbTableMethodCmd,
                         (ClientData)&ibsm_vl_arb_table_obj, 0);

    Tcl_CreateObjCommand(interp,"smSMInfoMad", 
                         TclsmSMInfoMethodCmd,
                         (ClientData)&ibsm_sm_info_obj, 0);

    Tcl_CreateObjCommand(interp,"smNodeDescMad", 
                         TclsmNodeDescMethodCmd,
                         (ClientData)&ibsm_node_desc_obj, 0);

    Tcl_CreateObjCommand(interp,"smNoticeMad", 
                         TclsmNoticeMethodCmd,
                         (ClientData)&ibsm_notice_obj, 0);

	 Tcl_CreateObjCommand(interp,"sacNodeQuery", 
								 TclsacNodeRecMethodCmd,
								 (ClientData)&ibsac_node_rec, 0);
    
	 Tcl_CreateObjCommand(interp,"sacPortQuery", 
								 TclsacPortRecMethodCmd,
								 (ClientData)&ibsac_portinfo_rec, 0);
    
	 Tcl_CreateObjCommand(interp,"sacSmQuery", 
								 TclsacSmRecMethodCmd,
								 (ClientData)&ibsac_sminfo_rec, 0);
    
	 Tcl_CreateObjCommand(interp,"sacSwQuery", 
								 TclsacSwRecMethodCmd,
								 (ClientData)&ibsac_swinfo_rec, 0);
    
	 Tcl_CreateObjCommand(interp,"sacLinkQuery", 
								 TclsacLinkRecMethodCmd,
								 (ClientData)&ibsac_link_rec, 0);

	 Tcl_CreateObjCommand(interp,"sacPathQuery", 
								 TclsacPathRecMethodCmd,
								 (ClientData)&ibsac_path_rec, 0);

	 Tcl_CreateObjCommand(interp,"sacLFTQuery", 
								 TclsacLFTRecMethodCmd,
								 (ClientData)&ibsac_lft_rec, 0);

	 Tcl_CreateObjCommand(interp,"sacMCMQuery", 
								 TclsacMCMRecMethodCmd,
								 (ClientData)&ibsac_mcm_rec, 0);

	 Tcl_CreateObjCommand(interp,"sacClassPortInfoQuery", 
								 TclsacClassPortInfoMethodCmd,
								 (ClientData)&ibsac_class_port_info, 0);

	 Tcl_CreateObjCommand(interp,"sacInformInfoQuery", 
								 TclsacInformInfoMethodCmd,
								 (ClientData)&ibsac_inform_info, 0);

	 Tcl_CreateObjCommand(interp,"sacServiceQuery", 
								 TclsacServiceRecMethodCmd,
								 (ClientData)&ibsac_svc_rec, 0);

	 Tcl_CreateObjCommand(interp,"sacSLVlQuery", 
								 TclsacSlVlRecMethodCmd,
								 (ClientData)&ibsac_slvl_rec, 0);

	 Tcl_CreateObjCommand(interp,"sacVlArbQuery", 
								 TclsacVlArbRecMethodCmd,
								 (ClientData)&ibsac_vlarb_rec, 0);

	 Tcl_CreateObjCommand(interp,"sacPKeyQuery", 
								 TclsacPKeyRecMethodCmd,
								 (ClientData)&ibsac_pkey_rec, 0);


	 Tcl_PkgProvide(interp,"ibis", "1.0");	 
    
  }
%}
  