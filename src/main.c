#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
  printf("ciao\n");

  CGEventRef event = CGEventCreate(NULL);
  CGPoint currentCoord = CGEventGetLocation(event);
  CFRelease(event);

  printf("%f %f", currentCoord.x, currentCoord.y);

  return 0;
}
