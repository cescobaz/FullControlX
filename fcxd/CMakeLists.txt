cmake_minimum_required(VERSION 3.13)

set(CMAKE_OSX_DEPLOYMENT_TARGET
    10.11
    CACHE STRING "Code uses API at least compatible with this OSX version")

project("FullControlX" VERSION 0.9)
configure_file(src/fullcontrol_x_config.h.in src/fullcontrol_x_config.h)

set(LIB_NAME "${PROJECT_NAME}_s")

find_package(json-c CONFIG REQUIRED)

set(SOURCES "src/logger.c" "src/fcx_request_handler.c" "src/fcx_app.c")
set(LIBRARIES json-c::json-c)

if(APPLE)
  # set_property(TARGET FullControlX PROPERTY OSX_ARCHITECTURES "x86_64;arm64")
  set(SOURCES
      ${SOURCES}
      "src/mac/fcx_mouse.c"
      "src/mac/fcx_system.m"
      "src/mac/fcx_keyboard_symbols_map.c"
      "src/mac/fcx_keyboard.c"
      "src/mac/fcx_apps.m"
      "src/mac/fcx_io_hid.c")

  set(LIBRARIES
      ${LIBRARIES} "-framework CoreFoundation" "-framework CoreGraphics"
      "-framework AppKit" "-framework IOKit" "-framework Carbon")
else()
  set(SOURCES
      ${SOURCES} "src/linux/fcx_mouse.c" "src/linux/fcx_system.c"
      "src/linux/fcx_keyboard_map.c" "src/linux/fcx_keyboard.c"
      "src/linux/fcx_apps.c")
  find_library(KEYMAP_LIBRARY keymap)
  find_library(KBDFILE_LIBRARY kbdfile)
  set(LIBRARIES ${LIBRARIES} ${KEYMAP_LIBRARY} ${KBDFILE_LIBRARY})
endif()

add_library(${LIB_NAME} STATIC ${SOURCES})
target_link_libraries(${LIB_NAME} PRIVATE ${LIBRARIES})

if(APPLE)
  add_executable(${PROJECT_NAME} "src/mac/main.m")
else()
  add_executable(${PROJECT_NAME} "src/main.c")
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE ${LIB_NAME} json-c::json-c)
target_include_directories(${PROJECT_NAME} PUBLIC "${PROJECT_BINARY_DIR}")

include(CTest)
# find_package(cunit CONFIG REQUIRED)
find_library(CUNIT_LIBRARY NAMES cunit libcunit cunitlib)
link_libraries(${LIB_NAME} ${CUNIT_LIBRARY} json-c::json-c)

set(TESTS mouse)

foreach(T ${TESTS})
  add_executable(${T} test/${T}.c)
  add_test(NAME ${T} COMMAND ${T})
endforeach()
