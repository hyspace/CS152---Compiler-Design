#ifndef __heading_h__
#define __heading_h__


#include <iostream>
#include <vector>
#include <stack>
#include <unordered_map>

#include <string>
#include <sstream>
#include <fstream>
#include <stdio.h>

#define __debug__ 0

using namespace std;

enum symbol_type { INT, INT_ARRAY };

typedef string * symbol_place;
typedef string * label;

struct Symbol{
    int val;
    int size; //for arrays only; -1 otherwise
    symbol_type type;
};

struct Loop{
  label istart;
  label iexit;
};

// typedef struct{
//   string *name;
//   unsigned int offset;
//   symbol_type type;
// } symbol_place;

struct Var_type{
    symbol_place place;
    symbol_place offset;
    symbol_type type;
    stringstream * code;
};

bool insert_to_symbol_table(string& name, const Symbol& value);
inline const Symbol * is_duplicate(const string& name);

inline string gen(const char * opration, string *op1);
inline string gen(const char * opration, string *op1, string *op2);
inline string gen(const char * opration, string *op1, string *op2, string *op3);
label new_label();
symbol_place new_temp();
symbol_place new_ptemp();
void print_symbols();
void yyerror(const char *msg);

#endif
