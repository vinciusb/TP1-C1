/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <stdlib.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT assim podemos ler do arquivo FILE fin */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int comment_depth = 0;
int should_terminate = 0;
int in_nested_comment = 0;
int string_const_length = 0;

%}

%option noyywrap

%x NESTED_COM
%x SIMPLE_COM
%x STRING_CONST
%x ESCAPE

/* DEFINIÇÃO DE ALGUNS PSEUDONIMOS */

TRUE  (t)(?i:rue)
FALSE (f)(?i:alse)

DIGIT               [0-9]
UPPER_ALPHA         [A-Z]
LOWER_ALPHA         [a-z]

OPS                 ("+"|"-"|"*"|\/)
SINGLE_OP           ("~"|"<"|"="|"("|")"|"{"|"}"|";"|":"|"."|","|"@")
WS                  (" "|\f|\r|\t|\v)
LETTER              ({UPPER_ALPHA}|{LOWER_ALPHA})

/* DEFINIÇÃO DOS MEUS TOKENS */

LET         (?i:let)
LOOP        (?i:loop)
CLASS       (?i:class)
IF          (?i:if)
THEN        (?i:then)
ELSE        (?i:else)
FI          (?i:fi)
POOL        (?i:pool)
WHILE       (?i:while)
CASE        (?i:case)
ESAC        (?i:esac)
OF          (?i:of)
DARROW      ("=>")
NEW         (?i:new)
IN          (?i:in)
INHERITS    (?i:inherits)
ISVOID      (?i:isvoid)
INT_CONST   ({DIGIT}+)
TYPEID      ("SELF_TYPE"|{UPPER_ALPHA}({LETTER}|{DIGIT}|"_")*)
OBJECTID    ("self"|{LETTER}({LETTER}|{DIGIT}|"_")*)
ASSIGN      ("<-")
NOT         (?i:not)
LE          ("<=")

/* DELIMITADORES */

NESTED_COM_START   "\(\*"
NESTED_COM_END     "\*\)"
SIMP_COM_START     ("--")
SIMP_COM_END       ("--")
STR_CONST_START            \"
STR_CONST_END              \"

%%

 /* KEY TERMS */
  
{CLASS}     return (CLASS);
{ELSE}      return (ELSE);
{FI}        return (FI);
{IF}        return (IF);
{IN}        return (IN);
{INHERITS}  return (INHERITS);
{LET}       return (LET);
{LOOP}      return (LOOP);
{POOL}      return (POOL);
{THEN}      return (THEN);
{WHILE}     return (WHILE);
{CASE}      return (CASE);
{ESAC}      return (ESAC);
{OF}        return (OF);
{NEW}       return (NEW);
{ISVOID}    return (ISVOID);
{NOT}       return (NOT);
{DARROW}    return (DARROW);
{ASSIGN}	  return (ASSIGN);
{LE}		    return (LE);

 /* COMENTARIOS ANINHADOS */

{NESTED_COM_START} { comment_depth++; BEGIN(NESTED_COM); in_nested_comment = 1; }
<NESTED_COM>{NESTED_COM_START} { comment_depth++; }
<NESTED_COM>{NESTED_COM_END} {
  comment_depth--;

  if (comment_depth < 0) {
    cool_yylval.error_msg = "Unmatched *)";
	  return (ERROR);
  }

  if (comment_depth == 0) {
    in_nested_comment = 0;
    BEGIN(INITIAL);
  }
}
<NESTED_COM><<EOF>> {
    if (should_terminate)
      yyterminate();
      
    cool_yylval.error_msg = "EOF in comment";
    should_terminate = 1;
    return (ERROR);
}
<NESTED_COM>\n        { curr_lineno++; }
<NESTED_COM>.         {  }

{NESTED_COM_END} {
  if (!in_nested_comment) {
    cool_yylval.error_msg = "Unmatched *)";
	  return (ERROR);
  }
}

 /* COMENTARIO SIMPLES */

{SIMP_COM_START} { BEGIN(SIMPLE_COM); }
<SIMPLE_COM>\n        { curr_lineno++; BEGIN(INITIAL); }
<SIMPLE_COM>.         {  }


 /* TOKENS DE STRINGS */

