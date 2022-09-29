/*
 * Empty C++ Application
 */

#include "main.h"

int main()
{
	//init_platform();
	//char c[1024];
	//printf ("Enter your file: \r\n");
	//scanf ("%s",&c[0]);
	//printf("Contents: %s\r\n", &c[0]);
	//cleanup_platform();

	//test_BCH_Encode();
	//test_BCH_Decode(true);

	// TIMER STUFF ***
	// PS Timer related definitions
	volatile u32 CntValue1;
	XScuTimer_Config *ConfigPtr;
	XScuTimer *TimerInstancePtr = &Timer;
	int Status;

	// Initialize timer counter
	ConfigPtr = XScuTimer_LookupConfig(TIMER_DEVICE_ID);

	Status = XScuTimer_CfgInitialize(TimerInstancePtr, ConfigPtr,
				 ConfigPtr->BaseAddr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Setup tests
	EccLib::BCH* bch = get_BCH_Instance();

	// Set options for timer/counter 0
	// Load the timer counter register.
	XScuTimer_LoadTimer(TimerInstancePtr, TIMER_LOAD_VALUE);

	// Start the Scu Private Timer device.
	XScuTimer_Start(TimerInstancePtr);

	XScuTimer_RestartTimer(TimerInstancePtr);
	// ***
	// Do test here
	bch_decode_timed(bch, 1);
	// End tests
	CntValue1 = XScuTimer_GetCounterValue(TimerInstancePtr);
	std::cout << "Clock cycles used: " << TIMER_LOAD_VALUE-CntValue1 << std::endl;
	// Exit code
	int s;
	std::cin >> s;
    return 0;
}

EccLib::BCH* get_BCH_Instance() {
	std::cout << "Enter Generator Matrix:" << std::endl;
	std::vector<unsigned char> genmat;
	int gensize = 386;
	for (int i=0; i<gensize; i++)
	{
		genmat.push_back(std::cin.get());
	}
	for (int i=0; i<1024-gensize; i++) {
		std::cin.get();
	}
	std::cout << "Enter Parity Check Matrix" << std::endl;
	std::vector<unsigned char> parchk;
	for (int j=0; j<394; j++)
	{
		parchk.push_back(std::cin.get());
	}
	std::cout << "par mat read" << std::endl;
	return new EccLib::BCH(genmat, parchk, 6, 3);
}

void bch_decode_timed(EccLib::BCH* bch, int iterations)
{
	int input_bit_len;
	int encoded_bit_len;
	input_bit_len = 45;
	encoded_bit_len = 63;
	int input_byte_len = (int)input_bit_len / 8;
	if (input_bit_len % 8 != 0)
	{
		input_byte_len++;
	}
	int encoded_byte_len = (int)encoded_bit_len / 8;
	if (encoded_bit_len % 8 != 0)
	{
		encoded_byte_len++;
	}
	for (int i=0; i<iterations; i++)
	{
		std::vector<unsigned char> ibvector = randomdata(input_byte_len);
		unsigned char* input_bytes = &ibvector[0];
		unsigned char* encoded = bch->Encode(input_bytes);
		/*
		unsigned char* errored = standardnoise(encoded, encoded_byte_len);
		unsigned char* decoded = bch->Decode(errored);
		bool eq = arraysequal(encoded, decoded, encoded_byte_len);
		if (!eq) {
			std::cout << "Errors not corrected." << std::endl;
		}
		delete decoded;
		delete input_bytes;
		delete encoded;
		delete errored;
		*/
		std::cout << i << std::endl;
	}
}

bool arraysequal(unsigned char* v1, unsigned char* v2, unsigned int size)
{
	bool res = true;
	for (unsigned int i=0; i < size; ++i)
	{
		if (v1[i] != v2[i])
		{
			res = false;
		}
	}
	// Wait to return until we've looped through completely (instead of immediately on false),
	// in order to preserve timing
	return res;
}

void test_BCH_Encode() {
	//EccLib::BCH bch = EccLib::BCH(R"(C:\Users\Wesley\dev\ecc-lib\pyGF\4095_4047_matrix)",
		//R"(C:\Users\Wesley\dev\ecc-lib\pyGF\4095_4047_check_matrix)",
		//12, 4);

	//std::istream_iterator<char> filein(std::cin);
	//std::istream_iterator<char> eof;
	//init_platform();
	char * buffer = new char[600];
	/*while (true) {
		std::cin.get(buffer, 6);
		std::cin.get();
		std::cin.get();
		for (int i=0; i<5; i++) {
			std::cout << (int)buffer[i] << std::endl;
		}
	}
*/
	std::cout << "Enter Generator Matrix:" << std::endl;

	std::cin.get(buffer, 504);
	std::cin.get();
	std::cin.get();
	std::vector<unsigned char> genmat;
	for (int i=0; i<504; i++)
	{
		genmat.push_back(buffer[i]);
	}
	//std::vector<unsigned char> genmat(std::istream_iterator<char>{std::cin}, std::istream_iterator<char>{});

	std::cout << "Enter Parity Check Matrix" << std::endl;
	buffer = new char[500];
	std::cin.get(buffer, 394);
	std::cin.get();
	std::cin.get();
	std::vector<unsigned char> parchk;
	for (int i=0; i<394; i++)
	{
		parchk.push_back(buffer[i]);
	}
	//std::vector<unsigned char> parchk(std::istream_iterator<char>{std::cin}, std::istream_iterator<char>{});
	//cleanup_platform();
	EccLib::BCH bch = EccLib::BCH(genmat, parchk, 6, 3);
	int input_bit_len = 45;
	int encoded_bit_len = 63;
	int t = 3;
	int mbytes = 1;
	int input_byte_len = (int)input_bit_len / 8;
	if (input_bit_len % 8 != 0)
	{
		input_byte_len++;
	}

	std::vector<unsigned char> ibvector = randomdata(input_byte_len);
	unsigned char* input_bytes = &ibvector[0];
	auto encoded = bch.Encode(input_bytes);
	std::cout << "BCH encode sucessful" << std::endl;
}

void test_BCH_Decode(bool small)
{
	EccLib::BCH* bch;
	int input_bit_len;
	int encoded_bit_len;
	int t;
	int mbytes;
	//if (small)
	//{
	init_platform();
		std::cout << "Enter Generator Matrix:" << std::endl;
		char * buffer = new char[500];
		std::vector<unsigned char> genmat;
		for (int i=0; i<386; i++)
		{
			genmat.push_back(std::cin.get());
		}
		//std::vector<unsigned char> genmat(std::istream_iterator<char>{std::cin}, std::istream_iterator<char>{});

		std::cout << "Enter Parity Check Matrix" << std::endl;
		buffer = new char[500];
		//std::cin.get(buffer, 395);
		std::cin.get();
		std::vector<unsigned char> parchk;
		for (int i=0; i<394; i++)
		{
			parchk.push_back(std::cin.get());
		}
		//std::vector<unsigned char> parchk(std::istream_iterator<char>{std::cin}, std::istream_iterator<char>{});
		cleanup_platform();
		bch = new EccLib::BCH(genmat, parchk, 6, 3);
		input_bit_len = 45;
		encoded_bit_len = 63;
		t = 3;
		mbytes = 1;
	/*}
	else
	{
		bch = new EccLib::BCH(R"(C:\Users\Wesley\dev\ecc-lib\pyGF\4095_4047_matrix)",
			R"(C:\Users\Wesley\dev\ecc-lib\pyGF\4095_4047_check_matrix)",
			12, 4);
		input_bit_len = 4047;
		encoded_bit_len = 4095;
		t = 4;
		mbytes = 2;
	}*/
	int input_byte_len = (int)input_bit_len / 8;
	if (input_bit_len % 8 != 0)
	{
		input_byte_len++;
	}
	int encoded_byte_len = (int)encoded_bit_len / 8;
	if (encoded_bit_len % 8 != 0)
	{
		encoded_byte_len++;
	}
	std::vector<unsigned char> ibvector = randomdata(input_byte_len);
	unsigned char* input_bytes = &ibvector[0];
	unsigned char* encoded = bch->Encode(input_bytes);
	unsigned char** syndrome = bch->ComputeSyndrome(encoded);
	if (!bch->CheckSyndrome(syndrome))
	{
		std::cout << "nonzero syndrome no error vector" << std::endl;
		for (int s = 0; s < 2 * t; s++)
		{
			for (int e = 0; e < mbytes; e++)
			{
				std::cout << std::hex << (int)syndrome[s][e];
			}
			std::cout << std::endl;
		}
	}
	else
	{
		std::cout << "zero syndrome no error vector" << std::endl;
		//std::vector<unsigned char*> elp = bch->ComputeErrorLocationPolynomial(syndrome);
		//std::cout << "no error ELP len " << elp.size() << std::endl;
	}
	ibvector = randomdata(input_byte_len);
	input_bytes = &ibvector[0];
	encoded = bch->Encode(input_bytes);
	unsigned char* errored = standardnoise(encoded, encoded_byte_len);
	syndrome = bch->ComputeSyndrome(errored);
	std::cout << "Syndrome:" << std::endl;
	for (int s = 0; s < 2 * t; s++)
	{
		std::cout << bch->_gf->GFElementToStr(syndrome[s]) << std::endl;
	}
	std::cout << ".Syndrome" << std::endl;
	if (bch->CheckSyndrome(syndrome))
	{
		std::cout << "zero syndrome on errored vector" << std::endl;
		for (int s = 0; s < 2 * t; s++)
		{
			for (int e = 0; e < mbytes; e++)
			{
				std::cout << std::hex << (int)syndrome[s][e];
			}
			std::cout << std::endl;
		}
	}
	else
	{
		std::cout << "nonzero syndrome errored vector" << std::endl;
		std::vector<unsigned char*> elp = bch->ComputeErrorLocationPolynomial(syndrome);
		std::cout << "Error ELP len " << elp.size() << std::endl;
		std::cout << bch->GFPolynomialToStr(elp) << std::endl;
		unsigned char* decoded = bch->Decode(errored);
		comparearrays(encoded, decoded, encoded_byte_len);
	}
}

void testdummyencode() {
	unsigned char* data = &randomdata(20)[0];
	unsigned char encodeddata[20];
	EccLib::Functions::DummyEncode(data, encodeddata);
	comparearrays(data, encodeddata, 20);
	unsigned char decodeddata[20];
	EccLib::Functions::DummyDecode(encodeddata, decodeddata);
	comparearrays(data, decodeddata, 20);
}

std::vector<unsigned char> randomdata(int len)
{
	std::random_device rd;   // non-deterministic generator
	std::mt19937 gen(rd());  // to seed mersenne twister.
	std::uniform_int_distribution<> dist(0,255);
	std::vector<unsigned char> data;
	data.reserve(len);
	for (int i = 0; i < len; ++i)
	{
		data.push_back(dist(gen));
	}
	return data;
}

// Applies a known error pattern (flips first two bits) to a vector (previously encoded)
unsigned char* standardnoise(unsigned char* v, int size)
{
	unsigned char* witherror = new unsigned char[size];
	for (int i = 0; i < size; i++)
	{
		witherror[i] = v[i];
	}
	witherror[0] ^= 0x03;
	return witherror;
}

void comparearrays(unsigned char* v1, unsigned char* v2, unsigned int size)
{
	for (unsigned int i=0; i < size; ++i)
	{
		if (v1[i] != v2[i])
		{
			std::cout << "diffval at " << i << std::endl;
			std::cout << std::hex << (int)v1[i] << std::endl;
			std::cout << std::hex << (int)v2[i] << std::endl;
			return;
		}
	}
	std::cout << "success" << std::endl;
}

/*
void testload_matrix()
{
	EccLib::BinaryMatrix bm = *EccLib::BinaryMatrix::Load(R"(C:\Users\Wesley\dev\ecc-lib\pyGF\63_45_matrix)");
	for (int col = 0; col < 10; col++) {
		std::cout << "col " << col << std::endl;
		int row = 0;
		while (!bm.GetElement(row, col)) {
			row++;
		}
		std::cout << "True row " << row << std::endl;
	}
}
void test_matrix_encode()
{
	EccLib::BinaryMatrix bm = *EccLib::BinaryMatrix::Load(R"(C:\Users\Wesley\dev\ecc-lib\pyGF\63_45_matrix)");
	unsigned char* data = new unsigned char[6];
	for (int i = 0; i < 6; i++)
	{
		data[i] = (unsigned char)(i+1);
	}
	unsigned char* encoded = bm.MultiplyVector(data);
	for (int i = 0; i < 8; i++)
	{
		std::cout << (int)encoded[i] << std::endl;
	}
}

void testload_gfmatrix()
{
	EccLib::GFMatrix gfm = *EccLib::GFMatrix::Load(R"(C:\Users\Wesley\dev\ecc-lib\pyGF\63_45_check_matrix)");
	for (int row = 0; row < gfm.rows; row++) {
		std::cout << "row " << row << " col " << 1 << ": 0x";
		int ebytes = (gfm.m + ((8 - gfm.m % 8) % 8)) / 8;
		unsigned char* element = gfm.GetElement(row, 1);
		for (int e = 0; e < ebytes; e++)
		{
			std::cout << std::hex << (int)element[e];
		}
		std::cout << std::endl;
	}
}
*/
