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

#ifndef _IBVS_BASE_H_
#define _IBVS_BASE_H_

#include <endian.h>

#define VS_CLASS             0x0a
#define VS_CLASS_PORT_INFO   0x01
#define VS_PRIVATE_LFT       0x10
#define VS_PORT_ON_OFF       0x11
#define VS_DEVICE_SOFT_RESET 0x12 
#define VS_EXT_PORT_ACCESS   0x13
#define VS_PHY_CONFIG        0x14
#define VS_MFT               0x15
#define VS_IB_PORT_CONFIG    0x16 
#define VENDOR_GET           0x01
#define VENDOR_SET           0x02
#define VENDOR_GET_RESP      0x81
#define EXT_CPU_PORT         0x01
#define EXT_I2C_PORT         0x01
#define EXT_I2C_PORT_1       0x02
#define EXT_I2C_PORT_2       0x03
#define EXT_GPIO_PORT        0x04
#define MAD_PAYLOAD_SIZE     256
#define IBVS_INITIAL_TID_VALUE 0xaaaa
#define IBVS_MULTI_MAX 64
#define IBVS_DATA_MAX 64
#define VS_FLASH_OPEN 0x0A
#define VS_FLASH_CLOSE 0x0B
#define VS_FLASH_BANK_SET 0x0C
#define VS_FLASH_ERASE_SECTOR 0x0F
#define VS_FLASH_READ_SECTOR 0x0D
#define VS_FLASH_WRITE_SECTOR 0x0E
#define ATTR_ID 0x0
#define ATTR_MOD 0x0
#define ATTR_MOD_LAST 0x1
#define VS_CPU_DATA_OFFSET 0
#define VS_GPIO_DATA_OFFSET 0
#define VS_I2C_DATA_OFFSET 3
#define VS_FLASH_DATA_OFFSET 2

typedef enum _ibvs_state
{
  IBVS_STATE_INIT,
  IBVS_STATE_READY,
  IBVS_STATE_BUSY,
} ibvs_state_t;

#include <complib/cl_packon.h>
typedef struct _ib_vs
{
ib_mad_t mad_header;
ib_net64_t vendor_key;
ib_net32_t data[56];
}	PACK_SUFFIX ib_vs_t;
#include <complib/cl_packoff.h>

#include <complib/cl_packon.h>
typedef struct _ib_vs_i2c
{
ib_mad_t mad_header;
ib_net64_t vendor_key;
ib_net32_t size;
ib_net32_t device_select;
ib_net32_t offset;
ib_net32_t data[53];
}	PACK_SUFFIX ib_vs_i2c_t;
#include <complib/cl_packoff.h>

#include <complib/cl_packon.h>
typedef struct _ib_vs_flash
{
ib_mad_t mad_header;
ib_net64_t vendor_key;
ib_net32_t size;
ib_net32_t offset;
ib_net32_t data[54];
}	PACK_SUFFIX ib_vs_flash_t;
#include <complib/cl_packoff.h>

#endif /* _IBVS_BASE_H_ */
