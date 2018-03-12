
all: parse

parser.cpp parser.hpp: parser.y
	bison -d -o parser.cpp parser.y

scanner.cpp: scanner.l
	flex -o scanner.cpp scanner.l

parse: main.cpp parser.cpp scanner.cpp ast.hpp
	g++ main.cpp parser.cpp scanner.cpp ast.hpp -std=c++11 -g -o parse

# p1.gv: parse p1.py
#     parse < p1.py > p1.gv && cat p1.gv
#
# p1.png: p1.gv
#     dot -Tpng -op1.png p1.gv

clean:
	rm -f parse scanner.cpp parser.cpp parser.hpp *.gv *.png
