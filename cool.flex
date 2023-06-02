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

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

/* CONSTS */

#define TRUE 1
#define FALSE 0

#define RED 31
#define GREEN 32
#define YELLOW 33
#define BLUE 34
#define MAGENTA 35
#define CYAN 36
#define WHITE 37
#define RESET 0


/* HELPERS */

#define SET_ERROR_MSG(X) (cool_yylval.error_msg = X)

#define SET_SYMBOL(X) (cool_yylval.symbol = X)

#define ADD_STRING_1(TABLE, STR) (TABLE.add_string(STR))

#define ADD_STRING_2(TABLE, STR, LEN) (TABLE.add_string(STR, LEN))

#define GET_3D_MACRO(TABLE, STR, LEN, NAME, ...) NAME

#define ADD_STRING__GET_ELEM(...) GET_3D_MACRO(__VA_ARGS__, ADD_STRING_2, ADD_STRING_1)(__VA_ARGS__)

/* DEFINICOES DE STRING */

#define APPEND_STRING_BUF_2(_1, _2) {\
  if (append_string_buf(_1, _2) == -1) {\
    string_buf_overflow_flag = TRUE;\
  }\
}

#define APPEND_STRING_BUF_1(_1) {\
  if (append_string_buf(_1) == -1) {\
    string_buf_overflow_flag = TRUE;\
  }\
}

#define GET_MACRO(_1, _2, NAME, ...) NAME

#define APPEND_STRING_BUF(...) GET_MACRO(__VA_ARGS__, APPEND_STRING_BUF_2, APPEND_STRING_BUF_1)(__VA_ARGS__)

#define ERROR_ON_STRING(MSG) {\
  BEGIN(INITIAL);\
  if (!string_invalid_char_flag) {\
    SET_ERROR_MSG(MSG);\
    return (ERROR);\
  }\
}

/* PROFUNDIDADE DO COMENTARIO */

int comment_depth = 0;

char string_buf_overflow_flag = FALSE;

char string_invalid_char_flag = FALSE;

void init_string_buf();

int append_string_buf(std::string str);

int append_string_buf(std::string str, int length);

// #define VERBOSE

void verbose();

void print(std::string str);

std::string coloring(std::string str, int color);

/* def: Debug Purpose   (End) */

%}

%option noyywrap

%x COMMENT
%x STRING

/*
 * Define names for regular expressions here.
 */

/* DEFINIÇÃO DE ALGUNS PSEUDONIMOS */

BR (\n)
CR (\r)

TRUE (t(?i:rue))
FALSE (f(?i:alse))

OPS  ("("|")"|"*"|"+"|","|"-"|"."|"/"|":"|";"|"<"|"="|"@"|"{"|"}"|"~")
WS (" "|"\f"|"\r"|"\t"|"\v")

DIGIT ([0-9])
UPPER_ALPHA ([A-Z])
LOWER_ALPHA ([a-z])

LETTER  ({UPPER_ALPHA}|{LOWER_ALPHA})
ID      ({LETTER}|{DIGIT}|_)
NEWLINE ({BR})

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
BOOL_CONST  ({TRUE}|{FALSE})
TYPEID      ({UPPER_ALPHA}{ID}*)
OBJECTID    ({LOWER_ALPHA}{ID}*)
ASSIGN      ("<-")
NOT         (?i:not)
LE          ("<=")

/* DELIMITADORES */

COM_BEGIN ("(*")
COM_END   ("*)")

LINE_COM_BEGIN  ("--")

STR_DELIM     ("\"")

/* FAZ MATCH COM QUALQUER COISA RESTANTE */

ANY (.)

%%

 /*
  * (A < ASD
  */

{COM_BEGIN} {
  /* Começar comentario */
  comment_depth++;
  BEGIN(COMMENT);
}

<COMMENT>{COM_BEGIN} {
  /* comentario aninhado  */
  comment_depth++;
}

{COM_END} { 
  /* Fim de comentario sem par */
  SET_ERROR_MSG("Unmatched *)");
  return (ERROR);
}

<COMMENT>{COM_END} { 
  /* Fim de comentario */
  comment_depth--;

  if(comment_depth == 0) {
    BEGIN(INITIAL);
  }
}

<COMMENT><<EOF>> {
  /* Fim de arquivo sem fechar comentario */
  
  BEGIN(INITIAL); // Don't end lexer with comment block!
  SET_ERROR_MSG("EOF in comment");
  return (ERROR);
}

<COMMENT>{NEWLINE} {
  /* LINE FEED */
  curr_lineno++;
}

<COMMENT>{ANY} {
  /* comentario bloco */

  // Comentario de bloco
}

{LINE_COM_BEGIN}{ANY}* {
  /* Linha comentada */
  
  // linha comentada
}

{STR_DELIM} { 
  BEGIN(STRING);
  init_string_buf();
}

