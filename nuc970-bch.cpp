/*
 * NUC970 FMI NAND ECC BCH
 * Adjustable NAND page sizes.
 * (512B+spare area, 2048B+spare area, 4096B+spare area and 8192B+spare area).
 * Support up to 4bit/8bit/12bit/15bit/24bit hardware ECC calculation circuit
 * By reading ECC_FLD_IF (FMI_NANDINTSTS[2]) to check the error occurrence while by reading 
 * FMI_NANDECCES0, FMI_NANDECCES1, FMI_NANDECCES2 and FMI_NANDECCES3 to know how many errors and if
 * those errors are correctable or not. If those errors are correctable, please read 
 * FMI_NANDECCEAx and FMI_NANDECCEDx to correct the errors manually. 
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <vector>
#include <iostream>
#include <algorithm>
#include <iomanip>

#include <assert.h>

#include "nuc970-bch.h"
#include "nuc970-data.h"	// 2 sample pages
#include "libbch.h"

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
		printf(" ED: %08x\n", uaErrorData[ii]);
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
		printf(" EA: %08x\n", fmi->FMI_NANDECCEA[ucFieidIndex - 1][ii]);
	}

	//--- pointer to begin address of field that with data error
	pDAddr += (ucFieidIndex - 1) * field_len;

	//--- correct each error bytes
	for (ii = 0; ii < ucErrorCnt; ii++)
	{

		std::cout << " >> fmiSM: " << std::dec << (int)ucFieidIndex << " " 
			<< uaAddr[ii] << "/" << std::hex << (int)uaData[ii] << std::endl;

		// for wrong data in field
		if (uaAddr[ii] < field_len)
		{
			std::cout << " << " << std::setfill('0') << std::setw(2) 
				<< std::hex << (int)*(pDAddr + uaAddr[ii]) << std::endl;
			*(pDAddr + uaAddr[ii]) ^= uaData[ii];
			std::cout << " >> " << std::setfill('0') << std::setw(2) << std::hex 
				<< (int)*(pDAddr + uaAddr[ii]) << std::endl;
		}
		// for wrong first-3-bytes in redundancy area
		else if (uaAddr[ii] < (field_len + 3))
		{
			uaAddr[ii] -= field_len;
			uaAddr[ii] += (parity_len * (ucFieidIndex - 1));    // field offset
			std::cout << " << " << uaAddr[ii] << std::endl;
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
			std::cout << " <<<< " << uaAddr[ii] << std::endl;
			// final address = first parity code of first field +
			//                 offset of fields +
			//                 offset within field
			*((uint8_t*)smra_index + (parity_len * (ucFieidIndex - 1)) + uaAddr[ii]) ^= uaData[ii];
		}
	}   // end of for (ii<ucErrorCnt)
}

int fmiSMCorrectData(NUC970FmiState* fmi, uint8_t* uDAddr)
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


/*-----------------------------------------------------------------------------------*
 * Definition for self-defined Macro.
 *-----------------------------------------------------------------------------------*/
#define OK      0
#define FAIL    -1

#define TRUE    1
#define FALSE   0

#define Successful  0
#define Fail        -1

 /*-----------------------------------------------------------------------------------*
  * Definition the global variables
  *-----------------------------------------------------------------------------------*/
unsigned char   gPage_buf[8192];    // buffer for a page of data
unsigned char   gRa_buf[512];       // buffer for redundancy area
unsigned long   gChecksum = 0;      // 32 bits checksum for all output data

/*-----------------------------------------------------------------------------
 * calculate 32 bits checksum for data
 * INPUT:
 *      data   : pointer to data.
 *      length : byte number of data.
 *      current_checksum : the current checksum for data that had calculated.
 * RETURN:
 *      final checksum value.
 *---------------------------------------------------------------------------*/
unsigned long calculate_checksum(unsigned char* data, int length, unsigned long current_checksum)
{
	int i;

	for (i = 0; i < length; i++)
		current_checksum = (current_checksum + data[i]) & 0xFFFFFFFF;
	return current_checksum;
}

