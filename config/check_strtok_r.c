#include <string.h>

int main()
{
    char *brkb;
    char strbuf[] = "abc";
    strtok_r(strbuf, ":", &brkb);
    return 0;
}
