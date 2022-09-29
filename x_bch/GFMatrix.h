#pragma once

#ifndef GFMATRIX_H
#define GFMATRIX_H
#include "ecclib.h"
#include <string>
#include <fstream>
#include <iterator>
#include <vector>

namespace EccLib
{
	class GFMatrix
	{
	public:
		int rows;
		int columns;
		int m;
		unsigned char* primitive_polynomial;

		static GFMatrix* Load(std::vector<unsigned char> &file);

		unsigned char* GetElement(int row, int column);
		unsigned char** MultiplyVector(unsigned char* data);
		static bool ElementZero(unsigned char* element, int m);
		
	private:
		GFMatrix(int rows, int columns, int m, unsigned char* primpoly);

		int _elementbytes;
		unsigned char** _matrix;
	};
}

#endif
