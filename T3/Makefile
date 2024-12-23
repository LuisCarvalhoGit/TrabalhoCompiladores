CC=gcc
BISON=bison 
BISON_INPUT=Nave-parser.y
BISON_OUTPUT=Nave-parser.tab.c
LEX=lex
LEX_OUTPUT=lex.yy.c 
LEX_INPUT=Nave.lexer.l 
CFLAGS=-lfl
TARGETS=Nave-parser.tab.c lex.yy.c a.out

all: ${TARGETS}

# gerar o ficheiro Nave-parser.tab.c
${BISON_OUTPUT}: ${BISON_INPUT}
	${BISON} -d ${BISON_INPUT}

# gerar o ficheiro lex.yy.c
${LEX_OUTPUT}: ${LEX_INPUT}
	${LEX} ${LEX_INPUT}

# Compilar ficheiros .c
a.out: ${BISON_OUTPUT} ${LEX_OUTPUT}
	${CC} ${BISON_OUTPUT} ${LEX_OUTPUT} ${CFLAGS} -o a.out

clean:
	rm -f ${BISON_OUTPUT} ${LEX_OUTPUT} a.out Nave-parser.tab.h
