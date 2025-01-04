%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "Nave-parser.tab.h"

// State variables
double init_x, init_y, init_z;
int input_degrees;
double min_x = 0, min_y = 0, min_z = 0, max_x = 100, max_y = 100, max_z = 100;
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
%option yylineno

%%

"START"[ \t]*"("    { printf("Found START and LPAREN\n"); return START_LPAREN; }
")"[ \t]*":"        { printf("Found RPAREN and COLON\n"); return RPAREN_COLON; }
";"                 { printf("Found SEMICOLON\n"); return SEMICOLON; }
":"[ \t]*"END"      { printf("Found COLON and END\n"); return COLON_END; }

[AEIOUaeiou][A-Za-z][0-9]{2,3} {
    printf("Found SHIP_ID\n");
    yylval.str = strdup(yytext);
    return SHIP_ID;
}

"<On--"[AEIOUaeiou][A-Za-z][0-9]{2,3}">" { 
    printf("Found On\n");
    yylval.str = strdup(yytext);
    return ON; 
}

"<Off>"             { printf("Found Off\n"); return OFF; }
"<Take-Off>"        { printf("Found Take-Off\n"); return TAKE_OFF; }
"<Land>"            { printf("Found Land\n"); return LAND; }

"<Turn--"[LR]"--"([1-9][0-9]?|[12][0-9]{2}|3[0-5][0-9])">" { 
    printf("Found Turn\n");
    yylval.str = strdup(yytext);
    return TURN; 
}

"<Move--"[0-9]+">"  { 
    printf("Found Move\n");
    yylval.str = strdup(yytext);
    return MOVE; 
}

"<Fly--"[-+]?[1-9][0-9]">" { 
    printf("Found Fly\n");
    yylval.str = strdup(yytext);
    return FLY; 
}

"<Set-Ship--"[-+]?[0-9]+"--"[-+]?[0-9]+"--"[0-9]+"--"(0|[1-9][0-9]?|[12][0-9]{2}|3[0-5][0-9])"--"[01]">" {
    //         X                   Y         Z                       DG                           ON   
    sscanf(yytext, "<Set-Ship--%lf--%lf--%lf--%d--%d>", 
           &init_x, &init_y, &init_z, &input_degrees, &is_powered);
    current_direction += input_degrees;
    printf("Found Set-Ship\n");
    yylval.str = strdup(yytext);
    return SET_SHIP;
}

"<Set-Space--"[-+]?[0-9]+"--"[-+]?[0-9]+"--"[-+]?[0-9]+"--"[-+]?[0-9]+"--"[0-9]+">" {
    //              X1              Y1             X2             Y2        Z2
    sscanf(yytext, "<Set-Space--%lf--%lf--%lf--%lf--%lf>", 
           &min_x, &min_y, &max_x, &max_y, &max_z);
    printf("Found Set-Space\n");
    yylval.str = strdup(yytext);
    return SET_SPACE;
}

[ \t\r\n]+            ; // Ignore whitespace
.                     ; // Ignore random text

%%