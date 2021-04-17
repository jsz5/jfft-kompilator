all: parser.tab lexer.l.c
	g++ -std=c++11 -o kompilator parser.tab.c lexer.l.c -lm

lexer.l.c: lexer.l
	flex -o lexer.l.c lexer.l

parser.tab: parser.y
	bison -d parser.y

clean:
	rm parser.tab.* lexer.l.*

cleanall:
	rm kompilator
