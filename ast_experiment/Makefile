all: tree.png

ast-test: test-ast.cpp ast.hpp
	g++ -g -std=c++11 test-ast.cpp ast.hpp -o ast-test

tree.gv: ast-test
	ast-test > tree.gv && cat tree.gv

tree.png: tree.gv
	dot -Tpng -otree.png tree.gv

clean:
	rm -f ast-test tree.gv tree.png
