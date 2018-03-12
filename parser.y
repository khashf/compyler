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
ASTNode* root = nullptr;
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
        BlockNode* result = new BlockNode(name);
        BlockNode* b = dynamic_cast<BlockNode*>($1);

        std::vector<ASTNode*>::iterator it;
        for (it = b->childs.begin(); it != b->childs.end(); ++it) {
            result->childs.push_back((*it));
        }
        root = result;
    }
  ;

statements
  : statement { 
        BlockNode* result = new BlockNode(std::string("temp"));
        result->childs.push_back($1);
        $$ = result;
    }
  | statements statement { 
        BlockNode* result = new BlockNode(std::string("temp"));
        BlockNode* tmp1 = dynamic_cast<BlockNode*>($1);
        /* BlockNode* tmp2 = dynamic_cast<BlockNode*>($2); */

        /* Bring all the childs of $1 to $$ */
        std::vector<ASTNode*>::iterator it;
        for (it = tmp1->childs.begin(); it != tmp1->childs.end(); ++it) {
            result->childs.push_back((*it));
        }
        result->childs.push_back($2);
        $$ = result;
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
        UnaryNode* result = new UnaryNode(name, "Paren");
        result->child = $2;
        $$ = result;
    }
  ;

negated_expression
  : NOT primary_expression { 
        std::string name = "not" + std::to_string(n_nodes);
        ++n_nodes;
        UnaryNode* result = new UnaryNode(name, "NOT");
        result->child = $2;
        $$ = result;
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
        BinaryNode* result = new BinaryNode(name, "PLUS");
        result->left = $1;
        result->right = $3;
        $$ = result;
    }
  | expression MINUS expression { 
        std::string name = "minus" + std::to_string(n_nodes);
        ++n_nodes;
        BinaryNode* result = new BinaryNode(name, "MINUS");
        result->left = $1;
        result->right = $3;
        $$ = result;
    }
  | expression TIMES expression { 
        std::string name = "times" + std::to_string(n_nodes);
        ++n_nodes;
        BinaryNode* result = new BinaryNode(name, "TIMES");
        result->left = $1;
        result->right = $3;
        $$ = result;
    } 
  | expression DIVIDEDBY expression { 
        std::string name = "dividedby" + std::to_string(n_nodes);
        ++n_nodes;
        BinaryNode* result = new BinaryNode(name, "DEVIDEDBY");
        result->left = $1;
        result->right = $3;
        $$ = result;
    }
  | expression EQ expression { 
        std::string name = "eq" + std::to_string(n_nodes);
        ++n_nodes;
        BinaryNode* result = new BinaryNode(name, "EQ");
        result->left = $1;
        result->right = $3;
        $$ = result;
    }
  | expression NEQ expression { 
        std::string name = "neq" + std::to_string(n_nodes);
        ++n_nodes;
        BinaryNode* result = new BinaryNode(name, "NEQ");
        result->left = $1;
        result->right = $3;
        $$ = result;
    }
  | expression GT expression { 
        std::string name = "gt" + std::to_string(n_nodes);
        ++n_nodes;
        BinaryNode* result = new BinaryNode(name, "GT");
        result->left = $1;
        result->right = $3;
        $$ = result;
    }
  | expression GTE expression { 
        std::string name = "gte" + std::to_string(n_nodes);
        ++n_nodes;
        BinaryNode* result = new BinaryNode(name, "GTE");
        result->left = $1;
        result->right = $3;
        $$ = result;
    }
  | expression LT expression { 
        std::string name = "lt" + std::to_string(n_nodes);
        ++n_nodes;
        BinaryNode* result = new BinaryNode(name, "LT");
        result->left = $1;
        result->right = $3;
        $$ = result;
    }
  | expression LTE expression { 
        std::string name = "lte" + std::to_string(n_nodes);
        ++n_nodes;
        BinaryNode* result = new BinaryNode(name, "LTE");
        result->left = $1;
        result->right = $3;
        $$ = result;
    }
  ;

assign_statement
  : IDENTIFIER ASSIGN expression NEWLINE { 
        std::string name = "assign" + std::to_string(n_nodes);
        ++n_nodes;
        BinaryNode* result = new BinaryNode(name, "Assignment");
        
        std::string name1 = "iden" + std::to_string(n_nodes);
        ++n_nodes;
        LiteralNode* iden = new LiteralNode(name1, "Identifier", *$1);
        result->left = iden;

        result->right = $3;
        $$ = result;
    }
  ;

block
  : INDENT statements DEDENT { 
        std::string name = "block" + std::to_string(n_nodes);
        ++n_nodes;
        BlockNode* result = new BlockNode(name);
        BlockNode* tmp2 = dynamic_cast<BlockNode*>($2);

        std::vector<ASTNode*>::iterator it;
        for (it = tmp2->childs.begin(); it != tmp2->childs.end(); ++it) {
            result->childs.push_back((*it));
        }
        $$ = result;
    }
  ;

condition
  : expression { 
        $$ = $1; 
    }
  | condition AND condition { 
        std::string name = "and" + std::to_string(n_nodes);
        ++n_nodes;
        BinaryNode* result = new BinaryNode(name, "AND");
        result->left = $1;
        result->right = $3;
        $$ = result;
    }
  | condition OR condition { 
        std::string name = "or" + std::to_string(n_nodes);
        ++n_nodes;
        BinaryNode* result = new BinaryNode(name, "OR");
        result->left = $1;
        result->right = $3;
        $$ = result;
    }
  ;

if_statement
  : IF condition COLON NEWLINE block elif_blocks else_block { 
        //$$ = new std::string("if (" + *$2 + ") " + *$5 + *$6 + *$7 + "\n"); delete $2; delete $5; delete $6; delete $7;
        std::string name = "if" + std::to_string(n_nodes);
        ++n_nodes;
        IfNode* result = new IfNode(name);
        result->condition = $2;
        result->if_block = dynamic_cast<BlockNode*>($5);

        /* Push bask $6 */
        if ($6 != nullptr) {
            ElifNode* tmp6 = dynamic_cast<ElifNode*>($6);
            result->elifs.push_back(tmp6);
            /* and push its siblings, too */
            std::vector<ElifNode*>::iterator it;
            for (it = tmp6->siblings.begin(); it != tmp6->siblings.end(); ++it) {
                result->elifs.push_back((*it));
            }
        }

        result->else_block = dynamic_cast<BlockNode*>($7);
        $$ = result;
    }
  ;

elif_blocks
  : %empty { 
        $$ = nullptr;
    }
  | elif_blocks ELIF condition COLON NEWLINE block { 
        std::string name = "elif" + std::to_string(n_nodes);
        ++n_nodes;
        ElifNode* result = new ElifNode(name);
        result->condition = $3;
        result->elif_block = dynamic_cast<BlockNode*>($6);
        if ($1 != nullptr) {
            ElifNode* tmp1 = dynamic_cast<ElifNode*>($1);
            std::vector<ElifNode*>::iterator it;
            for (it = tmp1->siblings.begin(); it != tmp1->siblings.end(); ++it) {
                result->siblings.push_back((*it));
            }
        }
        $$ = result;
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
        BinaryNode* result = new BinaryNode(name, "While");
        result->left = $2;
        result->right = $5;
        $$ = result;
    }
  ;

break_statement
  : BREAK NEWLINE { 
        std::string name = "break" + std::to_string(n_nodes);
        ++n_nodes;
        UnaryNode* result = new UnaryNode(name, "Break");
        /* result->child = nullptr; */
        $$ = result;
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
