#include <stdlib.h>

int main()
{
    void *ptr = NULL;
    int result = posix_memalign(&result, sizeof (double), 32 * sizeof(double));
    return result == 0 ? 0 : -2;
}
