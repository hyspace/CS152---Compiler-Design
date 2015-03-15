/* calculator. */
%{
  #include "heading.h"
  int yylex(void);
  extern int row;
  extern int col;

  stringstream *program_code;
  stringstream final_code;
  string program_name;

  unordered_map<string, Symbol> symbol_table;
  stack<Loop> loop_stack;

  label start_label = new string("START");
  label end_label = new string("EndLabel");

  symbol_place true_val = new string("1");
  symbol_place false_val = new string("0");
%}

%union{
  int                     int_val;
  char                    str_val[256];
  string                  *comp_type;
  struct{
    stringstream *code;
  }                       Nonterm;
  struct{
    //expression
    symbol_place place;
    //cond
    label iexit;
    label ifalse;
    label istart;
    //declaration
    symbol_type type;
    uint length;
    symbol_place offset;
    vector<string> *ids;
    vector<Var_type> *vars;
    //all
    stringstream *code;
  }                       Statement;
}

%error-verbose
%token PROGRAM BEGIN_PROGRAM END_PROGRAM INTEGER ARRAY OF IF THEN ENDIF ELSE ELSEIF WHILE DO BEGINLOOP ENDLOOP BREAK CONTINUE EXIT READ WRITE AND OR NOT
%token TRUE FALSE
%token SUB ADD MULT DIV MOD
%token EQ NEQ LT GT LTE GTE
%token <str_val> IDENT
%token <int_val> NUMBER
%token SEMICOLON COLON COMMA QUESTION L_BRACKET R_BRACKET L_PAREN R_PAREN ASSIGN

%type <Nonterm> program block many_declarations statement var_statement if_statement while_statement do_statement read_statement write_statement
%type <Statement> beginloop many_statements bool_exp else_statements many_elseif_statements expression post_var_statement multiplicative_exp term more_terms post_term declaration many_ids post_declaration var more_multiplicative_exps more_relation_and_exps relation_and_exp more_relation_exps relation_exp post_relation_exp if_front_statements many_vars
%type <comp_type> comp

%%
program:
      PROGRAM IDENT SEMICOLON block END_PROGRAM {
        program_name = string($2);
        if(is_duplicate(program_name)!=NULL){
          yyerror("Declared a variable with the same name as the MINI-L program itself");
        }
        program_code = $4.code;
      }
      ;

block:
      many_declarations BEGIN_PROGRAM many_statements {
        $$.code = $1.code;
        *($$.code) << $3.code->str();
        //delete $3.code;
      }
      ;

many_declarations:
      many_declarations declaration SEMICOLON {
        $$.code = $1.code;
        *($$.code) << $2.code->str();
        //delete $2.code;
      }
      | declaration SEMICOLON {
        $$.code = $1.code;
      }
      ;

many_statements:
      many_statements statement SEMICOLON {
        $$.code = $1.code;
        *($$.code) << $2.code->str();
        //delete $2.code;
      }
      | statement SEMICOLON {
        $$.code = $1.code;
      }
      ;

declaration:
      many_ids COLON post_declaration INTEGER {
        $$.code = new stringstream();
        for(int i=0; i<$1.ids->size(); ++i){
          Symbol symbol;
          symbol.type = $3.type;
          symbol.size = $3.length;
          insert_to_symbol_table($1.ids->at(i), symbol);
        }
        //delete $1.ids;
      }
      ;

many_ids:
      IDENT {
        $$.ids = new vector<string>();
        $$.ids->push_back(string($1));
      }
      | many_ids COMMA IDENT {
        $$.ids = $1.ids;
        $$.ids->push_back(string($3));
      }
      ;

post_declaration:
      {
        $$.type = INT;
        $$.length = 0;
      }//empty
      | ARRAY L_BRACKET NUMBER R_BRACKET OF {
        if($3 <= 0){
          yyerror("Declaring an array of size <= 0");
        }
        $$.type = INT_ARRAY;
        $$.length = $3;
      }
      ;