{STR_CONST_START}  { BEGIN(STRING_CONST); }
<STRING_CONST>{STR_CONST_END} {
  string_buf_ptr = (char*) &string_buf;
  cool_yylval.symbol = idtable.add_string(string_buf_ptr, string_const_length);
  string_const_length = 0;
  BEGIN(INITIAL);
  return (STR_CONST);
}
<STRING_CONST><<EOF>> {
    if (should_terminate)
      yyterminate();
      
    cool_yylval.error_msg = "EOF in string constant";
    should_terminate = 1;
    return (ERROR);
}
<STRING_CONST>\0 {
  	cool_yylval.error_msg = "String contains null character";
    string_const_length = 0;
		BEGIN(ESCAPE);
		return ERROR;
}
<STRING_CONST>\n {
  	cool_yylval.error_msg = "Unterminated string constant";
    string_const_length = 0;
    curr_lineno++;
	  BEGIN(INITIAL);
		return ERROR;
}
<STRING_CONST>"\\n" {
    if (string_const_length + 1< MAX_STR_CONST) {
      string_buf[string_const_length++] = '\n'; 
    } 
    else {
      cool_yylval.error_msg = "String constant too long";
      string_const_length = 0;
      BEGIN(ESCAPE);
      return (ERROR); 
    }
}
<STRING_CONST>"\\t" {
    if (string_const_length + 1 < MAX_STR_CONST) {
      string_buf[string_const_length++] = '\t'; 
    } 
    else {
      cool_yylval.error_msg = "String constant too long";
      string_const_length = 0;
      BEGIN(ESCAPE);
      return (ERROR); 
    }
}
<STRING_CONST>"\\b" {
    if (string_const_length + 1 < MAX_STR_CONST) {
      string_buf[string_const_length++] = '\b'; 
    } 
    else {
      cool_yylval.error_msg = "String constant too long";
      string_const_length = 0;
      BEGIN(ESCAPE);
      return (ERROR); 
    }
}
<STRING_CONST>"\\f" {
    if (string_const_length + 1 < MAX_STR_CONST) {
      string_buf[string_const_length++] = '\f'; 
    } 
    else {
      cool_yylval.error_msg = "String constant too long";
      string_const_length = 0;
      BEGIN(ESCAPE);
      return (ERROR); 
    }
}
<STRING_CONST>"\\"[^\0] {
    if (string_const_length + 1 < MAX_STR_CONST) {
      string_buf[string_const_length++] = yytext[1]; 
    } 
    else {
      cool_yylval.error_msg = "String constant too long";
      string_const_length = 0;
      BEGIN(ESCAPE);
      return (ERROR); 
    }
}
<STRING_CONST>. {
    if (string_const_length + 1 < MAX_STR_CONST ) {
      string_buf[string_const_length++] = yytext[0];
    }
    else {
      cool_yylval.error_msg = "String constant too long";
        string_const_length = 0;

      BEGIN(ESCAPE);
      return (ERROR); 
    }
}

<ESCAPE>[\n|"]	 { BEGIN(INITIAL);  }
<ESCAPE>[^\n|"]	 { }


 /* TOKENS DE APENAS UM SIMBOLO */
  
{SINGLE_OP} { return (int)(yytext[0]); }
{OPS} { return (int)(yytext[0]); }

 /* CONSTANTE BOOLEANA */
{TRUE} {
	cool_yylval.boolean = true;
	return (BOOL_CONST);
}
{FALSE} {
	cool_yylval.boolean = false;
	return (BOOL_CONST);
}

 /* CONSTANTE DE INTEIRO */

{INT_CONST} {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (INT_CONST);
}

 /* TYPEID */

{TYPEID} {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (TYPEID);
}

{OBJECTID} {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (OBJECTID);
}

 /* VERIFICACAO DE NOVAS LINHAS */
\n	 { curr_lineno++; }
{WS}+ {}


 /* IDENTIFICACAO DE ERROS */
.		{
			cool_yylval.error_msg = yytext;
			return (ERROR);
		}

%%