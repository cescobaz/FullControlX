cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "FullControlX")

project(${PROJECT_NAME} VERSION 0.9)
configure_file(src/fullcontrol_x_config.h.in src/fullcontrol_x_config.h)

set(SOURCES
  "src/mac/fcx_system.m"
  "src/mac/fcx_apps.m"
  "src/stream_parser.c"
  "src/request_handler.c"
  "src/fcx_io_interface.c"
  "src/main.m"
)

add_executable(${PROJECT_NAME} ${SOURCES})

#set_property(TARGET FullControlX PROPERTY OSX_ARCHITECTURES "x86_64;arm64")

find_package(json-c CONFIG)

target_link_libraries(${PROJECT_NAME} PRIVATE
  json-c::json-c
  "-framework CoreFoundation"
  "-framework CoreGraphics"
  "-framework AppKit"
)

target_include_directories(${PROJECT_NAME} PUBLIC
                           "${PROJECT_BINARY_DIR}"
                           )

include(CTest)
find_package(Unity CONFIG REQUIRED)
link_libraries(unity::framework)

set(TESTS
  mouse
)

foreach(T ${TESTS})
  add_executable(${T} test/${T}.c)
  add_test(NAME ${T} COMMAND ${T})
endforeach()
