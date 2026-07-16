// Retained crash recovery shared by every direct Embedded Swift firmware.
// SPDX-License-Identifier: GPL-2.0-or-later

#include QMK_KEYBOARD_H
#include "keymap_protocol_bridge.h"

#if defined(QMK_MCU_RP2040)
#    include "hardware/watchdog.h"
#else
#    include "ch.h"
#endif

#ifndef OBBUT_BUILD_ID
#    define OBBUT_BUILD_ID 0
#endif

#if defined(OBBUT_DIAGNOSTICS)
#    define OBBUT_WATCHDOG_SECONDS 2u
#else
#    define OBBUT_WATCHDOG_SECONDS 8u
#endif

#define OBBUT_RETAINED_MAGIC 0x4F424352u
#define OBBUT_SLOT_COMMIT 0x43524153u
#define OBBUT_STACK_GUARD 0xBADC0FFEu
#define OBBUT_STACK_POISON 0xA5u
#define OBBUT_HEALTHY_MILLISECONDS 10000u
#define OBBUT_HEALTHY_LOOPS 1000u
#define OBBUT_STACK_GUARD_WORDS 4u

typedef struct {
    uint32_t generation;
    obbut_crash_report_t report;
    uint16_t reserved;
    uint32_t checksum;
    uint32_t commit;
} obbut_crash_slot_t;

typedef struct {
    uint32_t magic;
    uint32_t build_id;
    uint32_t boot_started_at;
    uint32_t uptime;
    uint32_t heartbeat_sequence;
    uint32_t completed_loops;
    uint32_t stack_pointer;
    uint16_t stack_free;
    uint8_t phase;
    uint8_t stack_flags;
    uint8_t consecutive_failures;
    uint8_t healthy;
    uint8_t reset_expected_from_failure;
    uint8_t stack_initialized;
#if defined(OBBUT_DIAGNOSTICS)
    uint8_t phase_ring[32];
    uint8_t phase_ring_index;
    uint8_t phase_ring_count;
    uint8_t phase_ring_reserved[2];
#endif
} obbut_crash_working_t;

typedef struct {
    obbut_crash_slot_t slots[2];
    obbut_crash_working_t working;
} obbut_crash_retained_t;

// QMK's RP2040 linker explicitly keeps .ram0.* outside the startup-cleared
// .bss. GNU ld places the same orphan NOBITS section after .bss on STM32;
// startup clears only through __bss_end__, preserving this region on reset.
static volatile obbut_crash_retained_t obbut_retained
    __attribute__((section(".ram0.obbut_crash"), aligned(4), used));

extern uint8_t __process_stack_base__[];
extern uint8_t __process_stack_end__[];

static uint32_t obbut_last_stack_sample;

#if !defined(QMK_MCU_RP2040)
static virtual_timer_t obbut_watchdog_timer;
static volatile uint32_t obbut_watchdog_observed_heartbeat;
static volatile uint8_t obbut_watchdog_stalled_seconds;
#endif

static uint32_t obbut_checksum_bytes(const uint8_t *bytes, uint32_t length, uint32_t hash) {
    for (uint32_t index = 0; index < length; ++index) {
        hash ^= bytes[index];
        hash *= 16777619u;
    }
    return hash;
}

static uint32_t obbut_slot_checksum(uint32_t generation, const obbut_crash_report_t *report) {
    uint32_t hash = obbut_checksum_bytes((const uint8_t *)&generation, sizeof(generation), 2166136261u);
    return obbut_checksum_bytes((const uint8_t *)report, sizeof(*report), hash);
}

static void obbut_copy_from_volatile(void *destination, const volatile void *source, uint32_t length) {
    uint8_t *output = (uint8_t *)destination;
    const volatile uint8_t *input = (const volatile uint8_t *)source;
    for (uint32_t index = 0; index < length; ++index) output[index] = input[index];
}

static void obbut_copy_to_volatile(volatile void *destination, const void *source, uint32_t length) {
    volatile uint8_t *output = (volatile uint8_t *)destination;
    const uint8_t *input = (const uint8_t *)source;
    for (uint32_t index = 0; index < length; ++index) output[index] = input[index];
}

