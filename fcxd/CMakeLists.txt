cmake_minimum_required(VERSION 3.13)

set(CMAKE_OSX_DEPLOYMENT_TARGET
    10.11
    CACHE STRING "Code uses API at least compatible with this OSX version")

project("FullControlX" VERSION 0.9)
configure_file(src/fullcontrol_x_config.h.in src/fullcontrol_x_config.h)

set(LIB_NAME "${PROJECT_NAME}_s")

set(SOURCES "src/stream_parser.c" "src/request_handler.c" "src/fcx_app.c")

set(SOURCES_MAC "src/mac/fcx_mouse.c" "src/mac/fcx_system.m"
                "src/mac/fcx_apps.m" "src/mac/fcx_io_hid.c")

find_package(json-c CONFIG REQUIRED)
set(LIBRARIES json-c::json-c "-framework CoreFoundation"
              "-framework CoreGraphics" "-framework AppKit" "-framework IOKit")

# set_property(TARGET FullControlX PROPERTY OSX_ARCHITECTURES "x86_64;arm64")
add_library(${LIB_NAME} STATIC ${SOURCES} ${SOURCES_MAC})
target_link_libraries(${LIB_NAME} PRIVATE ${LIBRARIES})

add_executable(${PROJECT_NAME} "src/main.m")
target_link_libraries(${PROJECT_NAME} PRIVATE ${LIB_NAME} json-c::json-c)
target_include_directories(${PROJECT_NAME} PUBLIC "${PROJECT_BINARY_DIR}")

include(CTest)
find_package(Unity CONFIG REQUIRED)
link_libraries(${LIB_NAME} unity::framework json-c::json-c)

set(TESTS mouse)

foreach(T ${TESTS})
  add_executable(${T} test/${T}.c)
  add_test(NAME ${T} COMMAND ${T})
endforeach()
