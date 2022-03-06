/*
 *  The scanner definition for COOL.
 *  -------------------------------
 *  Group 01
 *  E/17/194 Madhushan R.
 *  E/17/338 Srimal R.M.L.C.
 *  -------------------------------
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
#include <string.h>

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
int comment_level;  /* to handle nested comments */

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
"%"             { return '%';}

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
    memset(string_buf, 0,sizeof string_buf);
    string_buf_ptr = string_buf;
}

    /* VALID Terminate string reading */
<STRING>\" {
    BEGIN(INITIAL);
    cool_yylval.symbol = stringtable.add_string(string_buf);
    *string_buf_ptr = '\0';
    return STR_CONST;
}

    /* String can't have unescaped new line --> the programmer missed the ending " */
<STRING>\n  {
    curr_lineno++;
    cool_yylval.error_msg = "Unterminated string constant";
    BEGIN(INITIAL);
    return ERROR;
}

    /* VALID escaped newline is accepted but it won't be counted as actual new line (should explicitely code as "...\n..." in the string)*/
<STRING>\\\n    { 
    curr_lineno++;
        *string_buf_ptr++ = '\n'; 
    }

    /* String can't contain null character */
<STRING>\\\0 {
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

    /* VALID user written escaped characters --> count them as single char and skip ahead */

<STRING>\\. {
    if (strlen(string_buf) + 1 > MAX_STR_CONST - 2) {
      cool_yylval.error_msg = "String is too long";
      BEGIN(INVALID_STRING);
      return ERROR;
    }

    if(yytext[1]=='\"'){
    *string_buf_ptr++ = '\"';

    }else if(yytext[1]=='b'){
    *string_buf_ptr++ = '\b';

    }else if(yytext[1]=='f'){
    *string_buf_ptr++ = '\f';

    }else if(yytext[1]=='n'){
    *string_buf_ptr++ = '\n';

    }else if(yytext[1]=='t'){
    *string_buf_ptr++ = '\t';
    
    }else{
    *string_buf_ptr++= yytext[1];
    }

}

    /* VALID String length < 1024 in COOL , if valid then concatinate the string portion with the previous portion*/

<STRING>. {
  if (strlen(yytext) + strlen(string_buf) > MAX_STR_CONST - 1){
    cool_yylval.error_msg = "String constant too long";
      BEGIN(INVALID_STRING);
      return ERROR;
  }

    *string_buf_ptr++ = yytext[0]; 
  
}

    /* If error occurs (INVALID_STRING state) termination of a string happens with \" or unescaped \n */
<INVALID_STRING>([\"]|[^\\]\n) {        
    BEGIN(INITIAL);
}

<INVALID_STRING>\n  {curr_lineno++;}

<INVALID_STRING>.   {}


    /* Comments */

--.*$ {}


    /*multiline comments*/
\*\) {
    cool_yylval.error_msg = "Unmatched *)";
    return ERROR;
}


\(\* {
    comment_level = 1;
    BEGIN(COMMENT);
}

    /* occurance of a nested comment */
<COMMENT>\(\* {
    comment_level++;
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

    /* occurance of `end comment` -> check the comment level and reduce the level */
<COMMENT>\*\) {
    if (comment_level == 1){
        comment_level = 0;
        BEGIN(INITIAL);
    }
    comment_level--;
}

<COMMENT>. {}


    /* Whitespace */

{WHITESPACE}    {}
\n+             {curr_lineno += yyleng;}
    
    /*invalid characters*/
.               {
                cool_yylval.error_msg = yytext;
                return ERROR;
}
%%