static bool obbut_slot_is_valid(uint8_t index, obbut_crash_slot_t *copy) {
    obbut_copy_from_volatile(copy, &obbut_retained.slots[index], sizeof(*copy));
    return copy->commit == OBBUT_SLOT_COMMIT
        && copy->checksum == obbut_slot_checksum(copy->generation, &copy->report);
}

static int8_t obbut_latest_slot(obbut_crash_slot_t *latest) {
    obbut_crash_slot_t first;
    obbut_crash_slot_t second;
    bool first_valid = obbut_slot_is_valid(0, &first);
    bool second_valid = obbut_slot_is_valid(1, &second);
    if (!first_valid && !second_valid) return -1;
    if (first_valid && (!second_valid || (int32_t)(first.generation - second.generation) > 0)) {
        *latest = first;
        return 0;
    }
    *latest = second;
    return 1;
}

static void obbut_commit_report(const obbut_crash_report_t *report) {
    obbut_crash_slot_t latest;
    int8_t latest_index = obbut_latest_slot(&latest);
    uint8_t next_index = latest_index == 0 ? 1 : 0;
    obbut_crash_slot_t next = {
        .generation = latest_index < 0 ? 1u : latest.generation + 1u,
        .report = *report,
        .reserved = 0,
        .commit = 0,
    };
    next.checksum = obbut_slot_checksum(next.generation, &next.report);
    obbut_retained.slots[next_index].commit = 0;
    obbut_copy_to_volatile(&obbut_retained.slots[next_index], &next, sizeof(next));
    __asm volatile("dmb" ::: "memory");
    obbut_retained.slots[next_index].commit = OBBUT_SLOT_COMMIT;
    __asm volatile("dsb" ::: "memory");
}

static void obbut_initialize_working_state(void) {
    volatile uint8_t *bytes = (volatile uint8_t *)&obbut_retained.working;
    for (uint32_t index = 0; index < sizeof(obbut_retained.working); ++index) bytes[index] = 0;
    obbut_retained.working.magic = OBBUT_RETAINED_MAGIC;
    obbut_retained.working.build_id = OBBUT_BUILD_ID;
    obbut_retained.working.phase = OBBUT_CRASH_PHASE_BOOT;
    obbut_retained.working.stack_free = UINT16_MAX;
}

static void obbut_sample_stack(void) {
    volatile uint32_t *guard = (volatile uint32_t *)__process_stack_base__;
    uint8_t flags = OBBUT_CRASH_FLAG_STACK_HIGH_WATER_VALID;
    bool guard_valid = true;
    for (uint8_t index = 0; index < OBBUT_STACK_GUARD_WORDS; ++index) {
        if (guard[index] != OBBUT_STACK_GUARD) guard_valid = false;
    }
    flags |= guard_valid ? OBBUT_CRASH_FLAG_STACK_GUARD_VALID : OBBUT_CRASH_FLAG_STACK_GUARD_DAMAGED;

    const uint8_t *cursor = (const uint8_t *)(guard + OBBUT_STACK_GUARD_WORDS);
    const uint8_t *end = __process_stack_end__;
    uint32_t free_bytes = 0;
    while (cursor < end && *cursor == OBBUT_STACK_POISON) {
        ++free_bytes;
        ++cursor;
    }
    obbut_retained.working.stack_free = free_bytes > UINT16_MAX ? UINT16_MAX : (uint16_t)free_bytes;
    obbut_retained.working.stack_flags = flags;
}

static obbut_crash_report_t obbut_make_report(uint8_t reason, uint32_t pc, uint32_t lr, uint32_t sp) {
    obbut_crash_report_t report = {
        .reason = reason,
        .phase = obbut_retained.working.phase,
        .flags = obbut_retained.working.stack_flags,
        .consecutive_failures = (uint8_t)(obbut_retained.working.consecutive_failures + 1u),
        .build_id = obbut_retained.working.build_id,
        .uptime = obbut_retained.working.uptime,
        .program_counter = pc,
        .link_register = lr,
        .stack_pointer = sp != 0 ? sp : obbut_retained.working.stack_pointer,
        .stack_free = obbut_retained.working.stack_free,
    };
    if (pc != 0 || lr != 0) report.flags |= OBBUT_CRASH_FLAG_FAULT_REGISTERS_VALID;
#if defined(OBBUT_DIAGNOSTICS)
    report.flags |= OBBUT_CRASH_FLAG_DEEP_DIAGNOSTICS;
#endif
    return report;
}

