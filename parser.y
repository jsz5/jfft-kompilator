%{
  /*todo: 
    1. ogarnąć podział na pliki i klasy
    2. CHECK IF VARIABLE IS INITIALIZED <- VALIDATION
    3. zrobić INC zamiast SHIFT gdzie trzeba przy generate_number
    4. przy dodawaniu INC dla liczb do 9
    5. todo przy odejmowaniu o dodawaniu ogarnąć odejmowanie 0
    6. optymalizacja przy while/do while -->zapisywanie stałej, zamiast generowania przy każdej iteracji
  */
  #include <math.h>
  #include <iostream>
  #include <string>
  #include <vector>
  #include <stack>
  #include<climits>
  #include <stdlib.h> 
  #include<map>
  #include "data.h"

 //Variables
  map<string, Variable*> variables;
  stack<Identifier*> identifiers;
  stack<Identifier*> condition_identifiers;
  stack< Jump*> jumps;
  stack< long long int> loops;
  Instruction instructions;
  long long int memory_counter=3;
  bool one=false; //if p_1=1
  bool minus_one=false; //if p_2=-1
  bool currently_assigning=false; //to  check if variable is initialised
  bool loop_iterator=false;

 //Operations
  void declare_variable(string name);
  void declare_array(string name, long long int start, long long int stop);
  void numeric_value(long long int value);
  Variable* array_validation(string array_name);
  Variable* index_validation(string index_name);
  void checkIfDeclared(string name);
  void generate_number(long long int number);
  void get_array_ident_address(string array_name, string index_name);
  void get_array_num_address(string array_name, long long int number);
  vector<bool> to_binary(long long int number);
  void get_identifier_address(string name);
  void assign();
  void read();
  void write();
  void remove_identifier();
  void remove_condition_identifier();
  void decrease_memory_counter(Identifier *identifier);



  //Arithmetic
  void expression_value();
  void expression_sub(bool condition, bool if_remove_identifier);
  void expression_add();
  void expression_mult();
  void expression_divide(bool modulo);
  void negate_address(long long int address);

  //Conditions
  void end_jump();
  void command_else();
  void condition_with_jump(string condition);
  void condition_equal();
  void condition_less();
  void condition_greater();
  void condition_without_jump(string condition);
  void condition_not_equal();
  void condition_less_equal();
  void condition_greater_equal();
  void add_without_jump(string condition);
  void add_with_jump(string condition);

  //Loops
  void end_while();
  void end_while_jump();
  void end_loop();
  void end_do();
  void begin_loop();
  void begin_for_loop(string name, string instruction);
  void end_for_loop(string instruction,string reverse_instruction,string name);
  void load_identifier(Identifier* identifier);

  //Bison methods
  int yylex (void);
  void yyerror (string);
  void show_line();
  extern FILE *yyin;
  extern int yylineno;

%}


/* Bison declarations. */
%token NUM
%token COMM
%token LEFT_BRACKET RIGHT_BRACKET
%token EQUAL NOT_EQUAL LESS GREATER LESS_OR_EQUAL GREATER_OR_EQUAL
%token END
%token ERROR
%token ASSIGN DECLARE BEG IF THEN ELSE ENDIF WHILE DO ENDWHILE ENDDO FOR FROM TO ENDFOR
%token DOWNTO READ WRITE SEMICOLON COLON PIDENTIFIER COMMA


%left SUB ADD
%left MULT DIV MOD //left (x+y)+z idzie od lewej


%type <number> NUM 
%type <name> PIDENTIFIER
%union{
    long long int number;
    char *name;
}
%% /* The grammar follows. */

program:
DECLARE  declarations BEG  commands 
    END { instructions.add("HALT");}
| BEG  commands  END 
;


declarations:
declarations COMM PIDENTIFIER LEFT_BRACKET NUM COLON NUM RIGHT_BRACKET {declare_array($3,$5,$7);}
|declarations COMM PIDENTIFIER  {declare_variable($3);}
|PIDENTIFIER {declare_variable($1);}
|PIDENTIFIER LEFT_BRACKET NUM COLON NUM RIGHT_BRACKET {declare_array($1,$3,$5);}
;

