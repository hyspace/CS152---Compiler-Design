all:
	rm -rf mini_l.yy.c lexer
	flex -o mini_l.yy.c mini_l.lex
	# mac
	gcc -o lexer mini_l.yy.c -ll
	# linux
	#gcc -o lexer mini_l.yy.c -lfl

test:
	cat tests/input/dowhiletest.min | ./lexer > tests/output/dowhiletest.tokens.1
	cat tests/input/ifelseiftest.min | ./lexer > tests/output/ifelseiftest.tokens.1
	cat tests/input/mytest.min | ./lexer > tests/output/mytest.tokens.1
	cat tests/input/primes.min | ./lexer > tests/output/primes.tokens.1

	diff -u tests/output/dowhiletest.tokens.1 tests/output/dowhiletest.tokens
	diff -u tests/output/ifelseiftest.tokens.1 tests/output/ifelseiftest.tokens
	diff -u tests/output/mytest.tokens.1 tests/output/mytest.tokens
	diff -u tests/output/primes.tokens.1 tests/output/primes.tokens

	cat tests/input/err1.min | ./lexer 2> tests/output/err1.stderr.1 || true
	cat tests/input/err2.min | ./lexer 2> tests/output/err2.stderr.1 || true
	cat tests/input/err3.min | ./lexer 2> tests/output/err3.stderr.1 || true

	diff -u tests/output/err1.stderr.1 tests/output/err1.stderr
	diff -u tests/output/err2.stderr.1 tests/output/err2.stderr
	diff -u tests/output/err3.stderr.1 tests/output/err3.stderr

	rm -rf tests/output/*.1