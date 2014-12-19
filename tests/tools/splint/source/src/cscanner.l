/*;-*-C-*-; 
** Splint - annotation-assisted static program checker
** Copyright (C) 1994-2003 University of Virginia,
**         Massachusetts Institute of Technology
**
** This program is free software; you can redistribute it and/or modify it
** under the terms of the GNU General Public License as published by the
** Free Software Foundation; either version 2 of the License, or (at your
** option) any later version.
** 
** This program is distributed in the hope that it will be useful, but
** WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
** General Public License for more details.
** 
** The GNU General Public License is available from http://www.gnu.org/ or
** the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
** MA 02111-1307, USA.
**
** For information on splint: splint@cs.virginia.edu
** To report a bug: splint-bug@cs.virginia.edu
** For more information: http://www.splint.org
*/
/*
** cscanner.l
**
** Flex lexer for C.
** Based on a C lexer by Nate Osgood
**    from hacrat@catfish.lcs.mit.edu Mon Jun 14 13:06:32 1993
*/
/*
** Modified by Herbert 08/19/97:
** - added #include for IBM's OS/2 compiler.
** - fixed weird bug with lookup of tmp files (OS/2 and MSDOS only).
*/
/*
** Modified by Mike Smith 
** Corrected missing 'line' in scanf() calls in handleSpecial().
** Without this, I get an error when Splint hits a '#line' directive
** in the pre-pre-processed source files. For safety, I have made these
** conditional on OS2 and MSDOS because I don't understand why noone else
** has seen this problem.
**
** Modified by Mike Smith, 4th June 1997
** Finally resolved the #line problem.  The scanf() calls have been fixed to
** allow the following #line forms:-
**
**        #line 123 "filename"
**        #line 123
**        # 123 "filename"
**        # 123
**
** The last two are generated by the GNU pre-processor, apparently
*/

Digit			[0-9]
Letter			[a-zA-Z_$]
H			[a-fA-F0-9]
E			[Ee][+-]?{Digit}+
U                       (u|U)
L                       (l|L)
FS			(f|F|l|L)
IS			(u|U|l|L)*
ULSuffix                ({U}{L}|{L}{U})

%{
# include "splintMacros.nf"
# if defined(OS2) && defined(__IBMC__)
   /* needed for isatty()... */
# include <io.h>
# else

/*
** Win32 doesn't have unistd.h
*/

# ifndef WIN32
# include <unistd.h>
# endif

# endif

# include "basic.h"

# include "cscannerHelp.h"
# include "cgrammar.h"
# include "cgrammar_tokens.h"
# include "osd.h"

/*@notfunction@*/
# define yyinput() (incColumn (), getc (yyin))

# include "flex.head"

%}

%%

"/*"		{ llfatalerror (cstring_makeLiteral ("Comment in pre-processor output")); }

"#"{Letter}({Letter}|{Digit})*  {  
                 context_saveLocation (); 
                 cscannerHelp_setTokLength (longUnsigned_toInt (mstring_length (yytext))); 

                 if (cscannerHelp_processHashIdentifier 
		     (cscannerHelp_makeIdentifier (yytext + 1)))
                   {
		     return cscannerHelp_returnString (cstring_makeLiteral ("\"\""));
		   }
                 else
                   { 
		     if (cscannerHelp_handleSpecial (yytext)) 
                       { 
			 cscannerHelp_setTokLength (1); 
			 return cscannerHelp_returnToken (0); 
		       }
		   }
                } 
"#"             { if (cscannerHelp_handleSpecial (yytext)) 
                    { 
                       cscannerHelp_setTokLength (1); return cscannerHelp_returnToken (0); 
                     }
                }
