import type { StateMachine } from 'rp2040js';
import type { DeterministicClock } from './clock.js';
import type { FirmwareMachine } from './machine.js';

const SYSTEM_CLOCK_HZ = 125_000_000;
const SYSTEM_CYCLE_NANOS = 1_000_000_000 / SYSTEM_CLOCK_HZ;

interface PIOEvent {
  readonly owner: FirmwareMachine;
  readonly machine: StateMachine;
  nextNanos: number;
}

export class DeterministicScheduler {
  private readonly cpuNextNanos: number[];
  private readonly pioEvents: PIOEvent[];
  private tieBreaker = 0;
  private startupPollSkipped = false;
  private startupPollExitNanos: number | undefined;
  eventCount = 0;

  constructor(
    readonly clock: DeterministicClock,
    readonly machines: readonly FirmwareMachine[],
  ) {
    this.cpuNextNanos = machines.map(() => clock.nanos);
    this.pioEvents = machines.flatMap((owner) =>
      owner.rp2040.pio.flatMap((pio) =>
        pio.machines.map((machine) => ({ owner, machine, nextNanos: Number.POSITIVE_INFINITY })),
      ),
    );
  }

  runFor(milliseconds: number, maxEvents = 50_000_000): void {
    const deadline = this.clock.nanos + milliseconds * 1_000_000;
    this.runLoop(undefined, deadline, maxEvents);
  }

  runUntil(
    predicate: () => boolean,
    deadlineNanos: number,
    maxEvents = 50_000_000,
  ): void {
    this.runLoop(predicate, deadlineNanos, maxEvents);
  }

  private runLoop(
    predicate: (() => boolean) | undefined,
    deadlineNanos: number,
    maxEvents: number,
  ): void {
    const finalEventCount = this.eventCount + maxEvents;
    while (!predicate?.()) {
      if (this.clock.nanos >= deadlineNanos) {
        if (!predicate) return;
        throw new Error(`Emulator timeout at ${(this.clock.nanos / 1_000_000).toFixed(3)} ms`);
      }
      if (this.eventCount >= finalEventCount) {
        throw new Error(
          `Emulator event budget exceeded (${maxEvents} events for this run) at `
          + `${(this.clock.nanos / 1_000_000).toFixed(3)} ms`,
        );
      }
      this.refreshReadyEvents();
      if (this.fastForwardMutualTimerPoll(deadlineNanos)) {
        this.eventCount++;
        continue;
      }
      let nextNanos = Math.min(deadlineNanos, this.clock.nextAlarmNanos);
      for (const cpuNanos of this.cpuNextNanos) {
        if (cpuNanos < nextNanos) nextNanos = cpuNanos;
      }
      for (const event of this.pioEvents) {
        if (event.nextNanos < nextNanos) nextNanos = event.nextNanos;
      }
      if (!Number.isFinite(nextNanos)) throw new Error('Both RP2040s deadlocked with no pending alarm');
      this.clock.advanceTo(nextNanos);
      this.executeDueCPUs();
      this.executeDuePIO();
      this.eventCount++;
      if (process.env.EMULATOR_PROGRESS && this.eventCount % 100_000 === 0) {
        process.stderr.write(
          `emulator progress: ${this.eventCount} events, `
          + `${(this.clock.nanos / 1_000_000).toFixed(3)} ms\n`,
        );
      }
    }
  }

