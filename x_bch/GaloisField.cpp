#include "GaloisField.h"

namespace EccLib
{
	GaloisField::GaloisField(unsigned char* primitive_polynomial, int m)
	{
		this->m_bytes = m / 8;
		int rem = m % 8;
		if (rem != 0)
		{
			m_bytes++;
		}
		this->m = m;
		int elementcount = (1 << m) + 1;
		this->fieldpositions.resize(elementcount);
		// gf[0] = 0
		this->GF.push_back(new unsigned char[m_bytes]);
		for (int e = 0; e < m_bytes; e++)
		{
			this->GF[0][e] = 0;
		}
		this->fieldpositions[0] = 0;
		// gf[i] = 2**(i-1) for i = 1...m
		this->GF.push_back(new unsigned char[m_bytes]);
		this->GF[1][0] = 1;
		for (int e = 1; e < m_bytes; e++)
		{
			this->GF[1][e] = 0;
		}
		this->fieldpositions[1] = 1;
		for (int i = 2; i < m+1; i++)
		{
			this->GF.push_back(LeftShiftGFElement(this->GF[i - 1]));
			this->fieldpositions[1 << (i - 1)] = i;
		}
		// gf[m+1] = trailing terms of primitive polynomial
		this->GF.push_back(new unsigned char[m_bytes]);
		for (int e = 0; e < m_bytes; e++)
		{
			this->GF[m + 1][e] = primitive_polynomial[e];
		}
		if (rem != 0)
		{
			this->GF[m + 1][m_bytes - 1] ^= (1 << rem);
		}

		this->fieldpositions[GFElementAsInt(this->GF[m + 1])] = m + 1;
		// gf[k] for k=m+2...2^m-1+2
		for (int i = m + 2; i < elementcount; i++)
		{
			bool carry;
			if (rem == 0)
			{
				carry = (this->GF[i - 1][m_bytes - 1] & 0x80) != 0;
			}
			else
			{
				carry = (this->GF[i - 1][m_bytes - 1] & (1 << (rem - 1))) != 0;
			}
			this->GF.push_back(LeftShiftGFElement(this->GF[i - 1]));
			if (carry)
			{
				for (int e = 0; e < m_bytes; e++)
				{
					this->GF[i][e] ^= this->GF[m + 1][e];
				}
			}
			this->fieldpositions[GFElementAsInt(this->GF[i])] = i;
		}
	}
	unsigned char* GaloisField::MultiplyGFElements(unsigned char * e1, unsigned char * e2)
	{
		int e1power = this->fieldpositions[GFElementAsInt(e1)] - 1;
		//int e2power = GFElementAsInt(e2) - 1;
		int e2power = this->fieldpositions[GFElementAsInt(e2)] - 1;
		if (e1power == -1 || e2power == -1)
		{
			return GF[0];
		}
		return this->GF[(e1power + e2power) % ((1 << m) - 1) + 1];
	}
	unsigned char * GaloisField::InvertGFElement(unsigned char * e)
	{
		int epower = this->fieldpositions[GFElementAsInt(e)] - 1;
		if (epower == -1)
		{
			throw std::invalid_argument("Cannot invert zero element");
		}
		if (epower == 0)
		{
			return GF[1];
		}
		return this->GF[(1 << m) - epower];
	}

	unsigned char* GaloisField::GFElementPow(unsigned char* e, int p)
	{
		int epower = this->fieldpositions[GFElementAsInt(e)] - 1;
		if (epower == -1)
		{
			return GF[0];
		}
		return this->GF[(p * epower) % ((1 << m) - 1) + 1];
	}

	unsigned char* GaloisField::LeftShiftGFElement(unsigned char* e)
	{
		unsigned char* shifte = new unsigned char[this->m_bytes];
		bool carry = false;
		for (int i = 0; i < this->m_bytes - 1; i++)
		{
			bool carrynext = (e[i] & 0x80) != 0;
			shifte[i] = e[i] << 1;
			if (carry)
			{
				shifte[i] |= 1;
			}
			carry = carrynext;
		}
		shifte[this->m_bytes - 1] = (e[this->m_bytes - 1] << 1);
		if (carry)
		{
			shifte[this->m_bytes - 1] |= 1;
		}
		// Keep unused bits zero
		int rem = m % 8;
		if (rem != 0)
		{
			shifte[this->m_bytes - 1] &= (0xff ^ (1 << rem));
		}
		return shifte;
	}

	int GaloisField::GFElementAsInt(unsigned char* e)
	{
		int val = 0;
		for (int i = this->m_bytes-1; i >= 0; i--)
		{
			val <<= 8;
			val |= e[i];
		}
		return val;
	}
	
	bool GaloisField::GFElementsEqual(unsigned char * e1, unsigned char * e2)
	{
		for (int i = 0; i < this->m_bytes; i++)
		{
			if (e1[i] != e2[i])
			{
				return false;
			}
		}
		return true;
	}

	std::string GaloisField::GFElementToStr(unsigned char* e)
	{
		std::string s = "";
		s += std::to_string(this->fieldpositions[GFElementAsInt(e)] - 1);
		return s;
	}
}
