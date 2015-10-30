#include "Msp430Adc12.h"
#include "printf.h"
#include "Tmsg.h"

module Adc1C
{
 provides 
 {
  interface AdcConfigure<const msp430adc12_channel_config_t*>;
 }

 uses
 {
  interface Boot;
  interface Leds;
  interface Msp430Adc12MultiChannel as MultiChannel;
  interface Resource;
  interface Timer<TMilli>;
  interface Packet;
  interface AMPacket;
  interface AMSend;
  interface Receive;
  interface SplitControl as AMControl;
 }
}

implementation
{
 #define BUFFER_SIZE 3
 
 const msp430adc12_channel_config_t config = {
      inch: INPUT_CHANNEL_A0,
      sref: REFERENCE_AVcc_AVss,
      ref2_5v: REFVOLT_LEVEL_1_5,
      adc12ssel: SHT_SOURCE_ADC12OSC,
      adc12div: SHT_CLOCK_DIV_1,
      sht: 2,
      sampcon_ssel: SAMPCON_SOURCE_SMCLK,
      sampcon_id: SAMPCON_CLOCK_DIV_1
  };
 
 adc12memctl_t memctl[] = {
      { inch: INPUT_CHANNEL_A1, sref: REFERENCE_AVcc_AVss },
      { inch: INPUT_CHANNEL_A2, sref: REFERENCE_AVcc_AVss }
  };

 uint16_t buffer[BUFFER_SIZE];
 uint16_t threshold=3000;
 uint8_t id;
 message_t mesg;
 am_addr_t addr = 'f26f';
 bool busy = FALSE;
 void task getData();

 async command const msp430adc12_channel_config_t* AdcConfigure.getConfiguration()
 {
  return &config; 				//Returns the ADC channel configuration values
 }

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
   post getData();
  }
  else
  {
   call AMControl.start();
  }
 }
 
 event void AMControl.stopDone(error_t err)
 {

 }

 void task getData()
 {
  call Resource.request();
 }

 event void Resource.granted()
 {
  call Timer.startPeriodic(500);
 }

 event void Timer.fired()
 {
  printf("Hi! Sensing started!\n");
  printfflush();
  if (call MultiChannel.configure(&config, memctl, 2, buffer, BUFFER_SIZE, 0) == SUCCESS)
   call MultiChannel.getData();			//This command reads the ADC channel value
 }

 async event void MultiChannel.dataReady(uint16_t *buf, uint16_t numSamples)
 {
  if (!busy) 
  {
   Msg_t* msg = (Msg_t*)call Packet.getPayload(&mesg, sizeof(Msg_t));

   uint16_t A = 5000-buf[0];
   uint16_t B = 5000-buf[1];
   uint16_t C = 5000-buf[2];
   uint16_t aval = (A>B)? ((A>C)? A:C):((B>C)? B:C);
   printf("Current Adc 1 value: %u\n\n", A);
   printf("Current Adc 2 value: %u\n\n", B);
   printf("Current Adc 3 value: %u\n\n", C);
   printf("Current Adc value: %u\n\n", aval);

   if(aval >= threshold)			//Threshold comparison
   {
    call Leds.led0On();				//Turning ON the Leds to indicate that the threshold value has been reached
    call Leds.led1On();
    call Leds.led2On();
    printf("Threshold reached\n");		//Prints the statement "Threshold reached" on the screen
    msg->NodeId=TOS_NODE_ID;
    msg->Pressure=aval;
    if(call AMSend.send(addr, &mesg, sizeof(Msg_t))==SUCCESS)
    {
     busy = TRUE;
     printf("Sending started by the node: %u\n", msg->NodeId);
    }
   }

   else
   {
    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2Off();
   }

   printfflush();				//Sends the printf statements to the command promt via usb
  }
 }

 event void AMSend.sendDone(message_t *msg, error_t error)
 {
  if (&mesg == msg)
  {
   busy = FALSE;
   printf("The message has been sent by the node: %u\n", TOS_NODE_ID);
   printfflush();
  }
 }

 event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len)
 {
  Msg_t* nmsg=(Msg_t*) payload;
  threshold=nmsg->Threshold;
  printf("Message received by the node: %u\n", nmsg->NodeId);
  printfflush();
  return msg;
 }

}
 
