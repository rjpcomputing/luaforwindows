# makefile for O2 Pre-Compiled Test Application

OIL= ../..

include $(OIL)/config

OBJS= hello.o \
      bind.o \
      main.o

INCS= -I$(LUA_INC) -I$(OIL)/src
LIBS= -L$(LUA_LIB) -L$(OIL)/src -lstdc++ -llua -ltolua++ -lluasocket -loilbit

CFLAGS= $(INCS)
CPPFLAGS= $(INCS)

T= servant

all: $T

$(OBJS): $(LOHS)

$T:	$(OBJS)
	$(CC) -o $@ $(OBJS) $(LIBS)

bind.o: bind.cpp

bind.cpp: hello.pkg
	$(LUA5_BIN)/tolua++ -H bind.hpp -o $@ $<
clean:
	rm -f $T $(OBJS) bind.hpp bind.cpp