extern "C" {	
	extern int df_t, df_m, df_p;
	extern int mm, nn, rr, tt;
	extern int kk_shorten, nn_shorten;
	extern int ttx2;
	extern int Parallel;
	extern int ntc_data_size;     // the bit size for one data segment
	extern int data_pad_size;     // the bit length to padding 0, value base on BCH type

	int calculate_BCH_parity_in_field(
		unsigned char* input_data,
		unsigned char* input_ra_data,
		int bch_error_bits,
		int protect_3B,
		int field_index,
		unsigned char* output_bch_parity,
		int bch_need_initial);
	void decode_bch();
	int nuc970_convert_data(NUC970FmiState* fmi, unsigned char* page, int field_index, int oob_size, int error_bits);
	void post_decode(NUC970FmiState* fmi, int field_index);
	void print_hex_low(int length, int Binary_data[], FILE* std);
	void generate_gf();

	void gen_poly();
}

/*-----------------------------------------------------------------------------
 * calculate BCH parity code for a page of data
 * INPUT:
 *      fdout : file pointer for output file
 *      block / page : the block index and page index of raw data
 *      raw_data : pointer to a page of raw data
 *      bch_need_initial : TRUE to initial BCH if the BCH configuration is changed.
 * 		ra_size: the oob size.
 * OUTPUT:
 *      ra_data : pointer to the buffer for a page of BCH parity code
 *---------------------------------------------------------------------------*/
int calculate_BCH_parity(
	//GOLDEN_INFO_T* psgoldeninfo,
	//IMG_INFO_T* psImgInfo,
	int page_size,
	int oob_size,
	int err_bits,
	//FILE* fdout,
	int block, int page,
	unsigned char* raw_data,
	unsigned char* ra_data,
	int bch_need_initial)
{
	int field_index, field_parity_size, field_size, field_count;
	int protect_3B;
	int bch_error_bits, nvt_ra_size;
	//int result;
	unsigned char bch_parity_buffer[512];
	unsigned char* parity_location_in_ra;

	//if (psImgInfo->m_i32OOBSize == 0)
	//    return OK;

	memset(ra_data, 0xFF, oob_size);

	if (block < 4) // first four blocks is system area
	{
		ra_data[0] = 0xFF;
		ra_data[1] = 0x5A;
		ra_data[2] = page & 0xFF;
		ra_data[3] = 0x00;
	}
	else
	{
		ra_data[0] = 0xFF;
		ra_data[1] = 0xFF;
		ra_data[2] = 0x00;
		ra_data[3] = 0x00;
	}
	bch_error_bits = err_bits;
	//nvt_ra_size = g_i32ParityNum[psgoldeninfo->m_ePageSize][psImgInfo->m_eBCHAlgorithm];
	//nvt_ra_size = psgoldeninfo->m_i32OOBSize ;
	nvt_ra_size = oob_size;

	switch (bch_error_bits)
	{
	case  4:
		field_size = 512;
		break;
	case  8:
		field_size = 512;
		break;
	case 12:
		field_size = 512;
		break;
	case 15:
		field_size = 512;
		break;
	case 24:
		field_size = 1024;
		break;
	default:
		printf("ERROR: BCH T must be 4 or 8 or 12 or 15 or 24.\n\n");
		return FAIL;
	}

	field_count = page_size / field_size;
	for (field_index = 0; field_index < field_count; field_index++)
	{
		if (field_index == 0)
			protect_3B = TRUE;  // BCH protect 3 bytes only for field 0
		else
		{
			protect_3B = FALSE;
			bch_need_initial = FALSE;   // BCH engine only need to initial once. So, initial it only for field 0.
		}

		field_parity_size = calculate_BCH_parity_in_field(
			raw_data + field_index * field_size, ra_data,
			bch_error_bits, protect_3B, field_index, bch_parity_buffer, bch_need_initial);
		parity_location_in_ra = ra_data + nvt_ra_size - (field_parity_size * field_count) + (field_parity_size * field_index);
		memcpy(parity_location_in_ra, bch_parity_buffer, field_parity_size);
	}

#if 0
	//Wayne
	{
		int i = 0;
		//printf("bch_error_bits=%d\n", bch_error_bits );
		printf("[block:%d, page:%d - %d OOB]=\n\t", block, page, bch_error_bits);
		for (i = 0; i < oob_size; i++)
		{
			printf("%02x ", ra_data[i]);
			if ((i % 16) == 15)
				printf("\n\t");
		}
		printf("\n");
	}
#endif

	//result = fwrite(ra_data, 1, oob_size, fdout);
	gChecksum = calculate_checksum(ra_data, oob_size, gChecksum);
	//if (result == 0)
	//{
	//    printf("ERROR: Fail to write block %d page %d into file, Return code = 0x%x (line %d)\n", block, page, result, __LINE__);
	//    return FAIL;
	//}

#if 0
	if (page == psgoldeninfo->m_i32PagePerBlock - 1)
		printf("	Image for block %d/%d, (%d/%d) done !!\n", block, psgoldeninfo->m_i32BlockNumber - 1, (block - psImgInfo->m_sFwImgInfo.startBlock), (psImgInfo->m_sFwImgInfo.endBlock - psImgInfo->m_sFwImgInfo.startBlock));
#endif

	return OK;
}

