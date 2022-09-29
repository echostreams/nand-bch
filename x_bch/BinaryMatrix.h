#pragma once

#ifndef BINARYMATRIX_H
#define BINARYMATRIX_H

#include "ecclib.h"
#include <string>
#include <fstream>
#include <iterator>
#include <vector>

namespace EccLib
{
	class BinaryMatrix
	{
	public:
		int rows;
		int columns;

		static BinaryMatrix* Load(std::vector<unsigned char> &file);

		unsigned char* MultiplyVector(unsigned char* data);
		bool GetElement(int row, int column);

	private:
		BinaryMatrix(int rows, int columns);

		int _memrows;
		unsigned char** _matrix;

		static unsigned char* AND_ByteArrays(unsigned char* x, unsigned char* y, int bytecount);
		static unsigned char XOR_Bytes(unsigned char* x, int bitcount);
	};
}


#endif
