#include<iostream>
#include<fstream>
#include<iostream>
#include<string>
using namespace std;



class SymbolInfo
{
private:

    string Name;
    string Type;
public:
    SymbolInfo* next_symbolInfo;
    int position_index;
    int position_serial;

    SymbolInfo()
    {
        next_symbolInfo=NULL;

    }
    SymbolInfo(string name,string type)
    {

        Name=name;
        Type=type;
        next_symbolInfo=NULL;
    }
    ~SymbolInfo()
    {
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

    string getname()
    {
        return Name;
    }

    string gettype()
    {
        return Type;
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



    int hashf(string name);
    bool Insert(string name,string type);
    SymbolInfo* LookUp(string name);
    bool Delete(string name);
    void print();
    void update_serial(int index);


};


void ScopeTable::update_serial(int id)
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


void ScopeTable::print()
{
    for(int i=0; i<bucket; i++)
    {
        SymbolInfo* tm=head[i];
        cout<<i<<" --> ";
        while(tm!=NULL)
        {
            cout<<" < "<<tm->getname()<<" : "<<tm->gettype()<<" > ";
            tm=tm->next_symbolInfo;
        }
        cout<<endl;

    }
}


bool ScopeTable::Delete(string name)
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


SymbolInfo* ScopeTable::LookUp(string name)
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


bool ScopeTable::Insert(string name,string type)
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
        cout<<"< "<<name<<","<<type<<" > already exists in current ScopeTable"<<endl;
        return false;
    }

}



int ScopeTable::hashf(string name)
{
    int asciisum=0;
    for(int i=0; i<name.length(); i++)
    {


        asciisum=asciisum+name[i];
    }
    return (asciisum%bucket);

}



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

    void EnterScope();
    void ExitScope();
    bool Insert_In_SymbolTable(string name,string type);
    bool Remove(string name);
    SymbolInfo* LookUp_SymbolTable(string name);
    void PrintCurrentScopeTable();
    void PrintAllScopeTable();

    ~SymbolTable()
    {
        delete current_scopetable;
    }


};



bool SymbolTable::Remove(string name)
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


void SymbolTable::EnterScope()
{
    ScopeTable* new_scopetable=new ScopeTable(b);


    ScopeTable* previous_top=current_scopetable;
    new_scopetable->parentScope=previous_top;

    int relative_id=previous_top->current_id;
    string str_relative_id=to_string(relative_id);

    new_scopetable->scopetable_id=new_scopetable->parentScope->scopetable_id+"."+str_relative_id;

    ///new_scopetable->scopetable_id=
    current_scopetable=new_scopetable;


    cout<<"New ScopeTable with id "<<new_scopetable->scopetable_id<<" created"<<endl;


}


void SymbolTable::ExitScope()
{

    cout<<"ScopeTable with id "<<current_scopetable->scopetable_id<<" removed"<<endl;

    ScopeTable* previous_top=new ScopeTable(b);

    previous_top=current_scopetable;

    ScopeTable* new_top=new ScopeTable(b);

    new_top = current_scopetable->parentScope;

    previous_top=NULL; ///should free

    current_scopetable=new_top;

    current_scopetable->current_id=current_scopetable->current_id+1;


}


bool SymbolTable::Insert_In_SymbolTable(string name,string type)
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


void SymbolTable::PrintCurrentScopeTable()
{
    cout<<"ScopeTable# "<<current_scopetable->scopetable_id<<endl;
    current_scopetable->print();
}


void SymbolTable::PrintAllScopeTable()
{
    ScopeTable* new_scope=new ScopeTable(b);
    new_scope=current_scopetable;
    int i=1;

    while(new_scope != NULL)
    {
        cout<<"ScopeTable# "<<new_scope->scopetable_id<<endl;

        new_scope->print();
        new_scope=new_scope->parentScope;
        i++;
    }

}




int main()
{
    int bucket_no;
    std::string bucket_no_str;

    std::fstream file("input.txt");
    std::string str;

    fstream myfile;
    myfile.open("output.txt",ios::out);
    string line;
    streambuf* stream_buffer_cout=cout.rdbuf();
    streambuf* stream_buffer_cin=cin.rdbuf();

    streambuf* stream_buffer_file=myfile.rdbuf();
    ///cout.rdbuf(stream_buffer_file);

    cout.rdbuf(stream_buffer_cout);




    bool fix_bucket=true;
    while(std::getline(file,str))
    {
        if(fix_bucket)
        {
            bucket_no_str=str;

            bucket_no = stoi(str);


            fix_bucket=false;
        }
    }


    SymbolTable st(bucket_no);

    std::fstream file1("input.txt");
    while(std::getline(file1,str))
    {
        string command="";
        string second="";
        string third="";

        int c=1;
        string word="";
        for(auto x: str)
        {
            if(x == ' ')
            {
                if(c==1)
                {
                    command=word;
                    c++;
                }
                else if(c==2)
                {
                    second=word;
                    c++;
                }
                else if(c==3)
                {
                    third=word;
                }
                word="";


            }
            else
            {
                word=word+x;
            }
        }

        if(c==1)
        {
            command=word;
            c++;
        }
        else if(c==2)
        {
            second=word;
            c++;
        }
        else if(c==3)
        {
            third=word;
        }





        if(str!=bucket_no_str)
        {
            cout<<command<<" "<<second<<" "<<third<<endl;

            if(command=="I")
            {


                if(st.Insert_In_SymbolTable(second,third))
                {



                    SymbolInfo* symbol=st.current_scopetable->LookUp(second);

                    if(symbol)
                    {

                        int pi=symbol->position_index;
                        int ps=symbol->position_serial;



                        cout<<"Inserted in ScopeTable# "<<st.current_scopetable->scopetable_id<<"  at position "<<pi<<" ,"<<ps<<endl;

                    }
                    else
                    {
                        cout<<"No symbol"<<endl;
                    }


                }


            }
            else if(command=="S")
            {
                st.EnterScope();

            }
            else if(command=="P")
            {

                if(second=="A")
                {
                    st.PrintAllScopeTable();

                }
                else if(second=="C")
                {
                    st.PrintCurrentScopeTable();
                }
            }
            else if(command=="L")
            {

                SymbolInfo* symbol=st.current_scopetable->LookUp(second);

                if(symbol)
                {

                    int pi=symbol->position_index;
                    int ps=symbol->position_serial;

                    cout<<"Found in ScopeTable# "<<st.current_scopetable->scopetable_id<<" at position "<<pi<<" ,"<<ps<<endl;

                }
                else
                {
                    ScopeTable* par=st.current_scopetable->parentScope;
                    while(par != NULL)
                    {


                        symbol=par->LookUp(second);
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

            else if(command == "E")
            {
                st.ExitScope();
            }
            else if(command == "D")
            {
                if(st.Remove(second))
                {


                }
                else
                {
                    cout<<"Not found"<<endl;
                    cout<<second<<" not found"<<endl;
                }
            }
        }

    }
    myfile.close();
    return 0;
}