"..."           { cscannerHelp_setTokLength (3); return cscannerHelp_returnToken (CTOK_ELIPSIS); }
"break"		{ cscannerHelp_setTokLength (5); return cscannerHelp_returnToken (BREAK); }
"case"		{ cscannerHelp_setTokLength (4); return cscannerHelp_returnToken (CASE); }
"continue"	{ cscannerHelp_setTokLength (8); return cscannerHelp_returnToken (CONTINUE); }
"default"	{ cscannerHelp_setTokLength (7); return cscannerHelp_returnToken (DEFAULT); }
"do"		{ cscannerHelp_setTokLength (2); return cscannerHelp_returnToken (DO); }
"else"		{ cscannerHelp_setTokLength (4); return cscannerHelp_returnToken (CELSE); }
"for"		{ cscannerHelp_setTokLength (3); return cscannerHelp_returnToken (CFOR); }
"goto"		{ cscannerHelp_setTokLength (4); return cscannerHelp_returnToken (GOTO); }
"if"		{ cscannerHelp_setTokLength (2); return cscannerHelp_returnToken (CIF); }
"return"	{ cscannerHelp_setTokLength (6); return cscannerHelp_returnToken (RETURN); }
"sizeof"	{ cscannerHelp_setTokLength (6); return cscannerHelp_returnToken (CSIZEOF); }
"offsetof"	{ cscannerHelp_setTokLength (8); return cscannerHelp_returnToken (COFFSETOF); }
"switch"	{ cscannerHelp_setTokLength (6); return cscannerHelp_returnToken (SWITCH); }
"while"		{ cscannerHelp_setTokLength (5); return cscannerHelp_returnToken (WHILE); }
"va_arg"        { cscannerHelp_setTokLength (6); return cscannerHelp_returnToken (VA_ARG); }   
"va_dcl"        { cscannerHelp_setTokLength (6); return cscannerHelp_returnToken (VA_DCL); }   
"inline"        { 
                  /* gcc extension...this might not be appropriate */
                  cscannerHelp_setTokLength (6); return cscannerHelp_returnToken (QINLINE); }

"struct"        { cscannerHelp_setTokLength (6); return cscannerHelp_returnToken (CSTRUCT); }  
"typedef"       { cscannerHelp_setTokLength (7); return cscannerHelp_returnToken (CTYPEDEF); }

"union"         { cscannerHelp_setTokLength (5); return cscannerHelp_returnToken (CUNION); }
"enum"          { cscannerHelp_setTokLength (4); return cscannerHelp_returnToken (CENUM); }

"void"		{ cscannerHelp_setTokLength (4); return cscannerHelp_returnType (CVOID, ctype_void); }
"int"		{ cscannerHelp_setTokLength (3); return cscannerHelp_returnType (CINT, ctype_int); }
"double"	{ cscannerHelp_setTokLength (6); return cscannerHelp_returnType (CDOUBLE, ctype_double); }
"char"		{ cscannerHelp_setTokLength (4); return cscannerHelp_returnType (CGCHAR, ctype_char); }
"float"		{ cscannerHelp_setTokLength (5); return cscannerHelp_returnType (CGFLOAT, ctype_float); }

"long"		{ cscannerHelp_setTokLength (4); return cscannerHelp_returnToken (QLONG); }
"short"		{ cscannerHelp_setTokLength (5); return cscannerHelp_returnToken (QSHORT); }
"unsigned"	{ cscannerHelp_setTokLength (8); return cscannerHelp_returnToken (QUNSIGNED); }
"signed"	{ cscannerHelp_setTokLength (6); return cscannerHelp_returnToken (QSIGNED); }

"volatile"	{ cscannerHelp_setTokLength (8); return cscannerHelp_returnToken (QVOLATILE); }
"const"		{ cscannerHelp_setTokLength (5); return cscannerHelp_returnToken (QCONST); }
"restrict"	{ cscannerHelp_setTokLength (8); return cscannerHelp_returnToken (QRESTRICT); }

                        /* some systems expect this! [gack!] */ 
"__const"	{ cscannerHelp_setTokLength (7); return cscannerHelp_returnToken (QCONST); }

"extern"	{ cscannerHelp_setTokLength (6); return cscannerHelp_returnToken (QEXTERN); }
"auto"		{ cscannerHelp_setTokLength (4); return cscannerHelp_returnToken (QAUTO); }
"register"	{ cscannerHelp_setTokLength (8); return cscannerHelp_returnToken (QREGISTER); }
"static"	{ cscannerHelp_setTokLength (6); return cscannerHelp_returnToken (QSTATIC); }

