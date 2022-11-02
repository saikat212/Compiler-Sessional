
%{
#include <stdio.h>
#include<iostream>
#include <stdlib.h>
#include<string>
#include<sstream>
#include<fstream>
#include<cstdlib>
#include<vector>

#include<algorithm>
#include <string.h>

#include "SymbolTable.h"



using namespace std;

int yylex(void);
int yyparse(void);

extern FILE* yyin;
FILE* input;
ofstream log_file;
ofstream error_file;

//ICG
ofstream code; // contains unoptimized assembly code
ofstream optimized_code; // contains optimized assembly code


SymbolTable st(30);
int error_count=0;
int line_count=1;
int scope_count=0;


/* auxiliary variables and structures and containers */

string type,type_final; // basially for function declaration-definition
string name,name_final; // basially for function declaration-definition

struct parameter
{
	string param_type;
	string param_name; // it is set to empty string "" for function declaration
}temp_parameter;

vector<parameter> param_list; // parameter list for function declaration, definition
vector<string> arg_list; // argument list for function call


struct var
{
	string var_name;
	int var_size; // it is set to -1 for variables
} temp_var;

vector<var> var_list; // for identifier(variable, array) insertion into symbolTable

//ICG
int label_count = 0; // they are for newly introduced functions
int temp_count = 0;

vector<string> data_list; //for all variables to be declared in data segment
bool can_be_defined = false; // for function definition (writing assembly codes)
vector<string> local_list; // for receiving arguments of a funtion
vector<string> temp_list; // for sending arguments to a funtion

/* auxiliary functions */
string insertVar(string _type,var var_in){
	 /* symbolTable insertion for variable and array */
	 SymbolInfo* symbolInfo=new SymbolInfo(var_in.var_name,"ID");
	 symbolInfo->set_Type(_type); // setting variable type
	 symbolInfo->set_arrSize(var_in.var_size);
	 
	 // additional for setting symbol
	 string str = var_in.var_name,temp;
	 stringstream ss;
	 ss << scope_count;
	 ss >> temp;
	 str += temp;
	 symbolInfo->setSymbol(str);
	 
	 if(var_in.var_size == -1){
	 	data_list.push_back(str+(string)" dw ?"); //variable
	 }
	 else{
	 	str += " dw ";
	 	ss.str("");
	 	ss.clear();
	 	ss << var_in.var_size;
	 	ss >> temp;
	 	str += temp;
	 	str += " dup (?)";
	 	data_list.push_back(str); //array
	 }
	 
	 
         st.insertSymbol_In_SymbolTable(*symbolInfo);
	 return str;
}

void insertFunc(string _type,string name,int _size)
{
    /*symbolTable insertion for function (declaration and definition)*/
    SymbolInfo* si=new SymbolInfo(name,"ID");
    si->set_Type(_type); // setting return type
    si->set_arrSize(_size); // Notice : for distinguishing between declaration and definition
    
    //ICG
    si->setSymbol(name); //setting symbol which will be used to call procedure in assembly code
    

    for(int i=0;i<param_list.size();i++)
    {
        si->addParam(param_list[i].param_type,param_list[i].param_name);

    }
    st.insertSymbol_In_SymbolTable(*si);
    return;

}


//ICG
string newLabel() {

	string str = "L",temp;
	stringstream ss;
	ss << label_count;
	ss >> temp;
	str += temp;
	label_count++;
	return str;
}

string newTemp() {
	string str = "t", temp;
	stringstream ss;
	ss << temp_count;
	ss >> temp;
	str += temp;
	temp_count++;
	return str;
}

void optimizeCode(string code)
{
    string temp ;
    stringstream ss(code);
    vector<string> tokens,tokens_1,tokens_2;

    while(getline(ss,temp,'\n'))
    {
        tokens.push_back(temp);
    }

    int op_line_count=tokens.size();

    for(int i=0;i<op_line_count;i++)
    {
        if(i == op_line_count-1)
        {
            optimized_code<< tokens[i] <<endl;
            continue;
        }

        if((tokens[i].length() < 4) ||(tokens[i+1].length() < 4 ) )
        {
            optimized_code << tokens[i] <<endl;
            continue;
        }

        if((tokens[i].substr(1,3) == "mov" ) && (tokens[i+1].substr(1,3) == "mov"))
        {
            stringstream ss_1(tokens[i]),ss_2(tokens[i+1]);
            while(getline(ss_1, temp, ' '))
            {
                tokens_1.push_back(temp);
            }


             while(getline(ss_2, temp, ' '))
            {
                tokens_2.push_back(temp);
            }

            //In this case, tokens_1 and tokens_2 have same  size that is same number of strings(3)

            if((tokens_1[1].substr(0, tokens_1[1].length()-1) == tokens_2[2]) && (tokens_2[1].substr(0, tokens_2[1].length()-1) == tokens_1[2])){
                optimized_code << tokens[i] <<endl;
                i++; // skipping next line as a part of optimization

            }
            else
            {
                optimized_code << tokens[i] <<endl;

            }

            tokens_1.clear();
            tokens_2.clear();


            

        } else {
            optimized_code << tokens[i] <<endl;
        }
    }

    tokens.clear();
    return;
}

//yyerror function for reporting syntax error
void yyerror(char*);

%}

%define api.value.type {SymbolInfo*}

%token CONST_INT CONST_FLOAT ID
%token INT FLOAT VOID IF ELSE FOR WHILE PRINTLN RETURN
%token ASSIGNOP NOT INCOP DECOP LOGICOP RELOP ADDOP MULOP
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE



%%
start : program {

	        $$ = new SymbolInfo("","NON_TERMINAL");
                log_file << "Line "<<(line_count-1)<<":start : program"<<"\n"<<endl;
       
             if(error_count == 0)
             {
       	//assembly code generation
       	
       	string assembly_code = "";
       	
       	assembly_code += (string)".model small\n.stack 100h\n.data\n\n";
       	
       	for(int i=0;i<data_list.size();i++) {
       	assembly_code += (string)"\t"+(string)data_list[i]+(string)"\n";
       	}
       	
       	data_list.clear();
       	
       	
       	//adding some extra variables
       	
       	assembly_code += (string)"\n\taddress dw 0\n\tdigit_num dw ?\n\tdivisor dw 10000\n\tis_zero_end db 0\n";
       	assembly_code += (string)"\n.code\n\n";
       	assembly_code += $1->getCode();
       	
       	
       	// println function

           assembly_code += (string)";println funtion:\nprintln proc\n\tpop address\n\tpop bx\n";

           assembly_code += (string)"\tcmp bx, 0\n\tjge continue_prog\n\tneg bx\n\tmov ah, 2\n\tmov dl, '-'\n\tint 21h\n\tcontinue_prog"+(string)":\n";

           assembly_code += (string)"\tmov ax, bx\n\txor dx, dx\n";

           assembly_code += (string)"\tfor_out"+(string)":\n\tdiv divisor\n\tmov digit_num, ax\n\tmov bx, dx\n";

           assembly_code += (string)"\tcmp digit_num, 0\n\tjne display\n\tcmp is_zero_end, 0\n\tjne display\n\tcmp divisor, 1\n\tjne continue\n";

           assembly_code += (string)"\tmov ah, 2\n\tmov dx, bx\n\tor dx, 30h\n\tint 21h\n\tjmp end_for_out\n";

           assembly_code += (string)"\tdisplay"+(string)":\n\tmov is_zero_end, 1\n\tmov ah, 2\n\tmov dx, digit_num\n\tor dx, 30h\n\tint 21h\n";

           assembly_code += (string)"\tcontinue"+(string)":\n\tmov digit_num, bx\n\tcmp divisor, 1\n\tje end_for_out\n";

           assembly_code += (string)"\tmov ax, divisor\n\txor dx, dx\n\tmov bx, 10\n\tdiv bx\n\tmov divisor, ax\n";

           assembly_code += (string)"\tmov ax, digit_num\n\txor dx, dx\n\tjmp for_out\n\tend_for_out"+(string)":\n";

           assembly_code += (string)"\tmov ah, 2\n\tmov dl, 0ah\n\tint 21h\n\tmov dl, 0dh\n\tint 21h\n\tmov divisor, 10000\n\tmov is_zero_end, 0\n";

           assembly_code += (string)"\tpush address\n\tret\nprintln endp\n\n";


           assembly_code += (string)"end main";



           $$->setCode(assembly_code);

           code << $$->getCode() << endl;

           optimizeCode($$->getCode());


        
       	
       	
       } else {

       }
       //deletion 
       
       delete $1;
       

	}
	;
program : program unit
        {
             //$$ = new SymbolInfo((string)$1->getname()+(string)$2->getname(),"NON_TERMINAL");
            $$ = new SymbolInfo("", "NON_TERMINAL");

            $$->setCode($1->getCode()+$2->getCode());
            
            
            log_file << "Line "<<line_count<<": program : program unit"<<"\n"<<endl;
            //log_file<<(string)$1->getname()+(string)$2->getname()<<"\n"<<endl;

            //deletion
            delete $1;
            
            delete $2;



            
        }
        | unit
        {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            $$->setCode($1->getCode());
            
            log_file << "Line "<<line_count<<": program : unit"<<"\n"<<endl;
            //log_file<<$1->getname()<<"\n"<<endl;
            

            delete $1;
            
	}
	   
	 

	;

