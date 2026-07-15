import { describe, expect, it } from 'vitest';
import { RP2040 } from 'rp2040js';
import { DeterministicClock } from '../src/clock.js';
import { applyQMKCompatibility } from '../src/compatibility.js';
import { MatrixAdapter } from '../src/kyria/matrix.js';
import type { FirmwareMachine } from '../src/machine.js';

describe('Kyria matrix', () => {
  it('keeps a pressed switch connected as the scanner changes rows', () => {
    const rp2040 = new RP2040(new DeterministicClock());
    applyQMKCompatibility(rp2040);
    const matrix = new MatrixAdapter({ half: 'left', rp2040 } as FirmwareMachine);

    const row0 = rp2040.gpio[8]!;
    const row1 = rp2040.gpio[11]!;
    row0.ctrl = 5;
    row1.ctrl = 5;
    rp2040.sio.gpioOutputEnable |= (1 << 8) | (1 << 11);
    matrix.press(0, 0);

    rp2040.sio.gpioValue &= ~(1 << 8);
    rp2040.sio.gpioValue |= 1 << 11;
    expect(rp2040.gpio[19]!.inputValue).toBe(false);

    rp2040.sio.gpioValue |= 1 << 8;
    rp2040.sio.gpioValue &= ~(1 << 11);
    expect(rp2040.gpio[19]!.inputValue).toBe(true);

    matrix.release(0, 0);
    rp2040.sio.gpioValue &= ~(1 << 8);
    expect(rp2040.gpio[19]!.inputValue).toBe(true);
  });
});
