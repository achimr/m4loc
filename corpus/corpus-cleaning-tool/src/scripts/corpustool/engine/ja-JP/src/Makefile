TARGET := chasen makemat makeda
COMPILER = $(CC)
LINK = $(CC)

# compiler options
OPTIMIZELEVEL := -O2
ARCH := -march=i686
FASTCOMPILE := -pipe
DEBUGLEVEL := -g -Wall
USER-CFLAGS = -DHAVE_CONFIG_H -DRCPATH='"./chasenrc"' -I.
LIBS = -lstdc++ -liconv   # comment the lib iconv on linux

# archive options
ARFLAGS = cru

# tools
AR := ar
CP := cp -a
MV := mv
RM := rm -rf
CC := gcc
CXX := g++

CFLAGS := $(OPTIMIZELEVEL)
CFLAGS += $(FASTCOMPILE)
#CFLAGS += $(DEBUGLEVEL)
CFLAGS += $(USER-CFLAGS)

CXXFLAGS = $(CFLAGS)

# match all c/c++ impl files as souces.
SOURCES := $(wildcard *.c *.cc *.cpp)
# match all header files.
HEADERS := $(wildcard *.h)
# get the object files according the sources.
# OBJS := $(patsubst %.c,%.o,$(patsubst %.cc,%.o,$(patsubst %.cpp,%.o,$(SOURCES))))
# Using the above subst instruction to get the list including all object files.
# Then delete the object file corresponding to the target files to get the list below.
OBJS := block.o chalib.o connect.o getid.o getopt.o grammar.o init.o iotool.o jfgets.o katuyou.o lisp.o literal.o mmap.o parse.o print.o tokenizer.o dartsdic.o

.PHONY: all clean install
all : .deps $(TARGET)

# create the deps automatically
.deps : $(SOURCES) $(HEADERS)
	@echo @@create the deps
	$(RM) .deps
	$(COMPILER) -MM $(SOURCES) -MP > .deps
	@echo @@Source:
	@echo $(SOURCES)
	@echo @@Header:
	@echo $(HEADERS)
	@echo @Obj:
	@echo $(OBJS)

-include .deps

%.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@

%.o : %.cpp
	$(CXX) -c $(CXXFLAGS) $< -o $@

chasen : chasen.o $(OBJS)
	$(CC) $(CFLAGS) $^ $(LIBS) -o $@

makemat : makemat.o $(OBJS)
	$(CC) $(CFLAGS) $^ $(LIBS) -o $@

makeda : dumpdic.o translate.o $(OBJS)
	$(CC) $(CFLAGS) $^ $(LIBS) -o $@

clean :
	-$(RM) $(TARGET)
	-$(RM) $(OBJS)
	-$(RM) chasen.o  dumpdic.o  makemat.o  translate.o
	-$(RM) .deps

install :
	-$(CP) chasen ..
	-$(CP) makemat ../dic
	-$(CP) makeda ../dic

uninstall :
	-$(RM) ../chasen
	-$(RM) ../dic/makemat
	-$(RM) ../dic/makeda
