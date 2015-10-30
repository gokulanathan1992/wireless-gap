#include "printf.h"
#include "Tmsg.h"

module BaseC
{
 uses
 {
  interface Boot;
  interface Leds;
  interface Timer<TMilli>;
  interface Packet;
  interface AMPacket;
  interface AMSend;
  interface Receive;
  interface SplitControl as AMControl;
  interface HplMsp430GeneralIO as PinTest;
 }
}

implementation
{
 uint16_t threshold=3000;
 uint16_t pressure;
 message_t mesg;
 bool busy = FALSE;

 event void Boot.booted()
 {
  call Leds.led0Off();
  call Leds.led1Off();
  call Leds.led2Off();
  call AMControl.start();
 }

 event void AMControl.startDone(error_t err)
 {
  if (err == SUCCESS)
  {
   call Timer.startPeriodic(500);
  }
  else
  {
   call AMControl.start();
  }
 }
 
 event void AMControl.stopDone(error_t err)
 {

 }

 event void Timer.fired()
 {
  call Leds.led0Off();
  call Leds.led1Off();
  call Leds.led2Off();
  if (!busy) 
  {
   Msg_t* msg = (Msg_t*)call Packet.getPayload(&mesg, sizeof(Msg_t)); 
   msg->NodeId=TOS_NODE_ID;
   msg->Threshold=threshold;
   if(threshold!=3000)
   {
    printf("Hi! This is Base Station\n");
    if(call AMSend.send(AM_BROADCAST_ADDR, &mesg, sizeof(Msg_t))==SUCCESS)
    {
     busy = TRUE;
     printf("Base Station sending new threshold value: %u\n", threshold);
    }
    printfflush();	
   }			
  }
 }
  
 event void AMSend.sendDone(message_t *msg, error_t error)
 {
  if (&mesg == msg)
  {
   busy = FALSE;
   printf("Base Station message has been sent successfully\n");
   printfflush();
  }
 }

 event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len)
 {
  Msg_t* nmsg=(Msg_t*) payload;
  pressure=nmsg->Pressure;
  printf("\nMessage received by the Base Station\n\n");
  printfflush();
  call PinTest.clr();
  call Leds.led0On();				//Turning ON the Leds to indicate that the threshold value has been reached
  call Leds.led1On();
  call Leds.led2On();
  call PinTest.setResistor(MSP430_PORT_RESISTOR_OFF);
  call PinTest.setResistor(MSP430_PORT_RESISTOR_PULLUP);
  call PinTest.makeOutput();
  call PinTest.set();
  printf("Threshold reached: %u\n\n", pressure);		//Prints the statement "Threshold reached" on the screen
  return msg;
 }
}

