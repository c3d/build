#include <malloc.h>

int main()
{
    void *result = __mingw_aligned_malloc(32 * sizeof(double), sizeof(double));
    return result ? 0 : -2;
}
