%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

// External function declarations
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

void yyerror(const char *s);

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
        fprintf(output_file, "move");
        for (int i = 0; i < move_count; i++) {
            fprintf(output_file, "(%.2f,%.2f,%.2f)", 
                    move_buffer[i].x, move_buffer[i].y, move_buffer[i].z);
        }
        fprintf(output_file, "\n");
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
    START LPAREN SHIP_ID RPAREN COLON init_instructions instruction_list COLON END {
        printf("Successfully parsed instruction block for ship %s\n", $3);
        flush_move_buffer();
        fprintf(output_file, "--- End of instructions for ship %s ---\n\n", $3);
        free($3);
    }
    ;

init_instructions:
    /* Empty */
    | SET_SHIP {
        fprintf(output_file, "init%s\n", $1);
        free($1);
    }
    | SET_SPACE {
        fprintf(output_file, "initspace%s\n", $1);
        free($1);
    }
    | SET_SHIP SET_SPACE {
        fprintf(output_file, "init%s\ninitspace%s\n", $1, $2);
        free($1);
        free($2);
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
            fprintf(stderr, "Error: Ship already powered on\n");
        } else {
            is_powered = 1;
            fprintf(output_file, "acao(ligar)\n");
        }
        free($1);
    }
    | OFF {
        flush_move_buffer();
        if (!is_powered) {
            fprintf(stderr, "Error: Ship already powered off\n");
        } else if (!can_power_off) {
            fprintf(stderr, "Error: Must land before powering off\n");
        } else {
            is_powered = 0;
            fprintf(output_file, "acao(desligar)\n");
        }
    }
    | TAKE_OFF {
        flush_move_buffer();
        if (!is_powered) {
            fprintf(stderr, "Error: Ship must be powered on to take off\n");
        } else {
            can_fly = 1;
            can_power_off = 0;
            fprintf(output_file, "take-off\n");
        }
    }
    | movement_sequence {
        flush_move_buffer();
    }
    ;

movement_sequence:
    movement
    | movement_sequence movement
    ;

movement:
    MOVE {
        if (!is_powered) {
            fprintf(stderr, "Error: Ship must be powered on to move\n");
        } else {
            int distance;
            sscanf($1, "<Move--%d>", &distance);
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
    | TURN {
        flush_move_buffer();
        if (!is_powered) {
            fprintf(stderr, "Error: Ship must be powered on to turn\n");
        } else {
            char direction;
            int degrees;
            sscanf($1, "<Turn--%c--%d>", &direction, &degrees);
            
            if (degrees <= 0 || degrees >= 360) {
                fprintf(stderr, "Error: Invalid turn angle\n");
            } else {
                if (direction == 'R') {
                    current_direction = (current_direction - degrees + 360) % 360;
                } else {
                    current_direction = (current_direction + degrees) % 360;
                }
                fprintf(output_file, "turn(%c,%d)\n", direction, degrees);
            }
        }
        free($1);
    }
    | FLY {
        if (!can_fly) {
            fprintf(stderr, "Error: Must take off before flying\n");
        } else if (!is_powered) {
            fprintf(stderr, "Error: Ship must be powered on to fly\n");
        } else {
            int height;
            sscanf($1, "<Fly--%d>", &height);
            
            if (current_z + height < 0) {
                fprintf(stderr, "Error: Cannot fly below ground level\n");
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

int main(int argc, char** argv) {
    if (argc != 2) {
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
