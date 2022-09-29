// nand-bch.cpp : Defines the entry point for the application.
//
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "libbch.h"

#include <vector>
#include <iostream>
#include <algorithm>
#include <iomanip>

using namespace std;
void hex_dump(const std::vector<uint8_t>& bytes, std::ostream& stream);
vector<unsigned int> randperm(int n, int k) // like the matlab/octave function
{
	vector<unsigned int> res;
	if (2 * k > n) {
		res.resize(n);
		for (int i = 0; i < n; ++i)
			res[i] = i;
		random_shuffle(res.begin(), res.end());
		res.resize(k);
	}
	else {
		res.reserve(k);
		for (int i = 0; i < k; ++i) {
			int next = rand() % n;
			while (find(res.begin(), res.end(), next) != res.end()) {
				next = rand() % n;
			}
			res.push_back(next);
		}
	}
	return res;
}

/**
 *
 * This program reads raw NAND image from standard input and updates ECC bytes in the OOB block for each sector.
 * Data layout is as following:
 *
 * 2 KB page, consisting of 4 x 512 B sectors
 * 64 bytes OOB, consisting of 4 x 16 B OOB regions, one for each sector
 *
 * In each OOB region, the first 9 1/2 bytes are user defined and the remaining 6 1/2 bytes are ECC.
 *
 */

#define BCH_T 4
//#define BCH_N 13
#define BCH_N 15
#define SECTOR_SZ 512
#define OOB_SZ 16
#define SECTORS_PER_PAGE 4
#define OOB_ECC_OFS 8
#define OOB_ECC_LEN 8
#define OOB_SIZE 64
#define ECC_POS	 32

 // Wide right shift by 4 bits. Preserves the very first 4 bits of the output.
static void shift_half_byte(const uint8_t* src, uint8_t* dest, size_t sz)
{
	// go right to left since input and output may overlap
	size_t j;
	dest[sz] = src[sz - 1] << 4;
	for (j = sz; j != 0; --j)
		dest[j] = src[j] >> 4 | src[j - 1] << 4;
	dest[0] |= src[0] >> 4;
}

/**
 * correct_bch - correct error locations as found in decode_bch
 * @bch,@data,@len,@errloc: same as a previous call to decode_bch
 * @nerr: returned from decode_bch
 */
void correct_bch(struct bch_control* bch, uint8_t* data, unsigned int len, unsigned int* errloc, int nerr)
{
	int i;
	for (i = 0; i < nerr; ++i) {
		unsigned int bi = errloc[i];
		if ((bi >> 3) < len)
			data[bi >> 3] ^= (1 << (bi & 7));
	}

}

int test(int m, int t, int ntrials)
{
	struct bch_control* bch = bch_init(m, t, 0, false);
	cout << "initialized" << " m=" << bch->m << " n=" << bch->n << " t=" << bch->t << " ecc_bits=" << bch->ecc_bits << " ecc_bytes=" << bch->ecc_bytes << endl;

	int N = (1 << m) - 1;
	int msgBits = N - bch->ecc_bits;

	cout << "running " << ntrials << " trials of BCH decoding with up to " << t << " errors\n";
	vector<uint8_t> data(msgBits / 8);
	//vector<uint8_t> data(SECTOR_SZ);
	vector<uint8_t> dataClean;
	cout << " data.size()=" << data.size() << endl;

	for (int trial = 0; trial < ntrials; ++trial) {
		// make a random message
		for (size_t k = 0; k < data.size(); ++k)
			data[k] = rand() & 0xFF;
		dataClean = data;

		// encode it
		vector<uint8_t> ecc(bch->ecc_bytes, 0);
		bch_encode(bch, &data[0], (unsigned int)data.size(), &ecc[0]);

		// introduce up to t errors
		int nerrs = rand() % (t + 1);
		vector<unsigned int> errLocIn = randperm((int)data.size() * 8, nerrs);
		for (size_t k = 0; k < errLocIn.size(); ++k) {
			int i = errLocIn[k];
			data[i >> 3] ^= (1 << (i & 7));
		}

		// decode and make sure the right errors were corrected
		vector<unsigned int> errLocOut(t);
		int nerrFound = bch_decode(bch, &data[0], (unsigned int)data.size(), &ecc[0], NULL, NULL, &errLocOut[0]);
		if (nerrFound != nerrs) {
			cerr << "decode_bch return value=" << nerrFound << " expected " << nerrs << endl;
			if (nerrFound < 0)
				cerr << strerror(-nerrFound) << endl;
			bch_free(bch);
			return 1;
		}
		errLocOut.resize(nerrFound);

		sort(errLocIn.begin(), errLocIn.end());
		sort(errLocOut.begin(), errLocOut.end());
		if (errLocIn != errLocOut) {
			cerr << "Input Errors!= Found Errors !!!!" << endl;
			bch_free(bch);
			return 1;
		}
		
		if (nerrFound) {
			correct_bch(bch, &data[0], (unsigned int)data.size(), &errLocOut[0], nerrFound);
		}

		if (dataClean != data) {
			cerr << "data not corrected\n";
			bch_free(bch);
			return 1;
		}
		else {
			printf("[%04d] data corrected\n", trial);
		}
	}
	bch_free(bch);
	return 0;
}