// verify sample page 1&2
int verify_pages()
{
	uint8_t* test_pages[] = {	// 2048 + 64
		nuc970_nand_sample_page1,
		//nuc970_nand_sample_page2
	};
	int need_initial = 1;

	for (int i = 0; i < sizeof(test_pages) / sizeof(uint8_t*); i++) {
		uint8_t ra_data[64];
		calculate_BCH_parity(
			2048,   // page_size
			64,     // oob_size
			4,      // err_bits
			4,      // block
			0,      // page,
			test_pages[i], // raw_data
			ra_data, // ra_data,
			need_initial   // bch_need_initial
		);
		if (need_initial)
			need_initial = 0;

		hex_dump(std::vector<uint8_t>(std::begin(ra_data), std::end(ra_data)), std::cout);

		// compare ecc bytes
		int cmpres = memcmp(ra_data + 32, &(test_pages[i])[2048 + 32], 32);
		if (cmpres == 0)
			std::cout << "  OK" << std::endl;
		else {
			std::cout << "  FAILED" << std::endl;
		}
		assert(cmpres == 0);
	}
	return 0;
}

// correct sample page 3
int correct_pages()
{
	uint8_t* test_pages[] = {	// 2048 + 64
			nuc970_nand_sample_page3	// error page
	};

	int need_initial = 1;

	NUC970FmiState fmi;
	memset(&fmi, 0, sizeof(NUC970FmiState));
	fmi.FMI_NANDCTL = BCH_T4 | (0x01 << 16);	// BCH_T4 encode/decode for 2048 bytes/page
	fmi.FMI_NANDRACTL = 0x40;	// 64 bytes redundant area

	for (int i = 0; i < sizeof(test_pages) / sizeof(uint8_t*); i++) {

		int field_index, field_parity_size, field_size, field_count;
		int protect_3B;
		int bch_error_bits, nvt_ra_size;
		unsigned char bch_parity_buffer[512];
		unsigned char* parity_location_in_ra;
		int bch_need_initial;
		bch_error_bits = 4;
		nvt_ra_size = 64;
		uint8_t* ra_data = &(test_pages[i])[2048];

		switch (bch_error_bits)
		{
		case  4:
			field_size = 512;
			break;
		case  8:
			field_size = 512;
			break;
		case 12:
			field_size = 512;
			break;
		case 15:
			field_size = 512;
			break;
		case 24:
			field_size = 1024;
			break;
		default:
			printf("ERROR: BCH T must be 4 or 8 or 12 or 15 or 24.\n\n");
			return FAIL;
		}

		field_count = 2048 / field_size;
		for (field_index = 0; field_index < field_count; field_index++)
		{
			if (field_index == 0) {
				protect_3B = TRUE;  // BCH protect 3 bytes only for field 0
				bch_need_initial = TRUE;
			}
			else
			{
				protect_3B = FALSE;
				bch_need_initial = FALSE;   // BCH engine only need to initial once. So, initial it only for field 0.
			}

			field_parity_size = calculate_BCH_parity_in_field(
				test_pages[i] + field_index * field_size, ra_data,
				bch_error_bits, protect_3B, field_index, bch_parity_buffer, bch_need_initial);
			parity_location_in_ra = ra_data + nvt_ra_size - (field_parity_size * field_count) + (field_parity_size * field_index);
			//memcpy(parity_location_in_ra, bch_parity_buffer, field_parity_size);

			std::cout << "Field Index " << field_index << " : ";
			if (memcmp(parity_location_in_ra, bch_parity_buffer, field_parity_size) == 0)
			{
				std::cout << " OK" << std::endl;
			}
			else {
				std::cout << " FAILED" << std::endl;
				nuc970_convert_data(&fmi, test_pages[i], field_index, 64, 4);
				decode_bch();
				post_decode(&fmi, field_index);

				assert(test_pages[i][0] == 0x80);
				assert(test_pages[i][31] == 0x01);
				assert(test_pages[i][2050] == 0x10);
				assert(test_pages[i][2083] == 0x56);
				assert(fmi.FMI_NANDRA[0] == 0x0010ffff);
				assert(fmi.FMI_NANDRA[8] == 0x568c6259);

			}
		} // for field_index

		fmiSMCorrectData(&fmi, test_pages[i]);

		for (int j = 0; j < 16; j++) {
			printf(" %08x", fmi.FMI_NANDRA[j]);
		}
		printf("\n");

		assert(test_pages[i][0] == 0x00);
		assert(test_pages[i][31] == 0x00);
		assert(fmi.FMI_NANDRA[0] == 0x0000ffff);
		assert(fmi.FMI_NANDRA[8] == 0x168c6259);

	}
	printf("==== DONE ====\n");
	return 0;
}

