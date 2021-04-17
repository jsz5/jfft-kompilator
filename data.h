#ifndef COMPILER_DATA_H
#define COMPILER_DATA_H
#include <cstring>
#include <iostream>
#include <vector>
#include<map>
#include <fstream>
using namespace std;

class Variable {
public:
    string name;
    long long int address, address_stop;
    long long int start, stop;
    bool initialised; //if variable has been initialised or only declared
    bool iterator; //if variable is loop iterator - can't change it
    /*
    przesunięcia dla tablic (do assign a[i])
    przy deklaracji tablicy alokujemy pamięć dla przesunięcia: address-1
    przy pierwszym odwołaniu do tablicy generujemy liczbę przesunięcia, żeby potem już się odwoływać do miejsca w pamięci: array_shift_init=true
    */
    bool array_shift_init=false;
    bool array = false;
    Variable(string name, long long int address, bool iterator){
        this->name = name;
        this->address = address;
        this->iterator = iterator;
    }
   
    Variable(string name, long long int address,long long int address_stop, long long int start, long long int stop){
        this->name = name;
        this->address = address;
        this->address_stop = address_stop;
        this->start = start;
        this->stop = stop;
        this->array = true;
        this->iterator = false;
    }
};

class Instruction {
public:
    vector<pair<string, long long int>> instructions;
    /*
    p_0 <- main
    p_1=1 <- 1 for generating numbers
    p_2 <- temporary address for address of a[i] when assigning
    p_3 <- value 1
    p_4 <- value 2
    */

    void add(string instruction){
        instructions.emplace_back(instruction, -1);
    }

    void add(string instruction, long long int address){
        instructions.emplace_back(instruction, address);
    }

    void print(string filename){
        ofstream output;
        output.open (filename);  
        for(int i=0; i<instructions.size();i++){
            long long int second=instructions[i].second;
            if(second!=-3){
                output<<instructions[i].first<<" ";
                if(second!=-1){
                    output<<second;
                }
            output<<endl;
            }
        }
        output.close();
    }
    long long int get_size(){
        return instructions.size();
    }

    void change_instruction(long long int address){
        instructions[address].second=instructions.size();
    }

    void change_instruction(long long int address, long long int jump){
        instructions[address].second=jump;
    }
   
};

class ErrorException 
{	
public:
  	ErrorException(string message)
	{
		cout<<message<<endl;
	}
};


class Identifier{
public:
    long long int address;
    bool no_array_ident; //true if store, false if storei 
    bool numeric;
    long long int value;
    string array_name, index_name;
    Identifier(long long int address, bool no_array_ident){
        this->no_array_ident = no_array_ident;
        this->address = address;
        this->numeric=false;
    }

    Identifier(long long int address, string array_name, string index_name){
        this->no_array_ident = false;
        this->address = address;
        this->numeric=false;
        this->array_name=array_name;
        this->index_name=index_name;
    }

    Identifier(long long int value){
        this->no_array_ident = true;
        this->value = value;
        this->numeric=true;
    }
};

class Jump{
public:
    long long int from;
    long long int to;
   
    Jump(long long int from, long long int to){
        this->from = from;
        this->to = to;
    }
};

#endif //COMPILER_DATA_H
