set(SRCFILES polynomial.c reed-solomon.c encode.c decode.c)
add_library(correct-reed-solomon OBJECT ${SRCFILES})
target_include_directories(correct-reed-solomon PRIVATE ".")