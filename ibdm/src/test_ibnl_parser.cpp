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
 * $Id: test_ibnl_parser.cpp,v 1.4 2005/02/23 21:08:43 eitan Exp $
 */

#include "Fabric.h"
#include "SysDef.h"

int
main(int argc,char **argv) {
  IBSystemsCollection sysCol;
  IBFabric fabric;
  map_str_str mods;

  if (argc != 3) {
    printf("Usage: ibnlparse <ib netlist file> <sys type>\n");
    return 1;
  }

  string fileName = argv[1];
  if (sysCol.parseIBSysdef(fileName)) {
	 printf("Error Parsing %s\n", argv[1]);
  }

  // build the system at hand:
  if (!sysCol.makeSystem(&fabric, "SW", argv[2], mods)) {
    printf("Error Building\n");
  }

  fabric.dump(cout);

  return 0;
}
