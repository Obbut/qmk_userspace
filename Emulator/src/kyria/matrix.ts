import type { FirmwareMachine } from '../machine.js';

const ROW_PINS = [8, 11, 7, 6] as const;
const LEFT_COLUMN_PINS = [19, 20, 25, 4, 9, 10, 5] as const;
const RIGHT_COLUMN_PINS = [5, 10, 9, 4, 25, 20, 19] as const;

export class MatrixAdapter {
  private readonly pressed = new Set<string>();
  private readonly columns: readonly number[];

  constructor(readonly machine: FirmwareMachine) {
    this.columns = machine.half === 'left' ? LEFT_COLUMN_PINS : RIGHT_COLUMN_PINS;
    for (const [column, pinNumber] of this.columns.entries()) {
      const pin = machine.rp2040.gpio[pinNumber]!;
      pin.setInputValue(true);

      // A keyboard switch is a live electrical connection between a driven row
      // and a column. Sampling only on GPIO listener callbacks can miss the
      // direction/value ordering used by ChibiOS while it scans rows, making a
      // held key appear to release. Resolve the column level at the instant the
      // firmware reads GPIO_IN instead.
      Object.defineProperty(pin, 'inputValue', {
        configurable: true,
        get: () => this.columnInputValue(column, pin.inputEnable, pin.inputOverride),
      });
    }
  }

  press(row: number, column: number): void {
    this.validate(row, column);
    this.pressed.add(`${row}:${column}`);
  }

  release(row: number, column: number): void {
    this.pressed.delete(`${row}:${column}`);
  }

  releaseAll(): void {
    this.pressed.clear();
  }

  private columnInputValue(column: number, inputEnable: boolean, inputOverride: number): boolean {
    const connectedToLowRow = ROW_PINS.some((rowPin, row) => {
      const gpio = this.machine.rp2040.gpio[rowPin]!;
      return gpio.outputEnable
        && !gpio.outputValue
        && this.pressed.has(`${row}:${column}`);
    });
    const input = !connectedToLowRow && inputEnable;
    switch (inputOverride) {
      case 0: return input;
      case 1: return !input;
      case 2: return false;
      case 3: return true;
      default: return input;
    }
  }

  private validate(row: number, column: number): void {
    if (!Number.isInteger(row) || row < 0 || row >= ROW_PINS.length) {
      throw new Error(`Invalid ${this.machine.half} matrix row ${row}`);
    }
    if (!Number.isInteger(column) || column < 0 || column >= this.columns.length) {
      throw new Error(`Invalid ${this.machine.half} matrix column ${column}`);
    }
  }
}
