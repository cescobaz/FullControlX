#include "../fcx_system.h"
#include <pwd.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <unistd.h>

struct json_object *fcx_system_info() {
  struct json_object *info = json_object_new_object();

  struct utsname utsname;
  if (uname(&utsname) == 0) {
    int len = strlen(utsname.sysname) + strlen(utsname.release) + 2;
    char *os_version = malloc(len);
    sprintf(os_version, "%s %s", utsname.sysname, utsname.release);
    json_object_object_add(info, "os_version",
                           json_object_new_string(os_version));
    json_object_object_add(info, "hostname",
                           json_object_new_string(utsname.nodename));
    free(os_version);
  }

  uid_t uid = getuid();
  struct passwd *pw = getpwuid(uid);
  json_object_object_add(info, "username", json_object_new_string(pw->pw_name));
  json_object_object_add(info, "full_user_name",
                         json_object_new_string(pw->pw_gecos));
  json_object_object_add(info, "home_directory",
                         json_object_new_string(pw->pw_dir));
  return info;
}
