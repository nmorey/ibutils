/* A Bison parser, made from /home/eitan/SW/cvsroot/IBADM/ibdm/datamodel/ibnl_parser.yy
   by GNU bison 1.35.  */

#define YYBISON 1  /* Identify Bison output.  */

# define	INT	257
# define	SYSTEM	258
# define	TOPSYSTEM	259
# define	NODE	260
# define	SUBSYSTEM	261
# define	NODETYPE	262
# define	NAME	263
# define	SPEED	264
# define	WIDTH	265
# define	LINE	266
# define	CFG	267

#line 40 "ibnl_parser.yy"


  /* header section */
#include <stdlib.h>
#include <stdio.h>
#include "SysDef.h"
#define YYERROR_VERBOSE 1

#define	yymaxdepth ibnl_maxdepth
#define	yyparse	ibnl_parse
#define	yylex	ibnl_lex
#define	yyerror	ibnl_error
#define	yylval	ibnl_lval
#define	yychar	ibnl_char
#define	yydebug	ibnl_debug
#define	yypact	ibnl_pact
#define	yyr1	ibnl_r1
#define	yyr2	ibnl_r2
#define	yydef	ibnl_def
#define	yychk	ibnl_chk
#define	yypgo	ibnl_pgo
#define	yyact	ibnl_act
#define	yyexca	ibnl_exca
#define  yyerrflag ibnl_errflag
#define  yynerrs	ibnl_nerrs
#define	yyps	ibnl_ps
#define	yypv	ibnl_pv
#define	yys	ibnl_s
#define	yy_yys	ibnl_yys
#define	yystate	ibnl_state
#define	yytmp	ibnl_tmp
#define	yyv	ibnl_v
#define	yy_yyv	ibnl_yyv
#define	yyval	ibnl_val
#define	yylloc	ibnl_lloc
#define yyreds	ibnl_reds
#define yytoks	ibnl_toks
#define yylhs	ibnl_yylhs
#define yylen	ibnl_yylen
#define yydefred ibnl_yydefred
#define yydgoto	ibnl_yydgoto
#define yysindex ibnl_yysindex
#define yyrindex ibnl_yyrindex
#define yygindex ibnl_yygindex
#define yytable	 ibnl_yytable
#define yycheck	 ibnl_yycheck
#define yyname   ibnl_yyname
#define yyrule   ibnl_yyrule

  extern int yyerror(char *msg);
  extern int yylex(void);



#line 96 "ibnl_parser.yy"
#ifndef YYSTYPE
typedef union {
  IBNodeType tval;
  int        ival;
  char      *sval;
} yystype;
# define YYSTYPE yystype
# define YYSTYPE_IS_TRIVIAL 1
#endif
#line 111 "ibnl_parser.yy"


  static int ibnlErr;
  long lineNum;
  static const char *gp_fileName;
  static int gIsTopSystem = 0;
  static list< char * > gSysNames;
  static IBSystemsCollection *gp_sysColl = 0;
  static IBSysDef *gp_curSysDef = 0;
  static IBSysInst *gp_curInstDef = 0;

  void ibnlMakeSystem(list< char * > &sysNames) {
#ifdef DEBUG
    printf("Making new system named:");
#endif
    gp_curSysDef = new IBSysDef(gp_fileName);

    for( list< char * >::iterator snI = sysNames.begin(); 
         snI != sysNames.end(); snI++) {
      char sname[512];
      if (gIsTopSystem) {
        sprintf(sname, "%s", *snI);
      } else {
        sprintf(sname, "%s/%s", gp_fileName, *snI);
      }
      gp_sysColl->addSysDef(sname, gp_curSysDef);
#ifdef DEBUG
      printf("%s ", sname);
#endif
    } 
#ifdef DEBUG
    printf("\n");
#endif

    // cleanup for next systems.
    sysNames.erase(sysNames.begin(), sysNames.end());
  }
  
  void ibnlMakeSubInstAttribute(char *hInst, char *attr, char *value) {
#ifdef DEBUG
    printf("Making new sub instance attribute inst:%s %s=%s\n", 
           hInst, attr, value);
#endif
    if (! gp_curSysDef) {
        printf("-E- How com e we got no system???\n");
        exit(3);
    }
    // append to existing attr or create new
    string hierInstName = string(hInst);
    string attrStr = string(attr);
    if (value)
       attrStr += "=" +  string(value);
    gp_curSysDef->setSubInstAttr(hierInstName, attrStr);
  }
  
  void ibnlMakeNode(IBNodeType type, int numPorts, char *devName, char* name) {
#ifdef DEBUG
    printf(" Making Node:%s dev:%s ports:%d\n", name, devName, numPorts);
#endif
    gp_curInstDef = new IBSysInst(name, devName, numPorts, type);
    gp_curSysDef->addInst(gp_curInstDef);
  }

  void ibnlMakeNodeToNodeConn(
    int fromPort, char *width, char *speed, char *toNode, int toPort) {
#ifdef DEBUG
    printf("  Connecting N-N port:%d to Node:%s/%d (w=%s,s=%s)\n",
           fromPort, toNode, toPort, width, speed);
#endif
    char buf1[8],buf2[8] ;
    sprintf(buf1, "%d", toPort);
    sprintf(buf2, "%d", fromPort); 
    IBSysInstPort *p_port = 
      new IBSysInstPort(buf2, toNode, buf1, char2width(width), 
                        char2speed(speed));
    gp_curInstDef->addPort(p_port);
  }

  void ibnlMakeNodeToPortConn(
    int fromPort, char *width, char *speed, char *sysPortName) {
#ifdef DEBUG
    printf("  System port:%s on port:%d (w=%s,s=%s)\n",
           sysPortName, fromPort, width, speed);
#endif
    char buf[8];
    sprintf(buf,"%d",fromPort);
    IBSysPortDef *p_sysPort = 
      new IBSysPortDef(sysPortName, gp_curInstDef->getName(), buf,
                       char2width(width), char2speed(speed));
    gp_curSysDef->addSysPort(p_sysPort);
  }
  
  void ibnlMakeSubsystem( char *masterName, char *instName) {
#ifdef DEBUG
    printf(" Making SubSystem:%s of type:%s\n", instName, masterName);
#endif
    gp_curInstDef = new IBSysInst(instName, masterName);
    gp_curSysDef->addInst(gp_curInstDef);    
  }

  void ibnlRecordModification( char *subSystem, char *modifier) {
#ifdef DEBUG
    printf("  Using modifier:%s on %s\n", modifier, subSystem);
#endif
    gp_curInstDef->addInstMod(subSystem, modifier);
  }

  void ibnlMakeSubsystemToSubsystemConn(
    char *fromPort, char *width, char *speed, char *toSystem, char *toPort) {
#ifdef DEBUG
    printf("  Connecting S-S port:%s to SubSys:%s/%s\n", 
         fromPort, toSystem, toPort);
#endif
    IBSysInstPort *p_port = 
      new IBSysInstPort(fromPort, toSystem, toPort, char2width(width), 
                        char2speed(speed));
    gp_curInstDef->addPort(p_port);
  }

  void ibnlMakeSubsystemToPortConn(
    char *fromPort, char *width, char *speed, char *toPort) {
#ifdef DEBUG
    printf("  Connecting port:%s to SysPort:%s\n", 
         fromPort, toPort);
#endif
    
    IBSysPortDef *p_sysPort = 
      new IBSysPortDef(toPort, gp_curInstDef->getName(), fromPort,
                       char2width(width), char2speed(speed));
    gp_curSysDef->addSysPort(p_sysPort);
  }