commands:
commands  command
| command 
;
command:
{currently_assigning=true;} identifier  ASSIGN  {currently_assigning=false; }  expression SEMICOLON  {assign();}                 
| IF  condition  THEN  commands  ELSE {command_else();} commands  ENDIF {end_jump();remove_condition_identifier();remove_condition_identifier();}
| IF  condition  THEN  commands  ENDIF {end_jump();remove_condition_identifier();remove_condition_identifier();}
| WHILE  condition  DO  commands  ENDWHILE {end_while();}
| DO {begin_loop();}commands  WHILE  condition ENDDO {end_do();remove_condition_identifier();remove_condition_identifier();}
| FOR  PIDENTIFIER  FROM  value TO  value {begin_for_loop($2,"INC"); }DO  commands  ENDFOR {end_for_loop("DEC","INC",$2);}
| FOR  PIDENTIFIER  FROM  value  DOWNTO  value {begin_for_loop($2,"DEC");} DO  commands  ENDFOR {end_for_loop("INC","DEC",$2);}
| READ {currently_assigning=true;} identifier {currently_assigning=false;} SEMICOLON {read();}
| WRITE  value 
SEMICOLON {write();}

;
expression: //result in p_0
value {expression_value();}
| value  ADD  value {expression_add(); }
| value  SUB  value {expression_sub(false,true); }
| value  MULT  value {expression_mult();}
| value  DIV  value {expression_divide(false);}
| value  MOD  value {expression_divide(true);}
;
condition: 
value EQUAL  value {condition_equal();}
| value  NOT_EQUAL  value {condition_not_equal();}
| value LESS  value {condition_less();}
| value GREATER  value {condition_greater();}
| value  LESS_OR_EQUAL  value {condition_less_equal();}
| value  GREATER_OR_EQUAL  value {condition_greater_equal();}
;
value: 
NUM {numeric_value($1); } 
| identifier 
;
identifier: 
PIDENTIFIER {get_identifier_address($1);}
| PIDENTIFIER LEFT_BRACKET PIDENTIFIER RIGHT_BRACKET {get_array_ident_address($1,$3);}
| PIDENTIFIER LEFT_BRACKET NUM RIGHT_BRACKET  {get_array_num_address($1,$3);}
;



;

%%
//////////////////////////////////
//          Declarations        //
//////////////////////////////////

/*
Declares variable 
Checks if variable has been already declared
@param string name - variable name
*/
void declare_variable(string name){
    checkIfDeclared(name);
    memory_counter++;
    Variable* variable = new Variable(name, memory_counter,false);
    variables.emplace(name, variable);
}
/*
Declares array
Allocates memory for the whole array
Checks if array has been already declared
@param string name - array name
@param long long int start- the beginning of the array
@param long long int end- the end of the array
*/
void declare_array(string name, long long int start, long long int stop){
    checkIfDeclared(name);
    if(stop<start){
      show_line();
      throw ErrorException("ERROR: the beginning of the table can not be grater than the end");
    }
    memory_counter+=3; //adress-1 for array shift
    long long int size=stop-start+3;
    Variable* variable = new Variable(name, memory_counter, memory_counter+size,start,stop);
    memory_counter+=size;

    variables.emplace(name, variable);
}


/*
Checks if variable has been already declared
*/
void checkIfDeclared(string name){
  if(variables.count(name)){
    show_line();
      throw ErrorException("ERROR: variable "+name+ " already declared");
  }
}

void remove_identifier(){
  Identifier *identifier=identifiers.top();
  if(!identifier->no_array_ident){
    memory_counter--;
  }
  identifiers.pop();
}

void remove_condition_identifier(){
  Identifier *identifier=condition_identifiers.top();
  condition_identifiers.pop();
}

void decrease_memory_counter(Identifier *identifier){
   if(!identifier->no_array_ident){
    memory_counter--;
  }
}
//////////////////////////////////
//          Operations          //
//////////////////////////////////

/*
Decimal to binary conversion
@return vector<bool>
*/
vector<bool> to_binary(long long int number)
{
  vector<bool> binary;
  long long int i = 0; 
  while (number > 0) {  
    binary.push_back(number%2);
        number/=2; 
        i++; 
  } 
  return binary;
}
/*
Generates code of creating a number
*/
void generate_number(long long int number){
  bool negative_and_one=false;
  instructions.add("SUB",0); //p_0=0
  if(number>=1 || number<=-1){
    if(number>0 && one){
      instructions.add("INC"); //p_0=1
    }
    if(!one){
      instructions.add("INC"); //p_0=1
      instructions.add("STORE",1); //p_1=1
      one=true;
      if(number<0){
        negative_and_one=true;
      }
    }
    string operation;
    if(number>0){
     operation="INC";
    }else{
      if(negative_and_one){
        instructions.add("SUB",0); 
      }
      operation="DEC";
      instructions.add(operation);
    }

    vector<bool>binary=to_binary(llabs(number));
    long long int length=binary.size();
    if(length>1){ //INC jest mniej kosztowne niż SHIFT todo: liczby do 10 INC zamiast SHIFT
      instructions.add(operation); //p_0=2
      if(binary[length-2]){
        instructions.add(operation); //p_0=3
      }
    }
    for(long long int i=length-3; i>=0; i--){
        instructions.add("SHIFT",1);
        if(binary[i]){
          instructions.add(operation);
        }
    }  
    
  }
}