\"(\\.|[^\\"])*\"([ \t\n]*\"(\\.|[^\\"])*\")* { return cscannerHelp_returnExpr (cscannerHelp_processString ()); }
L\"(\\.|[^\\"])*\"([ \t\n]*\"(\\.|[^\\"])*\")* { return cscannerHelp_returnExpr (cscannerHelp_processWideString ()); }
"out"                   { return (cscannerHelp_processSpec (QOUT)); }
"in"                    { return (cscannerHelp_processSpec (QIN)); }
"partial"               { return (cscannerHelp_processSpec (QPARTIAL)); }
"special"               { return (cscannerHelp_processSpec (QSPECIAL)); }
"anytype"               { return (cscannerHelp_processSpec (QANYTYPE)); }
"integraltype"          { return (cscannerHelp_processSpec (QINTEGRALTYPE)); }
"unsignedintegraltype"  { return (cscannerHelp_processSpec (QUNSIGNEDINTEGRALTYPE)); }
"signedintegraltype"    { return (cscannerHelp_processSpec (QSIGNEDINTEGRALTYPE)); }
"keep"                  { return (cscannerHelp_processSpec (QKEEP)); }
"null"                  { return (cscannerHelp_processSpec (QNULL)); } 
"notnull"               { return (cscannerHelp_processSpec (QNOTNULL)); } 
"isnull"                { return (cscannerHelp_processSpec (QISNULL)); } 
"truenull"              { return (cscannerHelp_processSpec (QTRUENULL)); } 
"falsenull"             { return (cscannerHelp_processSpec (QFALSENULL)); } 
"nullwhentrue"          { return (cscannerHelp_processSpec (QTRUENULL)); } 
"nullwhenfalse"         { return (cscannerHelp_processSpec (QFALSENULL)); } 
"relnull"               { return (cscannerHelp_processSpec (QRELNULL)); }
"reldef"                { return (cscannerHelp_processSpec (QRELDEF)); }
"exposed"               { return (cscannerHelp_processSpec (QEXPOSED)); }
"newref"                { return (cscannerHelp_processSpec (QNEWREF)); }
"tempref"               { return (cscannerHelp_processSpec (QTEMPREF)); }
"killref"               { return (cscannerHelp_processSpec (QKILLREF)); }
"refcounted"            { return (cscannerHelp_processSpec (QREFCOUNTED)); }
"checked"               { return (cscannerHelp_processSpec (QCHECKED)); }
"checkmod"              { return (cscannerHelp_processSpec (QCHECKMOD)); }
"checkedstrict"         { return (cscannerHelp_processSpec (QCHECKEDSTRICT)); }
"unchecked"             { return (cscannerHelp_processSpec (QUNCHECKED)); }
"only"                  { return (cscannerHelp_processSpec (QONLY)); }
"owned"                 { return (cscannerHelp_processSpec (QOWNED)); }
"observer"              { return (cscannerHelp_processSpec (QOBSERVER)); }
"dependent"             { return (cscannerHelp_processSpec (QDEPENDENT)); }
"unused"                { return (cscannerHelp_processSpec (QUNUSED)); }
"external"              { return (cscannerHelp_processSpec (QEXTERNAL)); }
"sef"                   { return (cscannerHelp_processSpec (QSEF)); }
"shared"                { return (cscannerHelp_processSpec (QSHARED)); }
"yield"                 { return (cscannerHelp_processSpec (QYIELD)); }
"undef"                 { return (cscannerHelp_processSpec (QUNDEF)); }
"killed"                { return (cscannerHelp_processSpec (QKILLED)); }
"nullterminated"        { return (cscannerHelp_processSpec (QNULLTERMINATED));}
"MaxSet"                { return (cscannerHelp_processSpec (QMAXSET));}
"MaxRead"               { return (cscannerHelp_processSpec (QMAXREAD));}
"maxSet"                { return (cscannerHelp_processSpec (QMAXSET));}
"maxRead"               { return (cscannerHelp_processSpec (QMAXREAD));}

{Letter}({Letter}|{Digit})* { int tok = cscannerHelp_processTextIdentifier (yytext);
                              if (tok != BADTOK)
				{
				  return (tok);
				}
			    }
0[xX]{H}+	        { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
                          return cscannerHelp_returnInt (ctype_int, cscannerHelp_processHex ());  /* evs 2000-05-17 was ctype_uint */
			}
0[xX]{H}+{L}	        { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
			  return cscannerHelp_returnInt (ctype_lint, cscannerHelp_processHex ()); }
0[xX]{H}+{L}{L}	        { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
			  return cscannerHelp_returnInt (ctype_llint, cscannerHelp_processHex ()); }
0[xX]{H}+{U}	        { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
                          return cscannerHelp_returnInt (ctype_uint, cscannerHelp_processHex ()); }