#ifndef YYDEBUG
# define YYDEBUG 0
#endif



#define	YYFINAL		107
#define	YYFLAG		-32768
#define	YYNTBASE	18

/* YYTRANSLATE(YYLEX) -- Bison token number corresponding to YYLEX. */
#define YYTRANSLATE(x) ((unsigned)(x) <= 267 ? yytranslate[x] : 47)

/* YYTRANSLATE[YYLEX] -- Bison token number corresponding to YYLEX. */
static const char yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,    15,    16,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,    14,    17,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     3,     4,     5,
       6,     7,     8,     9,    10,    11,    12,    13
};

#if YYDEBUG
static const short yyprhs[] =
{
       0,     0,     2,     5,     6,     8,    12,    13,    16,    17,
      21,    27,    33,    37,    38,    39,    47,    48,    49,    56,
      58,    62,    64,    65,    68,    71,    75,    81,    82,    86,
      88,    90,   100,   108,   116,   122,   131,   138,   145,   150,
     154,   161,   165,   166,   169,   173,   174,   178,   180,   182,
     192,   200,   208,   214,   223,   230,   237
};
static const short yyrhs[] =
{
      12,     0,    18,    12,     0,     0,    18,     0,    19,    21,
      24,     0,     0,    21,    27,     0,     0,    22,    23,    18,
       0,     9,    14,     9,    14,     9,     0,     9,    14,     9,
      14,     3,     0,     9,    14,     9,     0,     0,     0,     5,
      25,    30,    26,    18,    22,    32,     0,     0,     0,     4,
      28,    30,    29,    18,    32,     0,    31,     0,    30,    15,
      31,     0,     9,     0,     0,    32,    33,     0,    32,    39,
       0,    34,    18,    35,     0,     6,     8,     3,     9,     9,
       0,     0,    35,    36,    18,     0,    37,     0,    38,     0,
       3,    16,    11,    16,    10,    16,    17,     9,     3,     0,
       3,    16,    11,    16,    17,     9,     3,     0,     3,    16,
      10,    16,    17,     9,     3,     0,     3,    16,    17,     9,
       3,     0,     3,    16,    11,    16,    10,    16,    17,     9,
       0,     3,    16,    11,    16,    17,     9,     0,     3,    16,
      10,    16,    17,     9,     0,     3,    16,    17,     9,     0,
      40,    18,    43,     0,    40,    18,    13,    41,    18,    43,
       0,     7,     9,     9,     0,     0,    41,    42,     0,     9,
      14,     9,     0,     0,    43,    44,    18,     0,    45,     0,
      46,     0,     9,    16,    11,    16,    10,    16,    17,     9,
       9,     0,     9,    16,    11,    16,    17,     9,     9,     0,
       9,    16,    10,    16,    17,     9,     9,     0,     9,    16,
      17,     9,     9,     0,     9,    16,    11,    16,    10,    16,
      17,     9,     0,     9,    16,    11,    16,    17,     9,     0,
       9,    16,    10,    16,    17,     9,     0,     9,    16,    17,
       9,     0
};

#endif

#if YYDEBUG
/* YYRLINE[YYN] -- source line where rule number YYN was defined. */
static const short yyrline[] =
{
       0,   246,   248,   250,   251,   253,   255,   256,   259,   260,
     263,   265,   270,   273,   273,   273,   280,   280,   280,   285,
     287,   290,   294,   295,   296,   299,   303,   307,   308,   311,
     313,   316,   320,   323,   326,   331,   335,   338,   341,   346,
     348,   351,   355,   356,   359,   363,   364,   367,   369,   372,
     376,   379,   382,   387,   391,   394,   397
};
#endif


#if (YYDEBUG) || defined YYERROR_VERBOSE

