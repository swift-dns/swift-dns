#ifndef CSWIFT_DNS_IDNA_H
#define CSWIFT_DNS_IDNA_H

#include <stdint.h>
#include <stddef.h>

// IDNA2008 status enum values (matching IDNAMapping.IDNA2008Status)
typedef enum {
    IDNA_STATUS_NV8 = 0,
    IDNA_STATUS_XV8 = 1,
    IDNA_STATUS_NONE = 2
} IDNA2008Status;

// IDNA mapping result types (matching IDNAMapping cases)
typedef enum {
    IDNA_RESULT_VALID = 0,
    IDNA_RESULT_MAPPED = 1,
    IDNA_RESULT_DEVIATION = 2,
    IDNA_RESULT_DISALLOWED = 3,
    IDNA_RESULT_IGNORED = 4
} IDNAMappingResultType;

// Structure to hold mapping result data
typedef struct {
    uint8_t type;
    uint8_t status;  // Only used for valid results
    const uint32_t* mapped_unicode_scalars; // Array of mapped Unicode scalars (for mapped/deviation)
    uint8_t mapped_count;    // Number of mapped Unicode scalars
} IDNAMappingResult;

// Look up IDNA mapping for a given Unicode code point
// Returns a pointer to a static IDNAMappingResult
const IDNAMappingResult *idna_mapping_lookup(uint32_t code_point);

#endif // CSWIFT_DNS_IDNA_H
