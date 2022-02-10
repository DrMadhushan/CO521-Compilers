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

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
    if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
        YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

int str_len;
bool isMaxLenExceed() {
    return str_len >= 1024;
}

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */ 

%}

/*
 * Define names for regular expressions here.
 */

%x STRING
%x INVALID_STRING
%x COMMENT

TRUE        t[rR][uU][eE]
FALSE       f[aA][lL][sS][eE]

CLASS   [Cc][lL][aA][sS][sS]
ELSE    [eE][lL][sS][eE]
FI      [fF][iI]
IF      [iI][fF]
IN      [iI][nN]
INHERITS [iI][nN][hH][eE][rR][iI][tT][sS]
LET     [lL][eE][tT]
LOOP    [lL][oO][oO][pP]
POOL    [pP][oO][oO][lL]
THEN    [tT][hH][eE][nN]
WHILE   [wW][hH][iI][lL][eE]    
CASE    [cC][aA][sS][eE]
ESAC    [eE][sS][aA][cC]
OF      [oO][fF] 
NEW     [nN][eE][wW] 
ISVOID  [iI][sS][vV][oO][iI][dD]
NOT     [nN][oO][tT]

TYPEID      [A-Z][a-zA-Z0-9_]*
OBJECTID    [a-z][a-zA-Z0-9_]*

INT_CONST   [0-9]+
WHITESPACE  [\t\v\f\r ]+

DARROW  =>
ASSIGN  <-
LE      <=


%%
    /* Operators and other symbols */


{DARROW}        { return (DARROW);}
{ASSIGN}        { return ASSIGN;}
{LE}            { return LE;}


"("             { return '(';}
")"             { return ')';}
"."             { return '.';}
"@"             { return '@';}
"~"             { return '~';}
"*"             { return '*';}
"/"             { return '/';}
"+"             { return '+';}
"-"             { return '-';}
"<"             { return '<';}
"="             { return '=';}
"{"             { return '{';}
"}"             { return '}';}
":"             { return ':';}
","             { return ',';}
";"             { return ';';}

     /*
      * Keywords are case-insensitive except for the values true and false,
      * which must begin with a lower-case letter.
      */

{CLASS}         {return CLASS;}
{ELSE}          {return ELSE;}
{FI}            {return FI;}
{IF}            {return IF;}
{IN}            {return IN;}
{INHERITS}      {return INHERITS;}
{LET}           {return LET;}
{LOOP}          {return LOOP;}
{POOL}          {return POOL;}
{THEN}          {return THEN;}
{WHILE}         {return WHILE;}  
{CASE}          {return CASE;}
{ESAC}          {return ESAC;}
{OF}            {return OF;}
{NEW}           {return NEW;}
{ISVOID}        {return ISVOID;}
{NOT}           {return NOT;}
{TRUE}          {   
                    cool_yylval.boolean = true;
                    return BOOL_CONST;
                }
{FALSE}         {
                    cool_yylval.boolean = false;
                    return BOOL_CONST;
                }


    /* Identifiers and integers */

{INT_CONST}     {
                    cool_yylval.symbol = inttable.add_string(yytext);
                    return INT_CONST;
                }

{TYPEID}        {
                    cool_yylval.symbol = idtable.add_string(yytext);
                    return TYPEID;
                }
{OBJECTID}      {
                    cool_yylval.symbol = idtable.add_string(yytext);
                    return OBJECTID;
                }

     /*
      *  String constants (C syntax)
      *  Escape sequence \c is accepted for all characters c. Except for
      *  \n \t \b \f, the result is c.
      *
      */


    /* Start reading string */
\"  {
    BEGIN(STRING);
    str_len = 0;
    string_buf_ptr = string_buf;
}

    /* Terminate string reading */
<STRING>\" {
    BEGIN(INITIAL);
    *string_buf_ptr = '\0';
    cool_yylval.symbol = stringtable.add_string(string_buf);
    return STR_CONST;
}

    /* String can't have unescaped new line --> the programmer missed the ending " */
<STRING>\n  {
    cool_yylval.error_msg = "Unterminated string constant";
    BEGIN(INVALID_STRING);
    return ERROR;
}

    /* escaped newline is accepted */
<STRING>\\\n    { curr_lineno++; }

    /* String can't contain null character */
<STRING>\0 {
    cool_yylval.error_msg = "String contains null character";
    BEGIN(INVALID_STRING);
    return ERROR;
}

    /* EOF cannot occur in unterminated string */
<STRING><<EOF>> {
    cool_yylval.error_msg = "EOF in string constant";
    BEGIN(INVALID_STRING);
    return ERROR;
}

    /* user written escaped characters --> count them as single char and skip ahead */
<STRING>\\n |
<STRING>\\b |
<STRING>\\t |
<STRING>\\f {
    str_len ++;
    *string_buf_ptr++ = yytext[1];
}

    /* String length < 1024 in COOL */


    /* If error occurs (INVALID_STRING state) termination of a string happens with \" or unescaped \n */
<INVALID_STRING>(\"|\n) {BEGIN(INITIAL);}

    /* Comments */

--.*$ {}


    /*multiline comments*/
\*\) {
    cool_yylval.error_msg = "Unmatched *)";
    return ERROR;
}

\(\* {
    BEGIN(COMMENT);
}

<COMMENT><<EOF>> {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "EOF in comment";
    return ERROR;
}

<COMMENT>[^(\*\))] {
    if (yytext[0] == '\n') {
        curr_lineno++;
    }
}

<COMMENT>\*\) {
    BEGIN(INITIAL);
}

    /* Whitespace and leftovers */

{WHITESPACE}    ;
\n+             curr_lineno += yyleng;
.               {
                cool_yylval.error_msg = yytext;
                return ERROR;
}
%%