/* YYTNAME[TOKEN_NUM] -- String name of the token TOKEN_NUM. */
static const char *const yytname[] =
{
  "$", "error", "$undefined.", "INT", "SYSTEM", "TOPSYSTEM", "NODE", 
  "SUBSYSTEM", "NODETYPE", "NAME", "SPEED", "WIDTH", "LINE", "CFG", "'='", 
  "','", "'-'", "'>'", "NL", "ONL", "ibnl", "systems", 
  "sub_inst_attributes", "sub_inst_attribute", "topsystem", "@1", "@2", 
  "system", "@3", "@4", "system_names", "system_name", "insts", "node", 
  "node_header", "node_connections", "node_connection", 
  "node_to_node_link", "node_to_port_link", "subsystem", 
  "subsystem_header", "insts_modifications", "modification", 
  "subsystem_connections", "subsystem_connection", 
  "subsystem_to_subsystem_link", "subsystem_to_port_link", 0
};
#endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives. */
static const short yyr1[] =
{
       0,    18,    18,    19,    19,    20,    21,    21,    22,    22,
      23,    23,    23,    25,    26,    24,    28,    29,    27,    30,
      30,    31,    32,    32,    32,    33,    34,    35,    35,    36,
      36,    37,    37,    37,    37,    38,    38,    38,    38,    39,
      39,    40,    41,    41,    42,    43,    43,    44,    44,    45,
      45,    45,    45,    46,    46,    46,    46
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN. */
static const short yyr2[] =
{
       0,     1,     2,     0,     1,     3,     0,     2,     0,     3,
       5,     5,     3,     0,     0,     7,     0,     0,     6,     1,
       3,     1,     0,     2,     2,     3,     5,     0,     3,     1,
       1,     9,     7,     7,     5,     8,     6,     6,     4,     3,
       6,     3,     0,     2,     3,     0,     3,     1,     1,     9,
       7,     7,     5,     8,     6,     6,     4
};

/* YYDEFACT[S] -- default rule to reduce with in state S when YYTABLE
   doesn't specify something else to do.  Zero means the default is an
   error. */
static const short yydefact[] =
{
       3,     1,     4,     6,     2,     0,    16,    13,     5,     7,
       0,     0,    21,    17,    19,    14,     0,     0,     0,    20,
      22,     8,    18,    22,     0,     0,    23,     0,    24,     0,
       0,     0,    15,     0,     0,    27,    45,     0,     9,     0,
      41,    25,    42,    39,    12,     0,     0,     0,    29,    30,
       0,     0,     0,    47,    48,     0,    26,     0,    28,     0,
      45,    43,     0,    46,    11,    10,     0,     0,     0,     0,
      40,     0,     0,     0,     0,     0,    38,    44,     0,     0,
      56,     0,     0,     0,    34,     0,     0,     0,    52,    37,
       0,    36,    55,     0,    54,    33,     0,    32,    51,     0,
      50,    35,    53,    31,    49,     0,     0,     0
};

static const short yydefgoto[] =
{
       2,     3,   105,     5,    23,    31,     8,    11,    18,     9,
      10,    17,    13,    14,    22,    26,    27,    41,    47,    48,
      49,    28,    29,    50,    61,    43,    52,    53,    54
};

static const short yypact[] =
{
      -5,-32768,     9,-32768,-32768,    14,-32768,-32768,-32768,-32768,
      16,    16,-32768,    11,-32768,    11,    16,    -5,    -5,-32768,
       9,     9,    17,    20,    23,    25,-32768,    -5,-32768,    -5,
      18,    -5,    17,    33,    28,     9,    15,    29,     9,    30,
  -32768,    37,-32768,    32,    31,    34,    26,    -5,-32768,-32768,
       8,    35,    -5,-32768,-32768,    13,-32768,    -8,     9,    36,
       9,-32768,    -6,     9,-32768,-32768,    38,    39,    40,    43,
      32,    41,    42,    44,    27,    -4,    45,-32768,    46,    -2,
      47,    50,    48,    51,-32768,    52,    49,    53,-32768,    63,
      54,    64,    59,    55,    60,-32768,    61,-32768,-32768,    65,
  -32768,    70,    66,-32768,-32768,    76,    77,-32768
};

static const short yypgoto[] =
{
     -17,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
  -32768,-32768,    67,    68,    24,-32768,-32768,-32768,-32768,-32768,
  -32768,-32768,-32768,-32768,-32768,   -14,-32768,-32768,-32768
};


#define	YYLAST		84


static const short yytable[] =
{
      20,    21,    66,    67,    71,    72,    82,     1,    86,    68,
      35,    73,    36,    83,    38,    87,    64,    59,     6,     7,
       1,     4,    65,    24,    25,    12,    16,     4,    42,    30,
      58,    33,    37,    60,    34,    63,    39,    40,    44,    45,
      46,    51,    57,    56,    81,    55,    70,    32,    84,    76,
      69,    62,    77,    80,    74,    75,    88,    78,    79,    89,
      91,    92,    94,    85,    90,    93,    95,    97,    98,   100,
     101,    96,    99,   103,   102,   104,   106,   107,    15,     0,
       0,     0,     0,     0,    19
};

static const short yycheck[] =
{
      17,    18,    10,    11,    10,    11,    10,    12,    10,    17,
      27,    17,    29,    17,    31,    17,     3,     9,     4,     5,
      12,    12,     9,     6,     7,     9,    15,    12,    13,     9,
      47,     8,    14,    50,     9,    52,     3,     9,     9,     9,
       3,     9,    16,     9,    17,    14,    60,    23,     3,     9,
      14,    16,     9,     9,    16,    16,     9,    16,    16,     9,
       9,     9,     9,    17,    16,    16,     3,     3,     9,     9,
       9,    17,    17,     3,     9,     9,     0,     0,    11,    -1,
      -1,    -1,    -1,    -1,    16
};
/* -*-C-*-  Note some compilers choke on comments on `#line' lines.  */
#line 3 "/usr/share/bison/bison.simple"

/* Skeleton output parser for bison,

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002 Free Software
   Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

/* As a special exception, when this file is copied by Bison into a
   Bison output file, you may use that output file without restriction.
   This special exception was added by the Free Software Foundation
   in version 1.24 of Bison.  */

/* This is the parser code that is written into each bison parser when
   the %semantic_parser declaration is not specified in the grammar.
   It was written by Richard Stallman by simplifying the hairy parser
   used when %semantic_parser is specified.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

#if ! defined (yyoverflow) || defined (YYERROR_VERBOSE)

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# if YYSTACK_USE_ALLOCA
#  define YYSTACK_ALLOC alloca
# else
#  ifndef YYSTACK_USE_ALLOCA
#   if defined (alloca) || defined (_ALLOCA_H)
#    define YYSTACK_ALLOC alloca
#   else
#    ifdef __GNUC__
#     define YYSTACK_ALLOC __builtin_alloca
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's `empty if-body' warning. */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
# else
#  if defined (__STDC__) || defined (__cplusplus)
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   define YYSIZE_T size_t
#  endif
#  define YYSTACK_ALLOC malloc
#  define YYSTACK_FREE free
# endif
#endif /* ! defined (yyoverflow) || defined (YYERROR_VERBOSE) */


#if (! defined (yyoverflow) \
     && (! defined (__cplusplus) \
	 || (YYLTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  short yyss;
  YYSTYPE yyvs;
# if YYLSP_NEEDED
  YYLTYPE yyls;
# endif
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAX (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# if YYLSP_NEEDED
#  define YYSTACK_BYTES(N) \
     ((N) * (sizeof (short) + sizeof (YYSTYPE) + sizeof (YYLTYPE))	\
      + 2 * YYSTACK_GAP_MAX)
# else
#  define YYSTACK_BYTES(N) \
     ((N) * (sizeof (short) + sizeof (YYSTYPE))				\
      + YYSTACK_GAP_MAX)
# endif

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if 1 < __GNUC__
#   define YYCOPY(To, From, Count) \
      __builtin_memcpy (To, From, (Count) * sizeof (*(From)))
#  else
#   define YYCOPY(To, From, Count)		\
      do					\
	{					\
	  register YYSIZE_T yyi;		\
	  for (yyi = 0; yyi < (Count); yyi++)	\
	    (To)[yyi] = (From)[yyi];		\
	}					\
      while (0)
#  endif
# endif

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack)					\
    do									\
      {									\
	YYSIZE_T yynewbytes;						\
	YYCOPY (&yyptr->Stack, Stack, yysize);				\
	Stack = &yyptr->Stack;						\
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAX;	\
	yyptr += yynewbytes / sizeof (*yyptr);				\
      }									\
    while (0)

#endif


#if ! defined (YYSIZE_T) && defined (__SIZE_TYPE__)
# define YYSIZE_T __SIZE_TYPE__
#endif
#if ! defined (YYSIZE_T) && defined (size_t)
# define YYSIZE_T size_t
#endif
#if ! defined (YYSIZE_T)
# if defined (__STDC__) || defined (__cplusplus)
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# endif
#endif
#if ! defined (YYSIZE_T)
# define YYSIZE_T unsigned int
#endif

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		-2
#define YYEOF		0
#define YYACCEPT	goto yyacceptlab
#define YYABORT 	goto yyabortlab
#define YYERROR		goto yyerrlab1
/* Like YYERROR except do call yyerror.  This remains here temporarily
   to ease the transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */
#define YYFAIL		goto yyerrlab
#define YYRECOVERING()  (!!yyerrstatus)
#define YYBACKUP(Token, Value)					\
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    {								\
      yychar = (Token);						\
      yylval = (Value);						\
      yychar1 = YYTRANSLATE (yychar);				\
      YYPOPSTACK;						\
      goto yybackup;						\
    }								\
  else								\
    { 								\
      yyerror ("syntax error: cannot back up");			\
      YYERROR;							\
    }								\
while (0)

#define YYTERROR	1
#define YYERRCODE	256


/* YYLLOC_DEFAULT -- Compute the default location (before the actions
   are run).

   When YYLLOC_DEFAULT is run, CURRENT is set the location of the
   first token.  By default, to implement support for ranges, extend
   its range to the last symbol.  */

#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)       	\
   Current.last_line   = Rhs[N].last_line;	\
   Current.last_column = Rhs[N].last_column;
#endif


/* YYLEX -- calling `yylex' with the right arguments.  */

#if YYPURE
# if YYLSP_NEEDED
#  ifdef YYLEX_PARAM
#   define YYLEX		yylex (&yylval, &yylloc, YYLEX_PARAM)
#  else
#   define YYLEX		yylex (&yylval, &yylloc)
#  endif
# else /* !YYLSP_NEEDED */
#  ifdef YYLEX_PARAM
#   define YYLEX		yylex (&yylval, YYLEX_PARAM)
#  else
#   define YYLEX		yylex (&yylval)
#  endif
# endif /* !YYLSP_NEEDED */
#else /* !YYPURE */
# define YYLEX			yylex ()
#endif /* !YYPURE */


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)			\
do {						\
  if (yydebug)					\
    YYFPRINTF Args;				\
} while (0)
/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
#endif /* !YYDEBUG */

/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef	YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   SIZE_MAX < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#if YYMAXDEPTH == 0
# undef YYMAXDEPTH
#endif

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif

#ifdef YYERROR_VERBOSE

# ifndef yystrlen
#  if defined (__GLIBC__) && defined (_STRING_H)
#   define yystrlen strlen
#  else
/* Return the length of YYSTR.  */
static YYSIZE_T
#   if defined (__STDC__) || defined (__cplusplus)
yystrlen (const char *yystr)
#   else
yystrlen (yystr)
     const char *yystr;
#   endif
{
  register const char *yys = yystr;

  while (*yys++ != '\0')
    continue;

  return yys - yystr - 1;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined (__GLIBC__) && defined (_STRING_H) && defined (_GNU_SOURCE)
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
#   if defined (__STDC__) || defined (__cplusplus)
yystpcpy (char *yydest, const char *yysrc)
#   else
yystpcpy (yydest, yysrc)
     char *yydest;
     const char *yysrc;
#   endif
{
  register char *yyd = yydest;
  register const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif
#endif

#line 315 "/usr/share/bison/bison.simple"


/* The user can define YYPARSE_PARAM as the name of an argument to be passed
   into yyparse.  The argument should have type void *.
   It should actually point to an object.
   Grammar actions can access the variable by casting it
   to the proper pointer type.  */

#ifdef YYPARSE_PARAM
# if defined (__STDC__) || defined (__cplusplus)
#  define YYPARSE_PARAM_ARG void *YYPARSE_PARAM
#  define YYPARSE_PARAM_DECL
# else
#  define YYPARSE_PARAM_ARG YYPARSE_PARAM
#  define YYPARSE_PARAM_DECL void *YYPARSE_PARAM;
# endif
#else /* !YYPARSE_PARAM */
# define YYPARSE_PARAM_ARG
# define YYPARSE_PARAM_DECL
#endif /* !YYPARSE_PARAM */

/* Prevent warning if -Wstrict-prototypes.  */
#ifdef __GNUC__
# ifdef YYPARSE_PARAM
int yyparse (void *);
# else
int yyparse (void);
# endif
#endif

/* YY_DECL_VARIABLES -- depending whether we use a pure parser,
   variables are global, or local to YYPARSE.  */

#define YY_DECL_NON_LSP_VARIABLES			\
/* The lookahead symbol.  */				\
int yychar;						\
							\
/* The semantic value of the lookahead symbol. */	\
YYSTYPE yylval;						\
							\
/* Number of parse errors so far.  */			\
int yynerrs;

#if YYLSP_NEEDED
# define YY_DECL_VARIABLES			\
YY_DECL_NON_LSP_VARIABLES			\
						\
/* Location data for the lookahead symbol.  */	\
YYLTYPE yylloc;
#else
# define YY_DECL_VARIABLES			\
YY_DECL_NON_LSP_VARIABLES
#endif


/* If nonreentrant, generate the variables here. */

#if !YYPURE
YY_DECL_VARIABLES
#endif  /* !YYPURE */

int
yyparse (YYPARSE_PARAM_ARG)
     YYPARSE_PARAM_DECL
{
  /* If reentrant, generate the variables here. */
#if YYPURE
  YY_DECL_VARIABLES
#endif  /* !YYPURE */

  register int yystate;
  register int yyn;
  int yyresult;
  /* Number of tokens to shift before error messages enabled.  */
  int yyerrstatus;
  /* Lookahead token as an internal (translated) token number.  */
  int yychar1 = 0;

  /* Three stacks and their tools:
     `yyss': related to states,
     `yyvs': related to semantic values,
     `yyls': related to locations.

     Refer to the stacks thru separate pointers, to allow yyoverflow
     to reallocate them elsewhere.  */

  /* The state stack. */
  short	yyssa[YYINITDEPTH];
  short *yyss = yyssa;
  register short *yyssp;

  /* The semantic value stack.  */
  YYSTYPE yyvsa[YYINITDEPTH];
  YYSTYPE *yyvs = yyvsa;
  register YYSTYPE *yyvsp;

#if YYLSP_NEEDED
  /* The location stack.  */
  YYLTYPE yylsa[YYINITDEPTH];
  YYLTYPE *yyls = yylsa;
  YYLTYPE *yylsp;
#endif

#if YYLSP_NEEDED
# define YYPOPSTACK   (yyvsp--, yyssp--, yylsp--)
#else
# define YYPOPSTACK   (yyvsp--, yyssp--)
#endif

  YYSIZE_T yystacksize = YYINITDEPTH;


  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;
#if YYLSP_NEEDED
  YYLTYPE yyloc;
#endif

  /* When reducing, the number of symbols on the RHS of the reduced
     rule. */
  int yylen;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY;		/* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */

  yyssp = yyss;
  yyvsp = yyvs;
#if YYLSP_NEEDED
  yylsp = yyls;
#endif
  goto yysetstate;

/*------------------------------------------------------------.
| yynewstate -- Push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
 yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed. so pushing a state here evens the stacks.
     */
  yyssp++;

 yysetstate:
  *yyssp = yystate;

  if (yyssp >= yyss + yystacksize - 1)
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
      {
	/* Give user a chance to reallocate the stack. Use copies of
	   these so that the &'s don't force the real ones into
	   memory.  */
	YYSTYPE *yyvs1 = yyvs;
	short *yyss1 = yyss;

	/* Each stack pointer address is followed by the size of the
	   data in use in that stack, in bytes.  */
# if YYLSP_NEEDED
	YYLTYPE *yyls1 = yyls;
	/* This used to be a conditional around just the two extra args,
	   but that might be undefined if yyoverflow is a macro.  */
	yyoverflow ("parser stack overflow",
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),
		    &yyls1, yysize * sizeof (*yylsp),
		    &yystacksize);
	yyls = yyls1;
# else
	yyoverflow ("parser stack overflow",
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),
		    &yystacksize);
# endif
	yyss = yyss1;
	yyvs = yyvs1;
      }
#else /* no yyoverflow */
# ifndef YYSTACK_RELOCATE
      goto yyoverflowlab;
# else
      /* Extend the stack our own way.  */
      if (yystacksize >= YYMAXDEPTH)
	goto yyoverflowlab;
      yystacksize *= 2;
      if (yystacksize > YYMAXDEPTH)
	yystacksize = YYMAXDEPTH;

      {
	short *yyss1 = yyss;
	union yyalloc *yyptr =
	  (union yyalloc *) YYSTACK_ALLOC (YYSTACK_BYTES (yystacksize));
	if (! yyptr)
	  goto yyoverflowlab;
	YYSTACK_RELOCATE (yyss);
	YYSTACK_RELOCATE (yyvs);
# if YYLSP_NEEDED
	YYSTACK_RELOCATE (yyls);
# endif
# undef YYSTACK_RELOCATE
	if (yyss1 != yyssa)
	  YYSTACK_FREE (yyss1);
      }
# endif
#endif /* no yyoverflow */

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;
#if YYLSP_NEEDED
      yylsp = yyls + yysize - 1;
#endif

      YYDPRINTF ((stderr, "Stack size increased to %lu\n",
		  (unsigned long int) yystacksize));

      if (yyssp >= yyss + yystacksize - 1)
	YYABORT;
    }

  YYDPRINTF ((stderr, "Entering state %d\n", yystate));

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:

/* Do appropriate processing given the current state.  */
/* Read a lookahead token if we need one and don't already have one.  */
/* yyresume: */

  /* First try to decide what to do without reference to lookahead token.  */

  yyn = yypact[yystate];
  if (yyn == YYFLAG)
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* yychar is either YYEMPTY or YYEOF
     or a valid token in external form.  */

  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = YYLEX;
    }

  /* Convert token to internal form (in yychar1) for indexing tables with */

  if (yychar <= 0)		/* This means end of input. */
    {
      yychar1 = 0;
      yychar = YYEOF;		/* Don't call YYLEX any more */

      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yychar1 = YYTRANSLATE (yychar);

#if YYDEBUG
     /* We have to keep this `#if YYDEBUG', since we use variables
	which are defined only if `YYDEBUG' is set.  */
      if (yydebug)
	{
	  YYFPRINTF (stderr, "Next token is %d (%s",
		     yychar, yytname[yychar1]);
	  /* Give the individual parser a way to print the precise
	     meaning of a token, for further debugging info.  */
# ifdef YYPRINT
	  YYPRINT (stderr, yychar, yylval);
# endif
	  YYFPRINTF (stderr, ")\n");
	}
#endif
    }

  yyn += yychar1;
  if (yyn < 0 || yyn > YYLAST || yycheck[yyn] != yychar1)
    goto yydefault;

  yyn = yytable[yyn];

  /* yyn is what to do for this token type in this state.
     Negative => reduce, -yyn is rule number.
     Positive => shift, yyn is new state.
       New state is final state => don't bother to shift,
       just return success.
     0, or most negative number => error.  */

  if (yyn < 0)
    {
      if (yyn == YYFLAG)
	goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }
  else if (yyn == 0)
    goto yyerrlab;

  if (yyn == YYFINAL)
    YYACCEPT;

  /* Shift the lookahead token.  */
  YYDPRINTF ((stderr, "Shifting token %d (%s), ",
	      yychar, yytname[yychar1]));

  /* Discard the token being shifted unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  *++yyvsp = yylval;
#if YYLSP_NEEDED
  *++yylsp = yylloc;
#endif

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  yystate = yyn;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- Do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     `$$ = $1'.

     Otherwise, the following line sets YYVAL to the semantic value of
     the lookahead token.  This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];

#if YYLSP_NEEDED
  /* Similarly for the default location.  Let the user run additional
     commands if for instance locations are ranges.  */
  yyloc = yylsp[1-yylen];
  YYLLOC_DEFAULT (yyloc, (yylsp - yylen), yylen);
#endif

#if YYDEBUG
  /* We have to keep this `#if YYDEBUG', since we use variables which
     are defined only if `YYDEBUG' is set.  */
  if (yydebug)
    {
      int yyi;

      YYFPRINTF (stderr, "Reducing via rule %d (line %d), ",
		 yyn, yyrline[yyn]);

      /* Print the symbols being reduced, and their result.  */
      for (yyi = yyprhs[yyn]; yyrhs[yyi] > 0; yyi++)
	YYFPRINTF (stderr, "%s ", yytname[yyrhs[yyi]]);
      YYFPRINTF (stderr, " -> %s\n", yytname[yyr1[yyn]]);
    }
#endif

  switch (yyn) {

case 10:
#line 264 "ibnl_parser.yy"
{ ibnlMakeSubInstAttribute(yyvsp[-4].sval,yyvsp[-2].sval,yyvsp[0].sval); }
    break;
case 11:
#line 265 "ibnl_parser.yy"
{
      char buf[16]; 
      sprintf(buf, "%d", yyvsp[0].ival);
      ibnlMakeSubInstAttribute(yyvsp[-4].sval,yyvsp[-2].sval,buf); 
   }
    break;
case 12:
#line 270 "ibnl_parser.yy"
{ibnlMakeSubInstAttribute(yyvsp[-2].sval,yyvsp[0].sval,NULL); }
    break;
case 13:
#line 274 "ibnl_parser.yy"
{ gIsTopSystem = 1; }
    break;
case 14:
#line 275 "ibnl_parser.yy"
{ ibnlMakeSystem(gSysNames); }
    break;
case 16:
#line 281 "ibnl_parser.yy"
{ gIsTopSystem = 0; }
    break;
case 17:
#line 282 "ibnl_parser.yy"
{ ibnlMakeSystem(gSysNames); }
    break;
case 21:
#line 291 "ibnl_parser.yy"
{ gSysNames.push_back(yyvsp[0].sval); }
    break;
case 26:
#line 304 "ibnl_parser.yy"
{ ibnlMakeNode(yyvsp[-3].tval,yyvsp[-2].ival,yyvsp[-1].sval,yyvsp[0].sval); }
    break;
case 31:
#line 317 "ibnl_parser.yy"
{
      ibnlMakeNodeToNodeConn(yyvsp[-8].ival, yyvsp[-6].sval, yyvsp[-4].sval, yyvsp[-1].sval, yyvsp[0].ival);
    }
    break;
case 32:
#line 320 "ibnl_parser.yy"
{
      ibnlMakeNodeToNodeConn(yyvsp[-6].ival, yyvsp[-4].sval, "2.5", yyvsp[-1].sval, yyvsp[0].ival);
    }
    break;
case 33:
#line 323 "ibnl_parser.yy"
{
      ibnlMakeNodeToNodeConn(yyvsp[-6].ival, "4x", yyvsp[-4].sval, yyvsp[-1].sval, yyvsp[0].ival);
    }
    break;
case 34:
#line 326 "ibnl_parser.yy"
{
      ibnlMakeNodeToNodeConn(yyvsp[-4].ival, "4x", "2.5", yyvsp[-1].sval, yyvsp[0].ival);
    }
    break;
case 35:
#line 332 "ibnl_parser.yy"
{
      ibnlMakeNodeToPortConn(yyvsp[-7].ival, yyvsp[-5].sval, yyvsp[-3].sval, yyvsp[0].sval);
    }
    break;
case 36:
#line 335 "ibnl_parser.yy"
{
      ibnlMakeNodeToPortConn(yyvsp[-5].ival, yyvsp[-3].sval, "2.5", yyvsp[0].sval);
    }
    break;
case 37:
#line 338 "ibnl_parser.yy"
{
      ibnlMakeNodeToPortConn(yyvsp[-5].ival, "4x", yyvsp[-3].sval, yyvsp[0].sval);
    }
    break;
case 38:
#line 341 "ibnl_parser.yy"
{
      ibnlMakeNodeToPortConn(yyvsp[-3].ival, "4x", "2.5", yyvsp[0].sval);
    }
    break;
case 41:
#line 352 "ibnl_parser.yy"
{ ibnlMakeSubsystem(yyvsp[-1].sval,yyvsp[0].sval); }
    break;
case 44:
#line 360 "ibnl_parser.yy"
{ ibnlRecordModification(yyvsp[-2].sval,yyvsp[0].sval); }
    break;
case 49:
#line 373 "ibnl_parser.yy"
{
      ibnlMakeSubsystemToSubsystemConn(yyvsp[-8].sval, yyvsp[-6].sval, yyvsp[-4].sval, yyvsp[-1].sval, yyvsp[0].sval);
    }
    break;
case 50:
#line 376 "ibnl_parser.yy"
{
      ibnlMakeSubsystemToSubsystemConn(yyvsp[-6].sval, yyvsp[-4].sval, "2.5", yyvsp[-1].sval, yyvsp[0].sval);
    }
    break;
case 51:
#line 379 "ibnl_parser.yy"
{
      ibnlMakeSubsystemToSubsystemConn(yyvsp[-6].sval, "4x", yyvsp[-4].sval, yyvsp[-1].sval, yyvsp[0].sval);
    }
    break;
case 52:
#line 382 "ibnl_parser.yy"
{
      ibnlMakeSubsystemToSubsystemConn(yyvsp[-4].sval, "4x", "2.5", yyvsp[-1].sval, yyvsp[0].sval);
    }
    break;
case 53:
#line 388 "ibnl_parser.yy"
{
      ibnlMakeSubsystemToPortConn(yyvsp[-7].sval, yyvsp[-5].sval, yyvsp[-3].sval, yyvsp[0].sval);
    }
    break;
case 54:
#line 391 "ibnl_parser.yy"
{
      ibnlMakeSubsystemToPortConn(yyvsp[-5].sval, yyvsp[-3].sval, "2.5", yyvsp[0].sval);
    }
    break;
case 55:
#line 394 "ibnl_parser.yy"
{
      ibnlMakeSubsystemToPortConn(yyvsp[-5].sval, "4x", yyvsp[-3].sval, yyvsp[0].sval);
    }
    break;
case 56:
#line 397 "ibnl_parser.yy"
{
      ibnlMakeSubsystemToPortConn(yyvsp[-3].sval, "4x", "2.5", yyvsp[0].sval);
    }
    break;
}

#line 705 "/usr/share/bison/bison.simple"


  yyvsp -= yylen;
  yyssp -= yylen;
#if YYLSP_NEEDED
  yylsp -= yylen;
#endif

#if YYDEBUG
  if (yydebug)
    {
      short *yyssp1 = yyss - 1;
      YYFPRINTF (stderr, "state stack now");
      while (yyssp1 != yyssp)
	YYFPRINTF (stderr, " %d", *++yyssp1);
      YYFPRINTF (stderr, "\n");
    }
#endif

  *++yyvsp = yyval;
#if YYLSP_NEEDED
  *++yylsp = yyloc;
#endif

  /* Now `shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTBASE] + *yyssp;
  if (yystate >= 0 && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTBASE];

  goto yynewstate;


/*------------------------------------.
| yyerrlab -- here on detecting error |
`------------------------------------*/
yyerrlab:
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;

#ifdef YYERROR_VERBOSE
      yyn = yypact[yystate];

      if (yyn > YYFLAG && yyn < YYLAST)
	{
	  YYSIZE_T yysize = 0;
	  char *yymsg;
	  int yyx, yycount;

	  yycount = 0;
	  /* Start YYX at -YYN if negative to avoid negative indexes in
	     YYCHECK.  */
	  for (yyx = yyn < 0 ? -yyn : 0;
	       yyx < (int) (sizeof (yytname) / sizeof (char *)); yyx++)
	    if (yycheck[yyx + yyn] == yyx)
	      yysize += yystrlen (yytname[yyx]) + 15, yycount++;
	  yysize += yystrlen ("parse error, unexpected ") + 1;
	  yysize += yystrlen (yytname[YYTRANSLATE (yychar)]);
	  yymsg = (char *) YYSTACK_ALLOC (yysize);
	  if (yymsg != 0)
	    {
	      char *yyp = yystpcpy (yymsg, "parse error, unexpected ");
	      yyp = yystpcpy (yyp, yytname[YYTRANSLATE (yychar)]);

	      if (yycount < 5)
		{
		  yycount = 0;
		  for (yyx = yyn < 0 ? -yyn : 0;
		       yyx < (int) (sizeof (yytname) / sizeof (char *));
		       yyx++)
		    if (yycheck[yyx + yyn] == yyx)
		      {
			const char *yyq = ! yycount ? ", expecting " : " or ";
			yyp = yystpcpy (yyp, yyq);
			yyp = yystpcpy (yyp, yytname[yyx]);
			yycount++;
		      }
		}
	      yyerror (yymsg);
	      YYSTACK_FREE (yymsg);
	    }
	  else
	    yyerror ("parse error; also virtual memory exhausted");
	}
      else
#endif /* defined (YYERROR_VERBOSE) */
	yyerror ("parse error");
    }
  goto yyerrlab1;


