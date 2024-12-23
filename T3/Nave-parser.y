%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// External function declarations
extern int yylex();
extern int yylineno;
extern char* yytext;
void yyerror(const char *s);

// Output file handling
FILE *output_file;
%}

%union {
    char *str;
    int num;
}

%token START END SEMICOLON LPAREN RPAREN
%token ON OFF TAKE_OFF LAND TURN MOVE FLY SET_SHIP SET_SPACE
%token <str> SHIP_ID
%token <num> NUMBER DIRECTION_TURN DIRECTION_MOVE ONOFF_STATE

%type <str> instruction_block
%type <str> instructions
%type <str> instruction
%type <str> on_instruction off_instruction takeoff_instruction
%type <str> land_instruction turn_instruction move_instruction
%type <str> fly_instruction set_ship_instruction set_space_instruction

%%

program:
    /* Empty program is allowed */
    | program instruction_block
    ;

instruction_block: 
    START LPAREN SHIP_ID RPAREN ':' instructions ':' END {
        printf("[PARSER] Instruction block for ship %s processed successfully\n", $3);
        fprintf(output_file, "--- Instruction Block for Ship %s ---\n", $3);
        $$ = $3; // Pass the SHIP_ID to the parent
    }
    ;

instructions:
    instruction {
        $$ = $1; // Single instruction
    }
    | instructions SEMICOLON instruction {
        $$ = $1; // Combine multiple instructions (if needed for semantics)
    }
    ;

instruction: 
    on_instruction { $$ = $1; }
    | off_instruction { $$ = $1; }
    | takeoff_instruction { $$ = $1; }
    | land_instruction { $$ = $1; }
    | turn_instruction { $$ = $1; }
    | move_instruction { $$ = $1; }
    | fly_instruction { $$ = $1; }
    | set_ship_instruction { $$ = $1; }
    | set_space_instruction { $$ = $1; }
    ;

on_instruction: 
    ON { 
        printf("[PARSER] Power On Instruction\n");
        fprintf(output_file, "acao(ligar)\n"); 
        $$ = strdup("ON");
    }
    ;

off_instruction: 
    OFF { 
        printf("[PARSER] Power Off Instruction\n");
        fprintf(output_file, "acao(desligar)\n"); 
        $$ = strdup("OFF");
    }
    ;

takeoff_instruction: 
    TAKE_OFF { 
        printf("[PARSER] Take Off Instruction\n");
        $$ = strdup("TAKE_OFF");
    }
    ;

land_instruction: 
    LAND { 
        printf("[PARSER] Land Instruction\n");
        $$ = strdup("LAND");
    }
    ;

turn_instruction: 
    TURN { 
        printf("[PARSER] Turn Instruction\n");
        $$ = strdup("TURN");
    }
    ;

move_instruction: 
    MOVE { 
        printf("[PARSER] Move Instruction\n");
        $$ = strdup("MOVE");
    }
    ;

fly_instruction: 
    FLY { 
        printf("[PARSER] Fly Instruction\n");
        $$ = strdup("FLY");
    }
    ;

set_ship_instruction:
    SET_SHIP { 
        printf("[PARSER] Set Ship Instruction\n");
        $$ = strdup("SET_SHIP");
    }
    ;

set_space_instruction:
    SET_SPACE { 
        printf("[PARSER] Set Space Instruction\n");
        $$ = strdup("SET_SPACE");
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error on line %d: %s\n", yylineno, s);
    fprintf(stderr, "Near token: %s\n", yytext);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    // Open input file
    extern FILE *yyin;
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Error opening input file");
        return 1;
    }

    // Open output file
    output_file = fopen("Alienship.txt", "w");
    if (!output_file) {
        perror("Error creating output file");
        fclose(yyin);
        return 1;
    }

    // Parse the input
    printf("[PARSER] Starting spacecraft instruction parsing...\n");
    yyparse();

    // Close files
    fclose(yyin);
    fclose(output_file);

    printf("[PARSER] Parsing complete. Check Alienship.txt for output.\n");
    return 0;
}
