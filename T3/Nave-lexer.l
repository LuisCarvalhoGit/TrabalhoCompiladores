%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "Nave-parser.tab.h"

// State variables
int is_powered = 0;
int can_fly = 0;
int can_power_off = 1;
double current_x = 0;
double current_y = 0;
int current_z = 0;
int current_direction = 90; // xx -> 0; yy -> 90 (initial)

// Function to calculate new position after movement
void calculate_position(int distance, double *delta_x, double *delta_y) {
    double radians = current_direction * M_PI / 180.0;
    *delta_x = (fabs(distance * cos(radians)) < 1e-10) ? 0.0 : distance * cos(radians);
    *delta_y = (fabs(distance * sin(radians)) < 1e-10) ? 0.0 : distance * sin(radians);
}
%}

%option noyywrap

%%

"START"             { printf("Found START token\n"); return START; }
"END"              { printf("Found END token\n"); return END; }
";"                { printf("Found SEMICOLON\n"); return SEMICOLON; }
"("                { printf("Found LPAREN\n"); return LPAREN; }
")"                { printf("Found RPAREN\n"); return RPAREN; }
":"                { printf("Found COLON\n"); return COLON; }

[AEIOUaeiou][A-Za-z][0-9]{2,3} {
    printf("Found SHIP_ID\n");
    yylval.str = strdup(yytext);
    return SHIP_ID;
}

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

"<Set-Ship--"[0-9]+"--"[0-9]+"--"[0-9]+"--"(0|[1-9][0-9]?|[12][0-9]{2}|3[0-5][0-9])"--"[01]">" { 
    //         X         Y         Z                       DG                           ON   
    printf("Found Set-Ship\n");
    yylval.str = strdup(yytext);
    return SET_SHIP; 
}

"<Set-Space--"[0-9]+"--"[0-9]+"--"[0-9]+"--"[0-9]+"--"[0-9]+">" { 
    //         X1        Y1        X2        Y2        Z2
    printf("Found Set-Space\n");
    yylval.str = strdup(yytext);
    return SET_SPACE; 
}

[ \t\r]+            ; // Ignore whitespace
.                   ; // Ignore random text

%%