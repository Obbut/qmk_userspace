export interface EmulatorAlarm {
  schedule(deltaNanos: number): void;
  cancel(): void;
}

interface ScheduledAlarm {
  readonly id: number;
  readonly callback: () => void;
  nanos: number;
  scheduled: boolean;
  readonly source: string | undefined;
}

/** A deterministic replacement for rp2040js's wall-clock-oriented scheduler. */
export class DeterministicClock {
  private alarms: ScheduledAlarm[] = [];
  private nextID = 0;
  private now = 0;

  get nanos(): number {
    return this.now;
  }

  get micros(): number {
    return this.now / 1_000;
  }

  get nextAlarmNanos(): number {
    return this.alarms[0]?.nanos ?? Number.POSITIVE_INFINITY;
  }

  get nanosToNextAlarm(): number {
    return Number.isFinite(this.nextAlarmNanos) ? this.nextAlarmNanos - this.now : 0;
  }

  createAlarm(callback: () => void): EmulatorAlarm {
    const alarm: ScheduledAlarm = {
      id: this.nextID++,
      callback,
      nanos: 0,
      scheduled: false,
      source: process.env.EMULATOR_PROGRESS ? new Error().stack : undefined,
    };
    return {
      schedule: (deltaNanos) => this.schedule(alarm, deltaNanos),
      cancel: () => this.cancel(alarm),
    };
  }

  advanceTo(targetNanos: number): void {
    if (targetNanos < this.now) {
      throw new Error(`Clock cannot move backwards (${targetNanos} < ${this.now})`);
    }
    let callbackCount = 0;
    while (this.alarms[0] && this.alarms[0].nanos <= targetNanos) {
      if (++callbackCount > 100_000) {
        throw new Error(
          `Alarm callback budget exceeded while advancing to ${targetNanos}; `
          + `next alarm ${this.alarms[0].id} at ${this.alarms[0].nanos}; `
          + `${this.alarms[0].source ?? 'source unavailable'}`,
        );
      }
      const alarm = this.alarms.shift()!;
      alarm.scheduled = false;
      this.now = alarm.nanos;
      alarm.callback();
    }
    this.now = targetNanos;
  }

  tick(deltaNanos: number): void {
    this.advanceTo(this.now + Math.max(0, deltaNanos));
  }

  private schedule(alarm: ScheduledAlarm, deltaNanos: number): void {
    this.cancel(alarm);
    // rp2040js's fractional PWM math can round a sub-cycle periodic alarm to
    // zero. A positive minimum keeps time monotonic and matches the fact that
    // no RP2040 peripheral can complete twice at the same instant.
    alarm.nanos = this.now + Math.max(1, deltaNanos);
    alarm.scheduled = true;
    this.alarms.push(alarm);
    this.alarms.sort((left, right) => left.nanos - right.nanos || left.id - right.id);
  }

  private cancel(alarm: ScheduledAlarm): void {
    if (!alarm.scheduled) return;
    const index = this.alarms.indexOf(alarm);
    if (index >= 0) this.alarms.splice(index, 1);
    alarm.scheduled = false;
  }
}