unit : var_declaration

	{
	   //$$ = new SymbolInfo((string)$1->getname(),"NON_TERMINAL");
       $$ = new SymbolInfo("", "NON_TERMINAL");
       

       log_file << "Line "<<line_count<<": unit : var_declaration"<<"\n"<<endl;
       //log_file<<$1->getname()<<endl;
       
       delete $1;
       }
    |func_declaration
    {
      //$$ = new SymbolInfo((string)$1->getname(),"NON_TERMINAL");
      $$ = new SymbolInfo("", "NON_TERMINAL");

     

       log_file << "Line "<<line_count<<": unit : func_declaration"<<endl;
       //log_file<<$1->getname()<<"\n"<<endl;
       delete $1;

    }
    |func_definition
    {
       //$$ = new SymbolInfo((string)$1->getname(),"NON_TERMINAL");

       $$ = new SymbolInfo("", "NON_TERMINAL");

       $$->setCode(";func_definition#\n"+$1->getCode());


       


       log_file << "Line "<<line_count<<": unit : func_definition"<<"\n"<<endl;
       //log_file<<$1->getname()<<"\n"<<endl;
       
       delete $1;
    }

     ;

func_declaration: type_specifier id embedded LPAREN parameter_list RPAREN embedded_out_dec SEMICOLON
    {
        //$$ = new SymbolInfo((string)$1->getname()+(string)" "+(string)$2->getname()+(string)"("+(string)$5->getname()+(string)")"+(string)";"+(string)"\n","NON_TERMINAL");

        $$ = new SymbolInfo("", "NON_TERMINAL");
        
	    log_file << "Line "<<line_count<<": func_declaration: type_specifier ID LPAREN parameter_list RPAREN  SEMICOLON"<<"\n"<<endl;
        //log_file <<(string)$1->getname()+(string)" "+(string)$2->getname()+(string)"("+(string)$5->getname()+(string)")"+(string)";"<<"\n"<<endl;

        //clearing param_list
        param_list.clear();

        delete $1;

        delete $2;

        delete $5;

    }
    |type_specifier id embedded LPAREN RPAREN embedded_out_dec SEMICOLON
    {
        string tp=(string)$1->getname()+(string)" "+(string)$2->getname()+(string)"("+(string)")"+(string)";"+(string)"\n";
        //$$ = new SymbolInfo(tp,"NON_TERMINAL");
        
	    log_file << "Line "<<line_count<<":func_declaration: type_specifier ID LPAREN RPAREN  SEMICOLON"<<"\n"<<endl;
        //log_file <<(string)$1->getname()+(string)" "+(string)$2->getname()+(string)"("+(string)")"+(string)";"<<"\n"<<endl;

        $$ = new SymbolInfo("", "NON_TERMINAL");

        //clearing param_list
        param_list.clear();

        delete $1;
        delete $1;

    }
    ;
func_definition :type_specifier id embedded LPAREN parameter_list RPAREN embedded_out_def compound_statement 

    {
        //$$ = new SymbolInfo((string)$1->getname()+(string)" "+(string)$2->getname()+(string)"("+(string)$5->getname()+(string)")"+(string)$8->getname()+(string)"\n","NON_TERMINAL");
        
	   log_file << "Line "<<line_count<<": func_definition :  type_specifier ID LPAREN parameter_list RPAREN compound_statement"<<"\n"<<endl;
       //log_file <<(string)$1->getname()+(string)" "+(string)$2->getname()+(string)"("+(string)$5->getname()+(string)")"+(string)$8->getname()<<"\n"<<endl;

       $$ = new SymbolInfo("", "NON_TERMINAL");

       //code setting

       string temp = "";
      
      // 30 tarikh 
       if(($2->getname() == "main" ) && (can_be_defined == true) )
       {
           temp += (string)"main proc\n\tmov ax, @data\n\tmov ds ,ax\n\n";

           temp += $8->getCode();

           temp += (string)"\n\n\tmov ah, 4ch\n\tint 21h\nmain endp\n\n";

           can_be_defined = false; //NOTICE

       }
       else
       {
           if(can_be_defined == true)
           {
               temp += $2->getname()+(string)" proc\n\tpop address\n";


               for(int i=(local_list.size()-1);i>=0;i--)
               {
                   temp += (string)"\tpop "+local_list[i]+(string)"\n";
               }

               temp += $8->getCode();

               temp += (string)"\tpush address\n\tret\n";

               temp += $2->getname()+(string)" endp\n\n";

           }

           can_be_defined = false; //NOTICE

           
       }

       $$->setCode(temp);
       local_list.clear();

       delete $1;
       delete $2;
       delete $5;
       delete $8;

    }

    |type_specifier id embedded LPAREN RPAREN embedded_out_def compound_statement
    {
        //string tp=(string)$1->getname()+(string)" "+(string)$2->getname()+(string)"("+(string)")"+(string)$7->getname()+(string)"\n";
       // $$ = new SymbolInfo(tp,"NON_TERMINAL");
        
	    log_file << "Line "<<line_count<<": func_definition :  type_specifier ID LPAREN RPAREN compound_statement"<<"\n"<<endl;
        //log_file <<(string)$1->getname()+(string)" "+(string)$2->getname()+(string)"("+(string)")"+(string)$7->getname()<<"\n"<<endl;

         $$ = new SymbolInfo("","NON_TERMINAL");

         // code setting

         string temp = "";

         if(($2->getname() == "main") && (can_be_defined == true))
         {
             temp += (string)"main proc\n\tmov ax, @data\n\tmov ds ,ax\n\n";
             
             temp += $7->getCode();

             temp += (string)"\n\n\tmov ah, 4ch\n\tint 21h\nmain endp\n\n";



             can_be_defined = false; 
         }
         else
         {
             if(can_be_defined == true )
             {
                 temp += $2->getname()+(string)" proc\n\tpop address\n";



                 for(int i=(local_list.size()-1) ; i>=0 ;i--)
                 {
                     temp += (string)"\tpop "+local_list[i]+(string)"\n";
                 }


                 temp += $7->getCode();


                 temp += (string)"\tpush address\n\tret\n";

                 temp += $2->getname()+(string)" endp\n\n";


             }

             can_be_defined = false;

         }

         $$->setCode(temp);

         local_list.clear();


        delete $1;

        delete $2;

        delete $7;

    }
    ;
embedded:
    {
        type_final=type;
        name_final=name;
    }
    ;
embedded_out_dec:
    {
        SymbolInfo* temp=st.LookUp_At_All_SymbolTable(name_final);
        if(temp != NULL)
        {
            error_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<name_final <<"\n"<<endl;
           log_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<name_final  <<"\n"<<endl;
            error_count++;

    
        }
        else
        {
            //inserting function declaration in symbolTable
            insertFunc(type_final,name_final,-2);
        }
    }
    ;
embedded_out_def:
    {
        SymbolInfo* temp=st.LookUp_At_All_SymbolTable(name_final);
        if(temp == NULL)
        {
            //inserting function definition in symbolTable
            insertFunc(type_final,name_final,-3);

            //ICG
            can_be_defined = true;

        }
        else if(temp->get_arrSize() != -2)

        {
            //function declaration not found
            error_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<name_final <<"\n"<<endl;
            log_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<name_final  <<"\n"<<endl;
            error_count++;

        }
        else
        {
            //function declaration with similar name found 
            // further checking

            if(temp->get_Type() != type_final)
            {
                //return type not mathching
                error_file<<"Error at line  "<<line_count<<": Return type mismatch with function declaration in function  "<<name_final <<"\n"<<endl;
                log_file<<"Error at line  "<<line_count<<": Return type mismatch with function declaration in function "<<name_final  <<"\n"<<endl;
                error_count++;

            }
            else if(temp->get_paramSize() == 1 && param_list.size() == 0 && temp->getParam(0).param_type == "void")
            {
                //parameter list matched
                temp->set_arrSize(-3); //given function declaration has a matching definition ,so it can be called

                can_be_defined = true;


            }
            else if(temp->get_paramSize() == 0 && param_list.size() == 1 && param_list[0].param_type == "void")
            {
                //parameter list matched
                temp->set_arrSize(-3); //given function declaration has a matching definition ,so it can be called

                can_be_defined = true;


            }
            else if(temp->get_paramSize() != param_list.size())
            {
                //parameter list size not matching

                error_file<<"Error at line  "<<line_count<<": Total number of arguments mismatch with declaration in function "<<name_final <<"\n"<<endl;
                log_file<<"Error at line  "<<line_count<<": Total number of arguments mismatch with declaration in function "<<name_final  <<"\n"<<endl;
                error_count++;

            }
            else
            {
                //cheking parameter type
                int i;
                for(i=0;i<param_list.size();i++) //EC
                {
                    if(temp->getParam(i).param_type != param_list[i].param_type)
                    {
                        break;
                    }
                }
                if(i==param_list.size())
                {
                    //parameter list matched
                    temp->set_arrSize(-3); //given function declaration has a matching definition , so it can be called 

                    can_be_defined = true;
                }
                else
                {
                    //parameter list not matched
                    error_file<<"Error at line  "<<line_count<<": Total number of arguments mismatch with declaration in function  "<<name_final <<"\n"<<endl;
                    log_file<<"Error at line  "<<line_count<<": Total number of arguments mismatch with declaration in function "<<name_final  <<"\n"<<endl;
                    error_count++;

                }

            }
        }
    }
    ;
