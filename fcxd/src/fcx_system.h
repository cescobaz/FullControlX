#ifndef FCX_SYSTEM_H
#define FCX_SYSTEM_H

#define FCX_SYSTEM_STR_MAX 256

typedef struct {
  char os_version[FCX_SYSTEM_STR_MAX];
  char username[FCX_SYSTEM_STR_MAX];
  char full_user_name[FCX_SYSTEM_STR_MAX];
  char home_directory[FCX_SYSTEM_STR_MAX];
  char hostname[FCX_SYSTEM_STR_MAX];
} fcx_system_info_t;

// Fill `info` (caller-allocated, e.g. on the stack) with system details.
// Fields that don't apply on the current platform are set to an empty string.
void fcx_system_info(fcx_system_info_t *info);

#endif // FCX_SYSTEM_H