static u8 swap_bits_tbl[] = {
	0x00, 0x80, 0x40, 0xc0, 0x20, 0xa0, 0x60, 0xe0,
	0x10, 0x90, 0x50, 0xd0, 0x30, 0xb0, 0x70, 0xf0,
	0x08, 0x88, 0x48, 0xc8, 0x28, 0xa8, 0x68, 0xe8,
	0x18, 0x98, 0x58, 0xd8, 0x38, 0xb8, 0x78, 0xf8,
	0x04, 0x84, 0x44, 0xc4, 0x24, 0xa4, 0x64, 0xe4,
	0x14, 0x94, 0x54, 0xd4, 0x34, 0xb4, 0x74, 0xf4,
	0x0c, 0x8c, 0x4c, 0xcc, 0x2c, 0xac, 0x6c, 0xec,
	0x1c, 0x9c, 0x5c, 0xdc, 0x3c, 0xbc, 0x7c, 0xfc,
	0x02, 0x82, 0x42, 0xc2, 0x22, 0xa2, 0x62, 0xe2,
	0x12, 0x92, 0x52, 0xd2, 0x32, 0xb2, 0x72, 0xf2,
	0x0a, 0x8a, 0x4a, 0xca, 0x2a, 0xaa, 0x6a, 0xea,
	0x1a, 0x9a, 0x5a, 0xda, 0x3a, 0xba, 0x7a, 0xfa,
	0x06, 0x86, 0x46, 0xc6, 0x26, 0xa6, 0x66, 0xe6,
	0x16, 0x96, 0x56, 0xd6, 0x36, 0xb6, 0x76, 0xf6,
	0x0e, 0x8e, 0x4e, 0xce, 0x2e, 0xae, 0x6e, 0xee,
	0x1e, 0x9e, 0x5e, 0xde, 0x3e, 0xbe, 0x7e, 0xfe,
	0x01, 0x81, 0x41, 0xc1, 0x21, 0xa1, 0x61, 0xe1,
	0x11, 0x91, 0x51, 0xd1, 0x31, 0xb1, 0x71, 0xf1,
	0x09, 0x89, 0x49, 0xc9, 0x29, 0xa9, 0x69, 0xe9,
	0x19, 0x99, 0x59, 0xd9, 0x39, 0xb9, 0x79, 0xf9,
	0x05, 0x85, 0x45, 0xc5, 0x25, 0xa5, 0x65, 0xe5,
	0x15, 0x95, 0x55, 0xd5, 0x35, 0xb5, 0x75, 0xf5,
	0x0d, 0x8d, 0x4d, 0xcd, 0x2d, 0xad, 0x6d, 0xed,
	0x1d, 0x9d, 0x5d, 0xdd, 0x3d, 0xbd, 0x7d, 0xfd,
	0x03, 0x83, 0x43, 0xc3, 0x23, 0xa3, 0x63, 0xe3,
	0x13, 0x93, 0x53, 0xd3, 0x33, 0xb3, 0x73, 0xf3,
	0x0b, 0x8b, 0x4b, 0xcb, 0x2b, 0xab, 0x6b, 0xeb,
	0x1b, 0x9b, 0x5b, 0xdb, 0x3b, 0xbb, 0x7b, 0xfb,
	0x07, 0x87, 0x47, 0xc7, 0x27, 0xa7, 0x67, 0xe7,
	0x17, 0x97, 0x57, 0xd7, 0x37, 0xb7, 0x77, 0xf7,
	0x0f, 0x8f, 0x4f, 0xcf, 0x2f, 0xaf, 0x6f, 0xef,
	0x1f, 0x9f, 0x5f, 0xdf, 0x3f, 0xbf, 0x7f, 0xff,
};

