

#ifndef __BITVEC_UTILS_H__
#define __BITVEC_UTILS_H__

#define BIT_GET(x, i) ((x) & (1 << (i)))
#define BIT_SET(x, i) ((x) | (1 << (i)))
#define BIT_CLEAR(x, i) ((x) & ~(1 << (i)))


#define BITVEC_GET(x, i) (BIT_GET((x)[(i)/8], (i)%8))
#define BITVEC_SET(x, i) ((x)[(i)/8] = BIT_SET((x)[(i)/8], (i)%8))
#define BITVEC_CLEAR(x, i) ((x)[(i)/8] = BIT_CLEAR((x)[(i)/8], (i)%8))

#endif
