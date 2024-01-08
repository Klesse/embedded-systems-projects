#include <reg52.h>
#include <stdio.h>
#include <stdlib.h>

sbit rs=P1^0;
sbit rw=P1^1;
sbit en=P1^2;
sbit button=P0^0;

void delay(unsigned int);
void send_cmd(unsigned char);
void send_char(unsigned char);
void lcd_init(void);
void move_scene(void);
void game_over(void);
void button_pressed(void);
void send_cactus(void);
void send_score(void);
void begin_message(void);
void store_char(void);
int rand(void);

unsigned char begin1[11] = "TRex Game";
/*unsigned char begin2[16] = "Pedro, Alexandre";*/
	

unsigned char game[4] = "Game";
unsigned char over[4] = "Over";

unsigned char dino_sprite[8] = {
	0x07,
  0x05,
  0x07,
  0x1C,
  0x1E,
  0x1D,
  0x1C,
  0x14
};

unsigned char cactus_sprite[8] = {
  0x01,
  0x11,
  0x15,
  0x16,
  0x0E,
  0x04,
  0x04,
  0x04
};

unsigned char score_string[5];
unsigned int cactus_position[3]={0XCF, 0XCF, 0XCF};
unsigned int cactus_on[3] = {0,0,0};

unsigned int gameover = 0;
unsigned int score = 0;
unsigned int rex_position = 0XC0;

unsigned char *variavel;
unsigned int game_speed = 200;

unsigned int random_number;

unsigned int count_jump=0;
unsigned int a_button=0;


unsigned int generate_cactus;
float random_cactus;

unsigned int position_score = 0X8F;


int main(void)
{
	
	button=1;
	lcd_init();
	store_char();
	begin_message();
	
	
	while(1){
		move_scene();
		if(gameover == 1)
		{
			game_over();
			return 1;
		}
	}
}


void lcd_init(void)
{
	send_cmd(0x28); // Modo 4-bits 2 linhas
	send_cmd(0x01); // Limpar Display
	send_cmd(0x0c); // Sem mostrar cursor no display -> _
	send_cmd(0x80); // Posição Inicial do Cursor (80 é a home, 80+x muda o referencial inicial)
	send_cmd(0x06); // Modo de entrada de dados
	
}


void delay(unsigned int t)
{
	unsigned i, j;
	
	for(i=0;i<t;i++)
	for(j=0;j<127;j++);
}


void send_cmd(unsigned char a)
{
	unsigned char x;
	x=a&0xf0;
		
	P1=x;
	rs=0;
	rw=0;
	en=1;
	delay(5);
	en=0;
		
	x=(a<<4)&0xf0;
		
	P1=x;
	rs=0;
	rw=0;
	en=1;
	delay(5);
	en=0;
	
}


 void send_char(unsigned char a)
{
	unsigned char x;
	x=a&0xf0;

	P1=x;
	rs=1;
	rw=0;
	en=1;
	delay(5);
	en=0;
		
	x=(a<<4)&0xf0;
		
	P1=x;
	rs=1;
	rw=0;
	en=1;
	delay(5);
	en=0;
}

void move_scene()
{
	unsigned i, p;
	
	for (i=0; i < 16; i++)
	{
		
		if (button==0)
		{
			button_pressed();
		}
			
		send_cmd(0x01);
		send_cmd(rex_position); // Mudar referencial para a linha de baixo
		send_char(0);
		send_score();
		send_cactus(); // Mandar cactus pro LCD se a condição funcionar

		
		delay(game_speed);
		score++;
			
		if (rex_position == 0X80){
			count_jump++;
			if (count_jump==4)
			{
				count_jump = 0;
				rex_position = 0XC0;
			}
		}
		
		for(p=0;p<3;p++)
		{
			if(cactus_position[p] == 0XC0 && cactus_on[p] == 1 && rex_position == 0XC0)
			{
				gameover = 1;
				return;
			}
		  if (cactus_position[p] == 0XC0 && cactus_on[p] == 1 && rex_position != 0XC0)
			{
				cactus_position[p] = 0XCF;
				cactus_on[p] = 0;
			}
		}
		
		
		if (score % 50 == 0)
			game_speed = game_speed/2;
		}
		}
		

void game_over(void)
{
	unsigned i, j, k;
	
	send_cmd(0x01);
	
	send_cmd(0x80);
	
	for(i=0;game[i]!='\0';i++)
	    send_char(game[i]);

	send_cmd(0xC0);
	
	for(j=0;over[j]!='\0';j++)
		send_char(over[j]);
	
	send_char(' ');
	sprintf(score_string, "%d", score);
	variavel = score_string;
	
	for(k=0;variavel[k]!='\0';k++)
		send_char(variavel[k]);
 	delay(500);
}

void button_pressed(void)
{
	if(rex_position == 0x80)
		rex_position = 0xC0;
	else
		rex_position = 0x80;
}

void send_cactus()
{
	int l;
	
	generate_cactus = (rand() % 100);
	generate_cactus = (int)((generate_cactus + score)/score);
	
	for(l=0;l<3;l++)
	{
		if (cactus_on[l] == 0 && generate_cactus <= 40)
		{
			cactus_on[l] = 1;
			break;
		}
		else if (cactus_on[l] == 1)
		{
			send_cmd(cactus_position[l]);
			send_char(1);
			cactus_position[l] = cactus_position[l] - 1;
		}
	}
}

void send_score()
{
	unsigned int k;
	if(score == 10 || score == 100 || score == 1000 || score == 10000)
	{
		position_score--;
	}
	send_cmd(position_score);
	sprintf(score_string, "%d", score);
	variavel = score_string;
	
	for(k=0;over[k]!='\0';k++)
		send_char(variavel[k]);
}

void begin_message()
{
	unsigned i;
	send_cmd(0x80);
	
	for(i=0;begin1[i] != '\0' ;i++)
		send_char(begin1[i]);
	
	delay(2000);
}

void store_char()
{
	unsigned i, j;
	send_cmd(64);
	for(i=0;i<8;i++)
		send_char(dino_sprite[i]);
		
	send_cmd(72);
	for(j=0;j<8;j++)
		send_char(cactus_sprite[j]);
}
