#include <unistd.h>
#include <stdio.h>

int main()
{
    printf("#define CONFIG_SBRK_BASE ((void *) %p)\n", sbrk(0));
    return 0;
}
