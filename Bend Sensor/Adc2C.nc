#include "Msp430Adc12.h"
#include "printf.h"
#include "Tmsg.h"
#include<stdio.h>

module Adc2C
{
 provides 
 {
  interface AdcConfigure<const msp430adc12_channel_config_t*> as VoltageConfigure;
 }

 uses
 {
  interface Boot;
  interface Leds;
  interface Read<uint16_t> as VoltageRead;
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

 uint16_t threshold=1990;
 uint8_t id;
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
  printf("\n\n\nHi! Sensing started!\n");
  printfflush();
  call VoltageRead.read();			//This command reads the ADC channel value
 }

 event void VoltageRead.readDone( error_t result, uint16_t val )
 {
  if (!busy) 
  {
   Msg_t* msg = (Msg_t*)call Packet.getPayload(&mesg, sizeof(Msg_t));

   if (result == SUCCESS)
   {
    uint16_t aval = 5000-val;
    printf("Current Adc value: %u\n", aval);

    if(aval >= threshold)			//Threshold comparison
    {
     call Leds.led0On();			//Turning ON the Leds to indicate that the threshold value has been reached
     call Leds.led1On();
     call Leds.led2On();
     printf("Threshold reached\n");	//Prints the statement "Threshold reached" on the screen
     msg->NodeId=TOS_NODE_ID;
     msg->Pressure=aval;
     if(call AMSend.send(AM_BROADCAST_ADDR, &mesg, sizeof(Msg_t))==SUCCESS)
     {
      busy = TRUE;
      printf("\nSending started by the node: %u\n", msg->NodeId);
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

 async command const msp430adc12_channel_config_t* VoltageConfigure.getConfiguration()
 {
  return &config; 				//Returns the ADC channel configuration values
 }
}
 
