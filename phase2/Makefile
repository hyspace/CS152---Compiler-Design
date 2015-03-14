all:
	bison -v -d --file-prefix=y mini_l.y
	flex mini_l.lex
	# gcc -o parser y.tab.c lex.yy.c -lfl
	gcc -o parser y.tab.c lex.yy.c -ll

clean:
	rm -f lex.yy.c y.tab.* y.output *.o parser