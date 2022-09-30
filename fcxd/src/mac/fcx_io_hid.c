#include "fcx_io_hid.h"
#include <IOKit/hidsystem/IOHIDShared.h>

static io_connect_t _fcx_io_hid_connect = 0;

// CODE BY George Warner
// http://lists.apple.com/archives/usb/2002/Sep/msg00112.html
// https://web.archive.org/web/20090410024409/http://lists.apple.com/archives/usb/2002/Sep/msg00112.html
io_connect_t fcx_io_hid_connect() {
  mach_port_t masterPort, service, iter;
  kern_return_t kr;

  if (!_fcx_io_hid_connect) {
    kr = IOMasterPort(bootstrap_port, &masterPort);

    kr = IOServiceGetMatchingServices(
        masterPort, IOServiceMatching(kIOHIDSystemClass), &iter);

    service = IOIteratorNext(iter);

    kr = IOServiceOpen(service, mach_task_self(), kIOHIDParamConnectType,
                       &_fcx_io_hid_connect);

    IOObjectRelease(service);
    IOObjectRelease(iter);
  }

  return _fcx_io_hid_connect;
}
