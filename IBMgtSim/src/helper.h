
/****h* IBMgtSim/Helper
 * NAME
 *	 Helper
 *
 * DESCRIPTION
 * 	Provide Some Helper Functions for Printing the content of the messages.
 *
 *
 * $Revision: 1.6 $
 *
 * AUTHOR
 *	Eitan Zahavi, Mellanox
 *
 *********/

#ifndef IBMGTSIM_HELPER_H
#define IBMGTSIM_HELPER_H

#ifndef IN 
#define IN
#endif
#ifndef OUT
#define OUT
#endif

#include "simmsg.h"

/****f* IBMgtSim: ClientIfc/ibms_dump_msg
* NAME
*	ibms_dump_msg
*
* DESCRIPTION
*	Dump the given message
*
* SYNOPSIS
*/
void 
ibms_dump_msg(IN const ibms_client_msg_t *p_msg);
/*
* PARAMETERS
*	p_msg
*		[in] The message
*
* RETURN VALUE
*	NONE
*
* NOTES
*
* SEE ALSO
* 
*********/

/****f* IBMgtSim: ClientIfc/ibms_get_msg_str
* NAME
*	ibms_get_msg_str
*
* DESCRIPTION
*	return a string with the given message content
*
* SYNOPSIS
*/
std::string 
ibms_get_msg_str(IN const ibms_client_msg_t *p_msg);
/*
* PARAMETERS
*	p_msg
*		[in] The message
*
* RETURN VALUE
*	NONE
*
* NOTES
*
* SEE ALSO
* 
*********/

/****f* IBMgtSim: ibms_get_mad_header_str
* NAME
*	ibms_get_mad_header_str
*
* DESCRIPTION
*	return a string with the given mad header content
*
* SYNOPSIS
*/
std::string 
ibms_get_mad_header_str(ib_mad_t madHeader);
/*
* PARAMETERS
*	madHeader
*		[in] The mad header
*
* RETURN VALUE
*	string with the information to print to the display
*
* NOTES
*
* SEE ALSO
* 
*********/

/****f* IBMgtSim: ibms_get_portInfo_str
* NAME
*	ibms_get_portInfo_str
*
* DESCRIPTION
*	return a string with the given PortInfo content
*
* SYNOPSIS
*/
std::string 
ibms_get_port_info_str(ib_port_info_t*     pPortInfo);
/*
* PARAMETERS
*	madHeader
*		[in] The mad header
*
* RETURN VALUE
*	string with the information to print to the display
*
* NOTES
*
* SEE ALSO
* 
*********/

/****f* IBMgtSim: ibms_get_node_info_str
* NAME
*	ibms_get_node_info_str
*
* DESCRIPTION
*	return a string with the given NodeInfo content
*
* SYNOPSIS
*/
std::string 
ibms_get_node_info_str(ib_node_info_t*     pNodeInfo);
/*
* PARAMETERS
*	madHeader
*		[in] The mad header
*
* RETURN VALUE
*	string with the information to print to the display
*
* NOTES
*
* SEE ALSO
* 
*********/

/****f* IBMgtSim: ClientIfc/ibms_get_resp_str
* NAME
*	ibms_get_resp_str
*
* DESCRIPTION
*	Get the string representing the message status
*
* SYNOPSIS
*/
char *
ibms_get_resp_str(IN const ibms_response_t *p_response);
/*
* PARAMETERS
*	p_msg
*		[in] The message
*
* RETURN VALUE
*	NONE
*
* NOTES
*
* SEE ALSO
* 
*********/

#endif /* IBMGTSIM_HELPER_H */