/*-----------------------------------------------------------------------------
 * Define some constants for BCH
 *---------------------------------------------------------------------------*/
 // define the total padding bytes for 512/1024 data segment
#define BCH_PADDING_LEN_512     32
#define BCH_PADDING_LEN_1024    64
// define the BCH parity code lenght for 512 bytes data pattern
#define BCH_PARITY_LEN_T4  8
#define BCH_PARITY_LEN_T8  15
#define BCH_PARITY_LEN_T12 23
#define BCH_PARITY_LEN_T15 29
// define the BCH parity code lenght for 1024 bytes data pattern
#define BCH_PARITY_LEN_T24 45

#define BCH_T15   0x00400000
#define BCH_T12   0x00200000
#define BCH_T8    0x00100000
#define BCH_T4    0x00080000
#define BCH_T24   0x00040000

static const int g_i32BCHAlgoIdx[5] = { BCH_T4, BCH_T8, BCH_T12, BCH_T15, BCH_T24 };
static const int g_i32ParityNum[4][5] = {
	{ 8,    15,     23,     29,     -1  },  // For 512( 16bytes Redundant Area)
	{ 32,   60,     92,     116,    90  },  // For 2K ( 64bytes Redundant Area)
	{ 64,   120,    184,    232,    180 },  // For 4K (128bytes Redundant Area)
	{ 128,  240,    368,    464,    360 },  // For 8K (256bytes Redundant Area)
};

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

/*-----------------------------------------------------------------------------
 * Correct data by BCH alrogithm.
 *      Support 8K page size NAND and BCH T4/8/12/15/24.
 *---------------------------------------------------------------------------*/
