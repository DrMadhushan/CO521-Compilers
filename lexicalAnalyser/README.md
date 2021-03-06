README file for Programming Assignment 2 (C++ edition)
=====================================================

Your directory should contain the following files:

 Makefile
 README
 cool.flex
 test.cl
 lextest.cc      -> [cool root]/src/PA2/lextest.cc
 mycoolc         -> [cool root]/PA2/mycoolc
 stringtab.cc    -> [cool root]/PA2/stringtab.cc
 utilities.cc    -> [cool root]/PA2/utilities.cc
 handle_flags.cc -> [cool root]/PA2/handle_flags.cc
 *.d             dependency files
 *.*             other generated files

The include (.h) files for this assignment can be found in 
[cool root]/PA2

	The Makefile contains targets for compiling and running your
	program. DO NOT MODIFY.

	The README contains this info. Part of the assignment is to fill
	the README with the write-up for your project. You should
	explain design decisions, explain why your code is correct, and
	why your test cases are adequate. It is part of the assignment
	to clearly and concisely explain things in text as well as to
	comment your code. Just edit this file.

	cool.flex is a skeleton file for the specification of the
	lexical analyzer. You should complete it with your regular
	expressions, patterns and actions. 

	test.cl is a COOL program that you can test the lexical
	analyzer on. It contains some errors, so it won't compile with
	coolc. However, test.cl does not exercise all lexical
	constructs of COOL and part of your assignment is to rewrite
	test.cl with a complete set of tests for your lexical analyzer.

	cool-parse.h contains definitions that are used by almost all parts
	of the compiler. DO NOT MODIFY.

	stringtab.{cc|h} and stringtab_functions.h contains functions
        to manipulate the string tables.  DO NOT MODIFY.

	utilities.{cc|h} contains functions used by the main() part of
	the lextest program. You may want to use the strdup() function
	defined in here. Remember that you should not print anything
	from inside cool.flex! DO NOT MODIFY.

	lextest.cc contains the main function which will call your
	lexer and print out the tokens that it returns.  DO NOT MODIFY.

	mycoolc is a shell script that glues together the phases of the
	compiler using Unix pipes instead of statically linking code.  
	While inefficient, this architecture makes it easy to mix and match
	the components you write with those of the course compiler.
	DO NOT MODIFY.	

        cool-lexer.cc is the scanner generated by flex from cool.flex.
        DO NOT MODIFY IT, as your changes will be overritten the next
        time you run flex.

 	The *.d files are automatically generated Makefiles that capture
 	dependencies between source and header files in this directory.
 	These files are updated automatically by Makefile; see the gmake
 	documentation for a detailed explanation.

Instructions
------------

	To compile your lextest program type:

	% make lexer

	Run your lexer by putting your test input in a file 'foo.cl' and
	run the lextest program:

	% ./lexer foo.cl

	To run your lexer on the file test.cl type:

	% make dotest

	If you think your lexical analyzer is correct and behaves like
	the one we wrote, you can actually try 'mycoolc' and see whether
	it runs and produces correct code for any examples.
	If your lexical analyzer behaves in an
	unexpected manner, you may get errors anywhere, i.e. during
	parsing, during semantic analysis, during code generation or
	only when you run the produced code on spim. So beware.

	If you change architectures you must issue

	% make clean

	when you switch from one type of machine to the other.
	If at some point you get weird errors from the linker,	
	you probably forgot this step.

	GOOD LUCK!

---8<------8<------8<------8<---cut here---8<------8<------8<------8<---

## Write-up for PA2
----------------

## **Design specifications:**

String
------

	Starts with a " character
	- the string_buf adderss will be set

	Ends with another " character
	- once occured null char will be appended to the string_buf and returned token

	Unescaped new line `\n` will be considered as an error that the programmer missed a " character to terminate the string.

	An escaped newline is accepted \`\n` 

	Escaped null character not allowed in the string `\0`
	- return ERROR with message
	
	EOF is not allowed in a string 
	- return ERROR with EOF message
	
	Some escaped characters are treated specially
	`\\`c
	c == n 			-> append `\n`
	c == b 			-> append `\b`
	c == t 			-> append `\t`
	c == f 			-> append `\f`
	c == " 			-> append `\"`
	c == other char	-> append `c`
	to the string_buf

	One or more occurances of any characteres exept `\n`, `\\`, `\0` will be accepted and appended to the string_buf

Comment
-------
**Single line comment**

	Starts with -- 	
	 - any characters until the carriage return will be ignored


**Multi-line comment**

	Starts with (*
	 - any character until the next *) char sequence will be ignored 
	 - this will set the comment level to 1 (* nested comment level)
  
  	EOF in a multi-line comment is not allowed. 
	 - It should be terminated, otherwise error returned as 'EOF in comment'

	Nested comments handles level-wise
	 - each occurance of `(*` will increase the comment level
	 - each occarance of `*)` will decrease the comment level

  	Comment terminated with a *) char sequence at comment level 1
  
	***
	Apart from comments, an unmatched *) sequence will be considered as an error that a closing comment has no opening comment partner

Keywords
--------
Keyword tokens that are analysed;<br> *They are case insensitive*
	
	

	CLASS   	[Cc][lL][aA][sS][sS]
	ELSE    	[eE][lL][sS][eE]
	FI      	[fF][iI]
	IF      	[iI][fF]
	IN      	[iI][nN]
	INHERITS 	[iI][nN][hH][eE][rR][iI][tT][sS]
	LET     	[lL][eE][tT]
	LOOP    	[lL][oO][oO][pP]
	POOL    	[pP][oO][oO][lL]
	THEN    	[tT][hH][eE][nN]
	WHILE   	[wW][hH][iI][lL][eE]    
	CASE    	[cC][aA][sS][eE]
	ESAC    	[eE][sS][aA][cC]
	OF      	[oO][fF] 
	NEW     	[nN][eE][wW] 
	ISVOID  	[iI][sS][vV][oO][iI][dD]
	NOT     	[nN][oO][tT]

Boolean
-------
First letter is case sensitive (trailing letters are case insensitive)

	TRUE        t[rR][uU][eE]
	FALSE       f[aA][lL][sS][eE]

Identifiers
-----------

	TYPEID      [A-Z][a-zA-Z0-9_]*
	OBJECTID    [a-z][a-zA-Z0-9_]*

Operators and symbols
---------------------
	
	The following single character operators and double character operators are returned as them selves

	( ) . @ ~ * + / - < = { } : , ; %
	DARROW				`=>`  
	Assign				`<-`  
	Less than or equal	`<=`

White spaces
------------

	White space characters found outside comments and strings are ignored while `\n` is ignored but current_lineno is incremented foreach occurance.

<br>

## **Testing:**

Test program directories:<br>
`./tests/examples/`	<br>
`./tests/errors/`

Maximum possible test cases are tested
the `./tests/examples/` directory contains several functioning COOL programs to test whether the designed lexer imitates the tokenizing functionality of the pre-built lexer in error-free condition.

Possible errors in each rule defined are tested using individual files in `./tests/errors/` directory.

Testing is done using a shell script `./tests/evaluate.sh` to compare the results produced by pre-built lexer (`./benchmark/lexer`) and our lexer (`./lexer`).

The `evaluate.sh` will loop through all the files in `./tests/examples/` and `./tests/errors/` directories with `.cl` extension and prints the result for each test case as `'passed'` or `'failed'` with the difference.