<STRING>{STR_DELIM} {
  BEGIN(INITIAL);

  if(string_buf_overflow_flag){
    SET_ERROR_MSG("String constant too long");

    return (ERROR);
  } else if (string_invalid_char_flag){

  } else {
    SET_SYMBOL(ADD_STRING__GET_ELEM(stringtable, string_buf));
    return (STR_CONST);
  }
}

<STRING><<EOF>> {
  ERROR_ON_STRING("EOF in string constant");
}

<STRING>\0 {
  SET_ERROR_MSG("String contains invalid character");
  
  string_invalid_char_flag = TRUE;

  return (ERROR);
}

<STRING>{NEWLINE}	{
  ++curr_lineno;
  ERROR_ON_STRING("Unterminated string constant");
}

<STRING>\\[^\0]	{
  char matched = yytext[1];
  char text = matched;

  if (matched == 'b') {
    text = '\b';
  } else if (matched == 't') {
    text = '\t';
  } else if (matched == 'n') {
    text = '\n';
  } else if (matched == 'f') {
    text = '\f';
  } else if (matched == '\n') {
    ++curr_lineno;
  }

  APPEND_STRING_BUF(&text, 1);
}

<STRING>. {
  APPEND_STRING_BUF(yytext);
}

 /* ACTIONS PARA TOKENS */

{CLASS} {
  return (CLASS);
}

{ELSE} {
  return (ELSE);
}

{FI} {
  return (FI);
}

{IF} {
  return (IF);
}

{IN} {
  return (IN);
}

{INHERITS} {
  return (INHERITS);
}

{LET} {
  return (LET);
}

{LOOP} {
  return (LOOP);
}

{POOL} {
  return (POOL);
}

{THEN} {
  return (THEN);
}

{WHILE} {
  return (WHILE);
}

{CASE} {
  return (CASE);
}

{ESAC} {
  return (ESAC);
}

{OF} {
  return (OF);
}

{NEW} {
  return (NEW);
}

{ISVOID} {
  return (ISVOID);
}

{TRUE} { 
  cool_yylval.boolean = true;
  return (BOOL_CONST);
}

{FALSE} {
  cool_yylval.boolean = false;
  return (BOOL_CONST);
}

{NOT} {
  return (NOT);
}

 /* nova linha */

{NEWLINE} {
  ++curr_lineno;
}

{WS} {
   
}

 /* OBTEM OPERADORES DE MANEIRA GENERICA */

{OPS} {
  return (yytext[0]);
}

 /* OPERADORES DE MAIS DE 1 CARACTER */

{DARROW} {
  return (DARROW);
}

{ASSIGN} {
  return (ASSIGN);
}

{LE} {
  return (LE);
}

 /* def: Symbols (Begin) */

{INT_CONST} {
  SET_SYMBOL(ADD_STRING__GET_ELEM(inttable, yytext, yyleng));
  return (INT_CONST);
}

{TYPEID} {
  SET_SYMBOL(ADD_STRING__GET_ELEM(idtable, yytext, yyleng));
  return (TYPEID);
}

{OBJECTID} {
  SET_SYMBOL(ADD_STRING__GET_ELEM(idtable, yytext, yyleng));
  return (OBJECTID);
}

 /* EXCECAO */

{ANY} {
  SET_ERROR_MSG(yytext);
  return (ERROR);    
}


%%

/* def: String (Begin) */

void init_string_buf() {
  string_buf[0] = '\0';
  string_buf_ptr = string_buf;
  string_buf_overflow_flag = FALSE;
  string_invalid_char_flag = FALSE;
}

int append_string_buf(std::string str) {
  return append_string_buf(str, str.length());
}

int append_string_buf(std::string str, int length) {
  int result_length = strlen(string_buf) + length;

  if (result_length >= MAX_STR_CONST) {
    return -1;  
  }

  strncat(string_buf, str.c_str(), length);

  print("Current string_buf       : " + std::string(string_buf));
  print("Current string_buf length: " + std::to_string(result_length));

  return result_length;
}

/* def: String   (End) */


/* def: Debug Purpose (Begin) */

void verbose() {
#ifdef VERBOSE
  std::cout << coloring("[*] DEBUG", RED) << std::endl;
  std::cout << coloring("    - Input (yytext):  ", MAGENTA) << yytext << std::endl;
  std::cout << coloring("    - Length (yyleng): ", MAGENTA) << yyleng << std::endl;
  std::cout << coloring("    - Comment Depth:   ", MAGENTA) << comment_depth << std::endl;
#endif
}

void print(std::string str) {
#ifdef VERBOSE
  std::cout << coloring("[*] OUT: ", YELLOW) << str << std::endl;
#endif
}

std::string coloring(std::string str, int color) {
  return "\x1b[" + std::to_string(color) + "m" + str + "\x1b[" + std::to_string(RESET) + "m";
}

/* def: Debug Purpose   (End) */