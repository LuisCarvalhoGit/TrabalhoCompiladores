%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

// External function declarations
extern double init_x, init_y, init_z;
extern double min_x, min_y, max_x, max_y, max_z;
extern int yylex();
extern char* yytext;
extern int is_powered;
extern int can_fly;
extern int can_power_off;
extern double current_x;
extern double current_y;
extern int current_z;
extern int current_direction;
extern void calculate_position(int distance, double *delta_x, double *delta_y);

void yyerror(const char* s); // Function prototype for yyerror


// Output file handling
FILE *output_file;

// Movement buffer for consecutive moves
typedef struct {
    double x, y, z;
} Movement;

Movement move_buffer[100];
int move_count = 0;

void flush_move_buffer() {
    if (move_count > 0) {
        fprintf(output_file, "move");  // Write "move" only once
        for (int i = 0; i < move_count; i++) {
            fprintf(output_file, "(%.2f,%.2f,%.2f)", 
                    move_buffer[i].x, move_buffer[i].y, move_buffer[i].z);
        }
        fprintf(output_file, " ");  // Single newline after all coordinates
        move_count = 0;
    }
}
%}

%union {
    char *str;
    int num;
}

%token START END SEMICOLON LPAREN RPAREN COLON
%token <str> ON OFF TAKE_OFF LAND TURN MOVE FLY SET_SHIP SET_SPACE SHIP_ID


%%

program:
    /* Empty program is allowed */
    | program instruction_block
    ;

instruction_block: 
    START LPAREN SHIP_ID RPAREN COLON {
        fprintf(output_file, "%s\t", $3); // Write Ship ID as soon as it's parsed
    }
    init_instructions instruction_list COLON END {
        flush_move_buffer();
        fprintf(output_file, "--- End of instructions for ship %s ---\n\n", $3);
        free($3);
    }
    ;

init_instructions:
    /* Empty is allowed */
    | init_command
    | init_command SEMICOLON init_command
    ;

init_command:
    SET_SHIP {
        fprintf(output_file, "init (%.2f, %.2f, %.2f) %d\t", init_x, init_y, init_z, is_powered);
    }
    | SET_SPACE {
        fprintf(output_file, "initspace (%.2f, %.2f, 0) (%.2f, %.2f, %.2f)\t", 
                                        min_x, min_y,   max_x, max_y, max_z);
    }
    ;

instruction_list:
    instruction
    | instruction_list SEMICOLON instruction
    ;

instruction: 
    ON {
        flush_move_buffer();
        if (is_powered) {
            yyerror("Ship already powered on");
        } else {
            is_powered = 1;
            fprintf(output_file, "acao(ligar)  ");
        }
        free($1);
    }
    | OFF {
        flush_move_buffer();
        if (!is_powered) {
            yyerror("Ship already powered off");
        } else if (!can_power_off && current_z > 0) {
            yyerror("Must land before powering off");
        } else {
            is_powered = 0;
            fprintf(output_file, "acao(desligar)  ");
        }
    }
    | LAND {
        flush_move_buffer();
        if (!can_fly) {
            yyerror("Ship must be in the air to land");
        } else if (current_z != 0) {
            yyerror("Ship must be at altitude 0 to land");
        } else {
            can_fly = 0;  // The ship has landed
            can_power_off = 1;  // Allow powering off after landing
            fprintf(output_file, "acao(aterrar)  ");
        }
    }
    | SET_SHIP {
        flush_move_buffer();
        fprintf(output_file, "init (%.2f, %.2f, %.2f) %d\t", init_x, init_y, init_z, is_powered);
    }
    | SET_SPACE {
        flush_move_buffer();
        fprintf(output_file, "initspace (%.2f, %.2f, 0) (%.2f, %.2f, %.2f)\t", 
                                        min_x, min_y,   max_x, max_y, max_z);
    }
    | TAKE_OFF {
        flush_move_buffer();
        if (!is_powered) {
            yyerror("Ship must be powered on to take off");
        } else if (can_fly) {
            yyerror("Ship is already in the air");
        } else {
            can_fly = 1;  // Allow the ship to fly
            can_power_off = 0;  // Disable powering off while in the air
            fprintf(output_file, "acao(Take-off)  ");
        }
    }
    |TURN {
        flush_move_buffer();
        if (!is_powered) {
            yyerror("Ship must be powered on to turn");
        } else {
            char direction;
            int degrees;
            sscanf($1, "<Turn--%c--%d>", &direction, &degrees);  // Parse the direction and degrees from the lexeme
            
            if (degrees <= 0 || degrees >= 360) {
                yyerror("Invalid turn angle");
            } else {
                if (direction == 'R') {
                    current_direction = (current_direction - degrees + 360) % 360;
                } else {
                    current_direction = (current_direction + degrees) % 360;
                }
                fprintf(output_file, "turn(%c,%d)\t", direction, degrees);
            }
        }
        free($1);
    }
    |MOVE {
        if (!is_powered) {
            yyerror("Ship must be powered on to move");
        } else {
            int distance;
            sscanf($1, "<Move--%d>", &distance);  // Parse the distance from the lexeme
            double delta_x, delta_y;
            calculate_position(distance, &delta_x, &delta_y);
            
            move_buffer[move_count].x = delta_x;
            move_buffer[move_count].y = delta_y;
            move_buffer[move_count].z = 0;
            move_count++;
            
            current_x += delta_x;
            current_y += delta_y;
        }
        free($1);
    }
    | FLY {
        flush_move_buffer();
        if (!can_fly) {
            yyerror("Ship must take off before flying");
        } else if (!is_powered) {
            yyerror("Ship must be powered on to fly");
        } else {
            int height;
            sscanf($1, "<Fly--%d>", &height);

            if (current_z + height < 0) {
                yyerror("Cannot fly below ground level");
            } else {
                move_buffer[move_count].x = 0;
                move_buffer[move_count].y = 0;
                move_buffer[move_count].z = height;
                move_count++;
                current_z += height;
            }
        }
        free($1);
    }
    ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    // Open output file
    output_file = fopen("Alienship.txt", "w");
    if (!output_file) {
        perror("Error creating output file");
        return 1;
    }

    // Parse the input
    printf("[PARSER] Starting spacecraft instruction parsing...\n");
    yyparse();

    // Close files
    fclose(output_file);

    printf("[PARSER] Parsing complete. Check Alienship.txt for output.\n");
    return 0;
}
