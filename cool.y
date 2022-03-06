/*
*  cool.y
*              Parser definition for the COOL language.
*
*/
%{
  #include <iostream>
  #include "cool-tree.h"
  #include "stringtab.h"
  #include "utilities.h"
  
  extern char *curr_filename;
  
  
  /* Locations */
  #define YYLTYPE int              /* the type of locations */
  #define cool_yylloc curr_lineno  /* use the curr_lineno from the lexer
  for the location of tokens */
    
    extern int node_lineno;          /* set before constructing a tree node
    to whatever you want the line number
    for the tree node to be */
      
      
      #define YYLLOC_DEFAULT(Current, Rhs, N)         \
      Current = Rhs[1];                             \
      node_lineno = Current;
    
    
    #define SET_NODELOC(Current)  \
    node_lineno = Current;
    
    /* IMPORTANT NOTE ON LINE NUMBERS
    *********************************
    * The above definitions and macros cause every terminal in your grammar to 
    * have the line number supplied by the lexer. The only task you have to
    * implement for line numbers to work correctly, is to use SET_NODELOC()
    * before constructing any constructs from non-terminals in your grammar.
    * Example: Consider you are matching on the following very restrictive 
    * (fictional) construct that matches a plus between two integer constants. 
    * (SUCH A RULE SHOULD NOT BE  PART OF YOUR PARSER):
    
    plus_consts : INT_CONST '+' INT_CONST 
    
    * where INT_CONST is a terminal for an integer constant. Now, a correct
    * action for this rule that attaches the correct line number to plus_const
    * would look like the following:
    
    plus_consts : INT_CONST '+' INT_CONST 
    {
      // Set the line number of the current non-terminal:
      // ***********************************************
      // You can access the line numbers of the i'th item with @i, just
      // like you acess the value of the i'th exporession with $i.
      //
      // Here, we choose the line number of the last INT_CONST (@3) as the
      // line number of the resulting expression (@$). You are free to pick
      // any reasonable line as the line number of non-terminals. If you 
      // omit the statement @$=..., bison has default rules for deciding which 
      // line number to use. Check the manual for details if you are interested.
      @$ = @3;
      
      
      // Observe that we call SET_NODELOC(@3); this will set the global variable
      // node_lineno to @3. Since the constructor call "plus" uses the value of 
      // this global, the plus node will now have the correct line number.
      SET_NODELOC(@3);
      
      // construct the result node:
      $$ = plus(int_const($1), int_const($3));
    }
    
    */
    
    
    
    void yyerror(char *s);        /*  defined below; called for each parse error */
    extern int yylex();           /*  the entry point to the lexer  */
    
    /************************************************************************/
    /*                DONT CHANGE ANYTHING IN THIS SECTION                  */
    
    Program ast_root;       /* the result of the parse  */
    Classes parse_results;        /* for use in semantic analysis */
    int omerrs = 0;               /* number of errors in lexing and parsing */
    %}
    
    /* A union of all the types that can be the result of parsing actions. */
    %union {
      Boolean boolean;
      Symbol symbol;
      Program program;
      Class_ class_;
      Classes classes;
      Feature feature;
      Features features;
      Formal formal;
      Formals formals;
      Case case_;
      Cases cases;
      Expression expression;
      Expressions expressions;
      char *error_msg;
    }
    
    /* 
    Declare the terminals; a few have types for associated lexemes.
    The token ERROR is never used in the parser; thus, it is a parse
    error when the lexer returns it.
    
    The integer following token declaration is the numeric constant used
    to represent that token internally.  Typically, Bison generates these
    on its own, but we give explicit numbers to prevent version parity
    problems (bison 1.25 and earlier start at 258, later versions -- at
    257)
    */
    %token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
    %token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
    %token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
    %token <symbol>  STR_CONST 275 INT_CONST 276 
    %token <boolean> BOOL_CONST 277
    %token <symbol>  TYPEID 278 OBJECTID 279 
    %token ASSIGN 280 NOT 281 LE 282 ERROR 283
    
    /*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
    /**************************************************************************/
    
    /* Complete the nonterminal list below, giving a type for the semantic
    value of each non terminal. (See section 3.6 in the bison 
    documentation for details). */
    
    /* Declare types for the grammar's non-terminals. */
    %type <program> program
    %type <classes> class_list
    %type <class_> class
    
    /* You will want to change the following line. */
    /* %type <features> dummy_feature_list */
    %type <feature> feature
    %type <features> feature_list
    %type <formal> formal
    %type <formals> formal_list
    %type <case_> case
    %type <cases> cases
    %type <expression> expression
    %type <expression> expression_block
    %type <expression> dispatch
    %type <expression> let_assign
    %type <expression> let_expression
    %type <expressions> expressions_block
    %type <expressions> expressions_list
    
    /* Precedence declarations go here. */
    %precedence LET
    %right ASSIGN
    %precedence NOT
    %nonassoc '<' '=' LE
    %left '+' '-'
    %left '*' '/'
    %precedence ISVOID
    %precedence '~'
    %precedence '@'
    %precedence '.'
    
    %%
    /* 
    Save the root of the abstract syntax tree in a global variable.
    */
    program : class_list  { @$ = @1; ast_root = program($1); }
            ;
    
    class_list
            : class     /* single class */
            { 
              $$ = single_Classes($1);
              parse_results = $$; 
            }
            | class_list class  /* several classes */
            { 
              $$ = append_Classes($1, single_Classes($2)); 
              parse_results = $$; 
            }
            ;
            
    /* If no parent is specified, the class inherits from the Object class. */
    class   : 
            CLASS TYPEID '{' feature_list '}' ';'
            { 
              $$ = class_($2, idtable.add_string("Object"), $4, stringtable.add_string(curr_filename)); 
            }
            | CLASS TYPEID INHERITS TYPEID '{' feature_list '}' ';'
            { 
              $$ = class_($2, $4, $6, stringtable.add_string(curr_filename)); 
            }
            ;
    
    /* Feature list may be empty, but no empty features in list. */
    /* dummy_feature_list:    /* empty */
    /* {  $$ = nil_Features(); } */
    
    feature :
            OBJECTID '(' formal_list ')' ':' TYPEID '{' expression '}' ';' /* method definition */
            {
              /* method(name : Symbol; formals : Formals; return_type : Symbol; expr: Expression) : Feature; */
              $$ = method($1, $3, $6, $8);
            }
            | OBJECTID ':' TYPEID ';' /* attribute definition */
            {
              /* attr(name, type_decl : Symbol; init : Expression) : Feature; */
              $$ = attr($1, $3, no_expr());
            }
            | OBJECTID ':' TYPEID ASSIGN expression ';'  /* attribute def expression is optional */
            {
              $$ = attr($1, $3, $5);
            }
            ;

    feature_list :
            feature
            {
              $$ = single_Features($1);
            }
            | feature_list feature
            {
              $$ = append_Features($1, single_Features($2));
            }
            ;

    formal :
            OBJECTID ':' TYPEID
            {
              /* formal(name, type_decl: Symbol) : Formal; */
              $$ = formal($1, $3);
            }
            ;
    formal_list :
            {
              /* empty formal list */
              $$ = nil_Formals();
            }
            | formal
            {
              $$ = single_Formals($1);
            }
            | formal_list ',' formal
            {
              $$ = append_Formals($1, single_Formals($3));
            }
            ;
   

    dispatch : /* a method call -> 3 main formats e.id(e,e,e...) , id(e,e,..) , e@type.id(e,e,....) */
            /* format #1, #2 dispatch(expr : Expression; name : Symbol; actual : Expressions) : Expression; */
            /* format #3 static_dispatch(expr: Expression; type_name : Symbol; name : Symbol; actual : Expressions) : Expression; */
            expression '.' OBJECTID '(' ')' /* empty args #1 */
            {
              /*  */
              $$ = dispatch($1, $3, nil_Expressions());
            }
            | expression '.' OBJECTID '(' expression ')' /* single arg expression #1 */
            {
              /*  */
              $$ = dispatch($1, $3, single_Expressions($5));
            }
            | expression '.' OBJECTID '(' expression expressions_list ')' /* multiple (comma seperated) expressions as argument #1 */
            {
              /*  */
              $$ = dispatch($1, $3, append_Expressions(single_Expressions($5), $6));
            }
            | OBJECTID '(' ')' /* empty args #2 calls method from `self`*/
            {
              /*  */
              $$ = dispatch(object(idtable.add_string("self")), $1, nil_Expressions());
            }
            | OBJECTID '(' expression ')' /* single arg expression #2 */
            {
              /*  */
              $$ = dispatch(object(idtable.add_string("self")), $1, single_Expressions($3));
            }
            | OBJECTID '(' expression expressions_list ')' /* multiple (comma seperated) expressions as argument #2 */
            {
              /*  */
              $$ = dispatch(object(idtable.add_string("self")), $1, append_Expressions(single_Expressions($3), $4));
            }
            | expression '@' TYPEID '.' OBJECTID '(' ')' /* empty args #3 */
            {
              /*  */
              $$ = static_dispatch($1, $3, $5, nil_Expressions());
            }
            | expression '@' TYPEID '.' OBJECTID '(' expression ')' /* single arg expression #3 */
            {
              /*  */
              $$ = static_dispatch($1, $3, $5, single_Expressions($7));
            }
            | expression '@' TYPEID '.' OBJECTID '(' expression expressions_list ')' /* multiple (comma seperated) expressions as argument #3 */
            {
              /*  */
              $$ = static_dispatch($1, $3, $5, append_Expressions(single_Expressions($7), $8));
            }
            ;
    expression_block : 
            expression ';' /* a single line expression inside a { } block */
            {
              $$ = $1;
            }
            ;
    expressions_block : /* one or more expressions inside a { } block */
            expression_block 
            {
              $$ = single_Expressions($1);
            }
            | expressions_block expression_block 
            {
              $$ = append_Expressions($1, single_Expressions($2));
            }
            ;
    expressions_list :
            ',' expression
            {
              $$ = single_Expressions($2);
            }
            | ',' expression ',' expressions_list
            {
              $$ = append_Expressions(single_Expressions($2), $4);
            }
            ;

    let_assign :
            {
              $$ = no_expr();
            }
            | ASSIGN expression
            {
              /* to terminate a list of assignments / may be only one assign expression*/
              $$ = $2;
            }
            ;
    let_expression : 
            /* let(identifier, type_decl: Symbol; init, body: Expression): Expression; */
            OBJECTID ':' TYPEID let_assign IN expression
            {
              /*  */
              $$ = let($1, $3, $4, $6);
            }
            | OBJECTID ':' TYPEID let_assign ',' let_expression
            {
              $$ = let($1, $3, $4, $6);
            }
            ;
    
    case : /* branch(name, type_decl: Symbol; expr: Expression): Case; */
            OBJECTID ':' TYPEID DARROW expression ';'
            {
              $$ = branch($1, $3, $5);
            }
            ;
    cases :
            /* At least one or more branch */
            case
            {
              $$ = single_Cases($1);
            }
            | cases case
            {
              $$ = append_Cases($1, single_Cases($2));
            }
            ;

    expression : /* all possible expressions as mentioned in cool manual */
            OBJECTID ASSIGN expression
            {
              /* assign(name : Symbol; expr : Expression) : Expression; */
              $$ = assign($1, $3);
            }
            | dispatch
            {
              $$ = $1;
            }
            | IF expression THEN expression ELSE expression FI
            {
              /* cond(pred, then_exp, else_exp : Expression): Expression; */
              $$ = cond($2, $4, $6);
            }
            | WHILE expression LOOP expression POOL
            {
              /* loop(pred, body: Expression) : Expression; */
              $$ = loop($2, $4);
            }
            | '{' expressions_block '}'
            {
              /* block(body: Expressions) : Expression; */
              $$ = block($2);
            }
            | LET let_expression /* let_expression should go as long as code allow (let should capture all of them) */
            {
              $$ = $2;
            }
            | CASE expression OF cases ESAC
            {
              /* typcase(expr: Expression; cases: Cases): Expression; */
              $$ = typcase($2, $4);
            }
            | NEW TYPEID
            {
              /* new_(type_name: Symbol): Expression; */
              $$ = new_($2);
            }
            | ISVOID expression
            {
              /* isvoid(e1: Expression): Expression; */
              $$ = isvoid($2);
            }
            | expression '+' expression  /* arithmatic + */
            { $$ = plus($1, $3); }
            | expression '-' expression  /* arithmatic - */
            { $$ = sub($1, $3); }
            | expression '*' expression  /* arithmatic * */ 
            { $$ = mul($1, $3); }
            | expression '/' expression  /* arithmatic / */ 
            { $$ = divide($1, $3); }
            | '~' expression 
            { $$ = neg($2); }
            | expression '<' expression   /* Comparison */
            { $$ = lt($1, $3); }
            | expression LE expression   /* Comparison */ 
            { $$ = leq($1, $3); }
            | expression '=' expression   /* Comparison */ 
            { $$ = eq($1, $3); }
            | NOT expression 
            { $$ = comp($2); }
            | '(' expression ')' 
            { $$ = $2; }
            | OBJECTID 
            { $$ = object($1); }
            | INT_CONST 
            { $$ = int_const($1); }
            | STR_CONST 
            { $$ = string_const($1); }
            | BOOL_CONST 
            { $$ = bool_const($1); }
            ;



    /* end of grammar */
    %%
    
    /* This function is called automatically when Bison detects a parse error. */
    void yyerror(char *s)
    {
      extern int curr_lineno;
      
      cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
      << s << " at or near ";
      print_cool_token(yychar);
      cerr << endl;
      omerrs++;
      
      if(omerrs>50) {fprintf(stdout, "More than 50 errors\n"); exit(1);}
    }
    
    