  /**
   * ChibiOS deliberately busy-polls the RP2040 microsecond counter during the
   * one-second double-tap bootloader window. When both halves are in that
   * side-effect-free four-instruction loop, jump to the first loop exit. This
   * is equivalent to executing the omitted reads and keeps scheduled alarms
   * ahead of the exit in timestamp order.
   */
  private fastForwardMutualTimerPoll(deadlineNanos: number): boolean {
    if (this.startupPollSkipped) return false;
    if (this.startupPollExitNanos !== undefined) {
      let targetNanos = Math.min(
        deadlineNanos,
        this.clock.nextAlarmNanos,
        this.startupPollExitNanos,
      );
      for (const event of this.pioEvents) {
        if (event.nextNanos < targetNanos) targetNanos = event.nextNanos;
      }
      if (targetNanos <= this.clock.nanos) return false;
      this.clock.advanceTo(targetNanos);
      for (let index = 0; index < this.cpuNextNanos.length; index++) {
        this.cpuNextNanos[index] = targetNanos;
      }
      if (targetNanos >= this.startupPollExitNanos) this.startupPollSkipped = true;
      return true;
    }
    // Flash-pattern reads are relatively expensive; a busy loop lasts for
    // thousands of scheduler events, so sparse probing still catches it.
    if ((this.eventCount & 0x3f) !== 0) return false;
    let targetNanos = Math.min(deadlineNanos, this.clock.nextAlarmNanos);
    for (const event of this.pioEvents) {
      if (event.nextNanos < targetNanos) targetNanos = event.nextNanos;
    }
    let pollExitNanos = Number.POSITIVE_INFINITY;
    for (const machine of this.machines) {
      const core = machine.rp2040.core;
      let loopStart: number | undefined;
      for (let candidate = core.PC - 6; candidate <= core.PC; candidate += 2) {
        if (
          machine.rp2040.readUint16(candidate) === 0x6a93
          && machine.rp2040.readUint16(candidate + 2) === 0x1a5b
          && machine.rp2040.readUint16(candidate + 4) === 0x4298
          && machine.rp2040.readUint16(candidate + 6) === 0xd8fb
        ) {
          loopStart = candidate;
          break;
        }
      }
      if (loopStart === undefined) return false;

      const durationMicros = core.registers[0]! >>> 0;
      const startMicros = core.registers[1]! >>> 0;
      const nowMicros = Math.floor(this.clock.micros) >>> 0;
      const elapsedMicros = (nowMicros - startMicros) >>> 0;
      if (elapsedMicros >= durationMicros) return false;
      pollExitNanos = Math.min(
        pollExitNanos,
        this.clock.nanos + (durationMicros - elapsedMicros) * 1_000,
      );
      targetNanos = Math.min(
        targetNanos,
        this.clock.nanos + (durationMicros - elapsedMicros) * 1_000,
      );
    }
    if (targetNanos <= this.clock.nanos || !Number.isFinite(targetNanos)) return false;
    if (pollExitNanos - this.clock.nanos > 100_000_000) {
      this.startupPollExitNanos = pollExitNanos;
    }
    this.clock.advanceTo(targetNanos);
    for (let index = 0; index < this.cpuNextNanos.length; index++) {
      this.cpuNextNanos[index] = targetNanos;
    }
    if (this.startupPollExitNanos !== undefined && targetNanos >= this.startupPollExitNanos) {
      this.startupPollSkipped = true;
    }
    return true;
  }

  private refreshReadyEvents(): void {
    for (const [index, owner] of this.machines.entries()) {
      if (owner.rp2040.core.waiting) {
        this.cpuNextNanos[index] = Number.POSITIVE_INFINITY;
      } else if (!Number.isFinite(this.cpuNextNanos[index]!)) {
        this.cpuNextNanos[index] = this.clock.nanos;
      }
    }
    for (const event of this.pioEvents) {
      if (!event.machine.enabled || event.machine.waiting) {
        event.nextNanos = Number.POSITIVE_INFINITY;
      } else if (!Number.isFinite(event.nextNanos)) {
        event.nextNanos = this.clock.nanos;
      }
    }
  }

  private executeDueCPUs(): void {
    const count = this.machines.length;
    for (let offset = 0; offset < count; offset++) {
      const index = (this.tieBreaker + offset) % count;
      if (this.cpuNextNanos[index]! > this.clock.nanos) continue;
      const core = this.machines[index]!.rp2040.core;
      if (core.waiting) {
        this.cpuNextNanos[index] = Number.POSITIVE_INFINITY;
        continue;
      }
      const cycles = Math.max(1, core.executeInstruction());
      this.cpuNextNanos[index] = this.clock.nanos + cycles * SYSTEM_CYCLE_NANOS;
    }
    this.tieBreaker = (this.tieBreaker + 1) % Math.max(1, count);
  }

  private executeDuePIO(): void {
    let leftTouched = false;
    let rightTouched = false;
    for (const event of this.pioEvents) {
      if (event.nextNanos > this.clock.nanos) continue;
      if (!event.machine.enabled || event.machine.waiting) {
        event.nextNanos = Number.POSITIVE_INFINITY;
        continue;
      }
      const before = event.machine.cycles;
      event.machine.step();
      const instructionCycles = Math.max(1, event.machine.cycles - before);
      const integerDivider = event.machine.clockDivInt === 0 ? 65_536 : event.machine.clockDivInt;
      const divider = integerDivider + event.machine.clockDivFrac / 256;
      event.nextNanos = event.machine.waiting
        ? Number.POSITIVE_INFINITY
        : this.clock.nanos + instructionCycles * divider * SYSTEM_CYCLE_NANOS;
      if (event.owner === this.machines[0]) leftTouched = true;
      else rightTouched = true;
    }
    if (leftTouched) for (const pio of this.machines[0]!.rp2040.pio) pio.checkChangedPins();
    if (rightTouched) for (const pio of this.machines[1]!.rp2040.pio) pio.checkChangedPins();
  }
}