parameter_list: parameter_list COMMA type_specifier id
    {
       //string tp1=(string)$1->getname()+(string)","+(string)$3->getname()+(string)" "+(string)$4->getname();
       //$$ = new SymbolInfo(tp1,"NON_TERMINAL");

    

      // added 6 june 

       //extra added 
       
       for(int i=0;i<param_list.size();i++)
    {
      if(param_list[i].param_name == (string)$4->getname())
        {
        	   error_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<(string)$4->getname()<<" in parameter"<<"\n"<<endl;
                  log_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<(string)$4->getname()<<" in parameter"<<"\n"<<endl;
                    error_count++;
                    break;

        }
        

    }
    
       log_file << "Line "<<line_count<<": parameter_list : parameter_list COMMA type_specifier ID"<<"\n"<<endl;
      //log_file<<tp1<<"\n"<<endl; 

      //upto here





        $$ = new SymbolInfo("","NON_TERMINAL");


       //adding parameter to parameter list

       temp_parameter.param_type=(string)$3->getname();

       temp_parameter.param_name=(string)$4->getname();

       param_list.push_back(temp_parameter);


       delete $1;

       delete $3;

       delete $4;


       
    }
    | parameter_list COMMA type_specifier
    {
       //string tp1=(string)$1->getname()+(string)","+(string)$3->getname();
       //$$ = new SymbolInfo(tp1,"NON_TERMINAL");


       log_file << "Line "<<line_count<<": parameter_list : parameter_list COMMA type_specifier"<<"\n"<<endl;
      //log_file<<tp1<<"\n"<<endl; 

       $$ = new SymbolInfo("","NON_TERMINAL");


       //adding parameter to parameter list

       temp_parameter.param_type=(string)$3->getname();

       temp_parameter.param_name = "";

       param_list.push_back(temp_parameter);

       delete $1;

       delete $3;

    }
    |type_specifier id
    {
      //string tp1=(string)$1->getname()+(string)" "+(string)$2->getname();
      // $$ = new SymbolInfo(tp1,"NON_TERMINAL");


       log_file << "Line "<<line_count<<": parameter_list : type_specifier ID"<<"\n"<<endl;
       //log_file<<tp1<<"\n"<<endl;          
       

        $$ = new SymbolInfo("","NON_TERMINAL");

       //adding parameter to parameter list

       temp_parameter.param_type=(string)$1->getname();

       temp_parameter.param_name = (string)$2->getname();

       param_list.push_back(temp_parameter);

       delete $1;

       delete $2;

    }
    |type_specifier
    {
       //string tp1=(string)$1->getname();
      // $$ = new SymbolInfo(tp1,"NON_TERMINAL");


       log_file << "Line "<<line_count<<": parameter_list : type_specifier"<<"\n"<<endl;
       //log_file<<tp1<<"\n"<<endl;           

        $$ = new SymbolInfo("","NON_TERMINAL");

       //adding parameter to parameter list

       temp_parameter.param_type=(string)$1->getname();

       temp_parameter.param_name = "";

       param_list.push_back(temp_parameter);

       delete $1;
    }
    ;

compound_statement:LCURL embedded_in statements RCURL //embedded_in
    {
      //string tp1=(string)"{"+(string)"\n"+(string)$3->getname()+(string)"}"+(string)"\n";
      // $$ = new SymbolInfo(tp1,"NON_TERMINAL");


      log_file << "Line "<<line_count<<": compound_statement : LCURL statements RCURL"<<"\n"<<endl;
      //log_file<<tp1<<"\n"<<endl;  

      // st.PrintAllScopeTable(log_file);

       $$ = new SymbolInfo("","NON_TERMINAL");

       $$->setCode($3->getCode());

       st.ExitScope(log_file);

       delete $3;


    }
    |LCURL embedded_in RCURL
    {
       //string tp1=(string)"{"+(string)"\n"+(string)"\n"+(string)"}"+(string)"\n";
       //$$ = new SymbolInfo(tp1,"NON_TERMINAL");


       log_file << "Line "<<line_count<<": compound_statement : LCURL RCURL"<<"\n"<<endl;
       //log_file<<(string)"{"+(string)"}"<<"\n"<<endl;  

        $$ = new SymbolInfo("","NON_TERMINAL");

       //st.PrintAllScopeTable(log_file);
       st.ExitScope(log_file);
    }
    ;
embedded_in:
{
    st.EnterScope(log_file);
    scope_count++;

    //add parameter (if exists) to symboltable
    if(param_list.size() == 1 && param_list[0].param_type == "void")
    {
        //only parameter is void
    }
    else
    {
        for(int i=0;i<param_list.size();i++)
        {
            temp_var.var_name=param_list[i].param_name;
            temp_var.var_size=-1;
            // insertVar(param_list[i].param_type,temp_var);
            local_list.push_back(insertVar(param_list[i].param_type, temp_var));

        }
    }
    param_list.clear();
}
;
var_declaration : type_specifier declaration_list SEMICOLON
		{   
           // $$ = new SymbolInfo((string)$1->getname()+(string)" "+(string)$2->getname()+(string)";"+(string)"\n"+(string)"\n","NON_TERMINAL");
        
	        log_file << "Line "<<line_count<<": var_declaration : type_specifier declaration_list SEMICOLON"<<"\n"<<endl;
            
            $$ = new SymbolInfo("","NON_TERMINAL");

            string garbage;


            //symboltable insertion

            if($1->getname() == "void")
            { 
                 error_file<<"Error at line  "<<line_count<<": Variable type can not be void " <<"\n"<<endl;
                 log_file<<"Error at line  "<<line_count<<": Variable type can not be void " <<"\n"<<endl;
                 error_count++;

                 for (int i=0;i<var_list.size();i++)
                 {
                     insertVar("int",var_list[i]); //by default ,void type variable are float type
                 }

            }
            else
            {
                 for (int i=0;i<var_list.size();i++)
                 {
                   garbage = insertVar((string)$1->getname(),var_list[i]);
                 }
            }
            var_list.clear();
           //log_file <<(string)$1->getname()+(string)" "+(string)$2->getname()+(string)";"<<"\n"<<endl;

           delete $1;

           delete $2;

            
	    }
	    

 		 ;



type_specifier	: INT {

               $$=new SymbolInfo("int","NON_TERMINAL");

               
                log_file << "Line "<<line_count<<": type_specifier : INT"<<"\n"<<endl;
                //log_file<<"int"<<"\n"<<endl;
                type="int";


    }

 		| FLOAT {
 		$$=new SymbolInfo("float","NON_TERMINAL");
               log_file << "Line "<<line_count<<": type_specifier : FLOAT"<<"\n"<<endl;
               //log_file<<"float"<<"\n"<<endl;
               type="float";
               


 		}

 		| VOID {
 		    $$=new SymbolInfo("void","NON_TERMINAL");
             log_file << "Line "<<line_count<<": type_specifier : VOID"<<"\n"<<endl;
              //log_file<<"void"<<"\n"<<endl;
              type="void";
              


 		}

 		;


id:ID {
       

	$$ = new SymbolInfo((string)$1->getname(),"NON_TERMINAL");
	name =  $1->getname();

    delete $1;

	}
	;
