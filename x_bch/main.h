#pragma once

#include <vector>
#include <string>
#include <random>
#include <iostream>
#include <iterator>

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"

// TIMER STUFF ***
#include "xuartps.h"	// if PS uart is used
#include "xscutimer.h"  // if PS Timer is used
#include "xdmaps.h"		// if PS DMA is used
#include "xscugic.h" 	// if PS GIC is used
#include "xil_exception.h"	// if interrupt is used

// values used by the timer initialization
#define TIMER_DEVICE_ID	XPAR_SCUTIMER_DEVICE_ID
// BM: just seems like this is the initial value of the timer
// but why is it important to be -1 / maxuint?
#define TIMER_LOAD_VALUE 0xFFFFFFFF
// BM: not sure what these are, but I think interrupt related?
#define DMA0_ID XPAR_XDMAPS_1_DEVICE_ID
#define INTC_DEVICE_INT_ID XPAR_SCUGIC_SINGLE_DEVICE_ID
// ***

#include "ecclib.h"
#include "BinaryMatrix.h"
#include "GFMatrix.h"
#include "GaloisField.h"

int main();
void testdummyencode();
std::vector<unsigned char> randomdata(int len);
void comparearrays(unsigned char* v1, unsigned char* v2, unsigned int size);
void testload_matrix();
void test_matrix_encode();
void testload_gfmatrix();
void test_BCH_Encode();
void test_BCH_Decode(bool small=true);
unsigned char* standardnoise(unsigned char* v, int size);

EccLib::BCH* get_BCH_Instance();
void bch_decode_timed(EccLib::BCH* bch, int iterations=100);
bool arraysequal(unsigned char* v1, unsigned char* v2, unsigned int size);

// TIMER STUFF ***
XScuTimer Timer;		/* Cortex A9 SCU Private Timer Instance */
// these are two variables used to communicate between the interrupt handlers and main loop
volatile static int Done = 0;	/* Dma transfer is done */
volatile static int Error = 0;	/* Dma Bus Error occurs */
// ***
