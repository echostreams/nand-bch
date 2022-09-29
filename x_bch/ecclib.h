#pragma once

#ifndef ECCLIB_H
#define ECCLIB_H

#include <string>
#include <vector>

namespace EccLib
{
	class BinaryMatrix;
	class GFMatrix;
	class GaloisField;

	class Functions
	{
	public:
		static void DummyEncode(unsigned char data[20], unsigned char encoded[20]);
		static void DummyDecode(unsigned char data[20], unsigned char decoded[20]);
	};

	class BCH
	{
	public:
		BCH(std::vector<unsigned char> &generatormatrixfile, std::vector<unsigned char> &paritycheckmatrixfile, int m, int t);
		unsigned char* Encode(unsigned char* data);
		unsigned char* Decode(unsigned char* data);

		// Temporarily public for testing
		unsigned char** ComputeSyndrome(unsigned char* data);
		bool CheckSyndrome(unsigned char** syndrome);
		std::vector<unsigned char*> ComputeErrorLocationPolynomial(unsigned char** syndrome);
		std::string GFPolynomialToStr(std::vector<unsigned char*> p);

		GaloisField* _gf;
	private:
		BinaryMatrix* _generatormatrix;
		GFMatrix* _paritycheckmatrix;
		int t;
		int m;
		int m_bytes;

		std::vector<unsigned char*> SumGFPolynomials(std::vector<unsigned char*> p1, std::vector<unsigned char*> p2);
		bool CheckGFPolynomialRoot(std::vector<unsigned char*> poly, unsigned char* root);
	};
}


#endif