/*
Adds numeric identifier to stack
*/
void numeric_value(long long int value){
  identifiers.push(new Identifier(value));
}
/*
Generates number for numeric identifier
*/
void expression_value(){
  if(!identifiers.empty()){
    Identifier* identifier =identifiers.top();
    if(identifier->numeric){
      generate_number(identifier->value);
    }else if(identifier->no_array_ident){
      instructions.add("LOAD",identifier->address);
    }else{
      instructions.add("LOADI",identifier->address);
    }
    remove_identifier();
  }
}
/*
Returns address in memory of a declared variable
Checks if variable is declared
*/
void get_identifier_address(string name){
  auto variable = variables.find(name);
    if(variable == variables.end()) {
      show_line();
      throw ErrorException("ERROR: variable "+name+ " is not declared.");
    }else if(variable->second->array){
      show_line();
      throw ErrorException("ERROR: variable "+name+ " is an array.");
    }else if(!currently_assigning && !variable->second->initialised){
      show_line();
      throw ErrorException("ERROR: variable "+name+ " is not initialised.");
    }else if(currently_assigning && variable->second->iterator){
      show_line();
      throw ErrorException("ERROR: can not change variable "+name+ ", it's a loop iterator.");
    }
    else {
      identifiers.push(new Identifier(variable->second->address,true));
      variable->second->initialised=true;
    }
}


/*
Checks if variable is declared and it's an array
*/
Variable* array_validation(string array_name){
 auto array = variables.find(array_name);
    if(array == variables.end()) {
      show_line();
      throw ErrorException("ERROR: array "+array_name+ " is not declared.");
    }else if(!array->second->array){
      show_line();
      throw ErrorException("ERROR: variable "+array_name+ " is not an array.");
    }
    return array->second;
}

/*
Checks if variable is declared and it's not an array
*/
Variable* index_validation(string index_name){
  auto index = variables.find(index_name);
    if(index == variables.end()) {
      show_line();
      throw ErrorException("ERROR: variable "+index_name+ " is not declared.");
    }else if(index->second->array){
      show_line();
      throw ErrorException("ERROR: variable "+index_name+ " is an array.");
    }
    return index->second;
}
/*
Returns address in memory of an array[ident]
Checks if array is declared
*/
void get_array_ident_address(string array_name, string index_name){
    Variable* array_var=array_validation(array_name);
    Variable* index_var=index_validation(index_name);
  
   //todo: jak walidować out of bounds i initialised?
    if(!array_var->array_shift_init){ //generate and store array shift
      generate_number(array_var->start);  
      instructions.add("STORE",array_var->address-2);
      generate_number(array_var->address);  
      instructions.add("STORE",array_var->address-1);
      array_var->array_shift_init=true;
      instructions.add("ADD",index_var->address);
    

    }else{
    instructions.add("LOAD",index_var->address);
    instructions.add("ADD",array_var->address-1); //in p_0 we have address of array[index]
    }
    memory_counter++;
    instructions.add("STORE",memory_counter);
    identifiers.push(new Identifier(memory_counter,true));
    identifiers.push(new Identifier(array_var->address-2,true));
    expression_sub(false,true);
   
    instructions.add("STORE",memory_counter);
    identifiers.push(new Identifier(memory_counter,array_name,index_name));  
   
}

/*
Returns address in memory of an array[num]
Checks if array is declared
*/
void get_array_num_address(string array_name, long long int number){
  Variable* array_var=array_validation(array_name);
  if(array_var->stop<number || array_var->start>number){
    show_line();
    throw ErrorException("Index is out of array bounds.");
  }
  identifiers.push(new Identifier(array_var->address+number-array_var->start,true));
}

