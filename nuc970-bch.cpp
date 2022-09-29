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
		nuc970_nand_sample_page2
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
		if (memcmp(ra_data + 32, &(test_pages[i])[2048 + 32], 32) == 0)
			std::cout << "  OK" << std::endl;
		else {
			std::cout << "  FAILED" << std::endl;
		}
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

// using libbch to verify sample page 1&2
int libbch_verify_pages()
{
	uint8_t* test_pages[] = {	// 2048 + 64
		nuc970_nand_sample_page1,
		nuc970_nand_sample_page2
	};
	int i;
	struct bch_control* bch = bch_init(15, 4, 0xc001, false);
	if (!bch)
		return -1;

	for (i = 0; i < sizeof(test_pages) / sizeof(uint8_t*); i++) {

	}
	bch_free(bch);
	return 0;
}

int main(int argc, char** argv)
{
	//return verify_pages();
	//return correct_pages();
	return libbch_verify_pages();
	//return 0;
}
