# CMakeList.txt : CMake project for nand-bch, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.8)

project ("nand-bch")

if(WIN32)
	add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()

# Add source to this project's executable.
add_executable (nand-bch "nand-bch.cpp" "libbch.c" "hexdump.cpp")

add_executable (bch-test "bch_test.cc" "libbch.c")

add_library (ecclib 
	"x_bch/BinaryMatrix.cpp"
	"x_bch/GaloisField.cpp"
	"x_bch/GFMatrix.cpp"
	"x_bch/ecclib.cpp"
)

add_subdirectory("reed-solomon")

add_executable (nuc970-nand "nand_data.cpp" "libbch.c" "bch_encoder_verify.c")
target_link_libraries (nuc970-nand correct-reed-solomon)

add_executable (nuc970-bch "nuc970-bch.cpp" "hexdump.cpp" "bch_encoder_verify.c" "libbch.c")