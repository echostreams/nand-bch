#include "BinaryMatrix.h"

namespace EccLib
{
	// TODO: Handle systems with non 8-bit words
	// TODO: Standardize byteorder/support 
	// _matrix is defined as an array of columns, not rows
	BinaryMatrix::BinaryMatrix(int r, int c)
	{
		this->rows = r;
		this->columns = c;

		this->_memrows = (int)r / 8;
		if (r % 8 != 0) {
			this->_memrows++;
		}

		this->_matrix = new unsigned char*[c];
		for (int i = 0; i < c; i++)
		{
			this->_matrix[i] = new unsigned char[this->_memrows];
		}
	}

	BinaryMatrix* BinaryMatrix::Load(std::vector<unsigned char> &buffer)
	{
		//std::ifstream input(file, std::ios::binary);
		// copies all data into buffer
		int r = 0;
		int idx = 3;
		for (; idx >= 0; idx--)
		{
			r = (r << 8) | buffer[idx];
		}
		int c = 0;
		idx = 7;
		for (; idx >= 4; idx--)
		{
			c = (c << 8) | buffer[idx];
		}
		BinaryMatrix* bm = new BinaryMatrix(r, c);
		idx = 8;
		for (int i=0; i < bm->columns; i++)
		{
			for (int j = 0; j < bm->_memrows; j++)
			{
				bm->_matrix[i][j] = buffer[idx];
				idx++;
			}
		}
		return bm;
	}

	bool BinaryMatrix::GetElement(int row, int column)
	{
		unsigned char cell = this->_matrix[column][(int)row / 8];
		return (cell & (1 << (row % 8))) != 0;
	}

	// Left multiplies an array of data, length of `data` must be equal to _memrows
	// Returns array of bytes of length large enough to hold `columns` bits
	unsigned char* BinaryMatrix::MultiplyVector(unsigned char* data)
	{
		int lenbytes = (int)this->columns / 8;
		int remainingbits = this->columns % 8;
		if (remainingbits != 0)
		{
			lenbytes++;
		}
		unsigned char* product = new unsigned char[lenbytes];
		unsigned char newbyte = 0;
		for (int i = 0; i < this->columns; i++)
		{
			unsigned char* column = this->_matrix[i];
			// Calculate dotproduct of column and data
			unsigned char* bytesums = AND_ByteArrays(data, column, this->_memrows);
			unsigned char bytesum = XOR_Bytes(bytesums, this->rows);
			delete[] bytesums;
			// Find bit sum (http://graphics.stanford.edu/~seander/bithacks.html#ParityParallel)
			bytesum ^= bytesum >> 4;
			bytesum &= 0xf;
			newbyte = newbyte | (((0x6996 >> bytesum) & 1) << (i % 8)); // 0x6996 is a magic numer that functions as a lookup table for the correct parity bit of bytesum
			if ((i+1) % 8 == 0)
			{
				product[(int)i / 8] = newbyte;
				newbyte = 0;
			}
		}
		if (remainingbits != 0)
		{
			product[lenbytes - 1] = newbyte;
		}
		return product;
	}

	unsigned char* BinaryMatrix::AND_ByteArrays(unsigned char* x, unsigned char* y, int bytecount)
	{
		unsigned char* sum = new unsigned char[bytecount];
		for (int i = 0; i < bytecount; i++)
		{
			sum[i] = x[i] & y[i];
		}
		return sum;
	}

	unsigned char BinaryMatrix::XOR_Bytes(unsigned char* x, int bitcount)
	{
		unsigned char sum = 0;
		for (int i = 0; i < (int)bitcount/8; i++)
		{
			sum ^= x[i];
		}
		unsigned char bitremainder = bitcount % 8;
		if (bitremainder != 0)
		{
			sum ^= (x[(int)bitcount / 8] << (8 - bitremainder)) >> (8 - bitremainder);
		}
		return sum;
	}


}
