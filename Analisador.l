%x FLYING_STATE
%x LANDED_STATE

%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

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
   
    // Calcula componente x e y
    double delta_x = distance * cos(radians);
    double delta_y = distance * sin(radians);
   
    // Atualizar posição
    current_x += delta_x;
    current_y += delta_y;
   
    printf("move(%.2f,%.2f,0)\n", delta_x, delta_y);
    printf("INFO: Posição atual: (%.2f, %.2f, %d)\n", current_x, current_y, current_z);
}

// Função auxiliar para imprimir o estado atual
void print_state_error() {

    printf("Comando não reconhecido: %s\n", yytext);
    if (is_powered == 0) {
        printf("ERRO: Comando inválido. A nave está desligada.\n");
    } else if (can_fly == 0 && current_z == 0) {
        printf("ERRO: Comando inválido. A nave está no estado LANDED_STATE.\n");
    } else if (can_fly == 1) {
        printf("ERRO: Comando inválido. A nave está no estado FLYING_STATE.\n");
    } else {
        printf("ERRO: Comando inválido no estado atual.\n");
    }
}


%}

%%

<INITIAL>"<On--"[AEIOUaeiou][A-Za-z][0-9]{2,3}">"    {
    if(is_powered) {
        printf("ERRO: A nave já está ligada!\n");
    } else {
        is_powered = 1;
        printf("acao(ligar)\n");
    }
    BEGIN(LANDED_STATE);

}
<LANDED_STATE>"<Off>"    {
    if(!is_powered) {
        printf("ERRO: A nave já está desligada!\n");
    } else if(!can_power_off) {
        printf("ERRO: A nave precisa aterrar antes de desligar!\n");
    } else {
        is_powered = 0;
        printf("acao(desligar)\n");
    }
    BEGIN(INITIAL);

}
<LANDED_STATE>"<Take-Off>"    {
    if(!is_powered) {
        printf("ERRO: A nave precisa estar ligada para decolar!\n");
    } else if(can_fly) {
        printf("ERRO: Nave já está em voo!\n");
    } else {
        can_fly = 1;
        can_power_off = 0;
        printf("INFO: Modo de voo ativado!\n");
    }
    BEGIN(FLYING_STATE);

}
<FLYING_STATE>"<Land>"    {
    if(current_z != 0) {
        printf("ERRO: A nave precisa estar na altura 0 para aterrar!\n");
    } else {
        can_fly = 0;
        can_power_off = 1;
        printf("INFO: Aterragem completa\n");
    }
    BEGIN(LANDED_STATE);

}
<FLYING_STATE,LANDED_STATE>"<Turn--"[LR]"--"([1-9][0-9]?|[12][0-9]{2}|3[0-5][0-9])">"    {
    if(!is_powered) {
        printf("ERRO: A nave precisa estar ligada para virar!\n");
    } else {
        char direction = yytext[7]; // Posição de L ou R
        int degrees = atoi(yytext + 10); // Posição após "--"
       
        if(direction == 'R') {
            current_direction = (current_direction - degrees) % 360;
        } else {
            current_direction = (current_direction + degrees) % 360;
           
        }
        if (current_direction < 0) {
            current_direction += 360;
        }
        printf("INFO: A nave girou para %d graus\n", current_direction);
    }

}
<FLYING_STATE,LANDED_STATE>"<Move--"[1-9][0-9]">"    {
    if(is_powered) {
        int distance = atoi(yytext + 7);
        calculate_position(distance);
    } else {
        printf("ERRO: A nave precisa estar ligada para se mover!\n");
    }

}
<FLYING_STATE>"<Fly--"[-+]?[1-9][0-9]">"    {
    if(!can_fly) {
        printf("ERRO: Take-Off necessário antes de voar!\n");
    } else if (is_powered) {
        int height = atoi(yytext + 6);
        if(current_z + height < 0) {
            printf("ERRO: Movimento resultaria em altura negativa!\n");
        } else {
            current_z += height;
            printf("move(0,0,%d)\n", height);
            printf("INFO: Current height: %d\n", current_z);
        }
    } else {
        printf("ERRO: A nave precisa estar ligada para voar!\n");
    }

}

[ \t\n]+    ; // Ignorar espaços em branco


<INITIAL,LANDED_STATE,FLYING_STATE>"<"[A-Za-z0-9\-\+\.\_\>\<]*">" {
    print_state_error();
}
. {
    // Fallback for single characters or other unmatched inputs
    printf("ERRO: Caractere inesperado: %c\n", *yytext);
}

%%


int main() {
    yylex();
    return 0;
}