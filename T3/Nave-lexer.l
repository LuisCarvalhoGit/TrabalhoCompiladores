%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"

int line_num = 1;
%}

%option noyywrap

%%

"START"             { return START; }
"END"               { return END; }
";"                 { return SEMICOLON; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }

"<On--"[AEIOUaeiou][A-Za-z][0-9]{2,3}">" { 
    yylval.str = strdup(yytext);
    return ON; 
}
"<Off>"             { return OFF; }
"<Take-Off>"        { return TAKE_OFF; }
"<Land>"            { return LAND; }

"<Turn--"[LR]"--"([1-9][0-9]?|[12][0-9]{2}|3[0-5][0-9])">" { 
    yylval.str = strdup(yytext);
    return TURN; 
}

"<Move--"[1-9][0-9]">"  { 
    yylval.str = strdup(yytext);
    return MOVE; 
}

"<Fly--"[-+]?[1-9][0-9]">" { 
    yylval.str = strdup(yytext);
    return FLY; 
}

"<Set-Ship--"[0-9]+"-"[0-9]+"-"[0-9]+"-"([1-9][0-9]?|[12][0-9]{2}|3[0-5][0-9])"-"[01]">" { 
    yylval.str = strdup(yytext);
    return SET_SHIP; 
}

"<Set-Space--"[0-9]+"-"[0-9]+"-"[0-9]+"-"[0-9]+"-"[0-9]+">" { 
    yylval.str = strdup(yytext);
    return SET_SPACE; 
}

[ \t\r]+            ; // Ignore whitespace
\n                  { line_num++; }

.                   { printf("Unexpected character: %s\n", yytext); }

%%