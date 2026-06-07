#include "../fcx_system.h"
#include <pwd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <unistd.h>

void fcx_system_info(fcx_system_info_t *info) {
  struct utsname utsname;
  if (uname(&utsname) == 0) {
    snprintf(info->os_version, sizeof(info->os_version), "%s %s",
             utsname.sysname, utsname.release);
    snprintf(info->hostname, sizeof(info->hostname), "%s", utsname.nodename);
  } else {
    info->os_version[0] = '\0';
    info->hostname[0] = '\0';
  }

  struct passwd *pw = getpwuid(getuid());
  if (pw != NULL) {
    snprintf(info->username, sizeof(info->username), "%s", pw->pw_name);
    snprintf(info->full_user_name, sizeof(info->full_user_name), "%s",
             pw->pw_gecos != NULL ? pw->pw_gecos : "");
    snprintf(info->home_directory, sizeof(info->home_directory), "%s",
             pw->pw_dir);
  } else {
    info->username[0] = '\0';
    info->full_user_name[0] = '\0';
    info->home_directory[0] = '\0';
  }
}
