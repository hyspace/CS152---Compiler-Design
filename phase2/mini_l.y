/* calculator. */
%{
 #include <stdio.h>
 #include <stdlib.h>
 int yylex(void);
 void yyerror(const char *msg);
 extern int row;
 extern int col;
 FILE * yyin;
%}
%union{
  int                     int_val;
  char                    str_val[256];
}

%error-verbose
%token PROGRAM BEGIN_PROGRAM END_PROGRAM INTEGER ARRAY OF IF THEN ENDIF ELSE ELSEIF WHILE DO BEGINLOOP ENDLOOP BREAK CONTINUE EXIT READ WRITE AND OR NOT
%token TRUE FALSE
%token SUB ADD MULT DIV MOD
%token EQ NEQ LT GT LTE GTE
%token IDENT NUMBER
%token SEMICOLON COLON COMMA QUESTION L_BRACKET R_BRACKET L_PAREN R_PAREN ASSIGN

%type <int_val> NUMBER
%type <str_val> IDENT


%%
program:
      PROGRAM IDENT SEMICOLON block END_PROGRAM {printf("program -> PROGRAM IDENT SEMICOLON block END_PROGRAM\n");printf("---------- %s\n", $2);}
      ;

block:
      many_declarations BEGIN_PROGRAM many_statements {printf("block -> many_declarations BEGIN_PROGRAM many_statements\n");}
      ;

many_declarations:
      declaration SEMICOLON more_declarations {printf("many_declarations -> declaration SEMICOLON more_declarations\n");}
      ;

more_declarations:
      {printf("more_declarations -> EMPTY\n");}//empty
      | declaration SEMICOLON more_declarations {printf("more_declarations -> declaration SEMICOLON more_declarations\n");}
      ;

many_statements:
      many_statements statement SEMICOLON {
        printf("many_statements -> many_statements SEMICOLON statement\n");
      }
      | statement SEMICOLON {
        printf("many_statements -> many_statements\n");
      }
      ;
// many_statements:
//       statement SEMICOLON more_statements {printf("many_statements -> statement SEMICOLON more_statements\n");}
//       ;

// more_statements:
//       {printf("more_statements -> EMPTY\n");}//empty
//       | statement SEMICOLON more_statements {printf("more_statements -> statement SEMICOLON more_statements\n");}
//       ;

declaration:
      many_ids COLON post_declaration INTEGER {printf("declaration -> many_ids COLON post_declaration INTEGER\n");}
      ;


many_ids:
      IDENT {
        printf("many_ids -> IDENT\n");
        printf("---------- %s\n", $1);
      }
      | many_ids COMMA IDENT {
        printf("many_ids -> IDENT COMMA many_ids\n");
        printf("---------- %s\n", $3);
      }
      ;

// more_ids:
//       {printf("more_ids -> EMPTY\n");}//empty
//       | COMMA IDENT more_ids {printf("many_ids -> COMMA IDENT more_ids\n");}
//       ;

post_declaration:
      {printf("post_declaration -> EMPTY\n");}//empty
      | ARRAY L_BRACKET NUMBER R_BRACKET OF {printf("post_declaration -> ARRAY L_BRACKET NUMBER R_BRACKET OF\n");}
      ;

statement:
      var_statement {printf("statement -> var_statement\n");}
      | if_statement {printf("statement -> if_statement\n");}
      | while_statement {printf("statement -> while_statement\n");}
      | do_statement {printf("statement -> do_statement\n");}
      | read_statement {printf("statement -> read_statement\n");}
      | write_statement {printf("statement -> write_statement\n");}
      | BREAK {printf("statement -> BREAK\n");}
      | CONTINUE {printf("statement -> CONTINUE\n");}
      | EXIT {printf("statement -> EXIT\n");}
      ;

var_statement:
      var ASSIGN post_var_statement {printf("var_statement -> var ASSIGN post_var_statement\n");}
      ;

post_var_statement:
      expression {printf("post_var_statement -> expression\n");}
      | bool_exp QUESTION expression COLON expression {printf("post_var_statement -> bool_exp QUESTION expression COLON expression\n");}
      ;

if_statement:
      IF bool_exp THEN many_statements else_statements ENDIF {printf("if_statement -> IF bool_exp THEN many_statements else_statements ENDIF\n");}
      ;

else_statements:
      {printf("else_statements -> EMPTY\n");}//empty
      | many_elseif_statements else_statement {printf("else_statements -> many_elseif_statements else_statement\n");}
      | else_statement {printf("else_statements -> else_statement\n");}
      ;

many_elseif_statements:
      ELSEIF bool_exp many_statements more_elseif_statements {printf("many_elseif_statements -> ELSEIF bool_exp many_statements more_elseif_statements\n");}
      ;

