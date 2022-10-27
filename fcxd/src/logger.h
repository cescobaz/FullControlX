
#define FCX_LOG_DEBUG(format, ...)                                             \
  fcx_log("debug", format __VA_OPT__(, ) __VA_ARGS__)
#define FCX_LOG_INFO(format, ...)                                              \
  fcx_log("info", format __VA_OPT__(, ) __VA_ARGS__)
#define FCX_LOG_WARN(format, ...)                                              \
  fcx_log("warning", format __VA_OPT__(, ) __VA_ARGS__)
#define FCX_LOG_ERR(format, ...)                                               \
  fcx_log("error", format __VA_OPT__(, ) __VA_ARGS__)

void fcx_log(const char *tag, const char *format, ...);
