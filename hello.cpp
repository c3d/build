#include "config.h"
#if HAVE_IOSTREAM
#include <iostream>
#elif HAVE_STDIO_H
#include <stdio.h>
#endif // IO

#if HAVE_SYS_IMPROBABLE_H
#warning "Improbable header present, probably a fault in the build system"
#endif

#ifndef HAVE_IOSTREAM
#warning "We expect to have iostream"
#endif

int main()
{
#if HAVE_IOSTREAM
    std::cout << "You successfully built using build\n";
#elif HAVE_STDIO_H
    printf("You successfully built using build (without iostream)\n");
#else
#warning "Building without <iostream> or <stdio.h>. Cross-compiling?"
#endif // HAVE_IOSTREAM
}
