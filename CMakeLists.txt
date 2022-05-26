PROJECT(portaudio_ffi)
#to allow install from subdirectory
cmake_minimum_required(VERSION 3.13)

unset(CMAKE_C_FLAGS)
unset(CMAKE_CXX_FLAGS)
if(WIN32)
    remove_definitions(-DWIN32_LEAN_AND_MEAN -DNOMINMAX)
	set(PA_USE_ASIO ON CACHE BOOL "Enable support for ASIO" FORCE)
	set(CMAKE_SHARED_LIBRARY_PREFIX "")
endif()

set(PA_BUILD_STATIC OFF CACHE BOOL "PortAudio static library" FORCE)
set(PA_BUILD_SHARED ON CACHE BOOL "PortAudio shared library" FORCE)


# disable platform suffix
set(PA_LIBNAME_ADD_SUFFIX OFF CACHE BOOL "PortAudio static library suffix" FORCE)
# disable install target
set(PA_DISABLE_INSTALL ON CACHE BOOL "Disable PortAudio install" FORCE)

#set(ASIO_SDK_ZIP_PATH ../LuaJIT-rtaudio/
add_subdirectory(portaudio  EXCLUDE_FROM_ALL)
set_target_properties(PortAudio PROPERTIES PUBLIC_HEADER "")

add_custom_target(portaudio_ffi ALL)
add_dependencies(portaudio_ffi PortAudio)

set(CMAKE_FRAMEWORK ON)
set(CMAKE_INSTALL_PREFIX ${LUAJIT_BIN})

install(TARGETS PortAudio RUNTIME DESTINATION ${LUAJIT_BIN}
					LIBRARY DESTINATION ${LUAJIT_BIN}
					
)
INSTALL(FILES portaudio_ffi.lua DESTINATION ${LUAJIT_BIN}/lua)