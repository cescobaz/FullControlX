#include "logger.h"
#include <stdarg.h>
#include <stdio.h>
#include <time.h>

void fcx_log(const char *tag, const char *fmt, ...) {
  time_t now;
  time(&now);
  struct tm tm;
#ifdef _WIN32
  gmtime_s(&tm, &now);
#else
  gmtime_r(&now, &tm);
#endif
  fprintf(stderr, "[%s] [%04d:%02d:%02dT%02d:%02d:%02d] ", tag,
          tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min,
          tm.tm_sec);
  va_list args;
  va_start(args, fmt);
  vfprintf(stderr, fmt, args);
  fputc('\n', stderr);
  va_end(args);
}