// using libbch to verify sample page 1&2
int libbch_verify_pages()
{
	uint8_t* test_pages[] = {	// 2048 + 64
		nuc970_nand_sample_page1,
		//nuc970_nand_sample_page2
	};
	int i, j;
	int page, field_index;
	struct bch_control* bch = bch_init(15, 4, 0xc001, false);
	if (!bch)
		return -1;

	for (page = 0; page < sizeof(test_pages) / sizeof(uint8_t*); page++) {
		for (field_index = 0; field_index < 4; field_index++) {
			uint8_t sector[512 + 24];
			uint8_t ecc[8];
			memset(sector, 0, 512 + 24);
			memset(ecc, 0, 8);
			memcpy(sector, &test_pages[page][field_index * 512], 512);
			if (field_index == 0) {
				sector[512 + 0] = 0xff;
				sector[512 + 1] = 0xff;
				sector[512 + 2] = 0x00;
				sector[512 + 3] = 0x00;
			}
			// invert sector
			i = 0;
			j = 512 + 24 - 1;
			while (i < j)
			{
				int Temp = swap_bits_tbl[sector[i]];
				sector[i] = swap_bits_tbl[sector[j]];
				sector[j] = Temp;
				i++;
				j--;
			}
			for (i = 0; i < 512 + 24; i++) {
				printf("%02X", sector[i]);				
			}
			printf("\n");
			bch_encode(bch, sector, 512 + 24, ecc);
			for (i = 0; i < 8; i++)
				printf(" %02x", ecc[i]);
			printf("\n");
			
			int eccbits[60];
			for (i = 0; i < 8; i++) {
				for (j = 0; j < 8; j++) {
					if (i * 8 + j < 60)
						eccbits[i * 8 + j] = ecc[i] >> (7 - j) & 0x01;
				}
			}

			i = 0;
			j = 60 - 1;
			while (i < j)
			{
				int Temp = eccbits[i];
				eccbits[i] = eccbits[j];
				eccbits[j] = Temp;
				i++;
				j--;
			}
			print_hex_low(60, eccbits, stdout);
			printf("\n");
		}
	}
	bch_free(bch);
	return 0;
}

int decode_test(unsigned char* page)
{
	int field_index;
	NUC970FmiState fmi;
	memset(&fmi, 0, sizeof(NUC970FmiState));
	fmi.FMI_NANDCTL = BCH_T4 | (0x01 << 16);	// BCH_T4 encode/decode for 2048 bytes/page
	fmi.FMI_NANDRACTL = 0x40;	// 64 bytes redundant area

	//--- really do BCH decoding
	ntc_data_size = 512 * 8;
	data_pad_size = 24 * 8;
	mm = df_m;
	tt = df_t;
	if (tt == 4)
		Parallel = 32 /*8*/;
	else
		Parallel = 64 /*8*/;

	nn = (int)pow(2, mm) - 1;
	kk_shorten = 4096;

	// generate the Galois Field GF(2**mm)
	generate_gf();

	// Compute the generator polynomial and lookahead matrix for BCH code
	gen_poly();

	// Check if code is shortened
	nn_shorten = kk_shorten + rr;

	for (field_index = 0; field_index < 4; field_index++) {
		printf("==== field: %d ====\n", field_index);
		nuc970_convert_data(&fmi, page, field_index, 64, 4);
		decode_bch();
		post_decode(&fmi, field_index);
	}

	fmiSMCorrectData(&fmi, page);

	for (int j = 0; j < 16; j++) {
		printf(" %08x", fmi.FMI_NANDRA[j]);
	}
	printf("\n");

	assert(page[0] == 0x00);
	assert(page[31] == 0x00);
	assert(fmi.FMI_NANDRA[0] == 0x0000ffff);
	assert(fmi.FMI_NANDRA[8] == 0x168c6259);
	return 0;
}

int main(int argc, char** argv)
{
	verify_pages();
	//correct_pages();
	//libbch_verify_pages(); // not working
	decode_test(nuc970_nand_sample_page3);
	return 0;
}
