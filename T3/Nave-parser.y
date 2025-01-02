%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>  
#include <math.h>

// External function declarations
extern double init_x, init_y, init_z;
extern int input_degrees;
extern double min_x, min_y, min_z, max_x, max_y, max_z;
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

void print_art(){
    printf(" _______     _       _______     ______   ________  _____  _______      ___    \n");
    printf("|_   __ \\   / \\     |_   __ \\  .' ____ \\ |_   __  ||_   _||_   __ \\   .'   `.  \n");
    printf("  | |__) | / _ \\      | |__) | | (___ \\_|  | |_ \\_|  | |    | |__) | /  .-.  \\ \n");
    printf("  |  ___/ / ___ \\     |  __ /   _.____`.   |  _| _   | |    |  __ /  | |   | | \n");
    printf(" _| |_  _/ /   \\ \\_  _| |  \\ \\_| \\____) | _| |__/ | _| |_  _| |  \\ \\_\\  `-'  / \n");
    printf("|_____||____| |____||____| |___|\\______.'|________||_____||____| |___|`.___.'  \n");
    printf("                                                                               \n");
}

int print_initial_state() {
    printf("\n----------------------------------------\n");
    printf("[INITIAL STATE]\n");
    printf("  Current Position: (%.2f, %.2f, %d)\n", current_x, current_y, current_z);
    printf("  Current Direction: %d°\n", current_direction);
    printf("----------------------------------------\n");
}

void print_state(const char* instruction) {
    printf("\n----------------------------------------\n");
    printf("[INSTRUCTION] %s\n", instruction);
    printf("  Current Position: (%.2f, %.2f, %d)\n", current_x, current_y, current_z);
    printf("  Current Direction: %d°\n", current_direction);
    printf("----------------------------------------\n");
}


void yyerror(const char* s);

// Output file handling
FILE *output_file;

// Command buffer structure
#define MAX_BUFFER_SIZE 10000
char command_buffer[MAX_BUFFER_SIZE];
int buffer_pos = 0;

// Movement buffer for consecutive moves
typedef struct {
    double x, y, z;
} Movement;

Movement move_buffer[100];
int move_count = 0;

// Flags and buffers for initialization
int set_ship_initialized = 0;
int set_space_initialized = 0;
char ship_init_buffer[200];
char space_init_buffer[200];
char current_ship_id[100];

void reset_ship_state() {
    is_powered = 0;
    can_fly = 0;
    can_power_off = 1;
    current_x = 0;
    current_y = 0;
    current_z = 0;
    current_direction = 90;
    move_count = 0;
    min_x = 0;
    min_y = 0;
    min_z = 0;
    max_x = 100;
    max_y = 100;
    max_z = 100;
    buffer_pos = 0;
    command_buffer[0] = '\0';
    set_ship_initialized = 0;
    set_space_initialized = 0;
    ship_init_buffer[0] = '\0';
    space_init_buffer[0] = '\0';
}

void add_to_buffer(const char* command) {
    int len = strlen(command);
    if (buffer_pos + len < MAX_BUFFER_SIZE) {
        strcat(command_buffer + buffer_pos, command);
        buffer_pos += len;
    } else {
        yyerror("Command buffer overflow");
    }
}

void flush_move_buffer() {
    if (move_count > 0) {
        char move_str[1000] = "move";
        char coord_str[100];
        for (int i = 0; i < move_count; i++) {
            snprintf(coord_str, sizeof(coord_str), "(%.2f,%.2f,%.2f)", 
                    move_buffer[i].x, move_buffer[i].y, move_buffer[i].z);
            strcat(move_str, coord_str);
        }
        strcat(move_str, " ");
        add_to_buffer(move_str);
        move_count = 0;
    }
}

int is_within_boundaries(double x, double y, double z) {
    return x >= min_x && x <= max_x &&
           y >= min_y && y <= max_y &&
           z >= min_z && z <= max_z;
}

void write_all_commands() {
    // Write ship ID
    fprintf(output_file, "%s\t", current_ship_id);
    
    // Write Set-Ship if it exists
    if (set_ship_initialized) {
        fprintf(output_file, "%s\t", ship_init_buffer);
    }
    
    // Write Set-Space if it exists, otherwise write default
    if (set_space_initialized) {
        fprintf(output_file, "%s\t", space_init_buffer);
    } 

    // Write remaining commands
    fprintf(output_file, "%s", command_buffer);
}
%}

%union {
    char *str;
    int num;
}

%token START_LPAREN RPAREN_COLON SEMICOLON COLON_END
%token <str> ON OFF TAKE_OFF LAND TURN MOVE FLY SET_SHIP SET_SPACE SHIP_ID

%%

program:
    /* Empty program is allowed */
    | program instruction_block {
        reset_ship_state();
    }
    ;

