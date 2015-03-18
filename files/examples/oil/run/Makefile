# makefile for O2 Pre-Compiled Test Application

OIL= ../..

include $(OIL)/config

OBJS=	run.o

SRCS=	run.c

INCS= -I$(LUA_INC) -I$(OIL)/src
LIBS= -L$(LUA_LIB) -L$(OIL)/src -lm -ldl -llua -lluasocket -loilall

CFLAGS= -DPRELOAD $(INCS)

T= run

all: $T

$(OBJS): $(LOHS)

$T:	$(OBJS)
	$(CC) -o $@ $< $(LIBS)
	
clean:
	rm -f $T $(OBJS)
