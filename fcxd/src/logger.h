#define FCX_LOG(...) fcx_log(__VA_ARGS__)

#if FCX_LOG_LEVEL >= 4
#ifdef _WIN32
#define FCX_LOG_DEBUG(...)                                             \
  FCX_LOG("debug", __VA_ARGS__)
#else
#define FCX_LOG_DEBUG(format, ...)                                             \
  fcx_log("debug", format __VA_OPT__(, ) __VA_ARGS__)
#endif
#else
#define FCX_LOG_DEBUG(format, ...) ;
#endif

#if FCX_LOG_LEVEL >= 3
#ifdef _WIN32
#define FCX_LOG_INFO(...)                                              \
  FCX_LOG("info", __VA_ARGS__)
#else
#define FCX_LOG_INFO(format, ...)                                              \
  fcx_log("info", format __VA_OPT__(, ) __VA_ARGS__)
#endif
#else
#define FCX_LOG_INFO(format, ...) ;
#endif

#if FCX_LOG_LEVEL >= 2
#ifdef _WIN32
#define FCX_LOG_WARN(...)                                              \
  FCX_LOG("warning", __VA_ARGS__)
#else
#define FCX_LOG_WARN(format, ...)                                              \
  fcx_log("warning", format __VA_OPT__(, ) __VA_ARGS__)
#endif
#else
#define FCX_LOG_WARN(format, ...) ;
#endif

#if FCX_LOG_LEVEL >= 1
#ifdef _WIN32
#define FCX_LOG_ERR(...)                                               \
  FCX_LOG("error", __VA_ARGS__)
#else
#define FCX_LOG_ERR(format, ...)                                               \
  fcx_log("error", format __VA_OPT__(, ) __VA_ARGS__)
#endif
#else
#define FCX_LOG_ERR(format, ...) ;
#endif

void fcx_log(const char *tag, const char *format, ...);