instruction_block: 
    START_LPAREN SHIP_ID RPAREN_COLON {
        strcpy(current_ship_id, $2);
        free($2);
    }
    BLOCK_CONTENT COLON_END {
        flush_move_buffer(); // Ensure all moves are written out
        write_all_commands();
        fprintf(output_file, "\n\n");
    }
    ;

BLOCK_CONTENT:
    instruction_sequence
    ;

instruction_sequence:
    command_list 
    | init_sequence SEMICOLON command_list
    | init_sequence
    ;

init_sequence:
    init_command
    | init_sequence SEMICOLON init_command
    ;

init_command:
    SET_SHIP {
        if (!set_ship_initialized) {
            set_ship_initialized = 1;
            snprintf(ship_init_buffer, sizeof(ship_init_buffer), 
                    "init (%.2f, %.2f, %.2f) %d", 
                    init_x, init_y, init_z, is_powered);
        }
    }
    | SET_SPACE {
        if (!set_space_initialized) {
            set_space_initialized = 1;
            snprintf(space_init_buffer, sizeof(space_init_buffer), 
                    "initspace (%.2f, %.2f, %.2f) (%.2f, %.2f, %.2f)", 
                    min_x, min_y, min_z, max_x, max_y, max_z);
        }
    }
    ;

command_list:
    command
    | command_list SEMICOLON command
    ;

command: 
    ON {
        flush_move_buffer();
        if (is_powered) {
            yyerror("Ship already powered on");
        } else {
            is_powered = 1;
            add_to_buffer("acao(ligar)  ");
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
            add_to_buffer("acao(desligar)  ");
        }
    }
    | LAND {
        if (!can_fly) {
            yyerror("Ship must be in the air to land");
        } else if (current_z != 0) {
            yyerror("Ship must be at altitude 0 to land");
        } else {
            can_fly = 0;
            can_power_off = 1;
        }
    }
    | TAKE_OFF {
        if (!is_powered) {
            yyerror("Ship must be powered on to take off");
        } else if (can_fly) {
            yyerror("Ship is already in the air");
        } else {
            can_fly = 1;
            can_power_off = 0;
        }
    }
    | TURN {
        if (!is_powered) {
            yyerror("Ship must be powered on to turn");
        } else {
            char direction;
            int degrees;
            sscanf($1, "<Turn--%c--%d>", &direction, &degrees);
            
            if (degrees <= 0 || degrees >= 360) {
                yyerror("Invalid turn angle");
            } else {
                if (direction == 'R') {
                    current_direction = (current_direction - degrees + 360) % 360;
                } else {
                    current_direction = (current_direction + degrees) % 360;
                }
                print_state("TURN");
            }
        }
        free($1);
    }
    | MOVE {
        int distance;
        sscanf($1, "<Move--%d>", &distance);
        double delta_x, delta_y;
        calculate_position(distance, &delta_x, &delta_y);
        double new_x = current_x + delta_x;
        double new_y = current_y + delta_y;
        
        if(is_powered) {
            if (!is_within_boundaries(new_x, new_y, current_z)) {
                yyerror("Move exceeds space boundaries");
            } else {
                move_buffer[move_count].x = delta_x;
                move_buffer[move_count].y = delta_y;
                move_buffer[move_count].z = 0;
                move_count++;
                current_x = new_x;
                current_y = new_y;
                print_state("MOVE");
            }
        } else {
            yyerror("Ship must be turned on to move");
        }
        
        free($1);
    }
    | FLY {
        int height;
        sscanf($1, "<Fly--%d>", &height);
        double new_z = current_z + height;
        
        if(can_fly) {
            if (!is_within_boundaries(current_x, current_y, new_z)) {
            yyerror("Fly exceeds space boundaries");
            } else {
                move_buffer[move_count].x = 0;
                move_buffer[move_count].y = 0;
                move_buffer[move_count].z = height;
                move_count++;
                current_z = new_z;
                print_state("FLY");
            }
        } else {
            yyerror("Take-Off necessary before flying");
        }
        
        free($1);
    }
    ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "----------------------------------------\n");
    fprintf(stderr, "[ERROR] %s\n", s);
    fprintf(stderr, "  At token: '%s'\n", yytext);
    fprintf(stderr, "----------------------------------------\n");
}

int main() {
    output_file = fopen("Alienship.txt", "w");
    if (!output_file) {
        perror("Error creating output file");
        return 1;
    }

    print_art();
    
    printf("========================================\n");
    printf("[PARSER] Starting spacecraft instruction parsing...\n");
    printf("========================================\n");
    yyparse();

    fclose(output_file);
    printf("\n[PARSER] Parsing complete.\n");
    printf("[PARSER] Output written to 'Alienship.txt'.\n");
    printf("========================================\n");
    return 0;
}