/*
Assigns value to variable (in array or not)
*/
void assign(){
  if(!identifiers.empty()){
    Identifier* current_identifier=identifiers.top();
    remove_identifier();
    if(current_identifier->no_array_ident){
      instructions.add("STORE",current_identifier->address);
    }else{
      instructions.add("STOREI",current_identifier->address);
    }
  }else{
    show_line();
    throw ErrorException("An error occured.");
  }
}

void read(){
  instructions.add("GET");
  assign();
}

void write(){
  if(!identifiers.empty()){
    Identifier* current_identifier=identifiers.top();
    remove_identifier();
    if(current_identifier->numeric){
      generate_number(current_identifier->value);
    }else if(!current_identifier->no_array_ident){
      instructions.add("LOADI",current_identifier->address);
    }else{
      instructions.add("LOAD",current_identifier->address);
    }
    instructions.add("PUT");
  }
}

//////////////////////////////////
//          Arithmetic          //
//////////////////////////////////

void expression_add(){
   if(!identifiers.empty()){
    Identifier* first_value=identifiers.top();
    remove_identifier();
    if(!identifiers.empty()){
      Identifier* second_value=identifiers.top();
      remove_identifier();
      if(first_value->numeric && second_value->numeric){ //num+num
        if(second_value->value+first_value->value<=INT_MAX){
          generate_number(first_value->value+second_value->value);
        }else{
          generate_number(first_value->value);
          memory_counter++;
          instructions.add("STORE",memory_counter);
          generate_number(second_value->value);
          instructions.add("ADD",memory_counter);
        }
        
      }else if(!first_value->numeric & !second_value->numeric){ //!num+!num
        if(first_value->no_array_ident && second_value->no_array_ident){
          instructions.add("LOAD",first_value->address);
          instructions.add("ADD",second_value->address);
        }else if(!first_value->no_array_ident && !second_value->no_array_ident){
          instructions.add("LOADI",first_value->address);
          instructions.add("STORE",3);
          instructions.add("LOADI",second_value->address);
          instructions.add("ADD",3);
        }else if(first_value->no_array_ident){
          swap(first_value,second_value);
          instructions.add("LOADI",first_value->address);
          instructions.add("ADD",second_value->address);
        }
      }else {
          if(!first_value->numeric){
            swap(first_value,second_value);
          }
          if(first_value->value==0){
            load_identifier(second_value);
          }else{
            generate_number(first_value->value);
            if(second_value->no_array_ident){
              instructions.add("ADD",second_value->address);
            }else{
              instructions.add("STORE",3);
              instructions.add("LOADI",second_value->address);
              instructions.add("ADD",3);
            }
          }
        }
      }
    }
  
}

void expression_sub(bool condition,  bool if_remove_identifier){
  if(!identifiers.empty()){
    Identifier* first_value=identifiers.top();
    if(if_remove_identifier){
        remove_identifier();
    }
     else{
      identifiers.pop();
     }
    if(!identifiers.empty()){
      Identifier* second_value=identifiers.top();
      if(if_remove_identifier){
        remove_identifier();
      }else{
        identifiers.pop();
      }
      if(condition){
        condition_identifiers.push(second_value);
        condition_identifiers.push(first_value);
      }
      if(first_value->numeric && second_value->numeric ){ //num-num
       if(second_value->value-first_value->value>=INT_MIN){
          generate_number(second_value->value-first_value->value);
        }else{
          generate_number(first_value->value);
          memory_counter++;
          instructions.add("STORE",memory_counter);
          generate_number(second_value->value);
          instructions.add("SUB",memory_counter);
        }
       
      }else if(!first_value->numeric & !second_value->numeric){ //!num-!num
        if(first_value->no_array_ident && second_value->no_array_ident){ //pid-pid
          instructions.add("LOAD",second_value->address);
          instructions.add("SUB",first_value->address);
        }else if(!first_value->no_array_ident && !second_value->no_array_ident){//arr-arr
          instructions.add("LOADI",first_value->address);
          instructions.add("STORE",3);
          instructions.add("LOADI",second_value->address);
          instructions.add("SUB",3);
        }else if(first_value->no_array_ident && !second_value->no_array_ident){ //arr-pid
          instructions.add("LOADI",second_value->address);
          instructions.add("SUB",first_value->address);
        }else if(!first_value->no_array_ident && second_value->no_array_ident){ //pid-arr
          instructions.add("LOADI",first_value->address);
          instructions.add("STORE",3);
          instructions.add("LOAD",second_value->address);
          instructions.add("SUB",3);
        }
      }else if(!first_value->numeric && first_value->no_array_ident && second_value->numeric){ //num-pid
          generate_number(second_value->value);
          instructions.add("SUB",first_value->address);
      }else if(!second_value->numeric && second_value->no_array_ident && first_value->numeric){ //pid-num
        if(first_value->value==0){
          load_identifier(second_value);
        }else{
          generate_number(first_value->value);
          instructions.add("STORE",3);
          instructions.add("LOAD",second_value->address);
          instructions.add("SUB",3);
        }
      
      }else if(!first_value->numeric && !first_value->no_array_ident && second_value->numeric){ //num-arr  
           instructions.add("LOADI",first_value->address);
          instructions.add("STORE",3);
          generate_number(second_value->value);
          instructions.add("SUB",3); 
      
      }else if(!second_value->numeric && !second_value->no_array_ident && first_value->numeric){ //arr-num
        if(first_value->value==0){
          load_identifier(second_value);
        }else{        
          generate_number(first_value->value);
          instructions.add("STORE",3);
          instructions.add("LOADI",second_value->address);
          instructions.add("SUB",3);
        }
      }
      
    }
  }
}