declaration_list : declaration_list COMMA id
    {
       //$$ = new SymbolInfo((string)$1->getname()+(string)","+(string)$3->getname(),"NON_TERMINAL");
        
        $$ = new SymbolInfo("","NON_TERMINAL");
       
       
       //keeping track of indentifier(variable)
       temp_var.var_name=(string)$3->getname();
       temp_var.var_size=-1;
       var_list.push_back(temp_var);

       // cheking whether already declared or not

       SymbolInfo* temp=st.LookUp_At_SymbolTable($3->getname());
       
       if(temp != NULL)
       {
          
          
          error_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<$3->getname()<<"\n"<<endl;
           log_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<$3->getname()<<"\n"<<endl;
           error_count++;
       }
       else
       {
       	//error_file<<"temp is null value"<<"\n"<<endl;
       }
       
       log_file << "Line "<<line_count<<": declaration_list : declaration_list COMMA ID"<<"\n"<<endl;
       //log_file<<(string)$1->getname()+(string)","+(string)$3->getname()<<"\n"<<endl;

       delete $1;

       delete $3;

       
    }
    
    
    |declaration_list COMMA id LTHIRD CONST_INT RTHIRD

    {
        //array
      //string tp=(string)$1->getname()+(string)","+(string)$3->getname()+(string)"["+(string)$5->getname()+(string)"]";

       //$$ = new SymbolInfo(tp,"NON_TERMINAL");

       $$ = new SymbolInfo("","NON_TERMINAL");
       
       
       //keeping track of indentifier(array)

       temp_var.var_name=(string)$3->getname();
       stringstream temp_str((string)$5->getname());
       temp_str >>temp_var.var_size;
       var_list.push_back(temp_var);

       // cheking whether already declared or not

       SymbolInfo* temp=st.LookUp_At_SymbolTable($3->getname());
       
       if(temp != NULL)
       {
           
           
           error_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<$3->getname()<<"\n"<<endl;
           log_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<$3->getname()<<"\n"<<endl;
           error_count++;
       }
       
       log_file << "Line "<<line_count<<": declaration_list :declaration_list COMMA ID LTHIRD CONST_INT RTHIRD"<<"\n"<<endl;
       //log_file<<tp<<"\n"<<endl;

       delete $1;

       delete $3;

       delete $5;


    }
    
    
    
    |id
	{
       $$ = new SymbolInfo((string)$1->getname(),"NON_TERMINAL");

       
       
       //keeping track of indentifier(variable)
       temp_var.var_name=(string)$1->getname();
       temp_var.var_size=-1;
       var_list.push_back(temp_var);

       // cheking whether already declared or not
     
       SymbolInfo* temp=st.LookUp_At_SymbolTable($1->getname());
       
       if(temp != NULL)
       {
           error_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<$1->getname()<<"\n"<<endl;
           log_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<$1->getname()<<"\n"<<endl;
           error_count++;
          
      
       }
       log_file << "Line "<<line_count<<": declaration_list : ID"<<"\n"<<endl;
      //log_file<<$1->getname()<<"\n"<<endl;

      delete $1;
      
}
    
    |id LTHIRD CONST_INT RTHIRD
    {
        //string tp=(string)$1->getname()+(string)"["+(string)$3->getname()+(string)"]";

      // $$ = new SymbolInfo(tp,"NON_TERMINAL");


        $$ = new SymbolInfo((string)$1->getname(),"NON_TERMINAL");
       
       //keeping track of indentifier(array)

       temp_var.var_name=(string)$1->getname();
       stringstream temp_str((string)$3->getname());
       temp_str >>temp_var.var_size;
       var_list.push_back(temp_var);

       // cheking whether already declared or not

       SymbolInfo* temp=st.LookUp_At_SymbolTable($1->getname());
       
       if(temp != NULL)
       {
           error_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<$1->getname()<<"\n"<<endl;
           log_file<<"Error at line  "<<line_count<<": Multiple declaration of "<<$1->getname()<<"\n"<<endl;
           error_count++;
       }
       
       log_file << "Line "<<line_count<<": declaration_list : ID LTHIRD CONST_INT RTHIRD"<<"\n"<<endl;
       //log_file<<tp<<"\n"<<endl;

       delete $1;

       delete $3;

       
    }

    ;
statements: statement
{
    //$$ = new SymbolInfo((string)$1->getname(),"NON_TERMINAL");


   log_file << "Line "<<line_count<<": statements : statement"<<"\n"<<endl;
   //log_file<<$1->getname()<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    $$->setCode($1->getCode());

    delete $1;

}
|statements statement
{
    //$$ = new SymbolInfo((string)$1->getname()+(string)$2->getname(),"NON_TERMINAL");

    log_file << "Line "<<line_count<<": statements : statements statement"<<"\n"<<endl;
    //log_file<<(string)$1->getname()+(string)$2->getname()<<"\n"<<endl;

      $$ = new SymbolInfo("","NON_TERMINAL");

      $$->setCode($1->getCode()+$2->getCode());

      delete $1;

      delete $2;

}
;
statement:var_declaration
{
    //$$ = new SymbolInfo((string)$1->getname(),"NON_TERMINAL");

    log_file << "Line "<<line_count<<": statement : var_declaration"<<"\n"<<endl;
    //log_file<<$1->getname()<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    delete $1;

}
|expression_statement
{
    //$$ = new SymbolInfo((string)$1->getname(),"NON_TERMINAL");

    log_file << "Line "<<line_count<<": statement : expression_statement"<<"\n"<<endl;
    //log_file<<(string)$1->getname()<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    $$->setCode(";expression_statement\n"+$1->getCode());

    delete $1;

}
|compound_statement
{
   // $$ = new SymbolInfo((string)$1->getname()+(string)"\n","NON_TERMINAL");

   log_file << "Line "<<line_count<<": statement : compound_statement"<<"\n"<<endl;
   //log_file<<(string)$1->getname()<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    $$->setCode($1->getCode());

    delete $1;

}
|FOR LPAREN expression_statement embedded_exp embedded_void expression_statement embedded_exp embedded_void expression embedded_exp embedded_void RPAREN statement
{
    //solution: for this loop,the output in log will be a bit distorted for adding +(string)"\n" in expression_statement
    //string str3=(string)$3->getname();
    //str3.erase(remove(str3.begin(), str3.end(), '\n'),str3.end());
    
    //string str6=(string)$6->getname();
   //str6.erase(remove(str6.begin(), str6.end(), '\n'),str6.end());
    
    
    
    //string tp=(string)"for"+(string)"("+str3+str6+(string)$9->getname()+(string)")"+(string)$13->getname()+(string)"\n";
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": statement : FOR LPAREN expression_statement  expression_statement  expression  RPAREN statement"<<"\n"<<endl;
   //log_file<<tp<<endl;
   $$ = new SymbolInfo("","NON_TERMINAL");

   //code setting 

   if(($3->getSymbol() != ";") && ($6->getSymbol() !=";")) {

       string label1 = newLabel();

       string label2 = newLabel();


       $$->setCode(";For Loop\n"+$3->getCode());

       $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n"+$6->getCode()+(string)"\tmov ax, "+$6->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label2+(string)"\n");
       $$->setCode($$->getCode()+$13->getCode()+$9->getCode()+(string)"\tjmp "+label1+(string)"\n\t"+label2+(string)":\n");
   }

   delete $3;

   delete $6;

   delete $9;

   delete $13;


}
|IF LPAREN expression embedded_exp RPAREN embedded_void statement %prec LOWER_THAN_ELSE
{
    //conflict
   //string tp=(string)"if"+(string)"("+(string)$3->getname()+(string)")"+(string)$7->getname()+(string)"\n";
   // $$ = new SymbolInfo(tp,"NON_TERMINAL");
   log_file << "Line "<<line_count<<": statement : IF LPAREN expression  RPAREN  statement"<<"\n"<<endl;
   //log_file<<tp<<endl;

     $$ = new SymbolInfo("","NON_TERMINAL");

     string label = newLabel();

     $$->setCode(";IF condition\n"+$3->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label+(string)"\n"+$7->getCode()+(string)"\t"+label+(string)":\n");

     delete $3;
     delete $7;

}
|IF LPAREN expression embedded_exp RPAREN embedded_void statement ELSE statement
{
    //conflict
    //string tp=(string)"if"+(string)"("+(string)$3->getname()+(string)")"+(string)$7->getname()+(string)"else"+(string)"\n"+(string)$9->getname()+(string)"\n";
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": statement : IF LPAREN expression RPAREN statement ELSE statement"<<"\n"<<endl;
    //log_file<<tp<<endl;

     $$ = new SymbolInfo("","NON_TERMINAL");

     //code setting

     string label1 = newLabel();

     string label2 = newLabel();

     $$->setCode(";IF condition\n"+$3->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label1+(string)"\n"+$7->getCode()+(string)"\tjmp "+label2+(string)"\n");

     $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n"+$9->getCode()+(string)"\t"+label2+(string)":\n");


     delete $3;

     delete $7;

     delete $9;




}
|WHILE LPAREN expression embedded_exp RPAREN embedded_void statement
{
    //string tp=(string)"while"+(string)"("+(string)$3->getname()+(string)")"+(string)$7->getname()+(string)"\n";
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
   log_file << "Line "<<line_count<<": statement : WHILE LPAREN expression  RPAREN  statement"<<"\n"<<endl;
    //log_file<<tp<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    //code setting

    string label1 = newLabel();

    string label2 = newLabel();

    $$->setCode(";while condition\n"+(string)"\t"+label1+(string)":\n"+$3->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label2+(string)"\n");

    $$->setCode($$->getCode()+$7->getCode()+(string)"\tjmp "+label1+(string)"\n\t"+label2+(string)":\n");

    delete $3;

    delete $7;

}
|PRINTLN LPAREN id RPAREN SEMICOLON
{
    //string tp=(string)"printf"+(string)"("+(string)$3->getname()+(string)")"+(string)";"+(string)"\n";
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": statement : PRINTLN LPAREN ID RPAREN SEMICOLON"<<"\n"<<endl;
    
    $$ = new SymbolInfo("","NON_TERMINAL");
    
    //new added june 4
    SymbolInfo* temp=st.LookUp_At_All_SymbolTable($3->getname());

    string input_var ; //symbol/variable in assembly code


       
       if(temp == NULL)
       {
           //error_file<<"Error at line  "<<line_count<<":Undeclared variable  "<<$3->getname()<<"\n"<<endl;
           //log_file<<"Error at line  "<<line_count<<":Undeclared variable  "<<$3->getname()<<"\n"<<endl;
           error_file<<"Error at line  "<<line_count<<":Undeclared variable  "<<endl;
           log_file<<"Error at line  "<<line_count<<":Undeclared variable  "<<endl;
           error_count++;
        

           //$$->set_Type("float"); // by default , undeclared variables are of float type
           //$$->set_Type("int"); // by default , undeclared variables are of float type

           input_var = ""; //no id available

       }
       else
       {
           if(temp->get_Type() != "void")
           {
               input_var = temp->getSymbol();
           }
           else
           {
               input_var = ""; //no id available 
           }
       }
       
      //log_file<<tp<<endl;

       //checking whether it is actually variable or not

       if((temp != NULL) && (temp->get_arrSize() != -1))
       {
           error_count++;
           input_var = ""; //no id available
       }

       //building code part

       $$->setCode(";invoking println\n"+(string)"\tpush ax\n\tpush bx\n\tpush address\n\tpush "+input_var+(string)"\n\tcall println\n\tpop address\n\tpop bx\n\tpop ax\n");

       delete $3;
    
}
|RETURN expression SEMICOLON
{
    //string tp=(string)"return "+(string)$2->getname()+(string)";"+(string)"\n";
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": statement : RETURN expression SEMICOLON"<<"\n"<<endl;
    //log_file<<tp<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");
    
    //void checking -> can not return void expression here
    if($2->get_Type() == "void")
    {
        //void function call within expression

        error_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
        log_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
        error_count++;
        //type setting if necessary
    }

    //code setting

    $$->setCode($2->getCode()+(string)"\tpush "+$2->getSymbol()+(string)"\n"); //ret instruction will be written in func_def

    delete $2;


}

