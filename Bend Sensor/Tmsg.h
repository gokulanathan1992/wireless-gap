#ifndef Tmsg_h
#define Tmsg_h

typedef nx_struct Msg
{
 nx_uint8_t NodeId;
 nx_uint16_t Threshold;
 nx_uint16_t Pressure;
} Msg_t;

enum
{
 AM_TMSG=6
};

#endif
