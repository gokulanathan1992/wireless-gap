#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration BaseAppC
{

}

implementation
{
 components MainC, BaseC, LedsC;
 components PrintfC;
 components SerialStartC;
 components new TimerMilliC();
 components ActiveMessageC;
 components new AMSenderC(AM_TMSG);
 components new AMReceiverC(AM_TMSG);
 components HplMsp430GeneralIOC as PinMap;


 //wiring

 MainC.Boot <- BaseC;
 BaseC.Leds -> LedsC;
 BaseC.Timer -> TimerMilliC;
 BaseC.Packet -> AMSenderC;
 BaseC.AMPacket -> AMSenderC;
 BaseC.AMControl -> ActiveMessageC;
 BaseC.AMSend -> AMSenderC;
 BaseC.Receive -> AMReceiverC;
 BaseC.PinTest -> PinMap.DAC0;
}
