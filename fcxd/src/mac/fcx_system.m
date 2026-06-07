#include "../fcx_system.h"
#include <Foundation/Foundation.h>
#include <stdio.h>

void fcx_system_info(fcx_system_info_t *info) {
  NSProcessInfo *process = [NSProcessInfo processInfo];

  snprintf(info->os_version, sizeof(info->os_version), "%s",
           [[process operatingSystemVersionString] UTF8String]);
  snprintf(info->username, sizeof(info->username), "%s",
           [NSUserName() UTF8String]);
  snprintf(info->full_user_name, sizeof(info->full_user_name), "%s",
           [NSFullUserName() UTF8String]);
  snprintf(info->home_directory, sizeof(info->home_directory), "%s",
           [NSHomeDirectory() UTF8String]);
  snprintf(info->hostname, sizeof(info->hostname), "%s",
           [[process hostName] UTF8String]);
}
