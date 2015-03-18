# makefile for O2 Pre-Compiled Test Application

OIL= ../..

include $(OIL)/config

OBJS= oilaccess.o \
      hello.o \
      main.o

INCS= -I$(LUA_INC) -I$(OIL)/src
LIBS= -L$(LUA_LIB) -L$(OIL)/src -lstdc++ -llua -lluasocket -loilall

CPPFLAGS= $(INCS)

T= servant

all: $T

$(OBJS): $(LOHS)

$T:	$(OBJS)
	g++ -o $@ $? $(LIBS)
	
clean:
	rm -f $T $(OBJS)
