// SysTick.c
// Implements two busy-wait based delay routines
#include <stdint.h>
// Initialize SysTick with busy wait running at bus clock.
#define NVIC_ST_CTRL_R      (*((volatile unsigned long *)0xE000E010))
#define NVIC_ST_RELOAD_R    (*((volatile unsigned long *)0xE000E014))
#define NVIC_ST_CURRENT_R   (*((volatile unsigned long *)0xE000E018))
void SysTick_Init(void){
// you write this as part of Lab 5
	NVIC_ST_CTRL_R = 0;
	NVIC_ST_RELOAD_R = 0x00FFFFFF;
	NVIC_ST_CURRENT_R = 0;
	NVIC_ST_CTRL_R = 0x05;
  
}
// The delay parameter is in units of the 80 MHz core clock. (12.5 ns)
void SysTick_Wait(uint32_t delay){
// you write this as part of Lab 5
	volatile uint32_t elapsedTime;
  uint32_t startTime = NVIC_ST_CURRENT_R;
  do{
    elapsedTime = (startTime-NVIC_ST_CURRENT_R)&0x00FFFFFF;
  }
  while(elapsedTime <= delay);
  }

// Time delay using busy wait.
// waits for count*10ms
// 10000us equals 10ms
void SysTick_Wait10ms(uint32_t delay){
// you write this as part of Lab 5
	uint32_t i;
	for(i=0;i<delay;i++){
		SysTick_Wait(500000);  
	}  
}

