#include <stdint.h>

typedef struct NUC970FmiState {
	uint32_t FMI_NANDCTL;       // 0x8a0
	uint32_t FMI_NANDTMCTL;     // 0x8a4
	uint32_t FMI_NANDINTEN;     // 0x8a8
	uint32_t FMI_NANDINTSTS;    // 0x8ac
	uint32_t FMI_NANDCMD;       // 0x8b0
	uint32_t FMI_NANDADDR;      // 0x8b4
	uint32_t FMI_NANDDATA;      // 0x8b8
	uint32_t FMI_NANDRACTL;     // 0x8bc
	uint32_t FMI_NANDECTL;      // 0x8c0
	uint32_t FMI_NANDECCES[4];  // 0x8d0~0x8dc	(4 * 4: max fields 16)
	uint32_t FMI_NANDECCPROTA[2]; // 0x8e0~0x8e4

	// the error address and data registers should be a Fifo per field  
	uint32_t FMI_NANDECCEA[16][12]; // 0x900~0x92c	(2 * 12 = 24 max error address per field)
	uint32_t FMI_NANDECCED[16][6];  // 0x960~0x974	(4 * 6 = 24 max error data per field)

	uint32_t FMI_NANDRA[118];   // 0xa00 + 04 * n(0,1,...117)
} NUC970FmiState;