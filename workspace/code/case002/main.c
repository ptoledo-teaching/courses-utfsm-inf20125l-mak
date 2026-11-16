#include <stdio.h>

#include "checksum.h"
#include "decoder.h"

int main(void)
{
    const char *relay_name = "hoth-relay";

    printf("Relay %s: checksum=%d strength=%d\n",
           relay_name,
           checksum_value(relay_name),
           relay_strength(relay_name));

    return 0;
}