0[xX]{H}+{ULSuffix}     { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
			  return cscannerHelp_returnInt (ctype_ulint, cscannerHelp_processHex ()); }
0[xX]{H}+{U}{L}{L}      { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
			  return cscannerHelp_returnInt (ctype_ullint, cscannerHelp_processHex ()); }
0[xX]{H}+{L}{L}{U}      { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
			  return cscannerHelp_returnInt (ctype_ullint, cscannerHelp_processHex ()); }
0{Digit}+	        { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
			  return cscannerHelp_returnInt (ctype_int, cscannerHelp_processOctal ()); } 
0{Digit}+{U}	        { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
		 	  return cscannerHelp_returnInt (ctype_uint, cscannerHelp_processOctal ()); } 
0{Digit}+{L}	        { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
 		          return cscannerHelp_returnInt (ctype_lint, cscannerHelp_processOctal ()); } 
0{Digit}+{L}{L}	        { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
 		          return cscannerHelp_returnInt (ctype_llint, cscannerHelp_processOctal ()); } 
0{Digit}+{ULSuffix}     { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
	   	          return cscannerHelp_returnInt (ctype_ulint, cscannerHelp_processOctal ()); } 
0{Digit}+{U}{L}{L}      { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
	   	          return cscannerHelp_returnInt (ctype_ullint, cscannerHelp_processOctal ()); } 
0{Digit}+{L}{L}{U}      { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
	   	          return cscannerHelp_returnInt (ctype_ullint, cscannerHelp_processOctal ()); } 
{Digit}+	       { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
		         return cscannerHelp_returnInt (ctype_int, cscannerHelp_processDec ()); } 
{Digit}+{U}	       { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
		         return cscannerHelp_returnInt (ctype_uint, cscannerHelp_processDec ()); } 
{Digit}+{L}	       { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
	      	         return cscannerHelp_returnInt (ctype_lint, cscannerHelp_processDec ()); } 
{Digit}+{L}{L}	       { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
	      	         return cscannerHelp_returnInt (ctype_llint, cscannerHelp_processDec ()); } 
{Digit}+{ULSuffix}     { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
	    	         return cscannerHelp_returnInt (ctype_ulint, cscannerHelp_processDec ()); } 
{Digit}+{U}{L}{L}      { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
	    	         return cscannerHelp_returnInt (ctype_ullint, cscannerHelp_processDec ()); } 
{Digit}+{L}{L}{U}      { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
	    	         return cscannerHelp_returnInt (ctype_ullint, cscannerHelp_processDec ()); } 
'(\\.|[^\\'])+'	       { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
                         return cscannerHelp_returnChar (cscannerHelp_processChar ()); }
L'(\\.|[^\\'])+'       { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
                         return cscannerHelp_returnChar (cscannerHelp_processChar ()); }
{Digit}+{E}[fF]        { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
			 return cscannerHelp_returnFloat (ctype_float, cscannerHelp_processFloat ()); }
{Digit}+{E}[lL]        { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
			 return cscannerHelp_returnFloat (ctype_ldouble, cscannerHelp_processFloat ()); }
{Digit}+{E}            { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
			 return cscannerHelp_returnFloat (ctype_double, cscannerHelp_processFloat ()); }

{Digit}*"."{Digit}+({E})?[fF] { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
				return cscannerHelp_returnFloat (ctype_float, cscannerHelp_processFloat ()); }
{Digit}*"."{Digit}+({E})?[lL] { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
				return cscannerHelp_returnFloat (ctype_ldouble, cscannerHelp_processFloat ()); }
{Digit}*"."{Digit}+({E})?     { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
				return cscannerHelp_returnFloat (ctype_double, cscannerHelp_processFloat ()); }

{Digit}+"."{Digit}*({E})?[fF]   { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
				  return cscannerHelp_returnFloat (ctype_float, cscannerHelp_processFloat ()); }
{Digit}+"."{Digit}*({E})?[lL]   { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
				  return cscannerHelp_returnFloat (ctype_ldouble, cscannerHelp_processFloat ()); }
{Digit}+"."{Digit}*({E})?       { cscannerHelp_setTokLengthT (mstring_length (yytext)); 
				  return cscannerHelp_returnFloat (ctype_double, cscannerHelp_processFloat ()); }

