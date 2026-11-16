#include "checksum.h"

int checksum_value(const char *message)
{
    int value = 0;

    for (int i = 0; message[i] != '\0'; i++)
    {
        value = (value + message[i]) % 97;
    }

    return value;
}
