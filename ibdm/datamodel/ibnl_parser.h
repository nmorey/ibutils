#ifndef BISON_Y_TAB_H
# define BISON_Y_TAB_H

#ifndef YYSTYPE
typedef union {
  IBNodeType tval;
  int        ival;
  char      *sval;
} yystype;
# define YYSTYPE yystype
# define YYSTYPE_IS_TRIVIAL 1
#endif
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


extern YYSTYPE yylval;

#endif /* not BISON_Y_TAB_H */
