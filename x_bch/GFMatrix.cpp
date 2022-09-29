#include "GFMatrix.h"

namespace EccLib
{
	GFMatrix::GFMatrix(int rows, int columns, int m, unsigned char* primpoly)
	{
		this->rows = rows;
		this->columns = columns;
		this->m = m;
		this->primitive_polynomial = primpoly;

		this->_elementbytes = (int)m / 8;
		if (m % 8 != 0)
		{
			this->_elementbytes++;
		}

		this->_matrix = new unsigned char*[rows];
		for (int i = 0; i < rows; i++)
		{
			this->_matrix[i] = new unsigned char[columns*this->_elementbytes];
		}
	}

	GFMatrix* GFMatrix::Load(std::vector<unsigned char> &buffer)
	{
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
		int m = 0;
		idx = 11;
		for (; idx >= 8; idx--)
		{
			m = (m << 8) | buffer[idx];
		}

		idx = 12;
		unsigned char* primpoly = new unsigned char[4];
		for (int i = 0; i < 4; i++)
		{
			primpoly[i] = buffer[idx + i];
		}
		
		GFMatrix* gfm = new GFMatrix(r, c, m, primpoly);

		idx = 16;
		for (int i = 0; i < gfm->rows; i++)
		{
			for (int j = 0; j < gfm->columns * gfm->_elementbytes; j++)
			{
				gfm->_matrix[i][j] = buffer[idx];
				idx++;
			}
		}
		return gfm;
	}

	unsigned char* GFMatrix::GetElement(int row, int column) 
	{
		unsigned char* element = new unsigned char[this->_elementbytes];
		int startidx = column * this->_elementbytes;
		for (int i = 0; i < this->_elementbytes; i++)
		{
			element[i] = _matrix[row][startidx + i];
		}
		return element;
	}

	unsigned char** GFMatrix::MultiplyVector(unsigned char* data)
	{
		unsigned char** syndrome = new unsigned char*[this->rows];
		for (int r = 0; r < this->rows; r++)
		{
			syndrome[r] = new unsigned char[this->_elementbytes];
			for (int e = 0; e < this->_elementbytes; e++)
			{
				syndrome[r][e] = 0;
			}
			for (int c = 0; c < this->columns; c++)
			{
				unsigned char cell = data[(int)c / 8];
				if ((cell & (1 << (c % 8))) != 0) // If bit set at position c, add element at (r, c) to syndrome
				{
					for (int e = 0; e < this->_elementbytes; e++)
					{
						syndrome[r][e] ^= this->_matrix[r][c*this->_elementbytes+e];
					}
				}
			}
		}
		return syndrome;
	}
	bool GFMatrix::ElementZero(unsigned char* element, int m)
	{
		int ebytes = (m + ((8 - m % 8) % 8)) / 8;
		for (int i = 0; i < ebytes-1; i++)
		{
			if (element[i] != 0)
			{
				return false;
			}
		}
		unsigned char lastbits = element[ebytes-1];
		if (m % 8 != 0)
		{
			lastbits <<= (8 - m % 8);
		}
		return lastbits == 0;
	}
}
