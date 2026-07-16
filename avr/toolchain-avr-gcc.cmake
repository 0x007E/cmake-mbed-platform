set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(AVR_TOOLCHAIN_ROOT "${CMAKE_SOURCE_DIR}/avr8-gnu-toolchain-linux_x86_64" CACHE PATH "Path to AVR GNU toolchain")

set(CMAKE_C_COMPILER   "${AVR_TOOLCHAIN_ROOT}/bin/avr-gcc"     CACHE PATH "gcc"     FORCE)
set(CMAKE_ASM_COMPILER "${AVR_TOOLCHAIN_ROOT}/bin/avr-gcc"     CACHE PATH "asm"     FORCE)
set(CMAKE_CXX_COMPILER "${AVR_TOOLCHAIN_ROOT}/bin/avr-g++"     CACHE PATH "g++"     FORCE)
set(CMAKE_AR           "${AVR_TOOLCHAIN_ROOT}/bin/avr-ar"      CACHE PATH "ar"      FORCE)
set(CMAKE_LINKER       "${AVR_TOOLCHAIN_ROOT}/bin/avr-ld"      CACHE PATH "linker"  FORCE)
set(CMAKE_NM           "${AVR_TOOLCHAIN_ROOT}/bin/avr-nm"      CACHE PATH "nm"      FORCE)
set(CMAKE_OBJCOPY      "${AVR_TOOLCHAIN_ROOT}/bin/avr-objcopy" CACHE PATH "objcopy" FORCE)
set(CMAKE_OBJDUMP      "${AVR_TOOLCHAIN_ROOT}/bin/avr-objdump" CACHE PATH "objdump" FORCE)
set(CMAKE_STRIP        "${AVR_TOOLCHAIN_ROOT}/bin/avr-strip"   CACHE PATH "strip"   FORCE)
set(CMAKE_RANLIB       "${AVR_TOOLCHAIN_ROOT}/bin/avr-ranlib"  CACHE PATH "ranlib"  FORCE)
set(AVR_SIZE           "${AVR_TOOLCHAIN_ROOT}/bin/avr-size"    CACHE PATH "size"    FORCE)

set(CMAKE_EXECUTABLE_SUFFIX ".elf")