/*--------------------------------------------------.
| yyerrlab1 -- error raised explicitly by an action |
`--------------------------------------------------*/
yyerrlab1:
  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
	 error, discard it.  */

      /* return failure if at end of input */
      if (yychar == YYEOF)
	YYABORT;
      YYDPRINTF ((stderr, "Discarding token %d (%s).\n",
		  yychar, yytname[yychar1]));
      yychar = YYEMPTY;
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */

  yyerrstatus = 3;		/* Each real token shifted decrements this */

  goto yyerrhandle;


/*-------------------------------------------------------------------.
| yyerrdefault -- current state does not do anything special for the |
| error token.                                                       |
`-------------------------------------------------------------------*/
yyerrdefault:
#if 0
  /* This is wrong; only states that explicitly want error tokens
     should shift them.  */

  /* If its default is to accept any token, ok.  Otherwise pop it.  */
  yyn = yydefact[yystate];
  if (yyn)
    goto yydefault;
#endif


/*---------------------------------------------------------------.
| yyerrpop -- pop the current state because it cannot handle the |
| error token                                                    |
`---------------------------------------------------------------*/
yyerrpop:
  if (yyssp == yyss)
    YYABORT;
  yyvsp--;
  yystate = *--yyssp;
#if YYLSP_NEEDED
  yylsp--;
