%option noyywrap
%option yylineno
%{
#include <stdio.h>
#include <cstring>
#include <string>
#include "parser.tab.h"
int yylex();
using namespace std;
%}
%x comment
%%
"["            BEGIN(comment);
<comment>{
    ]              BEGIN(INITIAL);
     \n       ;
      .               ;
}


"PLUS"        {return ADD;}
"MINUS"       {return SUB;}
"TIMES"       {return MULT;}
"DIV"         {return DIV;}
"MOD"         {return MOD;}

"EQ"          {return EQUAL;}
"NEQ"         {return NOT_EQUAL;}
"LE"          {return LESS;}
"GE"          {return GREATER;}
"LEQ"         {return LESS_OR_EQUAL;}
"GEQ"         {return GREATER_OR_EQUAL;}

"ASSIGN"      {return ASSIGN;}
"DECLARE"     {return DECLARE;}
"BEGIN"       {return BEG;}
"END"         {return END;}
"IF"          {return IF;}
"THEN"        {return THEN;}
"ELSE"        {return ELSE;}
"ENDIF"       {return ENDIF;}
"WHILE"       {return WHILE;}
"DO"          {return DO;}
"ENDWHILE"    {return ENDWHILE;}
"ENDDO"       {return ENDDO;}
"FOR"         {return FOR;}
"FROM"        {return FROM;}
"TO"          {return TO;}
"ENDFOR"      {return ENDFOR;}
"DOWNTO"      {return DOWNTO;}
"READ"        {return READ;}
"WRITE"       {return WRITE;}
";"           {return SEMICOLON;}
":"           {return COLON;}
","           {return COMM;}
\(            {return LEFT_BRACKET;}
\)            {return RIGHT_BRACKET;}
[ \t\r\n]+        ;
[-]?[0-9]+        {yylval.number = stoll(yytext); return (NUM);}
[_a-z]+           {yylval.name =  strdup(yytext);  return PIDENTIFIER;}
.             {return ERROR;}
%%

