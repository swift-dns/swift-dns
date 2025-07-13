#ifndef CSWIFT_DNS_IDNA_TESTING_H
#define CSWIFT_DNS_IDNA_TESTING_H

#include <stddef.h>

typedef struct {
    const char* source;
    const char* toUnicode;
    const char** toUnicodeStatus;
    size_t toUnicodeStatusCount;
    const char* toAsciiN;
    const char** toAsciiNStatus;
    size_t toAsciiNStatusCount;
} IDNATestV2CCase;

const IDNATestV2CCase* idna_test_v2_all_cases(size_t* count);

#endif // CSWIFT_DNS_IDNA_TESTING_H