void fmiSM_CorrectData_BCH(NUC970FmiState* fmi, uint8_t ucFieidIndex, uint8_t ucErrorCnt, uint8_t* pDAddr)
{
	uint32_t uaData[24], uaAddr[24];
	uint32_t uaErrorData[6];
	uint8_t  ii, jj;
	uint32_t uPageSize;
	uint32_t field_len, padding_len, parity_len;
	uint32_t total_field_num;
	uint8_t* smra_index;

	//--- assign some parameters for different BCH and page size
	switch (fmi->FMI_NANDCTL & 0x007C0000)
	{
	case BCH_T24:
		field_len = 1024;
		padding_len = BCH_PADDING_LEN_1024;
		parity_len = BCH_PARITY_LEN_T24;
		break;
	case BCH_T15:
		field_len = 512;
		padding_len = BCH_PADDING_LEN_512;
		parity_len = BCH_PARITY_LEN_T15;
		break;
	case BCH_T12:
		field_len = 512;
		padding_len = BCH_PADDING_LEN_512;
		parity_len = BCH_PARITY_LEN_T12;
		break;
	case BCH_T8:
		field_len = 512;
		padding_len = BCH_PADDING_LEN_512;
		parity_len = BCH_PARITY_LEN_T8;
		break;
	case BCH_T4:
		field_len = 512;
		padding_len = BCH_PADDING_LEN_512;
		parity_len = BCH_PARITY_LEN_T4;
		break;
	default:
		return;
	}

	uPageSize = fmi->FMI_NANDCTL & 0x00030000;
	switch (uPageSize)
	{
	case 0x30000: total_field_num = 8192 / field_len; break;
	case 0x20000: total_field_num = 4096 / field_len; break;
	case 0x10000: total_field_num = 2048 / field_len; break;
	case 0x00000: total_field_num = 512 / field_len; break;
	default:
		return;
	}

	//--- got valid BCH_ECC_DATAx and parse them to uaData[]
	// got the valid register number of BCH_ECC_DATAx since one register include 4 error bytes
	jj = ucErrorCnt / 4;
	jj++;
	if (jj > 6)
		jj = 6;     // there are 6 BCH_ECC_DATAx registers to support BCH T24

	for (ii = 0; ii < jj; ii++)
	{
		uaErrorData[ii] = fmi->FMI_NANDECCED[ucFieidIndex - 1][ii];
	}

	for (ii = 0; ii < jj; ii++)
	{
		uaData[ii * 4 + 0] = uaErrorData[ii] & 0xff;
		uaData[ii * 4 + 1] = (uaErrorData[ii] >> 8) & 0xff;
		uaData[ii * 4 + 2] = (uaErrorData[ii] >> 16) & 0xff;
		uaData[ii * 4 + 3] = (uaErrorData[ii] >> 24) & 0xff;
	}

	//--- got valid REG_BCH_ECC_ADDRx and parse them to uaAddr[]
	// got the valid register number of REG_BCH_ECC_ADDRx since one register include 2 error addresses
	jj = ucErrorCnt / 2;
	jj++;
	if (jj > 12)
		jj = 12;    // there are 12 REG_BCH_ECC_ADDRx registers to support BCH T24

	for (ii = 0; ii < jj; ii++)
	{
		//uaAddr[ii * 2 + 0] = fmi->FMI_NANDECCEA[ii] & 0x07ff;   // 11 bits for error address
		//uaAddr[ii * 2 + 1] = (fmi->FMI_NANDECCEA[ii] >> 16) & 0x07ff;
		
		uaAddr[ii * 2 + 0] = fmi->FMI_NANDECCEA[ucFieidIndex - 1][ii] & 0x07ff;   // 11 bits for error address
		uaAddr[ii * 2 + 1] = (fmi->FMI_NANDECCEA[ucFieidIndex - 1][ii] >> 16) & 0x07ff;
	}

	//--- pointer to begin address of field that with data error
	pDAddr += (ucFieidIndex - 1) * field_len;

	//--- correct each error bytes
	for (ii = 0; ii < ucErrorCnt; ii++)
	{

		cout << " >> fmiSM: " << dec << (int)ucFieidIndex << " " << uaAddr[ii] << "/" << hex << (int)uaData[ii] << endl;

		// for wrong data in field
		if (uaAddr[ii] < field_len)
		{
			cout << " << " << setfill('0') << setw(2) << hex << (int)*(pDAddr + uaAddr[ii]) << endl;
			*(pDAddr + uaAddr[ii]) ^= uaData[ii];
			cout << " >> " << setfill('0') << setw(2) << hex << (int)*(pDAddr + uaAddr[ii]) << endl;
		}
		// for wrong first-3-bytes in redundancy area
		else if (uaAddr[ii] < (field_len + 3))
		{
			uaAddr[ii] -= field_len;
			uaAddr[ii] += (parity_len * (ucFieidIndex - 1));    // field offset
			*((uint8_t*)fmi->FMI_NANDRA + uaAddr[ii]) ^= uaData[ii];
		}
		// for wrong parity code in redundancy area
		else
		{
			// BCH_ERR_ADDRx = [data in field] + [3 bytes] + [xx] + [parity code]
			//                                   |<--     padding bytes      -->|
			// The BCH_ERR_ADDRx for last parity code always = field size + padding size.
			// So, the first parity code = field size + padding size - parity code length.
			// For example, for BCH T12, the first parity code = 512 + 32 - 23 = 521.
			// That is, error byte address offset within field is
			uaAddr[ii] = uaAddr[ii] - (field_len + padding_len - parity_len);

			// smra_index point to the first parity code of first field in register SMRA0~n
			smra_index = (uint8_t*)
				((uint8_t*)fmi->FMI_NANDRA + (fmi->FMI_NANDRACTL & 0x1ff) - // bottom of all parity code -
					(parity_len * total_field_num)                             // byte count of all parity code
					);

			// final address = first parity code of first field +
			//                 offset of fields +
			//                 offset within field
			*((uint8_t*)smra_index + (parity_len * (ucFieidIndex - 1)) + uaAddr[ii]) ^= uaData[ii];
		}
	}   // end of for (ii<ucErrorCnt)
}

