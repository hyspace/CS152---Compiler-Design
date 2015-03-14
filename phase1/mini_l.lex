%{
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
program         {printf("PROGRAM\n"); col += yyleng;}
beginprogram    {printf("BEGIN_PROGRAM\n"); col += yyleng;}
endprogram      {printf("END_PROGRAM\n"); col += yyleng;}
integer         {printf("INTEGER\n"); col += yyleng;}
array           {printf("ARRAY\n"); col += yyleng;}
of              {printf("OF\n"); col += yyleng;}
if              {printf("IF\n"); col += yyleng;}
then            {printf("THEN\n"); col += yyleng;}
endif           {printf("ENDIF\n"); col += yyleng;}
else            {printf("ELSE\n"); col += yyleng;}
elseif          {printf("ELSEIF\n"); col += yyleng;}
while           {printf("WHILE\n"); col += yyleng;}
do              {printf("DO\n"); col += yyleng;}
beginloop       {printf("BEGINLOOP\n"); col += yyleng;}
endloop         {printf("ENDLOOP\n"); col += yyleng;}
break           {printf("BREAK\n"); col += yyleng;}
continue        {printf("CONTINUE\n"); col += yyleng;}
exit            {printf("EXIT\n"); col += yyleng;}
read            {printf("READ\n"); col += yyleng;}
write           {printf("WRITE\n"); col += yyleng;}
and             {printf("AND\n"); col += yyleng;}
or              {printf("OR\n"); col += yyleng;}
not             {printf("NOT\n"); col += yyleng;}
true            {printf("TRUE\n"); col += yyleng;}
false           {printf("FALSE\n"); col += yyleng;}

-               {printf("SUB\n"); col += yyleng;}
\+              {printf("ADD\n"); col += yyleng;}
\*              {printf("MULT\n"); col += yyleng;}
\/              {printf("DIV\n"); col += yyleng;}
%               {printf("MOD\n"); col += yyleng;}

==              {printf("EQ\n"); col += yyleng;}
\<\>            {printf("NEQ\n"); col += yyleng;}
\<              {printf("LT\n"); col += yyleng;}
\>              {printf("GT\n"); col += yyleng;}
\<=             {printf("LTE\n"); col += yyleng;}
\>=             {printf("GTE\n"); col += yyleng;}

{ID}            {printf("IDENT %s\n", yytext); col += yyleng;}
{INTEGER}       {printf("NUMBER %s\n", yytext); col += yyleng;}

;               {printf("SEMICOLON\n"); col += yyleng;}
\:               {printf("COLON\n"); col += yyleng;}
,               {printf("COMMA\n"); col += yyleng;}
\?              {printf("QUESTION\n"); col += yyleng;}
\[              {printf("L_BRACKET\n"); col += yyleng;}
\]              {printf("R_BRACKET\n"); col += yyleng;}
\(              {printf("L_PAREN\n"); col += yyleng;}
\)              {printf("R_PAREN\n"); col += yyleng;}
\:=              {printf("ASSIGN\n"); col += yyleng;}

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
      fprintf(stderr, "Error at line %d, column %d: unrecognized symbol \"%s\"\n", row, col, s);
      break;
    }
    case BAD_ID1:{
      fprintf(stderr, "Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", row, col, s);
      break;
    }
    case BAD_ID2:{
      fprintf(stderr, "Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", row, col, s);
      break;
    }
    default:{
      fprintf(stderr, "Unknown Error at line %d, column %d with character(s) \"%s\"\n", row, col, s);
    }
  }
  exit(1);
}

int main( int argc, char **argv ){
  ++argv, --argc;  // skip over program name
  if ( argc > 0 )
    yyin = fopen( argv[0], "r" );
  else
    yyin = stdin;

  yylex();
}