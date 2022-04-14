// DSP Project DMA.c
//This program will be able to determinine wether the sibilance is present in the signal and turn the LED on for this to work.

#include "audio.h"
#include "LPFIR.h"
#include "HPFIR.h"

volatile int16_t audio_chR=0;    
volatile int16_t audio_chL=0; 
//We are declaring all our variables
float32_t x[DMA_BUFFER_SIZE], y1[DMA_BUFFER_SIZE], state1[NHP+(DMA_BUFFER_SIZE)-1], state2[NLP+(DMA_BUFFER_SIZE)-1], y2[DMA_BUFFER_SIZE];
float32_t p1, p2;
uint8_t is_ratio_above_threshold;

arm_fir_instance_f32 S1;
arm_fir_instance_f32 S2;

	uint32_t count = 0;
	float32_t debug = 0;

void DMA_HANDLER (void)  /****** DMA Interruption Handler*****/
{
      if (dstc_state(0)){ //check interrupt status on channel 0

					if(tx_proc_buffer == (PONG))
						{
						dstc_src_memory (0,(uint32_t)&(dma_tx_buffer_pong));    //Soucrce address
						tx_proc_buffer = PING; 
						}
					else
						{
						dstc_src_memory (0,(uint32_t)&(dma_tx_buffer_ping));    //Soucrce address
						tx_proc_buffer = PONG; 
						}
				tx_buffer_empty = 1;                                        //Signal to main() that tx buffer empty					
       
				dstc_reset(0);			                                        //Clean the interrup flag
    }
    if (dstc_state(1)){ //check interrupt status on channel 1

					if(rx_proc_buffer == PONG)
					  {
						dstc_dest_memory (1,(uint32_t)&(dma_rx_buffer_pong));   //Destination address
						rx_proc_buffer = PING;
						}
					else
						{
						dstc_dest_memory (1,(uint32_t)&(dma_rx_buffer_ping));   //Destination address
						rx_proc_buffer = PONG;
						}
					rx_buffer_full = 1;   
						
				dstc_reset(1);		
    }
}

void proces_buffer(void) 
{
 int ii;
  uint32_t *txbuf, *rxbuf;

  if(tx_proc_buffer == PING) txbuf = dma_tx_buffer_ping; 
  else txbuf = dma_tx_buffer_pong; 
  if(rx_proc_buffer == PING) rxbuf = dma_rx_buffer_ping; 
  else rxbuf = dma_rx_buffer_pong; 
	
	 for(ii=0; ii<DMA_BUFFER_SIZE ; ii++){
		audio_IN = rxbuf[ii]; // Grab the audio from one of the buffers
		audio_chL = (audio_IN & 0x0000FFFF); // Separate the audio into 2 left and right      
		audio_chR = ((audio_IN >>16)& 0x0000FFFF);// Separate the second half of the audio
		 //x[ii] = prbs(); // Create pseudo random noise to get filter responce and to debug
		 x[ii] = (float32_t)(audio_chL); // Add the left side audio for the for array and convert to float
		}
 
		//Process
		
		arm_fir_f32(&S1,x,y1,DMA_BUFFER_SIZE); // Do the FIR Highpass
		arm_fir_f32(&S2,x,y2,DMA_BUFFER_SIZE); // Do the FIR Lowpass
		
		arm_power_f32(y1,DMA_BUFFER_SIZE,&p1); // Get power from highpass filter output
	  arm_power_f32(y2,DMA_BUFFER_SIZE,&p2); // Get power from lowpass filter output
		
	
for (ii=0 ; ii<(DMA_BUFFER_SIZE) ; ii++){
		*txbuf++ = (((short)(y2[ii])<<16 & 0xFFFF0000)) + ((short)(y1[ii]) & 0x0000FFFF);	
		} 
		
		if (p1/p2 > debug) debug = p1/p2; //We used this debug to check on the change of power ratio
 
  tx_buffer_empty = 0;
  rx_buffer_full = 0;
	}

int main (void) {    //Main function
  init_LED(); //Initialise LED and turn them off
	gpio_set(LED_R, 1);
	gpio_set(LED_G, 1);
	gpio_set(LED_B, 1);
	
	 arm_fir_init_f32(&S1,NHP,h1,state1,DMA_BUFFER_SIZE); //initialise both filters
	 arm_fir_init_f32(&S2,NLP,h2,state2,DMA_BUFFER_SIZE); 
	 

audio_init (hz48000, line_in, dma, DMA_HANDLER);


	
while(1){
	while (!(rx_buffer_full && tx_buffer_empty)){};

		proces_buffer();  
		
		count++; // We add a count in order to keep the LED on, this will count up to 3000 and turn all LED off is no input was recieved.
		if (count > 3000 && p1 < 1000){
			gpio_set(LED_R, 1); // Turn all LEDs off, 1 = off and 0 = on
			gpio_set(LED_G, 1);
			gpio_set(LED_B, 1);
			count = 0; //reset the counter
		}
		
		if (p1 > 1000 ) { // If the power of the first filter reaches 1000, start this process. This means the signal will be processed real time
			is_ratio_above_threshold = p1/p2 > 0.79;	// Threshold from the signals
			if (is_ratio_above_threshold == 1){  //Boolean statement to check if threshold is reached
				gpio_set(LED_G, 0);// Turn red LED on
				gpio_set(LED_R, 1);
			}		
				else {
				gpio_set(LED_G, 1);// Turn Green LED on
				gpio_set(LED_R, 0);
			}
		}
		
	}
}
