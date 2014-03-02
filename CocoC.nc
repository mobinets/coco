
/**
Implementation of Coco.
Do not contain the CDS construciton phase.
DBG FORMAT:
time: %s, type, fields1, fields2, ...
 */
 
#include <Timer.h>
#include "Coco.h"
#include "Router.h"
#include "CocoMsgs.h"
#include "BitVecUtils.h"

module CocoC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer; //use this single timer and flags to control the time of state and report.
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend as SendDataMsg;
  uses interface AMSend as SendReportMsg;
  uses interface Receive;
  uses interface SplitControl as AMControl;
  uses interface BitVecUtils;
  uses interface Router;
}
implementation {

  uint16_t tmp;
  message_t pkt;
  bool busy = 0;
  //coco
  uint8_t childs; // mark whether a node has a child.
  uint8_t parent=1;
  uint16_t i=0;
  bool state; //0-tx, 1-sleep, 2-rx
//  uint8_t pktsToTransmit[COCO_PKT_BITVEC_SIZE]; // 1 stands for a pkt to tx, 0 stands for a pkt that has been transmited.
  uint8_t imgRxVec[COCO_IMG_BITVEC_SIZE];  // 1 stands for a pkt to receive, 0 strands for a received pkt.
  uint8_t imgTxVec[COCO_IMG_BITVEC_SIZE];  // 1 stands for a pkt to tx, 0 stands for a pkt that has been transmited.
  
  uint8_t txNum; // number of pkts to be sent in current tx state.
  bool txNumSet = 0; // marking whether txNum is set.
  bool rptRxDone=0; //a flag marking whether all reports are received.
  uint16_t nextPkt;


  bool imgFinish; // mark whether the img is entirely received.
  uint16_t rxNum; //number of pkts to receive in current round.
  bool report = 0; //marking whether the node has reported.
  uint16_t imgMissings = 0;//number of pkts in the entire image.
  uint16_t totalPktsToTx;

  uint16_t firstMissIdx;//index of the first missing packet in the imgRxVec.
  uint8_t whichByte;//locate position of the first missing packet.

  bool reportTimeSet=0; // marking whether the report time is set.
  uint16_t indexInPg, indexInImg;//for updateImgTxVec().
  bool finishSent=0;

  uint8_t startInReport;//start byte extracted in report.

  
  void setupDataMsg(){
    if (state != 0){
	dbg("Coco", "SetupDataMsg not in TX state, state:%d.\n", state);
    }
    if (!txNumSet){
    call BitVecUtils.countOnes(&imgMissings, imgTxVec, COCO_PKTS_PER_PAGE*10);
    if (imgMissings > COCO_PKTS_PER_PAGE) { //There are enough pkts for a page transmission. Tx the first PAGE_SIZE pkts in imgVector.
    txNum = COCO_PKTS_PER_PAGE;
    }
    else {// there not enough pkts for a page transmission. Tx all the remaining pkts in imgVector.
    txNum = imgMissings;
    }
    txNumSet=1;
    totalPktsToTx = txNum;
    dbg("Coco","txNum: %d, imgMissings: \n", txNum, imgMissings);
    }
    
    //start tx!
    if (!busy) {
      CocoDataMsg* btrpkt = (CocoDataMsg*)(call SendDataMsg.getPayload(&pkt, sizeof(CocoDataMsg)));
      if (btrpkt == NULL) {
      dbg("Coco","NULL\n");
	return;
      }
      btrpkt->src = TOS_NODE_ID;
//      dbg("Coco", "totalPkts: %d, txNum: %d\n", totalPktsToTx, txNum);
      //btrpkt->seqno = totalPktsToTx-txNum; //the ith pkt in current round transmissions. 
          
       if (call BitVecUtils.indexOf(&nextPkt, 0, imgTxVec, COCO_PKTS_PER_PAGE*10) != SUCCESS) {
      // no more packets to send
      dbg("Coco", "All pkts have been sent.\n");
    } else {
      btrpkt->pktNum = nextPkt;
      dbg("Coco", "time: %s, src: %d, pktNum: %d!\n", sim_time_string(), btrpkt->src, nextPkt);
      if (call SendDataMsg.send(AM_BROADCAST_ADDR, 
          &pkt, sizeof(CocoDataMsg)) == SUCCESS) {
        busy = 1;
      }
    }
    }
  }

  void SetupReportMsg() {
    if (imgFinish){ //finish is done. 
         report = 1; // For state control.
	  return;
	}
	dbg("Coco", "time: %s, Report Start.\n", sim_time_string());
    //start tx!
    if (!busy) {
      CocoReportMsg* btrpkt = (CocoReportMsg*)(call SendReportMsg.getPayload(&pkt, sizeof(CocoReportMsg)));
      if (btrpkt == NULL) {
      dbg("Coco","REPORT NULL\n");
	return;
      }
      btrpkt->dest = parent;
      btrpkt->src = TOS_NODE_ID;
      call BitVecUtils.indexOf(&firstMissIdx, 0, imgRxVec, COCO_PKTS_PER_PAGE*10);
      whichByte = firstMissIdx / 8;
      dbg("Coco", "firstMiss:%d, whichByte: %d\n", firstMissIdx, whichByte);
      memcpy(btrpkt->reports, imgRxVec+whichByte, COCO_PKT_BITVEC_SIZE);
      btrpkt->startByte = whichByte;
      if (call SendReportMsg.send(AM_BROADCAST_ADDR, 
          &pkt, sizeof(CocoReportMsg)) == SUCCESS) {
        busy = 1;
        report = 1; // For state control.
      }
    }
    //img finished?
	call BitVecUtils.countOnes(&imgMissings, imgRxVec, COCO_PKTS_PER_PAGE*10);
	if (imgMissings == 0){
	imgFinish = 1;
	dbg("Coco", "time: %s, img finished!\n", sim_time_string());
	}
	else {
	dbg("Coco", "%d pkts in need!\n", imgMissings);
	}
  }

  event void Boot.booted() {
    if (TOS_NODE_ID == 0){
    imgFinish = 1;//finished.
    }
    call AMControl.start();
    //getNeighbors
    parent = call Router.getParent(TOS_NODE_ID);
    dbg("Coco", "my parent: %d\n", parent);
    childs = call Router.getChildNum(TOS_NODE_ID);
    /*
    //get children number for judging whether all reports are received.
    childs = call Router.getChildNum(TOS_NODE_ID);
    childsNum = childs;
    for (i=0;i<childs;i++){
    children[i] = call Router.getChildren(TOS_NODE_ID, i);
    }
    */
    state = call Router.getInitState(TOS_NODE_ID);
    //dbg("Boot", "nid: %d, parent: %d, children: %d\n", TOS_NODE_ID, parent, children[1]);

    for (i=0;i<COCO_IMG_BITVEC_SIZE;i++){ //init the vectors.
	if (TOS_NODE_ID == 0) {
	imgRxVec[i] = 0x00;
	imgTxVec[i] = 0xff;
	}
	else {
	imgTxVec[i] = 0x00;
	imgRxVec[i] = 0xff;
	}
	}
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      if (state == 0){
      call Timer.startOneShot(410);// it should be assured that all receivers can reply requests within the time period.
      }
      else if (state == 1){
      call Timer.startOneShot(410);// it should be assured that all receivers can reply requests within the time period.
      }
      else{
      call Timer.startOneShot(360);// it should be assured that all receivers can reply requests within the time period.
      }
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void Timer.fired() {  
  if (state == 0){	//operations in SLEEP state.
	state = 1;//transit to SLEEP state.
	call Timer.startOneShot(410); // 50ms for the report.
	dbg("State", "time: %s, in SLEEP\n", sim_time_string());
  }
  else if (state == 1){	//operations in RX state.
	state = 2;//transit to RX state.
	call Timer.startOneShot(360); // 50ms for the report.
	report = 0;
	dbg("State", "time: %s, in RX\n", sim_time_string());
  }
  else { 
	  if (report){ //operations in TX state.

	  /*
	  //update the imgTxVec. Because the reports may marks the unreceived packets as 1 in imgTxVec.
	  call BitVecUtils.indexOf(&tmp, 0, imgRxVec, COCO_PKTS_PER_PAGE*10);
	  whichByte = tmp/8;
	  for (i=tmp;i<(whichByte+1)*8-tmp;i++){
	  BITVEC_CLEAR(imgTxVec,i);
	  }
	  for (i=whichByte+1;i<COCO_IMG_BITVEC_SIZE;i++){
	  imgTxVec[i] = 0x00;
	  }
	  */
	  //timer control
	  	call Timer.startOneShot(410);
	  	state = 0;//transit to TX state.
	  	txNumSet = 0;
		dbg("State", "time: %s, in TX\n", sim_time_string());
	  	if (childs > 0){ // have children.
	  	setupDataMsg();
	  	}
	  	else {
	  	dbg("Coco", "childs: %d\n", childs);
	  	}
	  }
	  else {
	  	call Timer.startOneShot(50);
	  	SetupReportMsg();
	  }
  }
  }

  event void SendDataMsg.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
      busy = FALSE;
    }
    BITVEC_CLEAR(imgTxVec, nextPkt); // clear the bit that has been sent.
    if (txNum != 0){//continue tx if not finished.
    if (state != 0){
    txNum = 0;
    txNumSet = 0;
    dbg("Coco", "not inTxState! txNum: %d, state:%d\n", txNum, state);
    return;
    }
    txNum--;
    setupDataMsg();
    }
    else if (txNum == 0){
    txNumSet = 0;
    }
  }

  event void SendReportMsg.sendDone(message_t* msg, error_t err) {
  if (&pkt == msg) {
      busy = FALSE;
    }
  //dbg("Coco", "time: %s, Report Done.\n", sim_time_string());
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
  	//data msg.
 	if (len == sizeof(CocoDataMsg)) {
      CocoDataMsg* btrpkt = (CocoDataMsg*)payload;
      if (BITVEC_GET(imgRxVec,btrpkt->pktNum) == 0){
      return msg;
      }
      dbg("Coco", "time: %s, Data %d rx from %d .\n", sim_time_string(), btrpkt->pktNum, btrpkt->src);
      //update imgTxVec for forwarding.
      BITVEC_SET(imgTxVec,btrpkt->pktNum);
      BITVEC_CLEAR(imgRxVec,btrpkt->pktNum);
    }
    //Report.
    if (len == sizeof(CocoReportMsg)) {
      CocoReportMsg* btrpkt = (CocoReportMsg*)payload;
      if (btrpkt->dest != TOS_NODE_ID){//not reports for me.
      return msg;
      }
      startInReport = btrpkt->startByte;
      for (i=0;i<COCO_PKT_BITVEC_SIZE;i++){
      imgTxVec[startInReport+i] |= btrpkt->reports[i] &(~imgRxVec[startInReport+i]);
//      dbg("Coco", "received report from %d: %x\n", btrpkt->src, btrpkt->reports[i]);
//      dbg("Coco", "reportRx %d: %x\n", btrpkt->src, reportsRx[i]);
      }
      dbg("Coco", "time: %s, Report rx from %d.\n", sim_time_string(), btrpkt->src);
    }
   
    return msg;
  }

}
