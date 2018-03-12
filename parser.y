%{
#include <iostream>
#include <set>

#include "parser.hpp"

extern int yylex();
void yyerror(YYLTYPE* loc, const char* err);
std::string* translate_boolean_str(std::string* boolean_str);

/*
 * Here, target_program is a string that will hold the target program being
 * generated, and symbols is a simple symbol table.
 */
std::string* target_program;
BlockNode* root = nullptr;
int n_nodes = 0;
std::set<std::string> symbols;
%}

 /* Enable location tracking. */
%code requires {
    #include "ast.hpp"
}
%locations

/*
 * All program constructs will be represented as strings, specifically as
 * their corresponding C/C++ translation.
 */
/* %define api.value.type { std::string* } */
%union {
    std::string* str;
    ASTNode* node;
}

/*
 * Because the lexer can generate more than one token at a time (i.e. DEDENT
 * tokens), we'll use a push parser.
 */
%define api.pure full
%define api.push-pull push
%define parse.error verbose
    
/*
 * These are all of the terminals in our grammar, i.e. the syntactic
 * categories that can be recognized by the lexer.
 */
%token <str> IDENTIFIER
%token <str> FLOAT INTEGER BOOLEAN
%token <str> INDENT DEDENT NEWLINE
%token <str> AND BREAK DEF ELIF ELSE FOR IF NOT OR RETURN WHILE
%token <str> ASSIGN PLUS MINUS TIMES DIVIDEDBY
%token <str> EQ NEQ GT GTE LT LTE
%token <str> LPAREN RPAREN COMMA COLON

%type <node> program
%type <node> statements
%type <node> statement assign_statement if_statement while_statement break_statement
%type <node> expression primary_expression negated_expression
%type <node> block
%type <node> condition
%type <node> elif_blocks else_block


/*
 * Here, we're defining the precedence of the operators.  The ones that appear
 * later have higher precedence.  All of the operators are left-associative
 * except the "not" operator, which is right-associative.
 */
%left OR
%left AND
%left PLUS MINUS
%left TIMES DIVIDEDBY
%left EQ NEQ GT GTE LT LTE
%right NOT

/* This is our goal/start symbol. */
%start program

%%

/*
 * Each of the CFG rules below recognizes a particular program construct in
 * Python and creates a new string containing the corresponding C/C++
 * translation.  Since we're allocating strings as we go, we also free them
 * as we no longer need them.  Specifically, each string is freed after it is
 * combined into a larger string.
 */
program
  : statements { 
        std::string name = "root" + std::to_string(n_nodes);
        ++n_nodes;
        root = new BlockNode(name);
        std::vector<ASTNode*>::iterator it;
        BlockNode* b = dynamic_cast<BlockNode*>($1);
        for (it = b->childs.begin(); it != b->childs.end(); ++it) {
            root->childs.push_back((*it));
        }
    }
  ;

statements
  : statement { 
        BlockNode* b = new BlockNode(std::string("temp"));
        b->childs.push_back($1);
        $$ = b;
    }
  | statements statement { 
        $$ = new BlockNode(std::string("temp"));
        /* Bring all the childs of $1 to $$ */
        std::vector<ASTNode*>::iterator it;
        for (it = $1->childs.begin(); it != $1->childs.end(); ++it) {
            $$->childs.push_back((*it));
        }
        $$->childs.push_back($2);
    }
  ;

statement
  : assign_statement { 
        $$ = $1;
    }
  | if_statement { 
        $$ = $1;
    }
  | while_statement {  
        $$ = $1;
    }
  | break_statement { 
        $$ = $1;
  }
  ;

primary_expression
  : IDENTIFIER { 
        std::string name = "iden" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new LiteralNode(name, "Identifier", *$1);
    }
  | FLOAT { 
        std::string name = "float" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new LiteralNode(name, "Float", *$1);
    }
  | INTEGER { 
        std::string name = "integer" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new LiteralNode(name, "Integer", *$1);
    }
  | BOOLEAN { 
        std::string name = "bool" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new LiteralNode(name, "Boolean", *$1);
    }
  | LPAREN expression RPAREN { 
        std::string name = "paren" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new UnaryNode(name, "Paren");
        $$->child = $2;
    }
  ;

negated_expression
  : NOT primary_expression { 
        std::string name = "not" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new UnaryNode(name, "NOT");
        $$->child = $2;
    }
  ;

