//#ifndef SYMBOLTABLE_H
//#define SYMBOLTABLE_H

#include<iostream>
#include<fstream>
#include<string>
#include<vector> // new


using namespace std;

class SymbolInfo
{
private:

    string Name;
    string Type;
public:
    SymbolInfo* next_symbolInfo;

    //beshi
    int position_index;
    int position_serial;

    //*************************
    // additional info (variable,array,function)
    string _type; //for variable and array and function(return type)
    int _size; // array size for array;(-1=variable,-2=function_declaration,-3=function_definition)

    struct param
    {
        string param_type;
        string param_name;
    } temp_param;


    vector<param> param_list; // parameter list for function declaration,definition
    
    
    string symbol; // for assembly code symbol
   
    string code; // for assembly code propagation


    SymbolInfo()
    {
        next_symbolInfo=NULL;

    }
    SymbolInfo(string name,string type)
    {

        Name=name;
        Type=type;
        next_symbolInfo=NULL;
        
        //ICG
        
        symbol="";
        code="";
    }
    ~SymbolInfo()
    {
        param_list.clear(); // new added
        delete next_symbolInfo;
    }


    void setname(string name)
    {
        Name=name;
    };

    void settype(string type)
    {
        Type=type;
    };

    string getname() const// used : getname() const
    {
        return Name;
    }

    string gettype() const
    {
        return Type;
    }

    // new added

    void setNext(SymbolInfo* next)
    {
        this->next_symbolInfo=next;
        return ;
    }

    SymbolInfo* getNext() const
    {
        return next_symbolInfo;
    }


    //additional functionalities
    void set_Type(string _type)
    {
        this->_type=_type;
        return ;
    }

    string get_Type() const
    {
        return _type;
    }

    void set_arrSize(int _size)
    {
        //basically for array
        this->_size=_size;
        return ;
    }
    int get_arrSize() const
    {
        return _size;
    }
    int get_paramSize() const
    {
        return param_list.size();
    }

    void addParam(string param_type,string param_name)
    {
        temp_param.param_type=param_type;
        temp_param.param_name=param_name;

        param_list.push_back(temp_param);
        return ;

    }

    param getParam(int index) const
    {
        return param_list[index];
    }
    
    // ICG
    
    void setSymbol(string symbol)
    {
    	this->symbol=symbol;
    	return ;
    }
    string getSymbol() const
    {
    	return symbol;
    }
    
    void setCode(string code)
    {
    	this->code=code;
    	return ;
    }
    
    string getCode() const
    {
    	return code;
    }
    
};


class ScopeTable
{

    SymbolInfo** head;

public:
    string scopetable_id;
    int current_id=1;
    ScopeTable* parentScope;

    int bucket;
    ScopeTable()
    {


    }

    ScopeTable(int bkt)
    {

        head=new SymbolInfo*[bkt];

        for(int i=0; i<bkt; i++)
        {
            head[i]=NULL;

        }
        bucket=bkt;

    }


    ~ScopeTable()
    {
        for(int i=0; i<bucket; i++)
        {
            SymbolInfo* entry=head[i];
            while(entry!=NULL)
            {
                SymbolInfo* previous=entry;
                entry=entry->next_symbolInfo;
                delete previous;

            }
        }


        delete[] head;
        delete parentScope;

    }


    /*
     int hashf(string name);
     bool Insert(string name,string type);
     SymbolInfo* LookUp(string name);
     bool Delete(string name);
     void print(FILE *logout);
     void update_serial(int index);
     bool insertSymbol_In_ScopeTable(SymbolInfo& symbol);
     */


    bool insertSymbol_In_ScopeTable(SymbolInfo& symbol)
    {
        if(LookUp(symbol.getname()) != NULL)
        {
            return false;
        }
        int ind=hashf(symbol.getname());
        SymbolInfo* temp =head[ind];
        if(temp==NULL)
        {

            head[ind]=&symbol;
            symbol.setNext(NULL);
            return true;
        }

        while(temp ->next_symbolInfo != NULL)
        {
            temp=temp->next_symbolInfo;

        }
        temp->setNext(&symbol);
        symbol.setNext(NULL);
        return true;
    }

    void update_serial(int id)
    {
        SymbolInfo* start=head[id];
        int c=0;

        if(start == NULL)
        {


        }

        while(start != NULL)
        {
            start->position_serial=c;

            start = start->next_symbolInfo;
            c++;
        }

    }


