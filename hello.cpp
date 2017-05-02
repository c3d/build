#include "config.h"
#include <iostream>

#if HAVE_SYS_IMPROBABLE_H
#warning "Strange header present"
#endif

#if !HAVE_IOSTREAM
#warning "We expect to have iostream"
#endif

int main()
{
    std::cout << "You successfully built using build\n";
}
