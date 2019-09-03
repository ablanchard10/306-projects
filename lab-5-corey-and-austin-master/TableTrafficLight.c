// TableTrafficLight.c edX lab 10, EE319K Lab 5
// Runs on LM4F120 or TM4C123
// Index implementation of a Moore finite state machine to operate a traffic light.  
// Daniel Valvano, Jonathan Valvano
// Feb 27, 2017

/* 
 Copyright 2018 by Jonathan W. Valvano, valvano@mail.utexas.edu
    You may use, edit, run or distribute this file
    as long as the above copyright notice remains
 THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
 OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
 VALVANO SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL,
 OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
 For more information about my classes, my research, and my books, see
 http://users.ece.utexas.edu/~valvano/
 */

// See TExaS.h for other possible hardware connections that can be simulated
// east/west red light connected to PE5
// east/west yellow light connected to PE4
// east/west green light connected to PE3
// north/south facing red light connected to PE2
// north/south facing yellow light connected to PE1
// north/south facing green light connected to PE0
// pedestrian detector connected to PA4 (1=pedestrian present)
// north/south car detector connected to PA3 (1=car present)
// east/west car detector connected to PA2 (1=car present)
// "walk" light connected to PF3,2,1 (built-in white LED)
// "don't walk" light connected to PF1 (built-in red LED)

#include <stdint.h>
#include "tm4c123gh6pm.h"
#include "SysTick.h"
#include "TExaS.h"

// Declare your FSM linked structure here
struct State {					//set up general structure for states
	uint32_t	out1;				//output for traffic lights (PE0-5)
	uint32_t	out2;				//output for walk signal (PF1,2,3)
	uint32_t	delay;
	uint8_t		Next [8];
} state_t;

typedef const struct State STyp;

#define SGWR	0
#define SYWR	1
#define SRWG	2
#define SRWY	3
#define	SYWRw	4
#define	SRWYw	5
#define	walk	6
#define	redon1	7
#define	redoff1	8
#define	redon2	9
#define	redoff2	10
#define	redon3	11
#define	redoff3	12
#define	nowalk	13
#define	SRWGw	14
#define	SRWYto0	15
#define	SGWRw	16
#define	SYWRto2	17

STyp FSM[18]={
	//									000, 001,  010,  011,  100,   101,  110,   111
	{0x21, 0x02, 200, {SGWR, SYWR, SGWR, SYWR, SYWRw, SYWRw, SYWRw, SYWRw}},	//SGWR
	{0x11, 0x02, 200, {SRWG, SRWG, SRWG, SRWG, walk, walk, walk, walk}},			//SYWR
	{0x0C, 0x02, 200, {SRWG, SRWG, SRWY, SRWY, SRWYw, SRWYw, SRWYw, SRWYw}},	//SRWG
	{0x0A, 0x02, 200, {SGWR, SGWR, SGWR, SGWR, walk, walk, walk, walk}},			//SRWY
	{0x11, 0x02, 200, {walk, walk, walk, walk, walk, walk, walk, walk}},			//SYWRw
	{0x0A, 0x02, 200, {walk, walk, walk, walk, walk, walk, walk, walk}},			//SRWYw
	{0x09, 0x0E, 200, {walk, redon1, redon1, redon1, walk, redon1, redon1, redon1}}, //walk
	{0x09, 0x02, 75, {redoff1, redoff1, redoff1, redoff1, redoff1, redoff1, redoff1, redoff1}}, //redon1
	{0x09, 0x00, 75, {redon2 , redon2, redon2, redon2, redon2, redon2, redon2, redon2}},//redoff1
	{0x09, 0x02, 75, {redoff2, redoff2, redoff2, redoff2, redoff2, redoff2, redoff2, redoff2}},//redon2
	{0x09, 0x00, 75, {redon3, redon3, redon3, redon3, redon3, redon3, redon3, redon3}},//redoff2
	{0x09, 0x02, 75, {redoff3, redoff3, redoff3, redoff3, redoff3, redoff3, redoff3, redoff3}}, //redon3
	{0x09, 0x00, 75, {nowalk, nowalk, nowalk, nowalk, nowalk, nowalk, nowalk, nowalk}}, //redoff3 
	{0x09, 0x02, 1, {SRWGw, SGWRw, SRWGw, SRWGw, SGWRw, SGWRw, SRWGw, SRWGw}}, //nowalk
	{0x0C, 0x02, 200, {SRWYto0, SRWYto0, SRWYto0, SRWYto0, SRWYto0, SRWYto0, SRWYto0, SRWYto0}}, //SRWGw
	{0x0A, 0x02, 200, {SGWR, SGWR, SGWR, SGWR, SGWR, SGWR, SGWR, SGWR}}, //SRWY to 0
	{0X21, 0X02, 200, {SYWRto2, SYWRto2, SYWRto2, SYWRto2, SYWRto2, SYWRto2, SYWRto2, SYWRto2}}, //SGWRw
	{0x11, 0x02, 200, {SRWG, SRWG, SRWG, SRWG, SRWG, SRWG, SRWG, SRWG}}}; //STWR to 2

	
	int foo = SGWR;			//current state
	int n;
	
	int data;
	
	void EnableInterrupts(void);

int main(void){ 
  TExaS_Init(SW_PIN_PA432, LED_PIN_PE543210); // activate traffic simulation and set system clock to 80 MHz
  SysTick_Init();     
  // Initialize ports and FSM you write this as part of Lab 5
	
	SYSCTL_RCGCGPIO_R |= 0x31;					//initialize clock for PE,PF,PA
	n++;
	n++;
	n++;
	n++;
	
	GPIO_PORTE_DIR_R |= 0x3F;         // make PE5-0 out
	GPIO_PORTF_DIR_R |= 0x0E;         // make PF3-1 out
	GPIO_PORTA_DIR_R &= 0xE3;         // make PA4-2 input
	
	GPIO_PORTE_DEN_R |= 0x3F;         // enable digital I/O on PE5-0
	GPIO_PORTF_DEN_R |= 0x0E;         // enable digital I/O on PF3-1
	GPIO_PORTA_DEN_R |= 0x1C;         // enable digital I/O on PA4-2
	
	GPIO_PORTE_AFSEL_R &= ~0x3F;      // disable alt funct on PB5-0
	GPIO_PORTF_AFSEL_R &= ~0x0E;      // disable alt funct on PB5-0
	GPIO_PORTA_AFSEL_R &= ~0x1C;      // disable alt funct on PB5-0+
	
  EnableInterrupts(); // TExaS uses interrupts
  while(1){
 // FSM Engine
 // you write this as part of Lab 5
		GPIO_PORTE_DATA_R = FSM[foo].out1;	//set traffic lights
		GPIO_PORTF_DATA_R = FSM[foo].out2;
		SysTick_Wait10ms(FSM[foo].delay);  // wait 10 ms * current state's Time value
		data = (GPIO_PORTA_DATA_R >> 2);
    foo = FSM[foo].Next[data];
  }
}