    void print(ofstream& oObj)
    {
        
        for(int i=0; i<bucket; i++)
        {
            if(head[i]==NULL)
            {
                continue;
            }
            oObj<<" "<<i<<" -->";
            SymbolInfo* temp =head[i];
            while(temp != NULL)
            {
                oObj << " < "<<temp->getname()<<" , "<<temp->gettype()<<" >"<<" ";
                temp=temp->next_symbolInfo;
            }
            oObj<<endl;
        }
        return;
    }

    bool Delete(string name)
    {
        int index=hashf(name);
        SymbolInfo* tmp=head[index];
        SymbolInfo* par=head[index];

        if(tmp == NULL)
        {
            return false;

        }

        if(tmp->getname() == name && tmp->next_symbolInfo == NULL)
        {
            head[index]=NULL;

            ///tmp->next_symbolInfo=NULL;

            delete tmp;

            return true;
        }

        while(tmp->getname() != name && tmp->next_symbolInfo !=NULL)
        {
            par=tmp;
            tmp=tmp->next_symbolInfo;
        }
        if(tmp->getname() == name && tmp->next_symbolInfo != NULL)
        {
            /// head has to delete
            if(tmp==par)
            {
                head[index]=tmp->next_symbolInfo;
            }
            else
            {
                par->next_symbolInfo=tmp->next_symbolInfo; ///between head and tail to delete

            }
            tmp->next_symbolInfo = NULL;
            delete tmp;
            return true;
        }
        else

        {

            par->next_symbolInfo = NULL;
            tmp->next_symbolInfo = NULL;
            delete tmp;
            return true;
        }
        return false;


    }


    SymbolInfo* LookUp(string name)
    {
        int index=hashf(name);
        SymbolInfo* start=head[index];
        if(start == NULL)
        {

            return NULL;

        }

        while(start != NULL)
        {


            if(start->getname() == name)
            {

                return start;
            }
            start = start->next_symbolInfo;
        }
        return NULL;
    }


    bool Insert(string name,string type)
    {
        SymbolInfo* IsFound=LookUp(name);

        if(IsFound == NULL)
        {

            int index=hashf(name);

            SymbolInfo* new_symbol=new SymbolInfo(name,type);

            if(head[index]==NULL)
            {
                new_symbol->position_index=index;
                new_symbol->position_serial=0;
                head[index]=new_symbol;
                return true;
            }
            else
            {

                SymbolInfo* start=head[index];
                int c=1;
                while(start->next_symbolInfo != NULL)
                {
                    start=start->next_symbolInfo;
                    c++;

                }
                new_symbol->position_index=index;
                new_symbol->position_serial=c;
                start->next_symbolInfo=new_symbol;
                return true;
            }
            return false;

        }
        else
        {
            //cout<<"< "<<name<<","<<type<<" > already exists in current ScopeTable"<<endl;

            return false;
        }

    }



    int hashf(string name)
    {
        int asciisum=0;
        for(int i=0; i<name.length(); i++)
        {


            asciisum=asciisum+name[i];
        }
        return (asciisum%bucket);

    }




};



class SymbolTable
{

public:
    int b;
    ScopeTable* current_scopetable;

    SymbolTable()
    {

        current_scopetable=new ScopeTable();
        current_scopetable->parentScope=NULL;
        current_scopetable->scopetable_id="1";


    }

    SymbolTable(int bn)
    {

        current_scopetable=new ScopeTable(bn);
        current_scopetable->parentScope=NULL;
        current_scopetable->scopetable_id="1";
        b=bn;


    }
    /*
    void EnterScope();
    void ExitScope();
    bool Insert_In_SymbolTable(string name,string type);
    bool Remove(string name);
    void LookUp_SymbolTable(SymbolTable* st,string name);
    void PrintCurrentScopeTable(FILE *logout);
    void PrintAllScopeTable(FILE *logout);
    */

    ~SymbolTable()
    {
        delete current_scopetable;
    }

    bool insertSymbol_In_SymbolTable(SymbolInfo& symbol)
    {

        if(current_scopetable == NULL)
        {
            return false;
        }
        return current_scopetable->insertSymbol_In_ScopeTable(symbol);
    }


    SymbolInfo* LookUp_At_SymbolTable(string key)
    {
    	if(current_scopetable ==  NULL)
    	{
    		return NULL;
    	}
    	return current_scopetable->LookUp(key);
    }
    