void expression_mult(){
   if(!identifiers.empty()){
    Identifier* first_value=identifiers.top();
    identifiers.pop();
    if(!identifiers.empty()){
      Identifier* second_value=identifiers.top();
      identifiers.pop();
      if(first_value->numeric && second_value->numeric && second_value->value*first_value->value<=INT_MAX){
          generate_number(second_value->value*first_value->value);
      }else{
        memory_counter++;
        long long int begin_counter=memory_counter;
        memory_counter+=4;
        instructions.add("SUB",0);
        instructions.add("STORE",begin_counter+2); //result
        if(!minus_one){
          instructions.add("DEC"); 
          instructions.add("STORE",2); //-1 w p2
          minus_one=true;
        }
        if(!one){
          instructions.add("INC"); 
          instructions.add("INC"); 
          instructions.add("STORE",1); //1 w p1
          one=true;
        }
        load_identifier(second_value);
        instructions.add("STORE",begin_counter+1); //b
        load_identifier(first_value);
        instructions.add("STORE",begin_counter); //a
        
        add_with_jump("JNEG"); //if a<0
        instructions.add("SUB",0);
        instructions.add("SUB",begin_counter);
        instructions.add("STORE",begin_counter); //a
        instructions.add("SUB",0);
        instructions.add("SUB",begin_counter+1);
        instructions.add("STORE",begin_counter+1); //b
        instructions.add("LOAD",begin_counter); //b
        end_jump(); //koniec if a<0

        add_without_jump("JZERO"); //while(a!=0)
        instructions.add("SHIFT",2); 
        instructions.add("STORE",begin_counter+4); //a/2
        instructions.add("SHIFT",1); 
        identifiers.push(new Identifier(0,true));
        identifiers.push(new Identifier(begin_counter,true));
        expression_sub(false,true);
        add_without_jump("JZERO"); //if(a%2==1)
        identifiers.push(new Identifier(begin_counter+2,true));
        identifiers.push(new Identifier(begin_counter+1,true));
        expression_add();
        identifiers.push(new Identifier(begin_counter+2,true));
        assign(); //result+=b;
        end_jump(); //koniec if(a%2==1)
        instructions.add("LOAD",begin_counter+1); //b
        instructions.add("SHIFT",1); 
        instructions.add("STORE",begin_counter+1); //b
        instructions.add("LOAD",begin_counter+4); 
        instructions.add("STORE",begin_counter); //a=a/2
        end_while_jump();//end while(a!=0)
        instructions.add("LOAD",begin_counter+2);//load result
        memory_counter-=5;
        decrease_memory_counter(first_value);
        decrease_memory_counter(second_value);
      }
    }
  }
}