statement:
      var_statement {
        $$.code = $1.code;
      }
      | if_statement {
        $$.code = $1.code;
      }
      | while_statement {
        $$.code = $1.code;
      }
      | do_statement {
        $$.code = $1.code;
      }
      | read_statement {
        $$.code = $1.code;
      }
      | write_statement {
        $$.code = $1.code;
      }
      | BREAK {
        if(loop_stack.size() < 1){
          yyerror("Using break statement outside a loop.");
        }
        $$.code = new stringstream();
        Loop l = loop_stack.top();
        *($$.code) << gen(":=", l.iexit);
      }
      | CONTINUE {
        if(loop_stack.size() < 1){
          yyerror("Using continue statement outside a loop.");
        }
        $$.code = new stringstream();
        Loop l = loop_stack.top();
        *($$.code) << gen(":=", l.istart);
      }
      | EXIT {
        $$.code = new stringstream();
        *($$.code) << gen(":=", end_label);
      }
      ;

var_statement:
      var ASSIGN post_var_statement {
        $$.code = $1.code;
        if ($1.type == INT_ARRAY){
          *($$.code) <<
            $3.code->str() <<
            gen("[]=", $1.place, $1.offset, $3.place);
        }else{
          *($$.code) <<
          $3.code->str() <<
          gen("=", $1.place, $3.place);
        }
        //delete $3.code;
      }
      ;

post_var_statement:
      expression {
        $$.place = $1.place;
        $$.code = $1.code;
      }
      | bool_exp QUESTION expression COLON expression {
        label iexit = new_label();
        label ifalse = new_label();
        $$.code = $1.code;
        $$.place = new_temp();
        *($$.code) <<
          gen("?:=", ifalse, $1.place) <<
          $3.code->str() <<
          gen("=", $$.place, $3.place) <<
          gen(":=", iexit) <<
          gen(":", ifalse) <<
          $5.code->str() <<
          gen("=", $$.place, $5.place) <<
          gen(":", iexit);
        //delete $3.code;
        //delete $5.code;
      }
      ;

if_statement:
      IF if_front_statements else_statements ENDIF {
        $$.code = $3.code;
        *($$.code) << gen(":", $2.iexit);
      }
      ;

if_front_statements:
      bool_exp THEN many_statements {
        $$.iexit = new_label();
        $$.ifalse = new_label();
        $$.code = $1.code;
        *($$.code) <<
          gen("?:=", $$.ifalse, $1.place) <<
          $3.code->str() <<
          gen(":=", $$.iexit);
        //delete $3.code;
      };

else_statements:
      {
        //Inherited attrs
        $$.iexit = $<Statement>0.iexit;
        $$.code = $<Statement>0.code;
        *($$.code) <<
          gen(":", $<Statement>0.ifalse);

      }//empty
      | many_elseif_statements ELSE many_statements {
        //Inherited attrs
        $$.code = $<Statement>0.code;
        $$.iexit = $1.iexit;
        *($$.code) <<
          $1.code->str() <<
          gen(":", $1.ifalse) <<
          $3.code->str() <<
          gen(":=", $$.iexit);
        //delete $3.code;
        //delete $1.code;
      }
      ;

many_elseif_statements:
      {
        $$.code =new stringstream();
        $$.ifalse = $<Statement>0.ifalse;
        $$.iexit = $<Statement>0.iexit;
      }
      | many_elseif_statements ELSEIF bool_exp many_statements {
        $$.code = $1.code;
        $$.iexit = $1.iexit;
        $$.ifalse = new_label();
        *($$.code) <<
          gen(":", $1.ifalse) <<
          $3.code->str() <<
          gen("?:=", $$.ifalse, $3.place) <<
          $4.code->str() <<
          gen(":=", $$.iexit);
        //delete $3.code;
        //delete $4.code;
      }
      ;

