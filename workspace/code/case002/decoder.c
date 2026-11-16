#include "checksum.h"
#include "decoder.h"

#ifndef RELAY_OFFSET
#define RELAY_OFFSET 17
#endif

int relay_strength(const char *message)
{
    return checksum_value(message) * 2 + RELAY_OFFSET;
}
