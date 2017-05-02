#include "config.h"
#include <iostream>

#if HAVE_SYS_IMPROBABLE_H
#warning "Improbable header present, probably a fault in the build system"
#endif

#ifndef HAVE_IOSTREAM
#warning "We expect to have iostream"
#endif

int main()
{
    std::cout << "You successfully built using build\n";
}
