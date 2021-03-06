#include <iostream>
#include <vector>
#include <string>
#include "ast.hpp"

//#define CONCAT(a,b) (a)+std::string("_")+(b)
//#define CONCAT(a,b) (a)+"_"+(b)
std::string MakeName(std::string parent_name, const std::string suffix) {
    std::string child_name = parent_name + std::string("_") + suffix;
    return child_name;
}

int main() {
    AST tree;
    tree.root = new BlockNode("root");
    BlockNode* root = dynamic_cast<BlockNode*>(tree.root);
    root->childs.push_back(new BinaryNode(MakeName("root", std::to_string((int)root->childs.size())), "Assignment"));
    root->childs.push_back(new IfNode(MakeName("root", std::to_string((int)root->childs.size()))));

    BinaryNode* root_0 = dynamic_cast<BinaryNode*>(root->childs[0]);
    root_0->left = new LiteralNode(MakeName(root_0->name, "left"), "Identifier", "pi");
    root_0->right = new BinaryNode(MakeName(root_0->name, "right"), "TIMES");

    BinaryNode* root_0_right = dynamic_cast<BinaryNode*>(root_0->right);
    root_0_right->left = new LiteralNode(MakeName(root_0_right->name, "left"), "Identifier", "a");
    root_0_right->right = new LiteralNode(MakeName(root_0_right->name, "right"), "Identifier", "b");

    IfNode* root_1 = dynamic_cast<IfNode*>(root->childs[1]);
    root_1->condition = new BinaryNode(MakeName(root_1->name, "cond"), "GT");
    root_1->if_block = new BlockNode(MakeName(root_1->name, "if"));

    BinaryNode* root_1_condition = dynamic_cast<BinaryNode*>(root_1->condition);
    root_1_condition->left = new LiteralNode(MakeName(root_1_condition->name, "left"), "Identifier", "a");
    root_1_condition->right = new LiteralNode(MakeName(root_1_condition->name, "right"), "Integer", "2");

    BlockNode* root_1_if_block = dynamic_cast<BlockNode*>(root_1->if_block);
    root_1_if_block->childs.push_back(new BinaryNode(MakeName(root_1_if_block->name, "0"), "Assignment"));
    root_1_if_block->childs.push_back(new IfNode(MakeName(root_1_if_block->name, "1")));

    IfNode* child_if = dynamic_cast<IfNode*>(root_1->if_block->childs[1]);
    child_if->condition = new UnaryNode(MakeName(child_if->name, "cond"), "NOT");
    child_if->if_block = new BlockNode(MakeName(child_if->name, "if"));

    tree.Print();

    return 0;
}
