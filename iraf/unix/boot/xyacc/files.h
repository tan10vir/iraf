/* This file has the location of the parser, and the size of the progam
 * desired.  It may also contain definitions to override various defaults:
 * for example, WORD32 tells yacc that there are at least 32 bits per int
 * on some systems, notably IBM, the names for the output files and tempfiles
 * must also be changed.
 */

#ifndef WORD32
#define WORD32
#endif

#ifndef PREFIX
#define PREFIX ""
#endif

/* Location of the parser text file */
# define PARSER "base/yaccpar.x"
# define PARSER1 PREFIX "/iraf/iraf/" PARSER	/* [MACHDEP] */
# define PARSER2 "/usr/iraf/" PARSER		/* [MACHDEP] */

/* Basic size of the Yacc implementation */
# define HUGE