more_elseif_statements:
      {printf("more_elseif_statements -> EMPTY\n");}//empty
      | ELSEIF bool_exp many_statements more_elseif_statements {printf("more_elseif_statements -> ELSEIF bool_exp many_statements more_elseif_statements\n");}
      ;

else_statement:
      ELSE many_statements {printf("else_statement -> ELSE many_statements\n");}
      ;

while_statement:
      WHILE bool_exp BEGINLOOP many_statements ENDLOOP {printf("while_statement -> WHILE bool_exp BEGINLOOP many_statements ENDLOOP\n");}
      ;

do_statement:
      DO BEGINLOOP many_statements ENDLOOP WHILE bool_exp {printf("do_statement -> DO BEGINLOOP many_statements ENDLOOP WHILE bool_exp\n");}
      ;

read_statement:
      READ many_vars {printf("read_statement -> READ many_vars\n");}
      ;

many_vars:
      many_vars COMMA var{
        printf("many_vars -> many_vars COMMA var\n");
      }
      | var{
        printf("many_vars -> var\n");
      }
      ;

write_statement:
      WRITE many_vars {printf("write_statement -> WRITE many_vars\n");}
      ;

bool_exp:
      relation_and_exp more_relation_and_exps {printf("bool_exp -> relation_and_exp more_relation_and_exps\n");}
      ;

more_relation_and_exps:
      {printf("more_relation_and_exps -> EMPTY\n");}//empty
      | OR relation_and_exp more_relation_and_exps {printf("more_relation_and_exps -> OR relation_and_exp more_relation_and_exps\n");}
      ;

relation_and_exp:
      relation_exp more_relation_exps {printf("relation_and_exp -> relation_exp more_relation_exps\n");}
      ;

more_relation_exps:
      {printf("more_relation_exps -> EMPTY\n");}//empty
      | AND relation_exp more_relation_exps {printf("more_relation_exps -> AND relation_exp more_relation_exps\n");}
      ;

relation_exp:
      NOT post_relation_exp {printf("relation_exp -> NOT post_relation_exp\n");}
      | post_relation_exp {printf("relation_exp -> post_relation_exp\n");}
      ;

post_relation_exp:
      expression comp expression {printf("post_relation_exp -> expression comp expression\n");}
      | TRUE {printf("post_relation_exp -> TRUE\n");}
      | FALSE {printf("post_relation_exp -> FALSE\n");}
      | L_PAREN bool_exp R_PAREN {printf("post_relation_exp -> L_PAREN bool_exp R_PAREN\n");}
      ;

comp:
      EQ {printf("comp -> EQ\n");}
      | NEQ {printf("comp -> NEQ\n");}
      | LT {printf("comp -> LT\n");}
      | GT {printf("comp -> GT\n");}
      | LTE {printf("comp -> LTE\n");}
      | GTE {printf("comp -> GTE\n");}
      ;

expression:
      multiplicative_exp more_multiplicative_exps {printf("expression -> multiplicative_exp more_multiplicative_exps\n");}
      ;

more_multiplicative_exps:
      {printf("more_multiplicative_exps -> EMPTY\n");}//empty
      | ADD multiplicative_exp more_multiplicative_exps {printf("more_multiplicative_exps -> ADD multiplicative_exp more_multiplicative_exps\n");}
      | SUB multiplicative_exp more_multiplicative_exps {printf("more_multiplicative_exps -> SUB multiplicative_exp more_multiplicative_exps\n");}
      ;

multiplicative_exp:
      term more_terms {printf("multiplicative_exp -> term more_terms\n");}
      ;

more_terms:
      {printf("more_terms -> EMPTY\n");}//empty
      | more_terms MULT term {printf("more_terms -> MULT term more_terms\n");}
      | more_terms MOD term {printf("more_terms -> MOD term more_terms\n");}
      | more_terms DIV term {printf("more_terms -> DIV term more_terms\n");}
      ;

term:
      SUB post_term {printf("term -> SUB post_term\n");}
      | post_term {printf("term -> post_term\n");}
      ;

post_term:
      var {printf("post_term -> var\n");}
      | NUMBER {printf("post_term -> NUMBER\n");printf("---------- %d\n", $1);}
      | L_PAREN expression R_PAREN {printf("post_term -> L_PAREN expression R_PAREN\n");}
      ;

var:
      IDENT post_var{printf("var -> IDENT post_var\n");printf("---------- %s\n", $1);}
      ;

post_var:
      |{printf("post_var -> EMPTY\n");}
      L_BRACKET expression R_BRACKET{
        printf("post_var -> L_BRACKET expression R_BRACKET\n");
      }
      ;
%%

int main(int argc, char **argv) {
   if (argc > 1) {
      yyin = fopen(argv[1], "r");
      if (yyin == NULL){
         printf("syntax: %s filename\n", argv[0]);
      }
   }
   yyparse();
   return 0;
}

void yyerror(const char *msg) {
   printf("** Line %d, position %d: %s\n", row, col, msg);
}
