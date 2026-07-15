import type { DeterministicScheduler } from '../scheduler.js';
import type { FirmwareMachine } from '../machine.js';

const ENCODER_A = 27;
const ENCODER_B = 26;
const ENCODER_BUTTON = 16;

export class EncoderAdapter {
  constructor(readonly machine: FirmwareMachine) {
    machine.rp2040.gpio[ENCODER_A]!.setInputValue(true);
    machine.rp2040.gpio[ENCODER_B]!.setInputValue(true);
    machine.rp2040.gpio[ENCODER_BUTTON]!.setInputValue(true);
  }

  rotate(direction: 'clockwise' | 'counterclockwise', detents: number, scheduler: DeterministicScheduler): void {
    const clockwise = [[true, false], [false, false], [false, true], [true, true]] as const;
    const states = direction === 'clockwise' ? clockwise : [...clockwise].reverse();
    for (let detent = 0; detent < detents; detent++) {
      for (const [a, b] of states) {
        this.machine.rp2040.gpio[ENCODER_A]!.setInputValue(a);
        this.machine.rp2040.gpio[ENCODER_B]!.setInputValue(b);
        // The real mechanical encoder stays in each quadrature state far
        // longer than a matrix scan. Thirty virtual milliseconds makes that
        // boundary explicit without depending on host execution speed.
        scheduler.runFor(30);
      }
    }
  }

  setButton(pressed: boolean): void {
    this.machine.rp2040.gpio[ENCODER_BUTTON]!.setInputValue(!pressed);
  }
}