int fmiPageSize(NUC970FmiState* fmi)
{
	switch ((fmi->FMI_NANDCTL >> 16) & 0x3) {   // PSIZE[17:16]
	case 0:
		return 512;
	case 1:
		return 2048;
	case 2:
		return 4096;
	case 3:
		return 8192;
	}
	return 512;
}

int fmiSMCorrectData(NUC970FmiState* fmi, uint8_t *uDAddr)
{
	int uStatus, ii, jj, i32FieldNum = 0;
	volatile int uErrorCnt = 0;

	if (fmi->FMI_NANDINTSTS & 0x4)
	{
		if ((fmi->FMI_NANDCTL & 0x7C0000) == BCH_T24)
			i32FieldNum = /*mtd->writesize*/fmiPageSize(fmi) / 1024;    // Block=1024 for BCH
		else
			i32FieldNum = /*mtd->writesize*/fmiPageSize(fmi) / 512;

		if (i32FieldNum < 4)
			i32FieldNum = 1;
		else
			i32FieldNum /= 4;

		for (jj = 0; jj < i32FieldNum; jj++)
		{
			uStatus = fmi->FMI_NANDECCES[jj];
			if (!uStatus)
				continue;

			for (ii = 1; ii < 5; ii++)
			{
				if (!(uStatus & 0x03)) { // No error

					uStatus >>= 8;
					continue;

				}
				else if ((uStatus & 0x03) == 0x01) { // Correctable error

					uErrorCnt = (uStatus >> 2) & 0x1F;
					fmiSM_CorrectData_BCH(fmi, jj * 4 + ii, uErrorCnt, (uint8_t*)uDAddr);

					uStatus >>= 8;
					continue;
				}
				else // uncorrectable error or ECC error
				{
					return -1;
				}
			}
		} //jj
	}
	return uErrorCnt;
}

void nuc970_nand_bch_test()
{
	int i;
	size_t k;
	NUC970FmiState fmi;
	memset(&fmi, 0, sizeof(NUC970FmiState));
	fmi.FMI_NANDCTL = BCH_T4 | (0x01 << 16);	// BCH_T4 encode/decode for 2048 bytes/page
	fmi.FMI_NANDRACTL = 0x40;	// 64 bytes redundant area
	struct bch_control* bch = bch_init(15, 4, 0, false);
	cout << "initialized" << " m=" << bch->m << " n=" << bch->n << " t=" << bch->t << " ecc_bits=" << bch->ecc_bits << " ecc_bytes=" << bch->ecc_bytes << endl;

	vector<uint8_t> page(SECTOR_SZ * SECTORS_PER_PAGE + OOB_SIZE);
	vector<uint8_t> pageClean;
	// make a random page
	for (k = 0; k < SECTOR_SZ * SECTORS_PER_PAGE; ++k)
		page[k] = rand() & 0xFF;
	for (k = 0; k < OOB_SIZE; ++k)
		page[k + SECTOR_SZ * SECTORS_PER_PAGE] = 0xFF;
	
	// encode it
	for (i = 0; i < 4; i++) {
		vector<uint8_t> ecc(bch->ecc_bytes, 0);
		bch_encode(bch, &page[SECTOR_SZ * i], SECTOR_SZ, &ecc[0]);
		memcpy(&page[SECTOR_SZ * SECTORS_PER_PAGE + ECC_POS + i * OOB_ECC_LEN], &ecc[0], bch->ecc_bytes);
	}
	pageClean = page;
	hex_dump(pageClean, std::cout);

	// introduce up max errors
	int nerrs = 4;
	for (i = 0; i < 4; i++) {
		vector<unsigned int> errLocIn = randperm(SECTOR_SZ * 8, nerrs);
		sort(errLocIn.begin(), errLocIn.end());
		for (k = 0; k < errLocIn.size(); ++k) {
			int loc = errLocIn[k];
			page[(i * SECTOR_SZ) + (loc >> 3)] ^= (1 << (loc & 7));

			cout << " >> err: " << dec << (loc >> 3) + i * SECTOR_SZ << "/" << (loc & 7) << " "
				<< hex << (int)pageClean[(i * SECTOR_SZ) + (loc >> 3)] << "/" 
				<< hex << (int)page[(i * SECTOR_SZ) + (loc >> 3)]				
				<< endl;
		}

		// decode and make sure the right errors were corrected
		vector<unsigned int> errLocOut(nerrs);
		int nerrFound = bch_decode(bch, &page[i * SECTOR_SZ], SECTOR_SZ,
			&pageClean[SECTOR_SZ * SECTORS_PER_PAGE + ECC_POS + i * OOB_ECC_LEN],
			NULL, NULL, &errLocOut[0]);
		if (nerrFound != nerrs) {
			cerr << "decode_bch return value=" << nerrFound << " expected " << nerrs << endl;
			if (nerrFound < 0)
				cerr << strerror(-nerrFound) << endl;
			bch_free(bch);
			return;
		}

		fmi.FMI_NANDECCES[0] |= ((nerrFound << 2) | 0x01);

		errLocOut.resize(nerrFound);
		sort(errLocOut.begin(), errLocOut.end());

		for (k = 0; k < nerrFound; k++) {

			cout << " << err: " << dec << (errLocOut[k] >> 3) + i * SECTOR_SZ << "/" << (errLocOut[k] & 7) << endl;

			fmi.FMI_NANDECCEA[i][k / 2] |= (errLocOut[k] >> 3) << (16 * (k % 2));

			fmi.FMI_NANDECCED[i][k / 4] |= (1 << (errLocOut[k] & 7)) << (8 * (k % 4));
		}

		if (nerrFound) {
			fmi.FMI_NANDINTSTS |= (1 << 2); // ECC_FLD_IF (ECC Field Check Error Interrupt Flag)		
		}

		int corrected = fmiSMCorrectData(&fmi, &page[i * SECTOR_SZ]);
		cout << "fmiSMCorrectData returns " << corrected << endl;
		for (k = 0; k < nerrFound; k++) {
			fmi.FMI_NANDECCEA[i][k] = 0;
			fmi.FMI_NANDECCED[i][k] = 0;
		}
	}
		
	if (pageClean != page) {
		cerr << "data not corrected\n";
		bch_free(bch);
		return;
	}
	else {
		printf("data corrected\n");
	}

	bch_free(bch);
}