expression
  : primary_expression { 
        $$ = $1; 
    }
  | negated_expression { 
        $$ = $1; 
    }
  | expression PLUS expression { 
        std::string name = "plus" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "PLUS");
        $$->left = $1;
        $$->right = $3;
    }
  | expression MINUS expression { 
        std::string name = "minus" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "MINUS");
        $$->left = $1;
        $$->right = $3;
    }
  | expression TIMES expression { 
        std::string name = "times" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "TIMES");
        $$->left = $1;
        $$->right = $3;
    } 
  | expression DIVIDEDBY expression { 
        std::string name = "dividedby" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "DEVIDEDBY");
        $$->left = $1;
        $$->right = $3;
    }
  | expression EQ expression { 
        std::string name = "eq" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "EQ");
        $$->left = $1;
        $$->right = $3;
    }
  | expression NEQ expression { 
        std::string name = "neq" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "NEQ");
        $$->left = $1;
        $$->right = $3;
    }
  | expression GT expression { 
        std::string name = "gt" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "GT");
        $$->left = $1;
        $$->right = $3;
    }
  | expression GTE expression { 
        std::string name = "gte" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "GTE");
        $$->left = $1;
        $$->right = $3;
    }
  | expression LT expression { 
        std::string name = "lt" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "LT");
        $$->left = $1;
        $$->right = $3;
    }
  | expression LTE expression { 
        std::string name = "lte" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "LTE");
        $$->left = $1;
        $$->right = $3;
    }
  ;

assign_statement
  : IDENTIFIER ASSIGN expression NEWLINE { 
        std::string name = "assign" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "Assignment");
        $$->left = $1;
        $$->right = $3;
    }
  ;

block
  : INDENT statements DEDENT { 
        std::string name = "block" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BlockNode(name);
        std::vector<ASTNode*>::iterator it;
        for (it = $1->childs.begin(); it != $1->childs.end(); ++it) {
            $$->childs.push_back((*it));
        }
    }
  ;

condition
  : expression { 
        $$ = $1; 
    }
  | condition AND condition { 
        std::string name = "and" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "AND");
        $$->left = $1;
        $$->right = $3;
    }
  | condition OR condition { 
        std::string name = "or" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "OR");
        $$->left = $1;
        $$->right = $3;
    }
  ;

if_statement
  : IF condition COLON NEWLINE block elif_blocks else_block { 
        //$$ = new std::string("if (" + *$2 + ") " + *$5 + *$6 + *$7 + "\n"); delete $2; delete $5; delete $6; delete $7;
        std::string name = "if" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new IfNode(name);
        $$->condition = $2;
        $$->if_block = $5;

        /* Push bask $6 */
        $$->elifs.push_back($6);
        /* and push its siblings, too */
        std::vector<ElifNode*>::iterator it;
        for (it = $6->siblings.begin(); it != $6->siblings.end(); ++it) {
            $$->elifs.push_back((*it));
        }

        $$->else_block = $7;
    }
  ;

elif_blocks
  : %empty { 
        $$ = nullptr;
    }
  | elif_blocks ELIF condition COLON NEWLINE block { 
        std::string name = "elif" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new ElifNode(name);
        $$->condition = $3;
        $$->elif_block = $6;
        if ($1 != nullptr) {
            std::vector<ElifNode*>::iterator it;
            for (it = $1->siblings.begin(); it != $1->siblings.end(); ++it) {
                $$->siblings.push_back((*it));
            }
        }
    }
  ;

else_block
  : %empty { 
        $$ = nullptr;
    }
  | ELSE COLON NEWLINE block { 
        std::string name = "block" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BlockNode(name);
    }


while_statement
  : WHILE condition COLON NEWLINE block { 
        std::string name = "while" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new BinaryNode(name, "While");
        $$->left = $2;
        $$->right = $5;
    }
  ;

break_statement
  : BREAK NEWLINE { 
        std::string name = "break" + std::to_string(n_nodes);
        ++n_nodes;
        $$ = new UnaryNode(name, "Break");
        $$->child = nullptr;
    }
  ;

%%

void yyerror(YYLTYPE* loc, const char* err) {
  std::cerr << "Error (line " << loc->first_line << "): " << err << std::endl;
}

/*
 * This function translates a Python boolean value into the corresponding
 * C++ boolean value.
 */
std::string* translate_boolean_str(std::string* boolean_str) {
  if (*boolean_str == "True") {
    return new std::string("true");
  } else {
    return new std::string("false");
  }
}