    SymbolInfo* LookUp_At_All_SymbolTable(string key)
    {
    	if(current_scopetable ==  NULL)
    	{
    		return NULL;
    	}
    	ScopeTable* temp=current_scopetable;
    	SymbolInfo* search_result=NULL;
    	while(temp != NULL)
    	{
    		search_result=temp->LookUp(key);
    		if(search_result != NULL)
    		{
    			break;
    		}
    		temp=temp->parentScope;
    		
    	}
    	return search_result;
    }

    
    void LookUp_SymbolTable(SymbolTable* st,string name)
    {


        SymbolInfo* symbol=st->current_scopetable->LookUp(name);

        if(symbol)
        {

            int pi=symbol->position_index;
            int ps=symbol->position_serial;

            cout<<"Found in ScopeTable# "<<st->current_scopetable->scopetable_id<<" at position "<<pi<<" ,"<<ps<<endl;

        }
        else
        {
            ScopeTable* par=st->current_scopetable->parentScope;
            while(par != NULL)
            {


                symbol=par->LookUp(name);
                if(symbol)
                {
                    int pi=symbol->position_index;
                    int ps=symbol->position_serial;

                    cout<<"Found in ScopeTable# "<<par->scopetable_id<<" at position "<<pi<<" ,"<<ps<<endl;
                    break;

                }
                else
                {
                    par=par->parentScope;

                }


            }
            if(par==NULL)
            {
                cout<<"Not Found"<<endl;

            }


        }

    }
    bool Remove(string name)
    {
        SymbolInfo* IsFound=current_scopetable->LookUp(name);
        if(IsFound != NULL)
        {

            SymbolInfo* symbol=current_scopetable->LookUp(name);

            cout<<"Found In ScopeTable# "<<current_scopetable->scopetable_id<<" at position "<<symbol->position_index<<", "<<symbol->position_serial<<endl;
            cout<<"Delete Entry "<<symbol->position_index<<", "<<symbol->position_serial<<" from current scopeTable"<<endl;



            if(current_scopetable->Delete(name))
            {
                int ind=current_scopetable->hashf(name);
                current_scopetable->update_serial(ind);
                return true;
            }
            else
            {
                cout<<"problem in delete"<<endl;
            }

        }
        else
        {

            return false;
        }

    }


    void EnterScope(ofstream& oObj)
    {
        ScopeTable* new_scopetable=new ScopeTable(b);


        ScopeTable* previous_top=current_scopetable;
        new_scopetable->parentScope=previous_top;

        int relative_id=previous_top->current_id;
        string str_relative_id=to_string(relative_id);

        new_scopetable->scopetable_id=new_scopetable->parentScope->scopetable_id+"."+str_relative_id;

        ///new_scopetable->scopetable_id=
        current_scopetable=new_scopetable;


        //cout<<"New ScopeTable with id "<<new_scopetable->scopetable_id<<" created"<<endl;
        //oObj<<"\t"<<"New ScopeTable with id "<<current_scopetable->scopetable_id<<" created"<<endl;
        return;


    }


    void ExitScope(ofstream& oObj)
    {
        if(current_scopetable==NULL)
        {
            return ;
        }

        //cout<<"ScopeTable with id "<<current_scopetable->scopetable_id<<" removed"<<endl;
        //oObj<<"\t"<<"ScopeTable with id "<<current_scopetable->scopetable_id<<" removed"<<endl;

        ScopeTable* previous_top=new ScopeTable(b);

        previous_top=current_scopetable;

        ScopeTable* new_top=new ScopeTable(b);

        new_top = current_scopetable->parentScope;

        previous_top=NULL; ///should free

        current_scopetable=new_top;

        current_scopetable->current_id=current_scopetable->current_id+1;
        return;


    }


    bool Insert_In_SymbolTable(string name,string type)
    {

        if(current_scopetable->Insert(name,type))
        {


            return true;
        }
        else
        {
            return false;
        }

    }


    void PrintCurrentScopeTable(ofstream& oObj)
    {
        if(current_scopetable==NULL)
        {
            return;
        }
        
        oObj<<"ScopeTable #"<<current_scopetable->scopetable_id<<endl;
        current_scopetable->print(oObj);
        return;
    }


    void PrintAllScopeTable(ofstream& oObj) //here can be use const
    {
        oObj<<endl;
        oObj<<endl;
        
        if(current_scopetable == NULL)
        {
            return ;
        }

        ScopeTable* temp=new ScopeTable(b);
        temp=current_scopetable;
        

        while(temp != NULL)
        {
             
        oObj<<"ScopeTable #"<< temp->scopetable_id<<endl;
            temp->print(oObj);
            oObj<<endl;
            oObj<<endl;
   
            temp=temp->parentScope;
        } 
        return;   

    }



};


