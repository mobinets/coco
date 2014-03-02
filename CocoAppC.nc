
#include <Timer.h>
#include "Coco.h"

configuration CocoAppC {
}
implementation {
  components MainC;
  components LedsC;
  components CocoC as App;
  components BitVecUtilsC; //bit vector operations.
  components RouterC; //get parents and children.
  components new TimerMilliC() as Timer0;
  components ActiveMessageC;
  components new AMSenderC(AM_COCO);
  components new AMReceiverC(AM_COCO);

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Timer -> Timer0;
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.SendDataMsg -> AMSenderC;
  App.SendReportMsg -> AMSenderC;
  App.Receive -> AMReceiverC;
  //bit vec operations.
  App.BitVecUtils -> BitVecUtilsC;
  App.Router -> RouterC;
}
