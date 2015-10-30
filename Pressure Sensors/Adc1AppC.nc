#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#include "Msp430Adc12.h"

configuration Adc1AppC
{

}

implementation
{
 components MainC, new Msp430Adc12ClientC() as AdcClient, Adc1C; 
 components LedsC;
 components PrintfC;
 components SerialStartC;
 components new TimerMilliC();
 components ActiveMessageC;
 components new AMSenderC(AM_TMSG);
 components new AMReceiverC(AM_TMSG);


 //wiring

 MainC.Boot <- Adc1C;
 Adc1C.MultiChannel -> AdcClient.Msp430Adc12MultiChannel;
 Adc1C.Resource -> AdcClient;
 Adc1C.Leds -> LedsC;
 Adc1C.Timer -> TimerMilliC;
 Adc1C.Packet -> AMSenderC;
 Adc1C.AMPacket -> AMSenderC;
 Adc1C.AMControl -> ActiveMessageC;
 Adc1C.AMSend -> AMSenderC;
 Adc1C.Receive -> AMReceiverC;
}