">>="		{ return cscannerHelp_returnTokenLength (RIGHT_ASSIGN, 3); }
"<<="		{ return cscannerHelp_returnTokenLength (LEFT_ASSIGN, 3); }
"+="		{ return cscannerHelp_returnTokenLength (ADD_ASSIGN, 2); }
"-="		{ return cscannerHelp_returnTokenLength (SUB_ASSIGN, 2); }
"*="		{ return cscannerHelp_returnTokenLength (MUL_ASSIGN, 2); }
"/="		{ return cscannerHelp_returnTokenLength (DIV_ASSIGN, 2); }
"%="		{ return cscannerHelp_returnTokenLength (MOD_ASSIGN, 2); }
"&="		{ return cscannerHelp_returnTokenLength (AND_ASSIGN, 2); }
"^="		{ return cscannerHelp_returnTokenLength (XOR_ASSIGN, 2); }
"|="		{ return cscannerHelp_returnTokenLength (OR_ASSIGN, 2); }
">>"		{ return cscannerHelp_returnTokenLength (RIGHT_OP, 2); }
"<<"		{ return cscannerHelp_returnTokenLength (LEFT_OP, 2); }
"++"		{ return cscannerHelp_returnTokenLength (INC_OP, 2); }
"--"		{ return cscannerHelp_returnTokenLength (DEC_OP, 2); }
"->"		{ return cscannerHelp_returnTokenLength (ARROW_OP, 2); }
"&&"		{ return cscannerHelp_returnTokenLength (AND_OP, 2); }
"||"		{ return cscannerHelp_returnTokenLength (OR_OP, 2); }
"/\\"		{ return cscannerHelp_returnTokenLength (TCAND, 2); }
"<="		{ return cscannerHelp_returnTokenLength (LE_OP, 2); }
">="		{ return cscannerHelp_returnTokenLength (GE_OP, 2); }
"=="		{ return cscannerHelp_returnTokenLength (EQ_OP, 2); }
"!="		{ return cscannerHelp_returnTokenLength (NE_OP, 2); }
";"		{ return cscannerHelp_returnTokenLength (TSEMI, 1); }
"{"		{ return cscannerHelp_returnTokenLength (TLBRACE, 1); }
"}"		{ return cscannerHelp_returnTokenLength (TRBRACE, 1); }
","		{ return cscannerHelp_returnTokenLength (TCOMMA, 1); }
":"		{ return cscannerHelp_returnTokenLength (TCOLON, 1); }
"="		{ return cscannerHelp_returnTokenLength (TASSIGN, 1); }
"("		{ return cscannerHelp_returnTokenLength (TLPAREN, 1); }
")"		{ return cscannerHelp_returnTokenLength (TRPAREN, 1); }
"["		{ return cscannerHelp_returnTokenLength (TLSQBR, 1); }
"]"		{ return cscannerHelp_returnTokenLength (TRSQBR, 1); }
"."		{ return cscannerHelp_returnTokenLength (TDOT, 1); }
"&"		{ return cscannerHelp_returnTokenLength (TAMPERSAND, 1); }
"!"		{ return cscannerHelp_returnTokenLength (TEXCL, 1); }
"~"		{ return cscannerHelp_returnTokenLength (TTILDE, 1); }
"-"		{ return cscannerHelp_returnTokenLength (TMINUS, 1); }
"+"		{ return cscannerHelp_returnTokenLength (TPLUS, 1); }
"*"		{ return cscannerHelp_returnTokenLength (TMULT, 1); }
"/"		{ return cscannerHelp_returnTokenLength (TDIV, 1); }
"%"		{ return cscannerHelp_returnTokenLength (TPERCENT, 1); }
"<"		{ return cscannerHelp_returnTokenLength (TLT, 1); }
">"		{ return cscannerHelp_returnTokenLength (TGT, 1); }
"^"		{ return cscannerHelp_returnTokenLength (TCIRC, 1); }
"|"		{ return cscannerHelp_returnTokenLength (TBAR, 1); }
"?"		{ return cscannerHelp_returnTokenLength (TQUEST, 1); }

[ \t\v\f]	{ incColumn (); }
\n              { int tok = cscannerHelp_handleNewLine (); 
                  if (tok != BADTOK) return tok; }
