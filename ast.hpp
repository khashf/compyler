#ifndef AST_H
#define AST_H

#include <iostream>
#include <vector>

// Abstract Node
struct ASTNode {
    std::string name = "undefined";
    std::string label = "undefined";
    virtual ~ASTNode() = 0;
    virtual void PrintLabel() {
        std::cout << "\t" << name << " [label=\"" << label << "\"]" << std::endl;
    }
    virtual void PrintChilds() = 0;
    virtual void Print() {
        PrintLabel();
        PrintChilds();
    }
};


struct LiteralNode: public ASTNode {
    std::string value = "undefined";
    LiteralNode(std::string name, std::string label, std::string value) {
        this->name = name;
        this->label = label;
        this->value = value; 
    }
    virtual void PrintLabel() {
        std::cout << "\t" << name << " [shape=box,label=\"" << label << ": " << value << "\"]" << std::endl;
    }
    virtual void PrintChilds() {
        // do nothing
    }
};

struct UnaryNode: public ASTNode {
    ASTNode* child = nullptr;
    UnaryNode(std::string name, std::string label) {
        this->name = name;
        this->label = label;
    }
    virtual void PrintChilds() {
        std::cout << "\t" << name << " -> " << name << "_" << child->name << ";";
        child->Print();
    }
};

struct BinaryNode: public ASTNode {
    ASTNode* left = nullptr;
    ASTNode* right = nullptr;
    BinaryNode(std::string name, std::string label) {
        this->name = name;
        this->label = label;
    }
    virtual void PrintChilds() {
        // example:
        // root_2 -> root_2_left
        // root_4_if_3_right
        std::cout << "\t" << name << " -> " << name << "_" << left->name << ";";
        left->Print();
        std::cout << "\t" << name << " -> " << name << "_" << right->name << ";";
        right->Print();
    }
};

struct BlockNode: public ASTNode {
    std::vector<ASTNode*> childs;
    BlockNode(std::string name, std::string label) {
        this->name = name;
        this->label = label;
    }
    virtual void PrintChilds() {
        std::vector<ASTNode*>::iterator it;
        for (it = childs.begin(); it != childs.end(); ++it) {
            // example
            // root -> root_4
            // if -> if_5
            // while -> while_6
            std::cout << "\t" << name << " -> " << name << "_" << (*it)->name << ";";
            (*it)->Print();
        }
    }
};

struct IfNode: public ASTNode {
    ASTNode* condition = nullptr; // TODO: Change to a more concrete type
    BlockNode* if_block = nullptr;
    BinaryNode* elif = nullptr;
    BlockNode* else_block = nullptr;
    IfNode(std::string name, std::string label) {
        this->name = name;
        this->label = label;
    }
    virtual void PrintChilds() {
        std::cout << "\t" << name << " -> " << name << "_" << condition->name << ";";
        condition->Print();
        std::cout << "\t" << name << " -> " << name << "_" << if_block->name << ";";
        if_block->Print();
        if (elif != nullptr) {
            std::cout << "\t" << name << " -> " << name << "_" << elif->name << ";";
            elif->Print();
        }
        if (else_block != nullptr) {
            std::cout << "\t" << name << " -> " << name << "_" << else_block->name << ";";
            else_block->Print();
        }
    }
};

// struct ElifNode: public ASTNode { //     ASTNode* condition; //     ASTNode* block; //     virtual void PrintChilds() { //         std::cout << "\t" << name << " -> " << name << "_" << condition->name << ";"; //         condition->Print(); //         std::cout << "\t" << name << " -> " << name << "_" << block->name << ";"; //         block->Print(); //     } //
// };
//
// struct WhileNode: public ASTNode {
//     ASTNode* condition;
//     ASTNode* block;
//     virtual void PrintChilds() {
//         std::cout << "\t" << name << " -> " << name << "_" << condition->name << ";";
//         condition->Print();
//         std::cout << "\t" << name << " -> " << name << "_" << block->name << ";";
//         block->Print();
//     }
// };


struct AST {
    ASTNode* root = new BlockNode("root", "Block");
    AST(){}
    ~AST() {
        if (root != nullptr) {
            delete root;
            root = nullptr;
        }
    }
};



#endif