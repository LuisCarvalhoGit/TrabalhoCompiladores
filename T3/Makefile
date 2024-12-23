CC=gcc
BISON=bison 
BISON_INPUT=exe1.y
BISON_OUTPUT=exe1.tab.c
LEX=lex
LEX_OUTPUT=lex.yy.c 
LEX_INPUT=exe1.l 
CFLAGS=-lfl
TARGETS=exe1.tab.c lex.yy.c a.out

all: ${TARGETS}

# gerar o ficheiro exe1.tab.c
${BISON_OUTPUT}: ${BISON_INPUT}
	${BISON} -d ${BISON_INPUT}

# gerar o ficheiro lex.yy.c
${LEX_OUTPUT}: ${LEX_INPUT}
	${LEX} ${LEX_INPUT}

# Compilar ficheiros .c
a.out: ${BISON_OUTPUT} ${LEX_OUTPUT}
	${CC} ${BISON_OUTPUT} ${LEX_OUTPUT} ${CFLAGS} -o a.out

clean:
	rm -f ${BISON_OUTPUT} ${LEX_OUTPUT} a.out exe1.tab.h
