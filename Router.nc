#include "Router.h"
interface Router{
	command uint8_t getParent(uint8_t nid);
	command bool getInitState(uint8_t nid);
	command uint8_t getChildNum(uint8_t nid);
}
