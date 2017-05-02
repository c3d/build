#include "build-config.h"
#include <iostream>

#if HAVE_sys_improbable_h
#warning "Strange header present"
#endif

#if !HAVE_iostream
#warning "We expect to have iostream"
#endif

int main()
{
    std::cout << "You successfully built using build\n";
}
