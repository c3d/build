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

extern "C" int lib1_foo(void);
extern "C" int lib2_bar(void);

int main()
{
#if HAVE_IOSTREAM
    std::cout << "You successfully built using build\n";
#elif HAVE_STDIO_H
    printf("You successfully built using build (without iostream)\n");
#else
#warning "Building without <iostream> or <stdio.h>. Cross-compiling?"
#endif // HAVE_IOSTREAM

    if (lib1_foo() != 0)
      exit(1);
    if (lib2_bar() != 0)
      exit(2);

    return 0;
}
