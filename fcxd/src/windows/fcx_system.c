#include "../fcx_system.h"

struct json_object *fcx_system_info() {
  struct json_object *info = json_object_new_object();
    json_object_object_add(info, "os_version",
                           json_object_new_string("Windows"));
    json_object_object_add(info, "hostname",
                           json_object_new_string("windows-tower"));

  json_object_object_add(info, "username", json_object_new_string("buro"));
  json_object_object_add(info, "full_user_name",
                         json_object_new_string("buro"));
  json_object_object_add(info, "home_directory",
                         json_object_new_string("/c/Users/buro"));
  return info;
}
