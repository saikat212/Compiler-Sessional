%option noyywrap

%{
#include<iostream>
#include<fstream>
#include<iostream>

#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<string>
#include"symtab.cpp"
SymbolTable st(7);
int line_count=1;
int error_count=0;
int current_line;
std::string str="";
std::string token_str="";
using namespace std;

FILE *logout;
FILE *tokenout;

%}

WHITESPACE [ \t\f\r\v]+
LETTER [a-zA-Z]
LETTER_UNDERSCORE [A-Za-z_]

DIGIT [0-9]
NEWLINE \n
NOT_NEWLINE [^\n]
ID {LETTER_UNDERSCORE}({LETTER_UNDERSCORE}|{DIGIT})*

INTEGER_LITERALS {DIGIT}+
FLOATTING_LITERALS {DIGIT}*(\.{DIGIT}+)(E[+-]?{DIGIT}+)?

CHARACTER ['][^\\\n'][']|['][\\][ntafrbv0\\\'][']

SINGLE_CHAR [\\][ntafrbv0\\\']|[^\\\n']

UNFINISHED_CHAR_ERROR1 ['][\n]
UNFINISHED_CHAR_ERROR2 [']({SINGLE_CHAR})
INCOP "++"|"--"
ADDOP "+"|"-"
MULOP "*"|"/"|"%"
RELOP "<="|"<"|">="|">"|"=="|"!="
ASSIGNOP "="
LOGICOP "&&"|"||"
NOT "!"
LPAREN "("
RPAREN ")"
LCURL "{"
RCURL "}"
LTHIRD "["
RTHIRD "]"
COMMA ","
SEMICOLON ";"


MANY_DECIMAL_POINT ([0-9]*[.][0-9]*[.][0-9]*)+

INVALID_SUFFIX_PREFIX ({INTEGER_LITERALS}|{FLOATTING_LITERALS})({ID})
ILL_FORM [0-9]+E([+-]?[0-9]*[.][0-9]+)

MUL_CHAR_ERROR [']({SINGLE_CHAR}+{SINGLE_CHAR}+)[']

SPEC_CHAR_ERROR [']([\\][ntafrbv0\\\']|[^\n])

EMPTY_CHAR_CONST_ERROR ([']['])
STRING_DETECTION ["]
%x INSIDE_STRING
%x INSIDE_SINGLE_LINE_COMMENT
%x INSIDE_MUL_LINE_COMMENT


%%

{NEWLINE} {line_count++;}
{WHITESPACE} {}

"if" {
	fprintf(tokenout,"<IF>");
	fprintf(logout,"Line no %d: Token <IF> Lexeme %s found\n",line_count,yytext);
	
	}
"for" {
	fprintf(tokenout,"<FOR>");
	fprintf(logout,"Line no %d: Token <FOR> Lexeme %s found\n",line_count,yytext);
	
	}
"do" {
	fprintf(tokenout,"<DO>");
	fprintf(logout,"Line no %d: Token <DO> Lexeme %s found\n",line_count,yytext);
	
	}
	
"int" {
	fprintf(tokenout,"<INT>");
	fprintf(logout,"Line no %d: Token <INT> Lexeme %s found\n",line_count,yytext);
	
	}
"void" {
	fprintf(tokenout,"<VOID>");
	fprintf(logout,"Line no %d: Token <VOID> Lexeme %s found\n",line_count,yytext);
	
	}
"float" {
	fprintf(tokenout,"<FLOAT>");
	fprintf(logout,"Line no %d: Token <FLOAT> Lexeme %s found\n",line_count,yytext);
	
	}

"switch" {
	fprintf(tokenout,"<SWITCH>");
	fprintf(logout,"Line no %d: Token <SWITCH> Lexeme %s found\n",line_count,yytext);
	
	}
"default" {
	fprintf(tokenout,"<DEFAULT>");
	fprintf(logout,"Line no %d: Token <DEFAULT> Lexeme %s found\n",line_count,yytext);
	
	}
"else" {
	fprintf(tokenout,"<ELSE>");
	fprintf(logout,"Line no %d: Token <ELSE> Lexeme %s found\n",line_count,yytext);
	
	}
	
"while" {
	fprintf(tokenout,"<WHILE>");
	fprintf(logout,"Line no %d: Token <WHILE> Lexeme %s found\n",line_count,yytext);
	
	}
"break" {
	fprintf(tokenout,"<BREAK>");
	fprintf(logout,"Line no %d: Token <BREAK> Lexeme %s found\n",line_count,yytext);
	
	}
"char" {
	fprintf(tokenout,"<CHAR>");
	fprintf(logout,"Line no %d: Token <CHAR> Lexeme %s found\n",line_count,yytext);
	
	}
"double" {
	fprintf(tokenout,"<DOUBLE>");
	fprintf(logout,"Line no %d: Token <DOUBLE> Lexeme %s found\n",line_count,yytext);
	
	}
	
"return" {
	fprintf(tokenout,"<RETURN>");
	fprintf(logout,"Line no %d: Token <RETURN> Lexeme %s found\n",line_count,yytext);
	
	}
"case" {
	fprintf(tokenout,"<CASE>");
	fprintf(logout,"Line no %d: Token <CASE> Lexeme %s found\n",line_count,yytext);
	
	}
"continue" {
	fprintf(tokenout,"<CONTINUE>");
	fprintf(logout,"Line no %d: Token <CONTINUE> Lexeme %s found\n",line_count,yytext);
	
	}

{INVALID_SUFFIX_PREFIX} {
	error_count++;
	fprintf(logout,"Error at line no %d:Invalid prefix on ID or invalid suffix on Number %s \n",line_count,yytext);
	
	}	
{EMPTY_CHAR_CONST_ERROR} {
	error_count++;
	fprintf(logout,"Error at line no %d:Empty character constant error %s \n",line_count,yytext);
	
	}
	
{UNFINISHED_CHAR_ERROR1} {
        
	error_count++;
	fprintf(logout,"Error at line no %d:Unterminated character %s",line_count,yytext);
	line_count++;
	
	}
{UNFINISHED_CHAR_ERROR2} {
	error_count++;
	fprintf(logout,"Error at line no %d:Unterminated character %s \n",line_count,yytext);
	
	}
{ILL_FORM} {
	error_count++;
	fprintf(logout,"Error at line no %d:Ill formed number %s \n",line_count,yytext);
	
	}
	
{MANY_DECIMAL_POINT} {
	error_count++;
	fprintf(logout,"Error at line no %d:Too many decimal points %s \n",line_count,yytext);
	}	

{MUL_CHAR_ERROR} {
	error_count++;
	fprintf(logout,"Error at line no %d:Multi character constant error %s \n",line_count,yytext);
	}
{INTEGER_LITERALS} { 
	fprintf(tokenout,"<CONST_INT,%s>",yytext);
	fprintf(logout,"Line no %d: Token <CONST_INT> Lexeme %s found\n",line_count,yytext);
	
	
	if(st.Insert_In_SymbolTable(yytext,"CONST_INT"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
	}

{FLOATTING_LITERALS} { 
	fprintf(tokenout,"<CONST_FLOAT,%s>",yytext);
	fprintf(logout,"Line no %d: Token <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
	
	if(st.Insert_In_SymbolTable(yytext,"CONST_FLOAT"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
	}
{CHARACTER} {
        char check;
	if(yytext[1]=='\\')
	{
		check=yytext[2];
		
		
		if(check=='t')
			{
			char pc='\t';
			fprintf(tokenout,"<CONST_CHAR,%c>",pc);
			fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR,%c>\n",line_count,yytext,pc);
			
			if(st.Insert_In_SymbolTable(yytext,"CONST_CHAR"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
			
			
			}
		if(check=='n')
			{
			char pc='\n';
			fprintf(tokenout,"<CONST_CHAR,%c>",pc);
			fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR,%c>\n",line_count,yytext,pc);
			
			if(st.Insert_In_SymbolTable(yytext,"CONST_CHAR"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
			}
		if(check=='a')
			{
			char pc='\a';
			fprintf(tokenout,"<CONST_CHAR,%c>",pc);
			fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR,%c>\n",line_count,yytext,pc);
			
			if(st.Insert_In_SymbolTable(yytext,"CONST_CHAR"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
			}
		if(check=='f')
			{
			char pc='\f';
			fprintf(tokenout,"<CONST_CHAR,%c>",pc);
			fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR,%c>\n",line_count,yytext,pc);
			
			if(st.Insert_In_SymbolTable(yytext,"CONST_CHAR"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
			}
		if(check=='r')
			{
			char pc='\r';
			fprintf(tokenout,"<CONST_CHAR,%c>",pc);
			fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR,%c>\n",line_count,yytext,pc);
			
			if(st.Insert_In_SymbolTable(yytext,"CONST_CHAR"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
			}
		if(check=='b')
			{
			char pc='\b';
			fprintf(tokenout,"<CONST_CHAR,%c>",pc);
			fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR,%c>\n",line_count,yytext,pc);
			if(st.Insert_In_SymbolTable(yytext,"CONST_CHAR"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
			}
		if(check=='0')
			{
			char pc='\0';
			fprintf(tokenout,"<CONST_CHAR,%c>",pc);
			fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR,%c>\n",line_count,yytext,pc);
			
			if(st.Insert_In_SymbolTable(yytext,"CONST_CHAR"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
			}
		if(check=='\\')
			{
			char pc='\\';
			fprintf(tokenout,"<CONST_CHAR,%c>",pc);
			fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR,%c>\n",line_count,yytext,pc);
			
			if(st.Insert_In_SymbolTable(yytext,"CONST_CHAR"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
			}
		if(check=='\'')
			{
			char pc='\'';
			fprintf(tokenout,"<CONST_CHAR,%c>",pc);
			fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR,%c>\n",line_count,yytext,pc);
			
			if(st.Insert_In_SymbolTable(yytext,"CONST_CHAR"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
			}
		if(check=='v')
			{
			char pc='\v';
			fprintf(tokenout,"<CONST_CHAR,%c>",pc);
			fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR,%c>\n",line_count,yytext,pc);
			
			if(st.Insert_In_SymbolTable(yytext,"CONST_CHAR"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
			}
	}
	
	else
	{
		char actual_char=yytext[1];
		
		fprintf(tokenout,"<CONST_CHAR,%c>",actual_char);
		fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --><CONST_CHAR,%c>\n",line_count,yytext,actual_char);
		
		if(st.Insert_In_SymbolTable(yytext,"CONST_CHAR"))
			{
			
				st.PrintAllScopeTable(logout);	
			}
			else
			
			{
				fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
			}
	
	}
	
	
	}
	
{ADDOP} {
	fprintf(tokenout,"<ADDOP,%s>",yytext);
	fprintf(logout,"Line no %d: Token <ADDOP> Lexeme %s found\n",line_count,yytext);
	
	}
	
{INCOP} {
	fprintf(tokenout,"<INCOP,%s>",yytext);
	fprintf(logout,"Line no %d: Token <INCOP> Lexeme %s found\n",line_count,yytext);
	
	} 
 
{MULOP} {
	fprintf(tokenout,"<MULOP,%s>",yytext);
	fprintf(logout,"Line no %d: Token <MULOP> Lexeme %s found\n",line_count,yytext);
	
	} 
{RELOP} {
	fprintf(tokenout,"<RELOP,%s>",yytext);
	fprintf(logout,"Line no %d: Token <RELOP> Lexeme %s found\n",line_count,yytext);
	
	} 
{ASSIGNOP} {
	fprintf(tokenout,"<ASSIGNOP,%s>",yytext);
	fprintf(logout,"Line no %d: Token <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
	
	} 
{LOGICOP} {
	fprintf(tokenout,"<LOGICOP,%s>",yytext);
	fprintf(logout,"Line no %d: Token <LOGICOP> Lexeme %s found\n",line_count,yytext);
	
	} 
{NOT} {
	fprintf(tokenout,"<NOT,%s>",yytext);
	fprintf(logout,"Line no %d: Token <NOT> Lexeme %s found\n",line_count,yytext);
	
	} 
{LPAREN} {
	fprintf(tokenout,"<LPAREN,%s>",yytext);
	fprintf(logout,"Line no %d: Token <LPAREN> Lexeme %s found\n",line_count,yytext);
	
	} 
{RPAREN} {
	fprintf(tokenout,"<RPAREN,%s>",yytext);
	fprintf(logout,"Line no %d: Token <RPAREN> Lexeme %s found\n",line_count,yytext);
	
	} 
{LCURL} {
	fprintf(tokenout,"<LCURL,%s>",yytext);
	fprintf(logout,"Line no %d: Token <LCURL> Lexeme %s found\n",line_count,yytext);
	st.EnterScope();
	
	} 
{RCURL} {
	fprintf(tokenout,"<RCURL,%s>",yytext);
	fprintf(logout,"Line no %d: Token <RCURL> Lexeme %s found\n",line_count,yytext);
	st.ExitScope();
	} 
{LTHIRD} {
	fprintf(tokenout,"<LTHIRD,%s>",yytext);
	fprintf(logout,"Line no %d: Token <LTHIRD> Lexeme %s found\n",line_count,yytext);
	
	} 
{RTHIRD} {
	fprintf(tokenout,"<RTHIRD,%s>",yytext);
	fprintf(logout,"Line no %d: Token <RTHIRD Lexeme %s found\n",line_count,yytext);
	
	} 
{COMMA} {
	fprintf(tokenout,"<COMMA,%s>",yytext);
	fprintf(logout,"Line no %d: Token <COMMA> Lexeme %s found\n",line_count,yytext);
	
	} 
{SEMICOLON} {
	fprintf(tokenout,"<SEMICOLON,%s>",yytext);
	fprintf(logout,"Line no %d: Token <SEMICOLON> Lexeme %s found\n",line_count,yytext);
	
	} 

 
{ID} {
	fprintf(tokenout,"<ID,%s>",yytext);
	fprintf(logout,"Line no %d: Token <ID> Lexeme %s found\n",line_count,yytext);
	
	if(st.Insert_In_SymbolTable(yytext,"ID"))
		{
			
			st.PrintAllScopeTable(logout);	
		}
		else
			
		{
			fprintf(logout,"%s already exists in current ScopeTable\n",yytext);
		}
	
	}

	
{STRING_DETECTION} {

	BEGIN INSIDE_STRING;
	current_line=line_count;
	
	str="\"";
	token_str="\"";
	
	}
<INSIDE_STRING>{STRING_DETECTION} {
  	
	
	str+="\"";
	token_str+="\"";
	
	int len=str.size();
	fprintf(logout,"Line no %d: Token <STRING> Lexeme ",current_line);
	
	for(int i=0;i<len;i++)
	{
		char sc=str[i];
		fprintf(logout,"%c",sc);
		
	}
	fprintf(logout," found --> <STRING,");
	len=token_str.size();
	for(int i=0;i<len;i++)
	{
		char sc=token_str[i];
		fprintf(logout,"%c",sc);
		
	}
	fprintf(logout," >\n");
	
	
	fprintf(tokenout,"<STRING, ");
	
	len=token_str.size();
	for(int i=0;i<len;i++)
	{
		char sc=token_str[i];
		fprintf(tokenout,"%c",sc);
		
	}
	fprintf(tokenout," >");
	

	BEGIN INITIAL;
	}
<INSIDE_STRING>{NEWLINE} {
	error_count++;
	fprintf(logout,"Error at line no %d:Unterminated String ",current_line);
	int len=str.size();
	for(int i=0;i<len;i++)
	{
		char sc=str[i];
		fprintf(logout,"%c",sc);
		
	}
	fprintf(logout,"\n");
	BEGIN INITIAL;
	line_count++;
	

	} 
<INSIDE_STRING>"\\\"" {
	
	str+="\\\"";
	token_str+="\"";
	
	}
<INSIDE_STRING>"\\t" {
	
	str+="\\t";
	token_str+="\t";

	
	}
<INSIDE_STRING>"\\n" {
	
	str+="\\n";
	token_str+="\n";
	

	
	}
<INSIDE_STRING>"\\v" {

	str+="\\v";
	token_str+="\v";
	
	
	}
<INSIDE_STRING>"\\a" {
	
	str+="\\a";
	token_str+="\a";
	
	}
		
<INSIDE_STRING>"\\f" {
	
	str+="\\f";
	token_str+="\f";
	
	}
<INSIDE_STRING>"\\r" {
	
	str+="\\r";
	token_str+="\r";
	
	
	}
<INSIDE_STRING>"\\b" {
	
	str+="\\b";
	token_str+="\b";
	
	
	}

<INSIDE_STRING>"\\0" {
	
	str+="\\0";
	token_str+="\0";
	
	
	}
<INSIDE_STRING>"\\'" {
	
	str+="\\'";
	token_str+="\'";
	
	}
								
<INSIDE_STRING>"\\\n" {
	
	line_count++;
	str+="\\\n";
	}
	
<INSIDE_STRING>{NOT_NEWLINE} {
	
	
	str+=yytext;
	token_str+=yytext;
	
	
	}
	
	
"\/\/" {
	BEGIN INSIDE_SINGLE_LINE_COMMENT;
	fprintf(logout,"Line no %d: Token <COMMENT> Lexeme %s",line_count,yytext);
	
	}
<INSIDE_SINGLE_LINE_COMMENT>"\\\n" {
	line_count++;
	fprintf(logout,"%s",yytext);
	}
<INSIDE_SINGLE_LINE_COMMENT>{NEWLINE} {
	line_count++;
	BEGIN INITIAL;
	fprintf(logout," found\n");
	
	}
<INSIDE_SINGLE_LINE_COMMENT>. {
	fprintf(logout,"%s",yytext);
	
	}
	
"\/\*" {
	current_line=line_count;
	BEGIN INSIDE_MUL_LINE_COMMENT;
	
	str="\/\*";
	
	}
	
<INSIDE_MUL_LINE_COMMENT><<EOF>> {

	error_count++;
	fprintf(logout,"Error at line no %d:Unterminated Comment ",current_line);
	int len=str.size();
	for(int i=0;i<len;i++)
	{
		char sc=str[i];
		fprintf(logout,"%c",sc);
		
	}
	st.PrintAllScopeTable(logout);
	fprintf(logout,"Total lines: %d\n",line_count-1);
	fprintf(logout,"Total errors: %d\n",error_count);
	BEGIN INITIAL;
	return 0;
	}
<INSIDE_MUL_LINE_COMMENT>"\*\/" {
	str+="\*\/";
	fprintf(logout,"Line no %d: Token <COMMENT> Lexeme ",current_line);
	int len=str.size();
	for(int i=0;i<len;i++)
	{
		char sc=str[i];
		fprintf(logout,"%c",sc);
		
	}
	fprintf(logout," found\n");
	BEGIN INITIAL;
	}
<INSIDE_MUL_LINE_COMMENT>. {
	str+=yytext;
	
	}

<INSIDE_MUL_LINE_COMMENT>{NEWLINE} {
	str+="\n";
	line_count++;
	}
	
<<EOF>> {
	st.PrintAllScopeTable(logout);
	fprintf(logout,"Total lines: %d\n",line_count-1);
	fprintf(logout,"Total errors: %d\n",error_count);
	
	return 0;
	
	}
. {
	error_count++;
	fprintf(logout,"Error at line no %d:Unrecognized character %s \n",line_count,yytext);
	}
%%

int main(int argc,char *argv[]){

	if(argc!=2)
	{
		printf("Please provide input file name and try again\n");
		return 0;
	}
	FILE *fin=fopen(argv[1],"r");
	
	if(fin==NULL)
	{
		printf("Cannot open specified file\n");
		return 0;
	}
	
    	
	logout=fopen("1705116_log.txt","w");
	tokenout=fopen("1705116_token.txt","w");
	
	

	yyin=fin;
	yylex();
	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;

}