while_statement:
      WHILE bool_exp beginloop many_statements ENDLOOP {
        $$.code = new stringstream();
        label istart = $3.istart;
        label iexit = $3.iexit;
        *($$.code) <<
          gen(":", istart) <<
          $2.code->str() <<
          gen("?:=", iexit, $2.place) <<
          $4.code->str() <<
          gen(":=", istart) <<
          gen(":", iexit);
        loop_stack.pop();
        //delete $2.code;
        //delete $4.code;
      }
      ;

do_statement:
      DO beginloop many_statements ENDLOOP WHILE bool_exp {
        $$.code = new stringstream();
        label istart = $2.istart;
        label iexit = $2.iexit;
        *($$.code) <<
          gen(":", istart) <<
          $3.code->str() <<
          $6.code->str() <<
          gen("?:=", iexit, $3.place) <<
          gen(":=", istart) <<
          gen(":", iexit);
        loop_stack.pop();
        //delete $3.code;
        //delete $6.code;
      }
      ;
beginloop:
      BEGINLOOP{
        Loop l;
        $$.istart = l.istart = new_label();
        $$.iexit = l.iexit = new_label();
        loop_stack.push(l);
      }
      ;
read_statement:
      READ many_vars {
        $$.code = new stringstream();
        for(int i = 0; i< $2.vars->size(); ++i){
          if($2.vars->at(i).type == INT_ARRAY){
            *($$.code) <<
              $2.vars->at(i).code->str() <<
              gen(".[]<", $2.vars->at(i).place, $2.vars->at(i).offset);
            //delete $2.vars->at(i).code;
          }else{
            *($$.code) <<
              gen(".<", $2.vars->at(i).place);
          }
        }
        //delete $2.vars;
      }
      ;

many_vars:
      many_vars COMMA var{
        $$.vars = $1.vars;
        Var_type var;
        var.type = $3.type;
        var.place = $3.place;
        var.offset = $3.offset;
        var.code = $3.code;
        $$.vars->push_back(var);
        //delete $3.code;
      }
      | var{
        $$.vars = new vector<Var_type>();
        Var_type var;
        var.type = $1.type;
        var.place = $1.place;
        var.offset = $1.offset;
        var.code = $1.code;
        $$.vars->push_back(var);
      }
      ;

write_statement:
      WRITE many_vars {
        $$.code = new stringstream();
        for(int i = 0; i< $2.vars->size(); ++i){
          if($2.vars->at(i).type == INT_ARRAY){
            *($$.code) <<
              $2.vars->at(i).code->str() <<
              gen(".[]>", $2.vars->at(i).place, $2.vars->at(i).offset);
            //delete $2.vars->at(i).code;
          }else{
            *($$.code) <<
              gen(".>", $2.vars->at(i).place);
          }
        }
      }
      ;

bool_exp:
      relation_and_exp more_relation_and_exps {
        $$.code = $2.code;
        $$.place = new_ptemp();
        *($$.code) <<
          gen ("==", $$.place, $2.place, false_val);
      }
      ;

more_relation_and_exps:
      {
        $$.code = $<Statement>0.code;
        $$.place = $<Statement>0.place;
      }//empty
      | more_relation_and_exps OR relation_and_exp  {
        $$.code = $1.code;
        symbol_place tmp = new_ptemp();
        *($$.code) <<
          $3.code->str() <<
          gen ("||", tmp, $1.place, $3.place);
        $$.place = tmp;
        //delete $3.code;
      }
      ;

relation_and_exp:
      relation_exp more_relation_exps {
        $$.code = $2.code;
        $$.place = $2.place;
      }
      ;

more_relation_exps:
      {
        $$.code = $<Statement>0.code;
        $$.place = $<Statement>0.place;
      }//empty
      | more_relation_exps AND relation_exp {
        $$.code = $1.code;
        symbol_place tmp = new_ptemp();
        *($$.code) <<
          $3.code->str() <<
          gen ("&&", tmp, $1.place, $3.place);
        $$.place = tmp;
        //delete $3.code;
      }
      ;