void expression_divide(bool modulo){

   if(!identifiers.empty()){
    Identifier* divisor=identifiers.top();
    identifiers.pop();
    if(!identifiers.empty()){
      Identifier* dividend=identifiers.top();
      identifiers.pop();
      
      if(divisor->numeric && divisor->value==0){
        instructions.add("SUB",0);
      }else if(dividend->numeric && divisor->numeric && dividend->value%divisor->value<=INT_MAX && dividend->value%divisor->value>=INT_MIN){
        if(!modulo){
         generate_number(dividend->value/divisor->value);
        }else{
          generate_number(dividend->value%divisor->value);
        }
       }else{
         memory_counter++;
        long long int begin_counter=memory_counter;
        load_identifier(divisor);
        //check if 0
        long long int k=instructions.get_size();
        instructions.add("JZERO",k+2); 
        instructions.add("JUMP",k+4); 
        instructions.add("SUB",0); 
        instructions.add("JUMP",-2); 
        jumps.push(new Jump(k+3,k+3));
        instructions.add("STORE",begin_counter); //sd
        
        instructions.add("SUB",0);
        instructions.add("STORE",begin_counter+2); //result
        instructions.add("INC"); 
        instructions.add("STORE",begin_counter+3); //mult
        instructions.add("STORE",begin_counter+6); //signDividend: -1=negative, 1=positive
        instructions.add("STORE",begin_counter+7); //signDivisor: -1=negative, 1=positive
        if(!one){
          instructions.add("STORE",1); //1 in p1
          one=true;
        }
        instructions.add("DEC"); 
        instructions.add("DEC"); 
        if(!minus_one){
          instructions.add("STORE",2); //-1
          minus_one=true;
        }
        
        load_identifier(dividend);
        instructions.add("STORE",begin_counter+5); //dividend
        instructions.add("STORE",begin_counter+1); //remain
        //sign
        add_with_jump("JNEG"); //if(dividend<0)
      
        negate_address(begin_counter+1);// remain
        instructions.add("STORE",begin_counter+5); //dividend
        instructions.add("LOAD",begin_counter+6); //sign
        instructions.add("DEC"); 
        instructions.add("DEC"); 
        instructions.add("STORE",begin_counter+6); //sign
        // negate_address(begin_counter+6);//sign=!sign
        
        end_jump();
        instructions.add("LOAD",begin_counter); //sd
        add_with_jump("JNEG"); //if(divisor<0)
        negate_address(begin_counter);//sd
        instructions.add("LOAD",begin_counter+7); //sign
        instructions.add("DEC"); 
        instructions.add("DEC"); 
        instructions.add("STORE",begin_counter+7); //sign
       
       
        end_jump();        
        identifiers.push(new Identifier(begin_counter,true)); //sd
        identifiers.push(new Identifier(begin_counter+5,true));//dividend
        expression_sub(false,true); //sd-dividend
        add_with_jump("JNEG"); //while(sd<dividend)
        instructions.add("LOAD",begin_counter); //sd
        instructions.add("SHIFT",1); //sd*2
        instructions.add("STORE",begin_counter); //sd=2*sd
        instructions.add("LOAD",begin_counter+3); //mult
        instructions.add("SHIFT",1); //mult*2
        instructions.add("STORE",begin_counter+3); //mult=2*mult
        identifiers.push(new Identifier(begin_counter,true)); //sd
        identifiers.push(new Identifier(begin_counter+5,true));//dividend
        expression_sub(false,true); //sd-dividend
        end_while_jump();//end while(sd<dividend)

        begin_loop(); //begin do while
        identifiers.push(new Identifier(begin_counter+1,true)); //remain
        identifiers.push(new Identifier(begin_counter,true));//sd
        expression_sub(false,true); //remain-sd
        add_without_jump("JNEG"); //if(remain>=sd)
        identifiers.push(new Identifier(begin_counter+1,true));//remain
        assign(); //remain-=sd;

        identifiers.push(new Identifier(begin_counter+2,true));//res
        identifiers.push(new Identifier(begin_counter+3,true));//mult
        expression_add();
        identifiers.push(new Identifier(begin_counter+2,true));
        assign(); //result+=mult;
        end_jump(); //koniec if(remain>=sd)
        instructions.add("LOAD",begin_counter); //sd
        instructions.add("SHIFT",2); //sd/2
        instructions.add("STORE",begin_counter); //sd=sd/2
        instructions.add("LOAD",begin_counter+3); //mult
        instructions.add("SHIFT",2); //mult/2
        instructions.add("STORE",begin_counter+3); //mult=mult/2
        if(!loops.empty()){
          long long int k=instructions.get_size();
          instructions.add("JZERO",k+2);
          instructions.add("JUMP",loops.top()); //while(mult!=0)     
          loops.pop();    
        }else{
          show_line();
          throw ErrorException("An error occured.");
        }
        long long int index_remain;
        instructions.add("LOAD",begin_counter+1);//remain
        add_with_jump("JZERO");      
        instructions.add("LOAD",begin_counter+6);//signDividend
        add_without_jump("JPOS");
        instructions.add("LOAD",begin_counter+2);
        negate_address(begin_counter+2);
        end_jump();
        instructions.add("LOAD",begin_counter+7);//signDivisor
        add_without_jump("JPOS");
        instructions.add("LOAD",begin_counter+2);
        negate_address(begin_counter+2);
        end_jump();
        index_remain=instructions.get_size();
        instructions.add("JUMP",-2);  
        end_jump();

        long long int index[5];
        instructions.add("LOAD",begin_counter+6);//load signDividend
        index[0]=instructions.get_size();
        instructions.add("JPOS",-2); //dividend>0
        instructions.add("LOAD",begin_counter+7);//load signDivisor
        index[1]=instructions.get_size();
        instructions.add("JPOS",-2); //divisor>0
         instructions.add("LOAD",begin_counter+1);//load remain
        negate_address(begin_counter+1);
        index[2]=instructions.get_size();
        instructions.add("JUMP",-2);
        instructions.change_instruction(index[1],instructions.get_size());
        identifiers.push(divisor);
        identifiers.push(new Identifier(begin_counter+1,true));//remain
        expression_sub(false,true);
        instructions.add("STORE",begin_counter+1); //remain=divisor-remain
        instructions.add("LOAD",begin_counter+2); //result
        instructions.add("INC"); 
        instructions.add("STORE",begin_counter+2);
        negate_address(begin_counter+2);//-(result+1)
        index[3]=instructions.get_size();
        instructions.add("JUMP",-2);
        instructions.change_instruction(index[0],instructions.get_size());
        instructions.add("LOAD",begin_counter+7);//load signDivisor
        index[4]=instructions.get_size();
        instructions.add("JPOS",-2); //divisor>0
        identifiers.push(divisor);
        identifiers.push(new Identifier(begin_counter+1,true));//remain
        expression_add();
        instructions.add("STORE",begin_counter+1); //remain=divisor+remain
        instructions.add("LOAD",begin_counter+2); //result
        instructions.add("INC"); 
        instructions.add("STORE",begin_counter+2);
        negate_address(begin_counter+2);//-(result+1)
        instructions.change_instruction(index[2],instructions.get_size());
        instructions.change_instruction(index[3],instructions.get_size());
        instructions.change_instruction(index[4],instructions.get_size());
        instructions.change_instruction(index_remain,instructions.get_size());
        

        long long int result_address;
        if(modulo){
          result_address=begin_counter+1;
        }else{
          result_address=begin_counter+2;
        }
        instructions.add("LOAD",result_address);//load result
        memory_counter--;
        end_jump();
         decrease_memory_counter(dividend);
        decrease_memory_counter(divisor);
      }
    }else{
      show_line();
      throw ErrorException("An error occured.");
    }
  }else{
    show_line();
      throw ErrorException("An error occured.");
    }
}