static void obbut_record_failure(uint8_t reason, uint32_t pc, uint32_t lr, uint32_t sp) {
    if (obbut_retained.working.magic != OBBUT_RETAINED_MAGIC) obbut_initialize_working_state();
    if (obbut_retained.working.stack_initialized) obbut_sample_stack();
    obbut_crash_report_t report = obbut_make_report(reason, pc, lr, sp);
    obbut_retained.working.consecutive_failures = report.consecutive_failures;
    obbut_retained.working.reset_expected_from_failure = 1;
    obbut_commit_report(&report);
}

static void obbut_record_reset(uint8_t reason) {
    obbut_crash_report_t report = obbut_make_report(reason, 0, 0, 0);
    report.consecutive_failures = 0;
    obbut_commit_report(&report);
}

#if defined(OBBUT_DIAGNOSTICS) && defined(OBBUT_INJECT_STACK_PRESSURE)
__attribute__((noinline)) static void obbut_inject_stack_pressure(void) {
    volatile uint8_t pressure[2304];
    for (uint32_t index = 0; index < sizeof(pressure); ++index) {
        pressure[index] = (uint8_t)index;
    }
    __asm volatile("" : : "r"(&pressure[0]) : "memory");
}
#endif

__attribute__((noreturn, noinline)) void obbut_crash_capture_fault(
    uint32_t *exception_frame,
    uint32_t exception_return,
    uint32_t reason
) {
    (void)exception_return;
    uint32_t lr = exception_frame == NULL ? 0 : exception_frame[5];
    uint32_t pc = exception_frame == NULL ? 0 : exception_frame[6];
    uint32_t sp = exception_frame == NULL ? 0 : (uint32_t)(uintptr_t)(exception_frame + 8);
    obbut_record_failure((uint8_t)reason, pc, lr, sp);
    NVIC_SystemReset();
    while (true) {}
}

#define OBBUT_FAULT_HANDLER(name, fault_reason) \
    __attribute__((naked, noreturn)) void name(void) { \
        __asm volatile( \
            "mov r1, lr\n" \
            "movs r0, #4\n" \
            "tst r1, r0\n" \
            "beq 1f\n" \
            "mrs r0, psp\n" \
            "b 2f\n" \
            "1: mrs r0, msp\n" \
            "2: movs r2, %0\n" \
            "b obbut_crash_capture_fault\n" \
            : : "I"(fault_reason)); \
    }

OBBUT_FAULT_HANDLER(HardFault_Handler, OBBUT_CRASH_REASON_HARD_FAULT)

#if !defined(QMK_MCU_RP2040)
OBBUT_FAULT_HANDLER(MemManage_Handler, OBBUT_CRASH_REASON_MEMORY_MANAGEMENT_FAULT)
OBBUT_FAULT_HANDLER(BusFault_Handler, OBBUT_CRASH_REASON_BUS_FAULT)
OBBUT_FAULT_HANDLER(UsageFault_Handler, OBBUT_CRASH_REASON_USAGE_FAULT)
#endif

#if !defined(QMK_MCU_RP2040)
static void obbut_watchdog_callback(virtual_timer_t *timer, void *argument) {
    (void)argument;
    uint32_t heartbeat = obbut_retained.working.heartbeat_sequence;
    if (heartbeat == obbut_watchdog_observed_heartbeat) {
        ++obbut_watchdog_stalled_seconds;
    } else {
        obbut_watchdog_observed_heartbeat = heartbeat;
        obbut_watchdog_stalled_seconds = 0;
    }
    if (obbut_watchdog_stalled_seconds >= OBBUT_WATCHDOG_SECONDS) {
        obbut_record_failure(OBBUT_CRASH_REASON_WATCHDOG, 0, 0, obbut_retained.working.stack_pointer);
        NVIC_SystemReset();
    }
    chSysLockFromISR();
    chVTSetI(timer, TIME_MS2I(1000), obbut_watchdog_callback, NULL);
    chSysUnlockFromISR();
}
#endif

