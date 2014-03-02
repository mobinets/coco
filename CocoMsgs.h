typedef int32_t object_id_t;
typedef nx_int32_t nx_object_id_t;
typedef uint32_t object_size_t;
typedef nx_uint32_t nx_object_size_t;
typedef uint8_t page_num_t;
typedef nx_uint8_t nx_page_num_t;


#ifndef __COCO_MSGS_H__
#define __COCO_MSGS_H__

enum {
  //COCO_PKT_PAYLOAD_SIZE  = 23,
  //COCO_BYTES_PER_PAGE    = 1024,
  //COCO_PKTS_PER_PAGE     = ((COCO_BYTES_PER_PAGE - 1) / COCO_PKT_PAYLOAD_SIZE) + 1,

  COCO_PKT_PAYLOAD_SIZE           = 23,
  COCO_PKTS_PER_PAGE              = 48,
  COCO_BYTES_PER_PAGE             = (COCO_PKTS_PER_PAGE*COCO_PKT_PAYLOAD_SIZE),
  COCO_PKT_BITVEC_SIZE   = (((COCO_PKTS_PER_PAGE - 1) / 8) + 1),//6
  COCO_IMG_BITVEC_SIZE	 = 10 * COCO_PKT_BITVEC_SIZE,  //10 pages.

  COCO_VERSION                    = 2,
  COCO_MAX_ADV_PERIOD_LOG2        = 22,
  COCO_NUM_NEWDATA_ADVS_REQUIRED  = 2,
  COCO_NUM_MIN_ADV_PERIODS        = 2,
  COCO_MAX_NUM_REQ_TRIES          = 1,
  COCO_REBOOT_DELAY               = 4,
  COCO_FAILED_SEND_DELAY          = 16,
  COCO_MIN_DELAY                  = 16,
//  COCO_DATA_OFFSET                = 128,
  COCO_IDENT_SIZE                 = 128,
  COCO_INVALID_ADDR               = (0x7fffffffL),
  COCO_MIN_ADV_PERIOD_LOG2        = 9,
  COCO_MAX_REQ_DELAY              = (0x1L << (COCO_MIN_ADV_PERIOD_LOG2 - 1)),
  COCO_NACK_TIMEOUT               = (COCO_MAX_REQ_DELAY >> 0x1),
  COCO_MAX_IMAGE_SIZE             = (128L * 1024L),
  COCO_MAX_PAGES                  = 128,
  COCO_CRC_SIZE                   = sizeof(uint16_t),
  COCO_CRC_BLOCK_SIZE             = COCO_MAX_PAGES * COCO_CRC_SIZE,
  COCO_GOLDEN_IMAGE_NUM           = 0x0,
  COCO_INVALID_OBJID              = 0xff,
  COCO_INVALID_PKTNUM             = 0xff,
  COCO_INVALID_PGNUM              = 0xff,
  COCO_QSIZE                      = 2
};



enum {
  COCO_ADV_NORMAL = 0,
  COCO_ADV_ERROR  = 1,
  COCO_ADV_PC     = 2,
  COCO_ADV_PING   = 3,
  COCO_ADV_RESET  = 4,
};

typedef nx_struct CocoReportMsg {
  nx_uint16_t    dest;
  nx_uint16_t    src;
  nx_uint8_t	 startByte;
  nx_uint8_t     reports[COCO_PKT_BITVEC_SIZE];
} CocoReportMsg;

typedef nx_struct CocoDataMsg {
  nx_uint16_t     pktNum;
  nx_uint8_t	 src;
  nx_uint8_t     data[COCO_PKT_PAYLOAD_SIZE];
} CocoDataMsg;


#endif