typedef struct SD_info_t
{
	unsigned int    CardType;       /*!< SDHC, SD, or MMC */
	unsigned int    RCA;            /*!< relative card address */
	unsigned char   IsCardInsert;   /*!< card insert state */
	unsigned int    totalSectorN;   /*!< total sector number */
	unsigned int    diskSize;       /*!< disk size in Kbytes */
	int             sectorSize;     /*!< sector size in bytes */
} SD_INFO_T;

int SD_Swap32(int val)
{
	int buf;

	buf = val;
	val <<= 24;
	val |= (buf << 8) & 0xff0000;
	val |= (buf >> 8) & 0xff00;
	val |= (buf >> 24) & 0xff;
	return val;
}

void test_sd_buffer()
{
	SD_INFO_T pSD;
	int i;
	unsigned int SDH_BA[5] = { 0x92600023, 0xffffdfff, 0x5f59e00f, 0x00260032, 0 };
	unsigned int tmpBuf[5];
	unsigned int Buffer[4] = { 0x92600023, 0xffffdfff, 0x5f59e00f, 0x00260032 };
	unsigned int R_LEN, C_Size, MULT, size;

	for (i = 0; i < 5; i++)
		tmpBuf[i] = SD_Swap32(SDH_BA[i]);

	for (i = 0; i < 4; i++)
		Buffer[i] = ((tmpBuf[i] & 0x00ffffff) << 8) | ((tmpBuf[i + 1] & 0xff000000) >> 24);

	if (Buffer[0] & 0xc0000000)
	{
		C_Size = ((Buffer[1] & 0x0000003f) << 16) | ((Buffer[2] & 0xffff0000) >> 16);
		size = (C_Size + 1) * 512;  // Kbytes

		pSD.diskSize = size;
		pSD.totalSectorN = size << 1;
	}
	else
	{
		R_LEN = (Buffer[1] & 0x000f0000) >> 16;
		C_Size = ((Buffer[1] & 0x000003ff) << 2) | ((Buffer[2] & 0xc0000000) >> 30);
		MULT = (Buffer[2] & 0x00038000) >> 15;
		size = (C_Size + 1) * (1 << (MULT + 2)) * (1 << R_LEN);

		pSD.diskSize = size / 1024;
		pSD.totalSectorN = size / 512;
	}
}