;
embedded_exp:
{
    type_final=type;


} 		  
;
embedded_void:
{
    //void checking 
    if(type_final == "void")
    {
        //void function call within expression 

         error_file<<"Error at line  "<<line_count<<": Void function called within expression"<<"\n"<<endl;
         log_file<<"Error at line  "<<line_count<<": Void function called within expression"<<"\n"<<endl;
         error_count++;
         //type setting if necessary

    }
}
;
expression_statement: SEMICOLON
{
    //string tp=(string)";"+(string)"\n";
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": expression_statement : SEMICOLON"<<"\n"<<endl;
    //log_file<<tp<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");
    //type setting 
    $$->set_Type("int"); 
    type="int";

    //symbol setting

    $$->setSymbol(";"); //will be used in for loop

}
|expression SEMICOLON
{
   //string tp=(string)$1->getname()+(string)";"+(string)"\n";
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
   log_file << "Line "<<line_count<<": expression_statement : expression SEMICOLON"<<"\n"<<endl;
    //log_file<<tp<<endl;
    //type setting 
    $$ = new SymbolInfo("","NON_TERMINAL");
    $$->set_Type($1->get_Type()); 
    type=$1->get_Type();

    //symbol and code setting

    $$->setSymbol($1->getSymbol());
    $$->setCode($1->getCode());

    delete $1;

}

;

variable:id
{
   //string tp=(string)$1->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": variable : ID"<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");
    
    //declaration checking & type setting 

    SymbolInfo* temp=st.LookUp_At_All_SymbolTable($1->getname());
       
       if(temp == NULL)
       {
           //error_file<<"Error at line  "<<line_count<<": Undeclared variable  "<<$1->getname()<<"\n"<<endl;
           //log_file<<"Error at line  "<<line_count<<": Undeclared variable  "<<$1->getname()<<"\n"<<endl;
           
           error_file<<"Error at line  "<<line_count<<": Undeclared variable  "<<endl;
           log_file<<"Error at line  "<<line_count<<": Undeclared variable  "<<endl;
           error_count++;

           //$$->set_Type("float"); // by default , undeclared variables are of float type
           
           $$->set_Type("int"); // by default , undeclared variables are of float type
         
           $$->set_arrSize(-1);

           //ICG was used 
           //$$->set_Type("float");

       }
       else
       {

            $$->set_arrSize(-1);

           if(temp->get_Type() != "void")
           {
               $$->set_Type(temp->get_Type());

               $$->setSymbol(temp->getSymbol());
           }
           else
           {
               $$->set_Type("int"); //matching function found with return type void
               //$$->set_Type("float"); // by default , undeclared variables are of float type
           }
       }
       // cheking whether it is id or not 
       if((temp != NULL)&&(temp->get_arrSize()!=-1))
       {
           //error_file<<"Error at line  "<<line_count<<": Type mismatch,"<<$1->getname()<< " is an array "<<"\n"<<endl;
           //log_file<<"Error at line  "<<line_count<<": Type mismatch,"<<$1->getname()<< " is an array "<<"\n"<<endl;
           
           error_file<<"Error at line  "<<line_count<<": Type mismatch"<<endl;
           log_file<<"Error at line  "<<line_count<<": Type mismatch"<<endl;
           error_count++;
       }
      //log_file<<tp<<"\n"<<endl;

       delete $1;

}
|id LTHIRD expression RTHIRD
{
    //array
    //string tp=(string)$1->getname()+(string)"["+(string)$3->getname()+(string)"]";
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": variable : ID LTHIRD expression RTHIRD"<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");
    
    //declaration checking and type setting
    SymbolInfo* temp=st.LookUp_At_All_SymbolTable($1->getname());
       
       if(temp == NULL)
       {
          //error_file<<"Error at line  "<<line_count<<": Undeclared variable  "<<$1->getname()<<"\n"<<endl;
          //log_file<<"Error at line  "<<line_count<<": Undeclared variable  "<<$1->getname()<<"\n"<<endl;
          
          error_file<<"Error at line  "<<line_count<<": Undeclared variable  "<<endl;
          log_file<<"Error at line  "<<line_count<<": Undeclared variable  "<<endl;
           error_count++;

           $$->set_Type("int"); // by default , undeclared variables are of float type


           //ICG
           $$->set_arrSize(0);

           

       }
       else
       {
           if(temp->get_Type() != "void")
           {
               $$->set_Type(temp->get_Type());

               //ICG
               $$->set_arrSize(temp->get_arrSize());

               $$->setSymbol(temp->getSymbol());

           }
           else
           {
               $$->set_Type("int"); //matching function found with return type void

               //ICG
                $$->set_arrSize(0);
           }
       }

       // cheking whether it is array or not 
       if((temp != NULL)&&(temp->get_arrSize() <= -1)) //EC
       {
         //error_file<<"Error at line  "<<line_count<<": "<<$1->getname()<<" not an array "<<"\n"<<endl;
         //log_file<<"Error at line  "<<line_count<<": "<<$1->getname()<<" not an array "<<"\n"<<endl;
         
         error_file<<"Error at line  "<<line_count<<":  not an array "<<"\n"<<endl;
         log_file<<"Error at line  "<<line_count<<":  not an array "<<"\n"<<endl;
           error_count++;


           //ICG
           $$->set_arrSize(0);
           $$->setSymbol("");
       }

        //semantic analysis (array index checking)

        if($3->get_Type() != "int")
        {
            //non integer (floating point) index for array
          error_file<<"Error at line  "<<line_count<<": Expression inside third brackets not an integer "<<"\n"<<endl;
           log_file<<"Error at line  "<<line_count<<": Expression inside third brackets not an integer "<<"\n"<<endl;
           error_count++;
        }
        //void checking
        if($3->get_Type() == "void") //EC
        {
            //void function call within expression
         error_file<<"Error at line  "<<line_count<<": Void function used in expression"<<"\n"<<endl;
          log_file<<"Error at line  "<<line_count<<": VVoid function used in expression"<<"\n"<<endl;
           error_count++;
           //type setting if necessary
        }
        
        
        //log_file<<tp<<"\n"<<endl;

        //symbol and code setting 

        $$->setCode($3->getCode()+(string)"\tmov bx, "+$3->getSymbol()+(string)"\n\t"+(string)"add bx, bx"+(string)"\n");

        delete $1;

        delete $3;

}
;

