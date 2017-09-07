CC = g++
all: build

lexer.cpp: lexer.lex
	flex --outfile=$@ $<

build: lexer

lexer: lexer.cpp
	$(CC) lexer.cpp -lfl -std=c++11 -o lexer

.PHONY: clean

run: build
	./lexer $(arg)

clean:
	rm -f *.o *~ lexer.cpp lexer