void obbut_crash_recovery_init(void) {
    bool watchdog_reboot = false;
#if defined(QMK_MCU_RP2040)
    watchdog_reboot = watchdog_enable_caused_reboot();
#endif

    obbut_crash_slot_t latest;
    bool has_retained_report = obbut_latest_slot(&latest) >= 0;
    bool retained_working_state = obbut_retained.working.magic == OBBUT_RETAINED_MAGIC;
    uint32_t retained_build_id = obbut_retained.working.build_id;
    if (!retained_working_state) {
        obbut_initialize_working_state();
        if (!has_retained_report) {
            obbut_record_reset(OBBUT_CRASH_REASON_POWER_ON_OR_BROWNOUT);
        }
    } else if (retained_build_id != OBBUT_BUILD_ID) {
        // Preserve the report across a firmware update, but begin a new boot-loop
        // window for the new image. This also lets a collector image retrieve a
        // report after the failed image has entered its hardware bootloader.
        obbut_initialize_working_state();
    } else if (watchdog_reboot
        && !obbut_retained.working.reset_expected_from_failure) {
        obbut_record_failure(
            OBBUT_CRASH_REASON_WATCHDOG,
            0,
            0,
            obbut_retained.working.stack_pointer
        );
    } else if (!obbut_retained.working.reset_expected_from_failure
        && !has_retained_report) {
        obbut_record_reset(OBBUT_CRASH_REASON_UNKNOWN);
    }
    obbut_retained.working.reset_expected_from_failure = 0;

    if (obbut_latest_slot(&latest) >= 0) {
        if (obbut_retained.working.consecutive_failures >= 3) {
            reset_keyboard();
            return;
        }
#if defined(OBBUT_DIAGNOSTICS) && defined(CONSOLE_ENABLE)
        uprintf(
            "crash reason=%u phase=%u count=%u build=%08lX uptime=%lu pc=%08lX lr=%08lX sp=%08lX stack=%u flags=%02X\n",
            latest.report.reason, latest.report.phase, latest.report.consecutive_failures,
            (unsigned long)latest.report.build_id, (unsigned long)latest.report.uptime,
            (unsigned long)latest.report.program_counter, (unsigned long)latest.report.link_register,
            (unsigned long)latest.report.stack_pointer, latest.report.stack_free, latest.report.flags
        );
        uprintf("crash phases=");
        uint8_t ring_count = obbut_retained.working.phase_ring_count;
        uint8_t ring_start = (uint8_t)(
            (obbut_retained.working.phase_ring_index + 32u - ring_count) & 31u
        );
        for (uint8_t offset = 0; offset < ring_count; ++offset) {
            uprintf(
                "%u%s",
                obbut_retained.working.phase_ring[(ring_start + offset) & 31u],
                offset + 1u == ring_count ? "\n" : ","
            );
        }
#endif
    }

    obbut_retained.working.build_id = OBBUT_BUILD_ID;
    obbut_retained.working.boot_started_at = timer_read32();
    obbut_retained.working.uptime = 0;
    obbut_retained.working.completed_loops = 0;
    obbut_retained.working.healthy = 0;
    obbut_retained.working.stack_initialized = 0;
    obbut_retained.working.stack_flags = 0;
    obbut_retained.working.stack_free = UINT16_MAX;
    obbut_crash_recovery_mark_phase(OBBUT_CRASH_PHASE_BOOT);

#if defined(QMK_MCU_RP2040)
    watchdog_enable(OBBUT_WATCHDOG_SECONDS * 1000u, true);
    watchdog_update();
#else
    obbut_watchdog_observed_heartbeat = obbut_retained.working.heartbeat_sequence;
    obbut_watchdog_stalled_seconds = 0;
    chVTObjectInit(&obbut_watchdog_timer);
    chVTSet(&obbut_watchdog_timer, TIME_MS2I(1000), obbut_watchdog_callback, NULL);
#endif
}

