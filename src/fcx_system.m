#include "fcx_system.h"
#include <Foundation/Foundation.h>

struct json_object *fcx_system_info() {
  struct json_object *info = json_object_new_object();
  NSString *os_version =
      [[NSProcessInfo processInfo] operatingSystemVersionString];
  json_object_object_add(info, "os_version",
                         json_object_new_string([os_version UTF8String]));
  json_object_object_add(info, "username",
                         json_object_new_string([NSUserName() UTF8String]));
  json_object_object_add(info, "full_user_name",
                         json_object_new_string([NSFullUserName() UTF8String]));
  json_object_object_add(
      info, "home_directory",
      json_object_new_string([NSHomeDirectory() UTF8String]));
  return info;
}
