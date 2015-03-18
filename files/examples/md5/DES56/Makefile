
CFLAGS= -O6 -DUSG=0 -DBSD=0

FILES=	Makefile des56.h des56.c fdemo.c ftest.c

all:	demo test

# demo -- evaluate, test and time DES, works even on non-UNIX systems

demo:	fdemo
	./fdemo -demo -c 1000

fdemo:	fdemo.o des56.o
	${CC} -o $@ $@.o des56.o

# test -- evaluates DES, compares with UNIX crypt

test:	ftest
	./ftest 4869207468657265 a820105412de3991 77129bd8c052e7
	./ftest 1.21280ac -c 5000000 -k 1000000 -C 100000 -K 100000

ftest:	ftest.o des56.o
	${CC} -o $@ $@.o des56.o -lcrypt

dist:
	@tar cvf - ${FILES}

clean:
	rm -f clean core fdemo ftest fdemo.o ftest.o des56.o