void obbut_crash_recovery_initialize_stack(void) {
    uintptr_t stack_base = (uintptr_t)__process_stack_base__;
    uintptr_t stack_end = (uintptr_t)__process_stack_end__;
    uintptr_t stack_pointer = __get_PSP();
    uint8_t local;
    if (stack_pointer < stack_base || stack_pointer > stack_end) stack_pointer = (uintptr_t)&local;
    if (stack_pointer > stack_end) stack_pointer = stack_end;

    volatile uint32_t *guard = (volatile uint32_t *)stack_base;
    for (uint8_t index = 0; index < OBBUT_STACK_GUARD_WORDS; ++index) guard[index] = OBBUT_STACK_GUARD;
    uintptr_t poison_start = (uintptr_t)(guard + OBBUT_STACK_GUARD_WORDS);
    uintptr_t poison_end = stack_pointer > poison_start + 64u ? stack_pointer - 64u : poison_start;
    volatile uint8_t *cursor = (volatile uint8_t *)poison_start;
    while ((uintptr_t)cursor < poison_end) *cursor++ = OBBUT_STACK_POISON;
    obbut_retained.working.stack_initialized = 1;
    obbut_sample_stack();

#if defined(OBBUT_DIAGNOSTICS) && defined(OBBUT_INJECT_STACK_PRESSURE)
    obbut_inject_stack_pressure();
#endif
#if defined(OBBUT_DIAGNOSTICS) && defined(OBBUT_INJECT_HARDFAULT)
    __asm volatile("udf #0");
#endif
#if defined(OBBUT_DIAGNOSTICS) && defined(OBBUT_INJECT_HANG)
    while (true) {}
#endif
}

void obbut_crash_recovery_mark_phase(uint8_t phase) {
    if (obbut_retained.working.magic != OBBUT_RETAINED_MAGIC) return;
    obbut_retained.working.phase = phase;
    obbut_retained.working.uptime = timer_read32() - obbut_retained.working.boot_started_at;
    obbut_retained.working.stack_pointer = __get_PSP();
#if defined(OBBUT_DIAGNOSTICS)
    uint8_t index = obbut_retained.working.phase_ring_index;
    obbut_retained.working.phase_ring[index] = phase;
    obbut_retained.working.phase_ring_index = (uint8_t)((index + 1u) & 31u);
    if (obbut_retained.working.phase_ring_count < 32u) ++obbut_retained.working.phase_ring_count;
#endif
}

void obbut_crash_recovery_heartbeat(void) {
    ++obbut_retained.working.heartbeat_sequence;
    ++obbut_retained.working.completed_loops;
    obbut_retained.working.uptime = timer_read32() - obbut_retained.working.boot_started_at;
    if (obbut_retained.working.uptime - obbut_last_stack_sample >= 1000u) {
        obbut_last_stack_sample = obbut_retained.working.uptime;
        obbut_sample_stack();
    }
    if (!obbut_retained.working.healthy
        && obbut_retained.working.uptime >= OBBUT_HEALTHY_MILLISECONDS
        && obbut_retained.working.completed_loops >= OBBUT_HEALTHY_LOOPS) {
        obbut_retained.working.healthy = 1;
        obbut_retained.working.consecutive_failures = 0;
    }
#if defined(QMK_MCU_RP2040)
    watchdog_update();
#endif
}

uint8_t obbut_crash_recovery_get_report(obbut_crash_report_t *report) {
    if (report == NULL) return 0;
    obbut_crash_slot_t latest;
    if (obbut_latest_slot(&latest) < 0) return 0;
    *report = latest.report;
    return 1;
}

void obbut_crash_recovery_clear_report(void) {
    obbut_retained.slots[0].commit = 0;
    obbut_retained.slots[1].commit = 0;
    __asm volatile("dmb" ::: "memory");
}
