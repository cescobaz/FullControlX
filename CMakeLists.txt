cmake_minimum_required(VERSION 3.10)

project(FullControlX VERSION 0.9)
configure_file(src/fullcontrol_x_config.h.in src/fullcontrol_x_config.h)

set(SOURCES
  "src/main.m"
)

add_executable(FullControlX ${SOURCES})

target_link_libraries(FullControlX
  "-framework CoreFoundation"
  "-framework CoreGraphics"
  "-framework AppKit"
)

target_include_directories(FullControlX PUBLIC
                           "${PROJECT_BINARY_DIR}"
                           )