void negate_address(long long int address){
  instructions.add("SUB",address); //0
  instructions.add("SUB",address); //!sign
  instructions.add("STORE",address); //sign=!sign
}

//////////////////////////////////
//          Conditions          //
//////////////////////////////////
void add_with_jump(string condition){
  long long int k=instructions.get_size();
  instructions.add(condition,k+2);
  instructions.add("JUMP",-2);
  jumps.push(new Jump(k+1,k));
}

void condition_with_jump(string condition){
  expression_sub(true,true);
  add_with_jump(condition);
}

void condition_equal(){
  condition_with_jump("JZERO");
}
void condition_less(){
  condition_with_jump("JNEG");
}
void condition_greater(){
  condition_with_jump("JPOS");
}
void add_without_jump(string condition){
  long long int k=instructions.get_size();
  instructions.add(condition,-2); //if condition then jump somewhere
  jumps.push(new Jump(k,k));
}
void condition_without_jump(string condition){

  expression_sub(true,true);
  add_without_jump(condition);
}
void condition_not_equal(){
  condition_without_jump("JZERO");
}
void condition_less_equal(){
  condition_without_jump("JPOS");
}
void condition_greater_equal(){
   condition_without_jump("JNEG");
}


void end_jump(){
  if(!jumps.empty()){
    long long int address=jumps.top()->from;
    jumps.pop();
    instructions.change_instruction(address);
  }else{
    show_line();
    throw ErrorException("An error occured.");
  } 
}

void command_else(){
  long long int k=instructions.get_size();
  instructions.add("JUMP",-2);
  end_jump();
  jumps.push(new Jump(k,k));
}

