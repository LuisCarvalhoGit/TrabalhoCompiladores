CC=gcc
BISON=bison
BISON_INPUT=Nave-parser.y
BISON_OUTPUT=Nave-parser.tab.c
BISON_HEADER=Nave-parser.tab.h
LEX=flex
LEX_OUTPUT=lex.yy.c
LEX_INPUT=Nave-lexer.l
CFLAGS=-lm -ll -lfl
TARGETS=${BISON_OUTPUT} ${LEX_OUTPUT} a.out

all: ${TARGETS}

# gerar o ficheiro Nave-parser.tab.c e Nave-parser.tab.h
${BISON_OUTPUT} ${BISON_HEADER}: ${BISON_INPUT}
	${BISON} -d ${BISON_INPUT}

# gerar o ficheiro lex.yy.c
${LEX_OUTPUT}: ${LEX_INPUT}
	${LEX} ${LEX_INPUT}

# Compilar ficheiros .c
a.out: ${BISON_OUTPUT} ${LEX_OUTPUT}
	${CC} ${BISON_OUTPUT} ${LEX_OUTPUT} ${CFLAGS} -o parser

clean:
	rm -f ${BISON_OUTPUT} ${LEX_OUTPUT} parser ${BISON_HEADER} Alienship.txt