int main(int argc, char* argv[])
{	
	int i;

	test_sd_buffer();

	unsigned poly = argc < 2 ? 0 : strtoul(argv[1], NULL, 0);

	struct bch_control* bch = bch_init(BCH_N, BCH_T, poly, false);
	if (!bch)
		return -1;

	uint8_t page_buffer[(SECTOR_SZ + OOB_SZ) * SECTORS_PER_PAGE];
	for (i = 0; i < SECTOR_SZ * SECTORS_PER_PAGE; i++)
	{
		page_buffer[i] = '>'; // 0x3e
	}
	page_buffer[0] = '<';
	page_buffer[513] = '<'; // 0x3c
	page_buffer[1026] = '<';
	page_buffer[1539] = '<';

	page_buffer[888] = 0x7e;

	for (i = 0; i < OOB_SZ * SECTORS_PER_PAGE; i++)
		page_buffer[SECTOR_SZ * SECTORS_PER_PAGE + i] = 0xff;

	//while (1)
	//{
		//if (fread(page_buffer, (SECTOR_SZ + OOB_SZ) * SECTORS_PER_PAGE, 1, stdin) != 1)
		//	break;

		// Erased pages have ECC = 0xff .. ff even though there may be user bytes in the OOB region
		int erased_block = 1;
		//unsigned i;
		for (i = 0; i != SECTOR_SZ * SECTORS_PER_PAGE; ++i)
			if (page_buffer[i] != 0xff)
			{
				erased_block = 0;
				break;
			}

		for (i = 0; i != SECTORS_PER_PAGE; ++i)
		{
			const uint8_t* sector_data = page_buffer + SECTOR_SZ * i;
			uint8_t* sector_oob = page_buffer + SECTOR_SZ * SECTORS_PER_PAGE + OOB_SZ * i;
			if (erased_block)
			{
				// erased page ECC consumes full 7 bytes, including high 4 bits set to 0xf
				memset(sector_oob + OOB_ECC_OFS, 0xff, OOB_ECC_LEN);
			}
			else
			{
				uint8_t recv_ecc[OOB_ECC_LEN] = { 0xe0, 0x5c, 0x81, 0xd6, 0x25, 0x2e, 0x3c, 0xc0 };
				uint32_t error_loc[BCH_T] = { 0, 0, 0, 0 };
				// concatenate input data
				uint8_t buffer[SECTOR_SZ + OOB_ECC_OFS + 1];
				buffer[0] = 0;
				
				//shift_half_byte(sector_data, buffer, SECTOR_SZ);
				memcpy(buffer, sector_data, SECTOR_SZ);
				//shift_half_byte(sector_oob, buffer + SECTOR_SZ, OOB_ECC_OFS);
				memcpy(buffer + SECTOR_SZ, sector_oob, OOB_ECC_OFS);

				// compute ECC
				uint8_t ecc[OOB_ECC_LEN];
				memset(ecc, 0, OOB_ECC_LEN);
				//encode_bch(bch, buffer, SECTOR_SZ + OOB_ECC_OFS + 1, ecc);
				bch_encode(bch, buffer, SECTOR_SZ, ecc);
				for (int j = 0; j < OOB_ECC_LEN; j++)
					printf(" %02x", ecc[j]);
				printf("\n");
				// copy the result in its OOB block, shifting right by 4 bits
				//shift_half_byte(ecc, sector_oob + OOB_ECC_OFS, OOB_ECC_LEN - 1);
				//sector_oob[OOB_ECC_OFS + OOB_ECC_LEN - 1] |= ecc[OOB_ECC_LEN - 1] >> 4;
				memcpy(sector_oob + OOB_ECC_OFS, ecc, OOB_ECC_LEN);

				int res = bch_decode(bch, buffer, SECTOR_SZ, recv_ecc, 
					sector_oob + OOB_ECC_OFS, NULL, error_loc);
				printf(" decode: %d\n", res);
				for (int j = 0; j < BCH_T; j++) {
					printf(" %d/%d", error_loc[j] / 8, error_loc[j] % 8);
				}
				printf("\n");
			}
		}

		//fwrite(page_buffer, (SECTOR_SZ + OOB_SZ) * SECTORS_PER_PAGE, 1, stdout);
	//}

	for (i = 0; i < 64; i++)
	{
		printf(" %02x", page_buffer[SECTOR_SZ * SECTORS_PER_PAGE + i]);
		if ((i + 1) % 16 == 0)
			printf("\n");
	}

	bch_free(bch);

	test(BCH_N, BCH_T, 10);

	nuc970_nand_bch_test();
}