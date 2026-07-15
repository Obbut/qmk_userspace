// Stack-independent recovery from Cortex-M faults into the STM32 ROM DFU loader.
// SPDX-License-Identifier: GPL-2.0-or-later

#include <stdint.h>

#if !defined(BOOTLOADER_STM32_DFU)
#    error "Planck crash recovery requires QMK's STM32 DFU bootloader support."
#endif

// QMK's STM32 DFU implementation reserves the final word of RAM for this
// marker and consumes it before normal firmware initialization.
extern uint32_t __ram0_end__;

__attribute__((naked, noreturn, used)) void HardFault_Handler(void) {
    __asm volatile(
        "ldr r0, =__ram0_end__\n"
        "ldr r1, =0xDEADBEEF\n"
        "str r1, [r0, #-4]\n"
        "ldr r0, =0xE000ED0C\n"
        "ldr r1, =0x05FA0004\n"
        "str r1, [r0]\n"
        "dsb\n"
        "isb\n"
        "1: b 1b\n");
}

void MemManage_Handler(void) __attribute__((alias("HardFault_Handler"), noreturn));
void BusFault_Handler(void) __attribute__((alias("HardFault_Handler"), noreturn));
void UsageFault_Handler(void) __attribute__((alias("HardFault_Handler"), noreturn));
