#include <iostream>
#include <set>
#include "parser.hpp"

extern int yylex();

extern std::string* target_program;
extern std::set<std::string> symbols;

int main() {
  if (!yylex()) {
    // Write initial C++ stuff.
    std::cout << "#include <iostream>" << std::endl;
    std::cout << "int main() {" << std::endl;

    // Write declaractions for all variables.
    std::set<std::string>::iterator it;
    for (it = symbols.begin(); it != symbols.end(); it++) {
      std::cout << "double " << *it << ";" << std::endl;
    }

    // Write the program itself.
    std::cout << std::endl << "/* Begin program */" << std::endl << std::endl;
    std::cout << *target_program << std::endl;
    std::cout << "/* End program */" << std::endl << std::endl;

    // Write print statements for all symbols.
    for (it = symbols.begin(); it != symbols.end(); it++) {
      std::cout << "std::cout << \"" << *it << ": \" << " << *it << " << std::endl;" << std::endl;
    }

    // Write terminating brace.
    std::cout << "}" << std::endl;

    delete target_program;
    target_program = NULL;

  }
}
