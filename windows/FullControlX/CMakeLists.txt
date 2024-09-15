# CMakeList.txt : CMake project for FullControlXWindows, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.8)

# Enable Hot Reload for MSVC compilers if supported.
if (POLICY CMP0141)
  cmake_policy(SET CMP0141 NEW)
  set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<IF:$<AND:$<C_COMPILER_ID:MSVC>,$<CXX_COMPILER_ID:MSVC>>,$<$<CONFIG:Debug,RelWithDebInfo>:EditAndContinue>,$<$<CONFIG:Debug,RelWithDebInfo>:ProgramDatabase>>")
endif()

project ("FullControlX")

# Add source to this project's executable.
add_executable (FullControlX "FullControlX.c" "FullControlX.h" "Resorces.rc"  "MainWindow.c" "MainWindow.h" "NotifyIcon.h" "NotifyIcon.c")

if(MSVC)
  set_target_properties(FullControlX PROPERTIES WIN32_EXECUTABLE TRUE)
  # SET( FCX_LINKFLAGS ${CMAKE_CURRENT_SOURCE_DIR}/Resorces.res )
  # SET_TARGET_PROPERTIES( FullControlX PROPERTIES LINK_FLAGS ${FCX_LINKFLAGS} )
 endif()

if (CMAKE_VERSION VERSION_GREATER 3.12)
  set_property(TARGET FullControlX PROPERTY CXX_STANDARD 20)
endif()

# TODO: Add tests and install targets if needed.
