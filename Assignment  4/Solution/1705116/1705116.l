%option noyywrap

%{
#include <stdio.h>
#include<iostream>
#include<string>
#include<fstream>
#include <stdlib.h>

#include "SymbolTable.h"
#include "y.tab.h"

using namespace std;




void yyerror(char *);
extern YYSTYPE yylval;
extern SymbolTable st; 
extern ofstream log_file;
extern ofstream error_file;

extern int line_count;
extern int error_count;


%}


digit [0-9]
DIGIT [0-9]
letter [A-Za-z]
delim [ \t\r\f\v]
newline \n
ws [delim]+

id (_|{letter})(_|{letter}|{digit})*
integer {digit}+
number {digit}*(\.{digit}+)?(E[+-]?{digit}+)?
ADDOP [+-] 
MULOP [*/%]

%%

{delim}+	{}
{newline} {line_count++;}

"if" {return IF;}
"else" {return ELSE;}
"for" {return FOR;}
"while" {return WHILE;}
"int" {return INT;}
"float" {return FLOAT;}
"return" {return RETURN;}
"void" {return VOID;}
"println"	{return PRINTLN;}

{ADDOP} { 
			SymbolInfo* s= new  SymbolInfo(yytext, (char *)"ADDOP");
			yylval = (YYSTYPE)s;
			return ADDOP;
		}



{MULOP}	{
			SymbolInfo* s= new  SymbolInfo(yytext, (char *)"MULOP");
			yylval = (YYSTYPE)s;
			return MULOP;
		}


"=" 	{return ASSIGNOP;}

">" |
"<" |
">=" |
"<=" |
"==" |
"!=" {
		SymbolInfo *s= new  SymbolInfo(yytext, (char *)"RELOP");
		yylval = (YYSTYPE)s;
		return RELOP;
	}

"&&"	|
"||"	{
			SymbolInfo *s= new  SymbolInfo(yytext, (char *)"LOGICOP");
			yylval = (YYSTYPE)s;
			return LOGICOP;
		}
"!"		{	return NOT; }


";" 	{ return SEMICOLON;}
"," 	{return COMMA;}
"(" 	{return LPAREN;}
")" 	{return RPAREN;}
"{" 	{return LCURL;}
"}" 	{return RCURL;}
"[" 	{return LTHIRD;}
"]" 	{return RTHIRD;}
"++" 	{return INCOP;}
"--" 	{return DECOP;}



{integer}	{
				SymbolInfo *s= new  SymbolInfo(yytext, (char *)"CONST_INT");
				yylval = (YYSTYPE)s;
				return CONST_INT;
			}
{number} 	{	

				string str=yytext+(string)"0";
				SymbolInfo *s= new  SymbolInfo(str, (char *)"CONST_FLOAT");
				yylval = (YYSTYPE)s;
				return CONST_FLOAT; 
			}
{id} 		{	 
				
				
				SymbolInfo *s= new  SymbolInfo(yytext, "ID");
				yylval = (YYSTYPE)s;
							
				return ID;
			}
			
			
({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)* {
	log_file<<"Error at line "<<line_count<<": Too many decimal point "<<yytext<<endl;
	error_file<<"Error at line "<<line_count<<": Too many decimal point "<<yytext<<endl;
	error_count++;
}

({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)*([Ee][+-]?({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)*)* {

       log_file<<"Error at line "<<line_count<<": Ill formed number"<<yytext<<endl;
	error_file<<"Error at line "<<line_count<<": Ill formed number"<<yytext<<endl;
	error_count++;
}

[0-9]+[A-Z_a-z][0-9A-Z_a-z]* {
	log_file<<"Error at line "<<line_count<<": Invalid prefix on ID or invalid suffix on Number"<<yytext<<endl;
	error_file<<"Error at line "<<line_count<<": Invalid prefix on ID or invalid suffix on Number"<<yytext<<endl;
	error_count++;
}			

. {
	log_file<<"Error at line "<<line_count<<":Unrecognized character "<<yytext<<endl;
	error_file<<"Error at line "<<line_count<<":Unrecognized character "<<yytext<<endl;
	error_count++;
}
%%
/*
//SV skipped 
int yywrap(void)
{
	return 1;
}
*/