relation_exp:
      NOT post_relation_exp {
        $$.code = $2.code;
        $$.place = $2.place;
        *($$.code) <<
          gen ("!", $$.place, $$.place);
      }
      | post_relation_exp {
        $$.code = $1.code;
        $$.place = $1.place;
      }
      ;

post_relation_exp:
      expression comp expression {
        $$.code = $1.code;
        symbol_place tmp = new_ptemp();
        *($$.code) <<
          $3.code->str() <<
          gen((*($2)).c_str(), tmp, $1.place, $3.place);
        $$.place = tmp;
        //delete $3.code;

      }
      | TRUE {
        $$.code = new stringstream();
        $$.place = true_val;
      }
      | FALSE {
        $$.code = new stringstream();
        $$.place = false_val;
      }
      | L_PAREN bool_exp R_PAREN {
        $$.code = $2.code;
        $$.place = $2.place;
      }
      ;

comp:
      EQ {
        $$ = new string("==");
      }
      | NEQ {
        $$ = new string("!=");
      }
      | LT {
        $$ = new string("<");
      }
      | GT {
        $$ = new string(">");
      }
      | LTE {
        $$ = new string("<=");
      }
      | GTE {
        $$ = new string(">=");
      }
      ;

expression:
      multiplicative_exp more_multiplicative_exps {
        $$.code = $2.code;
        $$.place = $2.place;
      }
      ;

more_multiplicative_exps:
      {
        $$.code = $<Statement>0.code;
        $$.place = $<Statement>0.place;
      }//empty
      | more_multiplicative_exps ADD multiplicative_exp {
        $$.code = $1.code;
        symbol_place tmp = new_temp();
        *($$.code) <<
          $3.code->str() <<
          gen ("+", tmp, $1.place, $3.place);
        $$.place = tmp;
        //delete $3.code;
      }
      | more_multiplicative_exps SUB multiplicative_exp {
        $$.code = $1.code;
        symbol_place tmp = new_temp();
        *($$.code) <<
          $3.code->str() <<
          gen ("-", tmp, $1.place, $3.place);
        $$.place = tmp;
        //delete $3.code;
      }
      ;

multiplicative_exp:
      term more_terms {
        $$.code = $2.code;
        $$.place = $2.place;
      }
      ;

more_terms:
      {
        //TODO
        $$.code = $<Statement>0.code;
        $$.place = $<Statement>0.place;
      }//empty
      | more_terms MULT term {
        $$.code = $1.code;
        symbol_place tmp = new_temp();
        *($$.code) <<
          $3.code->str() <<
          gen ("*", tmp, $1.place, $3.place);
        $$.place = tmp;
        //delete $3.code;
      }
      | more_terms MOD term {
        $$.code = $1.code;
        symbol_place tmp = new_temp();
        *($$.code) <<
          $3.code->str() <<
          gen ("%", tmp, $1.place, $3.place);
        $$.place = tmp;
        //delete $3.code;
      }
      | more_terms DIV term {
        $$.code = $1.code;
        symbol_place tmp = new_temp();
        *($$.code) <<
          $3.code->str() <<
          gen ("/", tmp, $1.place, $3.place);
        $$.place = tmp;
        //delete $3.code;
      }
      ;

term:
      SUB post_term {
        $$.code = $2.code;
        *($$.code) << gen ("-", $2.place, false_val, $2.place);
        $$.place = $2.place;
      }
      | post_term {
        $$.code = $1.code;
        $$.place = $1.place;
      }
      ;