#endif

#if YYDEBUG
  if (yydebug)
    {
      short *yyssp1 = yyss - 1;
      YYFPRINTF (stderr, "Error: state stack now");
      while (yyssp1 != yyssp)
	YYFPRINTF (stderr, " %d", *++yyssp1);
      YYFPRINTF (stderr, "\n");
    }
#endif

/*--------------.
| yyerrhandle.  |
`--------------*/
yyerrhandle:
  yyn = yypact[yystate];
  if (yyn == YYFLAG)
    goto yyerrdefault;

  yyn += YYTERROR;
  if (yyn < 0 || yyn > YYLAST || yycheck[yyn] != YYTERROR)
    goto yyerrdefault;

  yyn = yytable[yyn];
  if (yyn < 0)
    {
      if (yyn == YYFLAG)
	goto yyerrpop;
      yyn = -yyn;
      goto yyreduce;
    }
  else if (yyn == 0)
    goto yyerrpop;

  if (yyn == YYFINAL)
    YYACCEPT;

  YYDPRINTF ((stderr, "Shifting error token, "));

  *++yyvsp = yylval;
#if YYLSP_NEEDED
  *++yylsp = yylloc;
#endif

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;

/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;

/*---------------------------------------------.
| yyoverflowab -- parser overflow comes here.  |
`---------------------------------------------*/
yyoverflowlab:
  yyerror ("parser stack overflow");
  yyresult = 2;
  /* Fall through.  */

yyreturn:
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
  return yyresult;
}
#line 402 "ibnl_parser.yy"


int yyerror(char *msg)
{
  printf("-E-ibnlParse:%s at line:%ld\n", msg, lineNum);
  ibnlErr = 1;
  return 1;
}

/* parse apollo route dump file */
int ibnlParseSysDefs (IBSystemsCollection *p_sysColl, const char *fileName) {
  extern FILE * yyin;
   
  gp_sysColl = p_sysColl;
  gp_fileName = fileName;

  /* open the file */
  yyin = fopen(fileName,"r");
  if (!yyin) {
	 printf("-E- Fail to Open File:%s\n", fileName);
	 return(1);
  }
  if (FabricUtilsVerboseLevel & FABU_LOG_VERBOSE) 
     printf("-I- Parsing:%s\n", fileName);

  ibnlErr = 0;
  lineNum = 1;
  /* parse it */
  yyparse();

  fclose(yyin);
  return(ibnlErr);
}


