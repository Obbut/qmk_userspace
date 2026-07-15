import { describe, expect, it } from 'vitest';
import { DeterministicClock } from '../src/clock.js';

describe('DeterministicClock', () => {
  it('runs equal-time alarms in creation order', () => {
    const clock = new DeterministicClock();
    const events: number[] = [];
    const first = clock.createAlarm(() => events.push(1));
    const second = clock.createAlarm(() => events.push(2));
    first.schedule(100);
    second.schedule(100);
    clock.advanceTo(100);
    expect(events).toEqual([1, 2]);
  });

  it('cancels and reschedules alarms', () => {
    const clock = new DeterministicClock();
    let fired = false;
    const alarm = clock.createAlarm(() => { fired = true; });
    alarm.schedule(10);
    alarm.cancel();
    clock.advanceTo(20);
    expect(fired).toBe(false);
  });

  it('advances zero-duration peripheral alarms by one nanosecond', () => {
    const clock = new DeterministicClock();
    let calls = 0;
    const alarm = clock.createAlarm(() => {
      calls += 1;
      if (calls < 3) {
        alarm.schedule(0);
      }
    });

    alarm.schedule(0);
    clock.advanceTo(3);

    expect(calls).toBe(3);
    expect(clock.nanos).toBe(3);
  });
});
