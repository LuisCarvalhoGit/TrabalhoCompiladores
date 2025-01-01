%x FLYING_STATE
%x LANDED_STATE

%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

// Variáveis
int is_powered = 0;
int can_fly = 0;
int can_power_off = 1;
double current_x = 0;
double current_y = 0;
int current_z = 0;
int current_direction = 90; // xx -> 0; yy -> 90 (inicial)

// Função para calcular nova posição após movimento
void calculate_position(int distance) {
    // Converter graus para radianos
    double radians = current_direction * M_PI / 180.0;
   
    // Calcula componente x e y, garantindo que não exista -0.00
    double delta_x = (fabs(distance * cos(radians)) < 1e-10) ? 0.0 : distance * cos(radians);
    double delta_y = (fabs(distance * sin(radians)) < 1e-10) ? 0.0 : distance * sin(radians);
   
    // Atualizar posição
    current_x += delta_x;
    current_y += delta_y;

    // Arredonda valores muito pequenos para evitar -0.00
    double x = (fabs(current_x) < 1e-10) ? 0.0 : current_x;
    double y = (fabs(current_y) < 1e-10) ? 0.0 : current_y;
   
    printf("[MOVIMENTO] Deslocamento: (%.2f, %.2f, 0)\n", delta_x, delta_y);
    printf("[STATUS] Posição: (%.2f, %.2f, %d) | Direção: %d°\n", 
           x, y, current_z, current_direction);
}

// Função auxiliar para imprimir erros
void print_state_error() {
    printf("[ERRO] Comando invalido: %s\n", yytext);
    
    if (is_powered == 0) {
        printf("[ERRO] Nave DESLIGADA\n");
    } else if (can_fly == 0 && current_z == 0) {
        printf("[ERRO] Estado: LANDED\n");
    } else if (can_fly == 1) {
        printf("[ERRO] Estado: FLYING\n");
    } else {
        printf("[ERRO] Estado invalido\n");
    }
}

%}

%%

<INITIAL>"<On--"[AEIOUaeiou][A-Za-z][0-9]{2,3}">"    {
    if(is_powered) {
        printf("[ERRO] Nave ja esta ligada!\n");
    } else {
        is_powered = 1;
        printf("[COMANDO] acao(ligar)\n");
    }
    BEGIN(LANDED_STATE);
}

<LANDED_STATE>"<Off>"    {
    if(!is_powered) {
        printf("[ERRO] Nave ja esta desligada!\n");
    } else if(!can_power_off) {
        printf("[ERRO] Precisa aterrar antes de desligar!\n");
    } else {
        is_powered = 0;
        printf("[COMANDO] acao(desligar)\n");
    }
    BEGIN(INITIAL);
}

<LANDED_STATE>"<Take-Off>"    {
    if(!is_powered) {
        printf("[ERRO] Precisa estar ligada para decolar!\n");
    } else if(can_fly) {
        printf("[ERRO] Ja esta em voo!\n");
    } else {
        can_fly = 1;
        can_power_off = 0;
        printf("[COMANDO] Decolagem iniciada\n");
    }
    BEGIN(FLYING_STATE);
}

<FLYING_STATE>"<Land>"    {
    if(current_z != 0) {
        printf("[ERRO] Altitude deve ser zero para aterrissar!\n");
    } else {
        can_fly = 0;
        can_power_off = 1;
        printf("[COMANDO] Aterragem concluida\n");
        printf("[STATUS] Posição: (%.2f, %.2f, %d) | Direção: %d°\n", 
                fabs(current_x) < 1e-10 ? 0.0 : current_x, 
                fabs(current_y) < 1e-10 ? 0.0 : current_y, 
                current_z, 
                current_direction);
    }
    BEGIN(LANDED_STATE);
}

<FLYING_STATE,LANDED_STATE>"<Turn--"[LR]"--"([1-9][0-9]?|[12][0-9]{2}|3[0-5][0-9])">"    {
    char direction_desc[10];
    
    if(!is_powered) {
        printf("[ERRO] Precisa estar ligada para girar!\n");
    } else {
        char direction = yytext[7];
        int degrees = atoi(yytext + 10);
       
        if(direction == 'R') {
            current_direction = (current_direction - degrees) % 360;
            strcpy(direction_desc, "direita");
        } else {
            current_direction = (current_direction + degrees) % 360;
            strcpy(direction_desc, "esquerda");
        }
        
        if (current_direction < 0) {
            current_direction += 360;
        }
        
        
        printf("[COMANDO] Rotacao de %dº para a %s | Nova direcao: %d°\n", 
               degrees, direction_desc, current_direction);
    }
}

<FLYING_STATE,LANDED_STATE>"<Move--"[1-9][0-9]">"    {
    if(is_powered) {
        int distance = atoi(yytext + 7);
        calculate_position(distance);
    } else {
        printf("[ERRO] Precisa estar ligada para se mover!\n");
    }
}

<FLYING_STATE>"<Fly--"[-+]?[1-9][0-9]">"    {
    if(!can_fly) {
        printf("[ERRO] Decolagem necessaria antes de voar!\n");
    } else if (is_powered) {
        int height = atoi(yytext + 6);
        if(current_z + height < 0) {
            printf("[ERRO] Movimento resultaria em altitude negativa!\n");
        } else {
            current_z += height;
            printf("[COMANDO] Alteracao de altitude: %+d\n", height);
            printf("[STATUS] Altitude atual: %d\n", current_z);
        }
    } else {
        printf("[ERRO] Precisa estar ligada para voar!\n");
    }
}

[ \t\n]+    ; // Ignorar espaços em branco

<INITIAL,LANDED_STATE,FLYING_STATE>"<"[A-Za-z0-9\-\+\.\_\>\<]*">" {
    print_state_error();
}

<INITIAL,LANDED_STATE,FLYING_STATE>. {
    printf("[ERRO] Caractere inesperado: %c\n", *yytext);
}

%%

int main() {
    printf("[SISTEMA] Controlo da Nave Inicializado\n");
    yylex();
    return 0;
}