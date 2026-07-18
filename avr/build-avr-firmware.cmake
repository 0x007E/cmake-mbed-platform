function(build_avr_firmware TARGET)
    set(options)
    set(oneValueArgs MCU F_CPU OUTPUT_NAME DFP_ROOT)
    set(multiValueArgs SOURCES INCLUDES DEFINES COMPILE_OPTIONS LINK_OPTIONS)
    
    cmake_parse_arguments(AVR "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT AVR_MCU)
        message(FATAL_ERROR "build_avr_firmware(${TARGET}): MCU missing")
    endif()

    if(NOT AVR_F_CPU)
        message(FATAL_ERROR "build_avr_firmware(${TARGET}): F_CPU missing")
    endif()

    if(NOT AVR_OUTPUT_NAME)
        message(FATAL_ERROR "build_avr_firmware(${TARGET}): OUTPUT_NAME missing")
    endif()

    if(NOT AVR_DFP_ROOT)
        message(FATAL_ERROR "build_avr_firmware(${TARGET}): DFP_ROOT missing")
    endif()

    add_executable(${TARGET} ${AVR_SOURCES})

    target_include_directories(${TARGET} PRIVATE
        ${AVR_INCLUDES}
        ${AVR_DFP_ROOT}/include
    )

    target_compile_definitions(${TARGET} PRIVATE
        F_CPU=${AVR_F_CPU}
        ${AVR_DEFINES}
    )

    target_compile_options(${TARGET} PRIVATE
        -mmcu=${AVR_MCU}
        -B ${AVR_DFP_ROOT}/gcc/dev/${AVR_MCU}
        -funsigned-char
        -funsigned-bitfields
        -ffunction-sections
        -fdata-sections
        -fpack-struct
        -fshort-enums
        -Wall
        -g2
        -Og
        -std=gnu99
        ${AVR_COMPILE_OPTIONS}
    )

    target_link_options(${TARGET} PRIVATE
        -mmcu=${AVR_MCU}
        -B ${AVR_DFP_ROOT}/gcc/dev/${AVR_MCU}
        -Wl,--gc-sections
        -Wl,-Map=${CMAKE_BINARY_DIR}/${AVR_OUTPUT_NAME}.map
        ${AVR_LINK_OPTIONS}
    )

    target_link_libraries(${TARGET} PRIVATE m)

    set_target_properties(${TARGET} PROPERTIES
        OUTPUT_NAME ${AVR_OUTPUT_NAME}
    )

    add_custom_command(TARGET ${TARGET} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY}
            -O ihex
            -R .eeprom -R .fuse -R .lock -R .signature -R .user_signatures
            $<TARGET_FILE:${TARGET}>
            ${CMAKE_BINARY_DIR}/${AVR_OUTPUT_NAME}.hex
        COMMAND ${CMAKE_OBJCOPY}
            -j .eeprom
            --set-section-flags=.eeprom=alloc,load
            --change-section-lma .eeprom=0
            --no-change-warnings
            -O ihex
            $<TARGET_FILE:${TARGET}>
            ${CMAKE_BINARY_DIR}/${AVR_OUTPUT_NAME}.eep
        COMMAND /bin/sh -c
            "${CMAKE_OBJDUMP} -h -S '$<TARGET_FILE:${TARGET}>' > '${CMAKE_BINARY_DIR}/${AVR_OUTPUT_NAME}.lss'"
        COMMAND ${AVR_SIZE}
            $<TARGET_FILE:${TARGET}>
        BYPRODUCTS
            ${CMAKE_BINARY_DIR}/${AVR_OUTPUT_NAME}.hex
            ${CMAKE_BINARY_DIR}/${AVR_OUTPUT_NAME}.eep
            ${CMAKE_BINARY_DIR}/${AVR_OUTPUT_NAME}.lss
            ${CMAKE_BINARY_DIR}/${AVR_OUTPUT_NAME}.map
        VERBATIM
    )
endfunction()