post_term:
      var {
        $$.code = $1.code;
        if($1.type == INT_ARRAY){
          symbol_place tmp = new_temp();
          *($$.code) <<
            $1.code->str() <<
            gen("=[]", tmp, $1.place, $1.offset);
          $$.place = tmp;
        }else{
          $$.place = $1.place;
        }
      }
      | NUMBER {
        $$.code = new stringstream();
        symbol_place tmp = new string();
        *tmp = to_string($1);
        $$.place = tmp;
      }
      | L_PAREN expression R_PAREN {
        $$.code = $2.code;
        $$.place = $2.place;
      }
      ;

var:
      IDENT {
        symbol_place name = new string($1);
        const Symbol *s;
        if((s = is_duplicate(*name))!= NULL){
          if(s->type == INT){
            $$.place = name;
            $$.type = INT;
            $$.code = new stringstream();
          }else{
            yyerror("Forgetting to specify an array index when using an array variable.");
          }
        }else{
          yyerror("Using a variable without having first declared it");
        }
      }
      | IDENT L_BRACKET expression R_BRACKET {
        //array
        symbol_place name = new string($1);
        const Symbol *s;
        if((s = is_duplicate(*name))!= NULL){
          if(s->type == INT_ARRAY){
            $$.place = name;
            $$.offset = $3.place;
            $$.type = INT_ARRAY;
            $$.code = $3.code;
          }else{
            yyerror("Specifying an array index when using a regular integer variable");
          }
        }else{
          yyerror("Using a variable without having first declared it");
        }

      }
      ;
%%

inline const Symbol * is_duplicate(const string& name){
  unordered_map<string, Symbol>::const_iterator got = symbol_table.find(name);
  if(got == symbol_table.end()){
    return NULL;
  }else{
    return &got->second;
  }
}

inline string gen(const char * opration, string *op1){
  string t = string(opration);
  if (t == ":"){
    return string(opration) + " " + *op1 + "\n";
  }else{
    return "   " + string(opration) + " " + *op1 + "\n";
  }

}
string inline gen(const char * opration, string *op1, string *op2){
  return "   " + string(opration) + " " + *op1 + ", " + *op2 + "\n";
}
string inline gen(const char * opration, string *op1, string *op2, string *op3){
  return "   " + string(opration) + " " + *op1 + ", " + *op2 + ", " + *op3 + "\n";
}

bool insert_to_symbol_table(string& name, const Symbol& value){
  if(is_duplicate(name)){
    yyerror("Defining a variable more than once");
    return false;
  }else{
    pair<string, Symbol> symbol(name, value);
    symbol_table.insert(symbol);
    return true;
  }
}

symbol_place new_ptemp(){
  static unsigned int counter = 0;
  Symbol value;
  symbol_place name = new string();
  bool success = false;
  do{
    *name = "p" + to_string(counter++);
    success = insert_to_symbol_table(*name, value);
  } while(!success);
  return name;
}

symbol_place new_temp(){
  static unsigned int counter = 0;
  Symbol value;
  symbol_place name = new string();
  bool success = false;
  do{
    *name = "t" + to_string(counter++);
    success = insert_to_symbol_table(*name, value);
  } while(!success);
  return name;
}

void print_symbols(){
  for(auto kv_pair: symbol_table){
    if(kv_pair.second.type == INT_ARRAY){
      string s = to_string(kv_pair.second.size);
      final_code << gen(".[]", (string *)&(kv_pair.first), &s);
    }else{
      final_code << gen(".", (string *)&(kv_pair.first));
    }
  }
}

label new_label(){
  static int count = 0;
  string *ls = new string();
  *ls = "L" + to_string(count++);
  return ls;
}

int main(int argc, char **argv) {
   yyparse();

   print_symbols();

   final_code << gen(":", start_label);

   final_code << program_code->str();

   final_code << gen(":", end_label);

   ofstream file;
   file.open(program_name + ".mil");
   file << final_code.str();
   file.close();

   return 0;
}

void yyerror(const char *msg) {
   fprintf(stderr, "** Line %d, position %d: %s\n", row, col, msg);
   exit(1);
}