%{
#include "heading.h"
#include "y.tab.h"
#define UNRECOGNIZED_SYMBOL 0x0
#define BAD_ID1             0x1
#define BAD_ID2             0x2

int row = 1;
int col = 1;

void yyerr(int, char *);
%}

DIGIT           [0-9]
ALPHA           [A-Za-z]
WHITE_SPACE     [ \t]+
ID              {ALPHA}(({ALPHA}|{DIGIT}|_)*({ALPHA}|{DIGIT}))?
BAD_ID1         {DIGIT}+{ID}
BAD_ID2         {ID}_+
NEW_LINE        \n
INTEGER         {DIGIT}+
COMMENT         ##.*

%%
program         {return(PROGRAM); col += yyleng;}
beginprogram    {return(BEGIN_PROGRAM); col += yyleng;}
endprogram      {return(END_PROGRAM); col += yyleng;}
integer         {return(INTEGER); col += yyleng;}
array           {return(ARRAY); col += yyleng;}
of              {return(OF); col += yyleng;}
if              {return(IF); col += yyleng;}
then            {return(THEN); col += yyleng;}
endif           {return(ENDIF); col += yyleng;}
else            {return(ELSE); col += yyleng;}
elseif          {return(ELSEIF); col += yyleng;}
while           {return(WHILE); col += yyleng;}
do              {return(DO); col += yyleng;}
beginloop       {return(BEGINLOOP); col += yyleng;}
endloop         {return(ENDLOOP); col += yyleng;}
break           {return(BREAK); col += yyleng;}
continue        {return(CONTINUE); col += yyleng;}
exit            {return(EXIT); col += yyleng;}
read            {return(READ); col += yyleng;}
write           {return(WRITE); col += yyleng;}
and             {return(AND); col += yyleng;}
or              {return(OR); col += yyleng;}
not             {return(NOT); col += yyleng;}
true            {return(TRUE); col += yyleng;}
false           {return(FALSE); col += yyleng;}

-               {return(SUB); col += yyleng;}
\+              {return(ADD); col += yyleng;}
\*              {return(MULT); col += yyleng;}
\/              {return(DIV); col += yyleng;}
%               {return(MOD); col += yyleng;}

==              {return(EQ); col += yyleng;}
\<\>            {return(NEQ); col += yyleng;}
\<              {return(LT); col += yyleng;}
\>              {return(GT); col += yyleng;}
\<=             {return(LTE); col += yyleng;}
\>=             {return(GTE); col += yyleng;}

{ID}            {strcpy(yylval.str_val, yytext); col += yyleng; return(IDENT); }
{INTEGER}       {yylval.int_val = atoi(yytext); col += yyleng; return(NUMBER);}

;               {return(SEMICOLON); col += yyleng;}
\:              {return(COLON); col += yyleng;}
,               {return(COMMA); col += yyleng;}
\?              {return(QUESTION); col += yyleng;}
\[              {return(L_BRACKET); col += yyleng;}
\]              {return(R_BRACKET); col += yyleng;}
\(              {return(L_PAREN); col += yyleng;}
\)              {return(R_PAREN); col += yyleng;}
\:=             {return(ASSIGN); col += yyleng;}

{COMMENT}       {col += yyleng;}
{WHITE_SPACE}   {col += yyleng;}
{NEW_LINE}      {++row; col = 1;}

{BAD_ID1}       {yyerr(BAD_ID1, yytext);}
{BAD_ID2}       {yyerr(BAD_ID2, yytext);}
.               {yyerr(UNRECOGNIZED_SYMBOL, yytext);}
%%

void yyerr(int ERR_NUM, char * s){
  switch(ERR_NUM){
    case UNRECOGNIZED_SYMBOL:{
      fprintf(stderr, "** Line %d, position %d: Token format error, unrecognized symbol \"%s\"\n", row, col, s);
      break;
    }
    case BAD_ID1:{
      fprintf(stderr, "** Line %d, position %d: Token format error, identifier \"%s\" must begin with a letter\n", row, col, s);
      break;
    }
    case BAD_ID2:{
      fprintf(stderr, "** Line %d, position %d: Token format error, identifier \"%s\" cannot end with an underscore\n", row, col, s);
      break;
    }
    default:{
      fprintf(stderr, "** Line %d, position %d: Unknown token format error,  with character(s) \"%s\"\n", row, col, s);
    }
  }
  exit(1);
}