expression: logic_expression
{
   //string tp=(string)$1->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": expression : logic expression"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    //type setting -> NOTICE: semantic analysis might be required -> think about void function

     $$ = new SymbolInfo("","NON_TERMINAL");

    $$->set_Type($1->get_Type()); 
    type=$1->get_Type();

    //symbol and code setting

    $$->setSymbol($1->getSymbol());

    $$->setCode($1->getCode());

    delete $1;


}
|variable ASSIGNOP logic_expression
{
    //string tp=(string)$1->getname()+(string)"="+(string)$3->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": expression : variable ASSIGNOP logic_expression"<<"\n"<<endl;
    
     $$ = new SymbolInfo("","NON_TERMINAL");

    //void checking
    if($3->get_Type() == "void") //EC
        {
            //void function call within expression
           error_file<<"Error at line  "<<line_count<<":Void function used in expression "<<"\n"<<endl;
          log_file<<"Error at line  "<<line_count<<":Void function used in expression "<<"\n"<<endl;
           error_count++;
           //type setting if necessary

           $3->set_Type("int"); //by default , float type is understand

        }
    //checking type consistency
    if((($1->get_Type() != $3->get_Type()) && ($1->get_Type() != "float") && ($3->get_Type() != "int") ))  // newly added 4 june
    {
       error_file<<"Error at line  "<<line_count<<": Type Mismatch "<<"\n"<<endl;
        log_file<<"Error at line  "<<line_count<<": Type Mismatch "<<"\n"<<endl;
        error_count++;
    }
    //type setting 
   $$->set_Type($1->get_Type());
   type=$1->get_Type();
   
   //log_file<<tp<<"\n"<<endl;

  //symbol and code setting

  if($1->get_arrSize() > -1)
  {
      //array

      string temp = newTemp();

      data_list.push_back(temp+(string)" dw ?");
      string op1=$1->getSymbol();
      string op2=$3->getSymbol();
      
      $$->setCode($3->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n");
      
      $$->setCode($$->getCode()+(string)"\tmov "+$1->getSymbol()+(string)"[bx], ax\n\tmov "+temp+(string)", ax\n"); //IMPORTANT

      $$->setSymbol(temp);

  }
  else
  {
      //variable
      
      string op1=$1->getSymbol();
      string op2=$3->getSymbol();

      $$->setCode($1->getCode()+$3->getCode()+"\t;"+op1+" = "+op2+"\n"+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n\tmov "+$1->getSymbol()+(string)", ax\n");

      $$->setSymbol($1->getSymbol());
  }

  delete $1;

  delete $3;

}
;
logic_expression:rel_expression
{
    //string tp=(string)$1->getname();
   // $$ = new SymbolInfo(tp,"NON_TERMINAL");
   log_file << "Line "<<line_count<<": logic_expression : rel_expression"<<"\n"<<endl;
   //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    //typ setting : semantic analysis might be required

    $$->set_Type($1->get_Type());

    //symbol and code setting

    $$->setSymbol($1->getSymbol());

    $$->setCode($1->getCode());
    
    delete $1;


}
|rel_expression LOGICOP rel_expression
{
    //string tp=(string)$1->getname()+(string)$2->getname()+(string)$3->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": logic_expression : rel_expression LOGICOP rel_expression"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    //typ setting : semantic analysis (type_casting) might be required
    
    //void checking ->
    if($1->get_Type() == "void")
    {
        //void function call within expression

        error_file<<"Error at line  "<<line_count<<": Void function used in expression "<<"\n"<<endl;
        log_file<<"Error at line  "<<line_count<<": Void function used in expression "<<"\n"<<endl;
        error_count++;
        //type setting if necessary
    }
    if($3->get_Type() == "void")
    {
        //void function call within expression

        error_file<<"Error at line  "<<line_count<<": Void function used in expression "<<"\n"<<endl;
        log_file<<"Error at line  "<<line_count<<": Void function used in expression "<<"\n"<<endl;
        error_count++;
        //type setting if necessary

    }

    //typ casting
    $$->set_Type("int");


    //symbol and code setting

    string label1 = newLabel();

    string label2 = newLabel();

    string temp = newTemp();

    data_list.push_back(temp +(string)" dw ?");

    $$->setCode($1->getCode()+$3->getCode());

    if($2->getname() == "&&")
    {
    	string op1=$1->getSymbol();
	string op2=$3->getSymbol();
	
        $$->setCode($$->getCode()+"\t;"+op1+"&&"+op2+"\n"+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label1+(string)"\n");
        $$->setCode($$->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label1+(string)"\n");
        $$->setCode($$->getCode()+(string)"\tmov ax, 1\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n\t");
        $$->setCode($$->getCode()+label1+(string)":\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\t");

        $$->setCode($$->getCode()+label2+(string)":\n");

    }
    else
    {
        //logicop is "||"

	string op1=$1->getSymbol();
	string op2=$3->getSymbol();
	
        $$->setCode($$->getCode()+"\t;"+op1+"||"+op2+"\n"+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tcmp ax, 0\n\tjne "+label1+(string)"\n");
        $$->setCode($$->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n\tcmp ax, 0\n\tjne "+label1+(string)"\n");
        $$->setCode($$->getCode()+(string)"\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n\t");
        $$->setCode($$->getCode()+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t");

        $$->setCode($$->getCode()+label2+(string)":\n");


    }

    $$->setSymbol(temp);

    delete $1;

    delete $2;
    delete $3;
}
;

rel_expression:simple_expression
{
    //string tp=(string)$1->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": rel_expression : simple_expression"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");
    

    //typ setting : semantic analysis might be required
    $$->set_Type($1->get_Type());

    //symbol and code setting

    $$->setSymbol($1->getSymbol());

    $$->setCode($1->getCode());

    delete $1;


}
|simple_expression RELOP simple_expression
{
    //string tp=(string)$1->getname()+(string)$2->getname()+(string)$3->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": rel_expression : simple_expression RELOP simple_expression"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    //typ setting : semantic analysis (type_casting) might be required
    
    //void checking ->
    if($1->get_Type() == "void")
    {
        //void function call within expression

       error_file<<"Error at line  "<<line_count<<": Void function used in expression "<<"\n"<<endl;
       log_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
        error_count++;
        //type setting if necessary
    }
    if($3->get_Type() == "void")
    {
        //void function call within expression

        error_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
       log_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
        error_count++;
        //type setting if necessary

    }

    //typ casting
    $$->set_Type("int");


    //symbol and code setting

    string label1 = newLabel();

    string label2 = newLabel();

    string temp = newTemp();

    data_list.push_back(temp+(string)" dw ?");

    $$->setCode($1->getCode()+$3->getCode()+"\t;RELOP OPERATION\n"+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tcmp ax, "+$3->getSymbol()+(string)"\n");
    string op1=$1->getSymbol();
    string op2=$3->getSymbol();

    if($2->getname() == "<"){
    
      

        $$->setCode($$->getCode()+"\t;"+op1+"<"+op2+"\n"+(string)"\tjl "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
        $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");
    }else if($2->getname() == "<=")
    {
    
        $$->setCode($$->getCode()+"\t;"+op1+"<="+op2+"\n"+(string)"\tjle "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
        $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");
    }else if($2->getname() == ">")
    {
        $$->setCode($$->getCode()+"\t;"+op1+">"+op2+"\n"+(string)"\tjg "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
        $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");
    }else if($2->getname() == ">=")
    {
        $$->setCode($$->getCode()+"\t;"+op1+">="+op2+"\n"+(string)"\tjge "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
        $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");
    }else if($2->getname() == "==")
    {
        $$->setCode($$->getCode()+"\t;"+op1+"=="+op2+"\n"+(string)"\tje "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
        $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");
    }else {
        //relop is "!="

         $$->setCode($$->getCode()+"\t;"+op1+"!="+op2+"\n"+(string)"\tjne "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
        $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");

    }

    $$->setSymbol(temp);

    delete $1;

    delete $2;

    delete $3;
}
;

simple_expression:term
{
  //string tp=(string)$1->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": simple_expression : term"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");
    

    //typ setting : semantic analysis might be required
    $$->set_Type($1->get_Type());

    //symbol and code setting

    $$->setSymbol($1->getSymbol());

    $$->setCode($1->getCode());

    delete $1;


}
|simple_expression ADDOP term
{
    //string tp=(string)$1->getname()+(string)$2->getname()+(string)$3->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": simple_expression : simple_expression ADDOP term"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;
    $$ = new SymbolInfo("","NON_TERMINAL");

    //typ setting : semantic analysis (type_casting) might be required
    
    //void checking ->
    if($1->get_Type() == "void")
    {
        //void function call within expression

       error_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
       log_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
        error_count++;
        //type setting if necessary
        $1->set_Type("int");
    }
    if($3->get_Type() == "void")
    {
        //void function call within expression

        error_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
        log_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
        error_count++;
        //type setting if necessary
        $3->set_Type("int");

    }


  //type setting (with type casting if required)

  if($1->get_Type() == "float" || $3->get_Type() == "float")
  {
      $$->set_Type("float");

  }
  else
  {
       $$->set_Type($1->get_Type()); // basially int
  }


  //symbol and code setting 

  string temp = newTemp();

  data_list.push_back(temp+(string)" dw ?");

  if($2->getname() == "+")
  {
      //addition
      string op1=$1->getSymbol();
      string op2=$3->getSymbol();
      
      $$->setCode($1->getCode()+$3->getCode()+"\t;"+op1+"+"+op2+"\n"+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tadd ax, "+$3->getSymbol()+(string)"\n\tmov "+temp+(string)", ax\n");

      $$->setSymbol(temp);
  } else {
      //subtraction
    
     string op1=$1->getSymbol();
     string op2=$3->getSymbol(); 
     $$->setCode($1->getCode()+$3->getCode()+"\t;"+op1+"-"+op2+"\n"+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tsub ax, "+$3->getSymbol()+(string)"\n\tmov "+temp+(string)", ax\n");

    $$->setSymbol(temp);

  }

  delete $1;

  delete $2;

  delete $3;
}
;

term: unary_expression
{
    //string tp=(string)$1->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": term : unary_expression"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");
    

    //typ setting : 
    $$->set_Type($1->get_Type());

    //symbol and code setting 

    $$->setSymbol($1->getSymbol());

    $$->setCode($1->getCode());

    delete $1;

}
|term MULOP unary_expression
{
   //string tp=(string)$1->getname()+(string)$2->getname()+(string)$3->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
   log_file << "Line "<<line_count<<": term : term MULOP unary_expression"<<"\n"<<endl;
    
    $$ = new SymbolInfo("","NON_TERMINAL");

    //typ setting : semantic analysis (type_casting,mod-operands checking) might be required
    //new added
    if(($2->getname() == "%") && ($3->getname() == "0"))
    {
    	error_file<<"Error at line  "<<line_count<<": Modulus by Zero "<<"\n"<<endl;
        log_file<<"Error at line  "<<line_count<<": Modulus by  Zero "<<"\n"<<endl;
        error_count++;
    }
    
    //void checking ->

    if($1->get_Type() == "void")
    {
        //void function call within expression

        error_file<<"Error at line  "<<line_count<<": Void function used in expression "<<"\n"<<endl;
        log_file<<"Error at line  "<<line_count<<": Void function used in expression "<<"\n"<<endl;
        error_count++;
        //type setting if necessary
        $1->set_Type("int"); //by default ,float type
    }
    if($3->get_Type() == "void")
    {
        //void function call within expression

        error_file<<"Error at line  "<<line_count<<": Void function used in expression "<<"\n"<<endl;
       log_file<<"Error at line  "<<line_count<<": Void function used in expression "<<"\n"<<endl;
        error_count++;
        //type setting if necessary
        $3->set_Type("int"); //by default ,float type


    }

    //type setting (with semantic analysis)
    if(($2->getname() == "%") && ($1->get_Type() != "int" || $3->get_Type() != "int"))
    {
        //type checking for mod operator

       error_file<<"Error at line  "<<line_count<<": Non-Integer operand on modulus operator "<<"\n"<<endl;
       log_file<<"Error at line  "<<line_count<<":Non-Integer operand on modulus operator"<<"\n"<<endl;
        error_count++;

        //type conversion
        $$->set_Type("int");
    }
    else if(($2->getname() != "%") && ($1->get_Type() == "float" || $3->get_Type() == "float")) //EC
    {
        //type conversion
        $$->set_Type("float");
    }
    else
    {
       
        $$->set_Type($1->get_Type());
    }
    
    //log_file<<tp<<"\n"<<endl;

    //symbol and code setting

    string temp = newTemp();

    data_list.push_back(temp+(string)" dw ?");

    if($2->getname() == "*"){
        //mult
      string op1=$1->getSymbol();
      string op2=$3->getSymbol();
        $$->setCode($1->getCode()+$3->getCode()+"\t;"+op1+"*"+op2+"\n"+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tmov bx, "+$3->getSymbol()+(string)"\n\timul bx\n\tmov "+temp+(string)", ax\n");
        $$->setSymbol(temp);

    }else{

        //divison or mod
        string op1=$1->getSymbol();
        string op2=$3->getSymbol();
        $$->setCode($1->getCode()+$3->getCode()+"\t;"+op1+"/"+op2+"\n"+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tcwd\n");

        $$->setCode($$->getCode()+(string)"\tmov bx, "+$3->getSymbol()+(string)"\n\tidiv bx\n");

        if($2->getname() == "/"){
            $$->setCode($$->getCode()+(string)"\tmov "+temp+(string)", ax\n"); //division

        }
        else{

            $$->setCode($$->getCode()+(string)"\tmov "+temp+(string)", dx\n"); //mod

        }
        $$->setSymbol(temp);
    }

    delete $1;

    delete $2;

    delete $3;

  
}
;

unary_expression: ADDOP unary_expression
{
    //string tp=(string)$1->getname()+(string)$2->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": unary_expression : ADDOP unary_expression"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

  
    
    //void checking ->

    if($2->get_Type() == "void")
    {
        //void function call within expression

        error_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
       log_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
        error_count++;
        //type setting if necessary
        
        //EC previous $1
        
        $$->set_Type("int"); //by default ,float type
    }
    else
    {
    	//EC previous $1
         //type setting
        $$->set_Type($2->get_Type()); 
    }

    //symbol and code setting

    if($1->getname() == "-"){
        //negative number

        string temp = newTemp();

        data_list.push_back(temp+(string)" dw ?");

        $$->setCode($2->getCode()+"\t;-"+$2->getSymbol()+"\n"+(string)"\tmov ax, "+$2->getSymbol()+(string)"\n\tmov "+temp+(string)", ax\n\tneg "+temp+(string)"\n");
        $$->setSymbol(temp);
    } else {
        //positive number

        $$->setSymbol($2->getSymbol());

        $$->setCode($2->getCode());

    }
    delete $1;

    delete $2;

}
|NOT unary_expression
{
    //string tp=(string)"!"+(string)$2->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": unary_expression : NOT unary expression"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

  
    
    //void checking ->

    if($2->get_Type() == "void")
    {
        //void function call within expression

        error_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
        log_file<<"Error at line  "<<line_count<<": Void function used in expression "<<"\n"<<endl;
        error_count++;
        
    }
    //type casting
    $$->set_Type("int");

    //symbol and code setting

    string label1 = newLabel();

    string label2 = newLabel();

    string temp = newTemp();

    data_list.push_back(temp+(string)" dw ?");

    $$->setCode($2->getCode()+(string)"\tmov ax, "+$2->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
    $$->setCode($$->getCode()+(string)"\t"+label1+(string)": \n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");

    $$->setSymbol(temp);

    delete $2;

}
|factor
{
    //string tp=(string)$1->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": unary_expression : factor"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    //type setting
    $$->set_Type($1->get_Type());

    //symbol and code setting

    $$->setSymbol($1->getSymbol());

    $$->setCode($1->getCode());

    delete $1;


}
;

factor:variable
{
    //string tp=(string)$1->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": factor : variable"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");
    //variable or array
    $$->set_arrSize($1->get_arrSize());

    //type setting
    $$->set_Type($1->get_Type());

    //symbol and code setting

    $$->setSymbol($1->getSymbol());
    $$->setCode($1->getCode());

    if($$->get_arrSize() > -1)
    {
        //array
        string temp = newTemp();

        data_list.push_back(temp+(string)" dw ?");

        $$->setCode($$->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"[bx]\n\tmov "+temp+(string)", ax\n");
        $$->setSymbol(temp);
    }
    delete $1;
}
|id LPAREN argument_list RPAREN
{
    //string tp=(string)$1->getname()+(string)"("+(string)$3->getname()+(string)")";
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": factor : ID LPAREN argument_list RPAREN"<<"\n"<<endl;
    
    $$ = new SymbolInfo("","NON_TERMINAL");

    bool is_valid = false;


    //type setting : semantic analysis(matching argument_list with parameter_list) required

     SymbolInfo* temp=st.LookUp_At_All_SymbolTable($1->getname());

     if(temp == NULL)
     {
         //no such id found
        error_file<<"Error at line  "<<line_count<<": Undeclared function "<<$1->getname()<<"\n"<<endl;
        log_file<<"Error at line  "<<line_count<<": Undeclared function "<<$1->getname()<<"\n"<<endl;
        error_count++;
        $$->set_Type("int"); // by default ,float type
     }
     else if(temp->get_arrSize() != -3)
     {
         //no such function definition found
        error_file<<"Error at line  "<<line_count<<": Undeclared function "<<$1->getname()<<"\n"<<endl;
        log_file<<"Error at line  "<<line_count<<": Undeclared function "<<$1->getname()<<"\n"<<endl;
        error_count++;
        //$$->set_Type("int"); // by default ,float type
        $$->set_Type(temp->get_Type());
     }
     else
     {
         //matching argument with parameter list
         if(temp->get_paramSize() == 1 && arg_list.size()==0 && temp->getParam(0).param_type=="void")
         {
             //consistent function call & type setting
             $$->set_Type(temp->get_Type());

             is_valid = true;

         }
         else if(temp->get_paramSize() != arg_list.size())
         {
             //inconsistent function call
             error_file<<"Error at line  "<<line_count<<": Total number of arguments mismatch in function "<<$1->getname()<<"\n"<<endl;
           log_file<<"Error at line  "<<line_count<<": Total number of arguments mismatch in function "<<$1->getname()<<"\n"<<endl;
            error_count++;
            //$$->set_Type("int"); //by default , float type
            $$->set_Type(temp->get_Type());


         }
         else
         {
             int i;

             for(i=0;i<arg_list.size();i++) //EC int i=0
             {
                 if(temp->getParam(i).param_type != arg_list[i])
                 {
                     break;
                 }
             }
             if(i != arg_list.size())
             {
                 //inconsistent function call
                log_file<<"Error at line  "<<line_count<<": "<<(i+1)<<"th argument mismatch in function "<<$1->getname()<<"\n"<<endl;
               error_file<<"Error at line  "<<line_count<<": "<<(i+1)<<"th argument mismatch in function "<<$1->getname()<<"\n"<<endl;
                error_count++;
                //$$->set_Type("float"); //by default , float type
                $$->set_Type(temp->get_Type());


             }
             else
             {
                 //consistent function call & type setting
                 $$->set_Type(temp->get_Type());

                 is_valid = true;
             }
         }
     }

    if(is_valid == true)
    {

        string _temp = newTemp();

        data_list.push_back(_temp+(string)" dw ?");

        $$->setCode($3->getCode());
        $$->setCode($$->getCode()+(string)"\tpush ax\n\tpush bx\n\tpush address\n");

        for(int i=0;i<temp_list.size();i++)
        {
            $$->setCode($$->getCode()+(string)"\tpush "+temp_list[i]+(string)"\n");
        }
        $$->setCode($$->getCode()+(string)"\tcall "+temp->getSymbol()+(string)"\n");
        if(temp->get_Type() != "void")
        {
            $$->setCode($$->getCode()+(string)"\tpop "+_temp+(string)"\n");
        }

        $$->setCode($$->getCode()+(string)"\tpop address\n\tpop bx\n\tpop ax\n");
        $$->setSymbol(_temp);
    }


     arg_list.clear();
     temp_list.clear();

     delete $1;

     delete $3;
     //log_file<<tp<<"\n"<<endl;
    
}
|LPAREN expression RPAREN
{
    //string tp=(string)"("+(string)$2->getname()+(string)")";
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": factor : LPAREN expression RPAREN"<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    $$->setSymbol($2->getSymbol());
    $$->setCode($2->getCode());
    

     //void checking ->

    if($2->get_Type() == "void")
    {
        //void function call within expression

        error_file<<"Error at line  "<<line_count<<": Void function used in expression "<<"\n"<<endl;
        log_file<<"Error at line  "<<line_count<<": Void function used in expression  "<<"\n"<<endl;
        error_count++;
        //type setting 
        $2->set_Type("int");
        

    }
    //type setting 
    $$->set_Type($2->get_Type());
   //log_file<<tp<<"\n"<<endl;
   delete $2;
    
}
|CONST_INT 

{
    //string tp=(string)$1->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": factor : CONST_INT"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

     $$ = new SymbolInfo("","NON_TERMINAL");
     $$->setSymbol($1->getname());

    //type setting
    $$->set_Type("int");

    delete $1;
}
|CONST_FLOAT
{
    //string tp=(string)$1->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": factor:CONST_FLOAT"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

     $$ = new SymbolInfo("","NON_TERMINAL");

     $$->setSymbol($1->getname());


    //type setting
    $$->set_Type("float");

    delete $1;

}
|variable INCOP
{
    //string tp=(string)$1->getname()+(string)"++";
     //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": factor : variable INCOP"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    //type setting
    $$->set_Type($1->get_Type());

    //symbol and code setting

    string temp1;

    if($1->get_arrSize() > -1)
    {
        //array

        temp1 = newTemp();

        data_list.push_back(temp1+(string)" dw ?");

        $$->setCode($1->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"[bx]\n\tmov "+temp1+(string)", ax\n");
        $$->setCode($$->getCode()+(string)"\tinc "+$1->getSymbol()+(string)"[bx]\n");

        $$->setSymbol(temp1);
    }
    else
    {
        //variable
        temp1 = newTemp();

        data_list.push_back(temp1+(string)" dw ?");
        $$->setCode($1->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tmov "+temp1+(string)", ax\n\tinc "+$1->getSymbol()+(string)"\n");
        $$->setSymbol(temp1);
        
     }

     delete $1;
}
|variable DECOP
{
    //string tp=(string)$1->getname()+(string)"--";
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": factor : variable DECOP"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    //type setting
    $$->set_Type($1->get_Type());

   //symbol and code setting

    string temp1;

    if($1->get_arrSize() > -1)
    {
        //array

        temp1 = newTemp();

        data_list.push_back(temp1+(string)" dw ?");

        $$->setCode(";"+$1->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"[bx]\n\tmov "+temp1+(string)", ax\n");
        $$->setCode($$->getCode()+(string)"\tdec "+$1->getSymbol()+(string)"[bx]\n");

        $$->setSymbol(temp1);
    }
    else
    {
        //variable
        temp1 = newTemp();

        data_list.push_back(temp1+(string)" dw ?");
        $$->setCode($1->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tmov "+temp1+(string)", ax\n\tdec "+$1->getSymbol()+(string)"\n");
        $$->setSymbol(temp1);
        
     }

     delete $1;
}
;

argument_list:arguments
{
    //string tp=(string)$1->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": argument_list : arguments"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    //code setting

    $$->setCode($1->getCode());

    delete $1;

}
|
{
    //epsilon production
    //string tp="";
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": argument_list : <epsilon-production>"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");


}
;
arguments: arguments COMMA logic_expression
{
    //string tp=(string)$1->getname()+(string)", "+(string)$3->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
    log_file << "Line "<<line_count<<": arguments : arguments COMMA logic_expression"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");

    //code setting

    $$->setCode($1->getCode()+$3->getCode());



     //void checking ->

    if($3->get_Type() == "void")
    {
        //void function call within argument of function


        error_file<<"Error at line  "<<line_count<<": Void function call within argument of function "<<"\n"<<endl;
       log_file<<"Error at line  "<<line_count<<": Void function call within argument of function "<<"\n"<<endl;
        error_count++;
        //type setting 
        $3->set_Type("int");
        

    }
    //keeping track of encountered argument
    arg_list.push_back($3->get_Type());

    //keeping track of arguments sent

    temp_list.push_back($3->getSymbol());

    delete $1;

    delete $3;

}
|logic_expression
{
    
    //string tp=(string)$1->getname();
    //$$ = new SymbolInfo(tp,"NON_TERMINAL");
   log_file << "Line "<<line_count<<": arguments : logic_expression"<<"\n"<<endl;
    //log_file<<tp<<"\n"<<endl;

    $$ = new SymbolInfo("","NON_TERMINAL");
    //code setting

    $$->setCode($1->getCode());


     //void checking ->

    if($1->get_Type() == "void")
    {
        //void function call within argument of function


        error_file<<"Error at line  "<<line_count<<": Void function call within argument of function"<<"\n"<<endl;
        log_file<<"Error at line  "<<line_count<<": Void function call within argument of function"<<"\n"<<endl;
        error_count++;
        //type setting 
        $1->set_Type("int");
        

    }
    //keeping track of encountered argument
    arg_list.push_back($1->get_Type());

    //keeping track of arguments sent

    temp_list.push_back($1->getSymbol());

    delete $1;

}
;

%%

int main(int argc ,char* argv[])
{
    if(argc != 2)
    {
        cout<<"input file name not provided ,terminating program..."<<endl;
        return 0;
    }
    input =fopen(argv[1],"r");
    if(input == NULL)
    {
        cout<<"input file not opened properly,terminating program..."<<endl;
        exit(EXIT_FAILURE);
    }
    
    
     scope_count++; //added 
    log_file.open("log.txt",ios::out);
    error_file.open("error.txt",ios::out);

    if(log_file.is_open() != true)
    {
        cout<<"log file not opened properly , terminating program..."<<endl;
        fclose(input);
        exit(EXIT_FAILURE);
    }
    
    code.open("code.asm",ios::out);
    optimized_code.open("optimized_code.asm",ios::out);

    if(error_file.is_open() != true)

    {
        cout<<"error file not opened properly, terminating program......"<<endl;
        fclose(input);
        log_file.close();
        exit(EXIT_FAILURE);

    }

    if(code.is_open() != true)

    {
        cout<<"code file not opened properly, terminating program......"<<endl;
        fclose(input);
        log_file.close();
        exit(EXIT_FAILURE);

    }

     if(optimized_code.is_open() != true)

    {
        cout<<"optimized_code file not opened properly, terminating program......"<<endl;
        fclose(input);
        log_file.close();
        exit(EXIT_FAILURE);

    }

     
        yyin=input;
        yyparse(); // processing starts
        log_file<<endl;

       
        
        //st.PrintAllScopeTable(log_file);
        
        log_file<<"Total lines: "<<(--line_count)<<endl;
        log_file<<"Total errors: "<<(error_count)<<endl;
        
        st.ExitScope(log_file);

        if(error_count > 0)
        {
            code<<"error found in input code"<<endl;
            optimized_code<<"error found in input code"<<endl;
        }

        
       

        fclose(yyin);
        log_file.close();
        error_file.close();
        code.close();
        optimized_code.close();
        return 0;


}

void yyerror(char* s)
{
    log_file<<"Line " <<line_count<<": "<<s<<endl;
    line_count++;
    error_count++;
    return;
}

