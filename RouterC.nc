#include "Router.h"

module RouterC{
	provides interface Router;
}

implementation {

	uint8_t parentSet[ndNum] = {0, 0, 0, 1, 1, 2, 2, 3, 4, 5, 6};
	uint8_t childrenNum[ndNum]= {2,2,2,1, 1, 1, 1, 0, 0, 0, 0};
	bool stateSet[ndNum] = {2, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2};

	command uint8_t Router.getParent(uint8_t nid){
		return parentSet[nid];
	}
	command bool Router.getInitState(uint8_t nid){
		return stateSet[nid];
	}
	command uint8_t Router.getChildNum(uint8_t nid){
		return childrenNum[nid];
	}

}