//////////////////////////////////
//          Loops               //
//////////////////////////////////
void prepare_condition(Identifier *identifier){
  if(!identifier->no_array_ident){
    get_array_ident_address(identifier->array_name, identifier->index_name);
  }else{
    identifiers.push(identifier);
  }
}

void end_while_jump(){
   if(!jumps.empty()){
        Jump *jump=jumps.top();
        jumps.pop();
        instructions.add("JUMP",jump->to);
        instructions.change_instruction(jump->from);

      }else{
        show_line();
        throw ErrorException("An error occured.");
      } 
}
void end_while(){
  if(!condition_identifiers.empty()){
    Identifier *identifier_first=condition_identifiers.top();
    remove_condition_identifier();
    if(!condition_identifiers.empty()){
      Identifier *identifier_second=condition_identifiers.top();
      remove_condition_identifier();
      prepare_condition(identifier_second);
      prepare_condition(identifier_first);    
      expression_sub(false,true);
      end_while_jump();
    }else{
      show_line();
        throw ErrorException("An error occured.");
    } 
  }else{
    show_line();
        throw ErrorException("An error occured.");
   } 
}


void end_loop(){
  if(!jumps.empty()){
      Jump *jump=jumps.top();
      jumps.pop();
      instructions.add("JUMP",jump->to);
      instructions.change_instruction(jump->from);

  }else{
    show_line();
    throw ErrorException("An error occured.");
  } 
}
void begin_loop(){
  loops.push(instructions.get_size());
}
void end_do(){
  if(!jumps.empty()&& !loops.empty()){
    long long int k=jumps.top()->from;
    jumps.pop();
    long long int begin=loops.top();
    loops.pop();
    if(instructions.instructions[k].first=="JUMP"){ //with jump to without jump
      instructions.change_instruction(k-1,begin);
      instructions.change_instruction(k,-3);
    }else{
      instructions.change_instruction(k,k+2); //without jump to with jump
      instructions.instructions.insert(instructions.instructions.begin()+k+1,make_pair("JUMP",begin));
    }
  }else{
    show_line();
    throw ErrorException("An error occured.");
  } 
}

void begin_for_loop(string name, string instruction){  
  
    Identifier *identifier_first=identifiers.top();
    identifiers.pop();
   // remove_identifier();
    Identifier *identifier_second=identifiers.top();
    identifiers.pop();
    //remove_identifier();
    identifiers.push(identifier_first);
    identifiers.push(identifier_second);
    load_identifier(identifier_second);
    memory_counter++; 
    Variable* variable = new Variable(name, memory_counter,true);
    variable->initialised=true;
    variables.emplace(name, variable);
    instructions.add("STORE",memory_counter);
    expression_sub(false,false);
    instructions.add(instruction);
    memory_counter++;
    jumps.push(new Jump(instructions.get_size(),instructions.get_size()));

    if(instruction=="DEC"){
      instructions.add("JPOS",-2);
    }else{
      instructions.add("JNEG",-2);
    }
    instructions.add("STORE",memory_counter);
    jumps.push(new Jump(instructions.get_size(),instructions.get_size()));
    instructions.add("JZERO",-2);
}

void end_for_loop(string instruction, string reverse_instruction, string name){
  auto variable = variables.find(name);
  instructions.add("LOAD",variable->second->address);
  instructions.add(reverse_instruction);
  instructions.add("STORE",variable->second->address);
  instructions.add("LOAD",variable->second->address+1);
  instructions.add(instruction);
  instructions.add("STORE",variable->second->address+1);
  end_loop();
  memory_counter-=2;
  variables.erase(name); 
  end_jump();
}

void load_identifier(Identifier* identifier){
   if(identifier->numeric){
      generate_number(identifier->value);
    }else if(identifier->no_array_ident){
      instructions.add("LOAD",identifier->address);
    }else{
      instructions.add("LOADI",identifier->address);
    }
}
//////////////////////////////////
//         Bison methods        //
//////////////////////////////////
void show_line()
{
  cout<<"Line "<<yylineno<<": ";
}
void yyerror (string s)
{
  show_line();
  cout<<s<<endl;
  
}

int main (int argv, char* argc[])
{
  if(argv<3){
    cout<<"Wymagane są dwa argumenty\n";
  }else{
    try{
      yyin = fopen(argc[1], "r");
      if (yyin == NULL){
        throw ErrorException("File does not exist.");
      }
      else{
        yyparse ();
        instructions.print(argc[2]);
      }
    }catch(ErrorException &e){}
  }
    return 0;
}