"@@MR@@"        { cscannerHelp_setTokLength (6); 
		  
		  if (cscannerHelp_processMacro ()) {
		    if (context_inIterDef ()) 
		      { 
			return cscannerHelp_returnToken (LLMACROITER); 
		      }
		    if (context_inIterEnd ())
		      {
			return cscannerHelp_returnToken (LLMACROEND); 
		      }
		    if (context_inMacro ())
		      {
			return cscannerHelp_returnToken (LLMACRO); 
		      }
		  }
		}
"@QLMR"         { if (context_inHeader () || context_inFunction ())
		    { 
		      cscannerHelp_handleMacro ();
		    }
                  else
		    {
		      int nspchar = cscannerHelp_ninput ();
		      int nspaces;

		      /* 
		      ** This is a hack to get the column number correct.
		      */

		      llassert (nspchar >= '0' && nspchar <= '9');
		      
		      nspaces = nspchar - '0';

		      cscannerHelp_setTokLength (5 + nspaces); 
		      
		      if (cscannerHelp_processMacro ()) 
			{
			  DPRINTF (("Here we are: %s", context_unparse ()));
			  
			  if (context_inIterDef ()) 
			    {
			      return cscannerHelp_returnToken (LLMACROITER); 
			    }
			  if (context_inIterEnd ())
			    {
			      return cscannerHelp_returnToken (LLMACROEND); 
			    }
			  if (context_inMacro ())
			    { 
			      return cscannerHelp_returnToken (LLMACRO); 
			    }
			}
		    }
		}
"@.CT"          { cscannerHelp_setTokLength (4); lldiagmsg (ctype_unparseTable ()); }
"@.FA"          { cscannerHelp_setTokLength (4); lldiagmsg (message ("Access types: %q", typeIdSet_unparse (context_fileAccessTypes ()))); }
"@.F"           { cscannerHelp_setTokLength (3); 
		  lldiagmsg (message ("%q: *** marker ***", fileloc_unparse (g_currentloc)));
		}
"@.L"           { cscannerHelp_setTokLength (3); usymtab_printLocal (); }
"@.A"           { cscannerHelp_setTokLength (3); lldiagmsg (usymtab_unparseAliases ()); }
"@.C"           { cscannerHelp_setTokLength (3); lldiagmsg (context_unparse ()); }
"@.W"           { cscannerHelp_setTokLength (3); lldiagmsg (context_unparseClauses ()); }
"@.G"           { cscannerHelp_setTokLength (3); usymtab_printGuards (); }
"@.S"           { cscannerHelp_setTokLength (3); usymtab_printOut (); }
"@.X"           { cscannerHelp_setTokLength (3); usymtab_printAll (); }
"@.Z"           { cscannerHelp_setTokLength (3); usymtab_printComplete (); }
"@.T"           { cscannerHelp_setTokLength (3); usymtab_printTypes (); }
"@.K"           { cscannerHelp_setTokLength (3); lldiagmsg (usymtab_unparseStack ()); }
"@.R"           { cscannerHelp_setTokLength (3); return cscannerHelp_returnToken (QDREVEALSTATE); }
"@.M"           { cscannerHelp_setTokLength (3); 
		  lldiagmsg (message ("Can modify: %q", 
				  sRefSet_unparse (context_modList ()))); 
		}
"%{"            { /* BEFORE_COMMENT_MARKER */
                  int tok; 
		  incColumn (); incColumn ();
		  tok = cscannerHelp_handleLlSpecial (); 

		  if (tok != BADTOK)
		    {
		      if (tok == CANNOTATION) {
			return (tok);
		      } else {
			/* Beware - this bashes yylval! */
			return cscannerHelp_returnToken (tok); 
		      }
		    }
		}
"%}"            { /* AFTER_COMMENT_MARKER */ 
                  cscannerHelp_setTokLength (2);
		  cscannerHelp_exitSpecPart ();
		  return cscannerHelp_returnToken (QENDMACRO); }
"\\"            { incColumn (); cscannerHelp_setContinueLine (); }
.		{ incColumn (); 
                  if ((int) *yytext == 13 ) {
		     ;
                  } else {
		    voptgenerror
		      (FLG_SYNTAX, 
		       message ("Invalid character (ascii: %d), skipping character",
				(int)(*yytext)),
		       g_currentloc);
		  }
		}
%%

/*
** These need to go here, after flex-generated code defined input and unput.
*/

int cscanner_input (void)
{
  return input (); /* input is a static procedure defined by flex-generated code */
}

void cscanner_unput (int c)
{
  unput (c); /* unput is a static procedure defined by flex-generated code */
}


