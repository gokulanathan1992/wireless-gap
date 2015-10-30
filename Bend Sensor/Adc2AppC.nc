#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration Adc2AppC
{

}

implementation
{
 components MainC, new AdcReadClientC(), Adc2C, LedsC;
 components PrintfC;
 components SerialStartC;
 components new TimerMilliC();
 components ActiveMessageC;
 components new AMSenderC(AM_TMSG);
 components new AMReceiverC(AM_TMSG);


 //wiring

 MainC.Boot <- Adc2C;
 Adc2C.VoltageRead -> AdcReadClientC;
 AdcReadClientC.AdcConfigure -> Adc2C.VoltageConfigure;
 Adc2C.Leds -> LedsC;
 Adc2C.Timer -> TimerMilliC;
 Adc2C.Packet -> AMSenderC;
 Adc2C.AMPacket -> AMSenderC;
 Adc2C.AMControl -> ActiveMessageC;
 Adc2C.AMSend -> AMSenderC;
 Adc2C.Receive -> AMReceiverC;
}
