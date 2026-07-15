import type { FirmwareMachine } from '../machine.js';
import type { BoardKind } from '../scenario.js';

const KYRIA_ROW_PINS = [8, 11, 7, 6] as const;
const KYRIA_LEFT_COLUMN_PINS = [19, 20, 25, 4, 9, 10, 5] as const;
const KYRIA_RIGHT_COLUMN_PINS = [5, 10, 9, 4, 25, 20, 19] as const;
const ELORA_ROW_PINS = [8, 11, 7, 6, 5] as const;
const ELORA_LEFT_COLUMN_PINS = [24, 19, 20, 25, 4, 9, 10] as const;
const ELORA_RIGHT_COLUMN_PINS = [10, 9, 4, 25, 20, 19, 24] as const;

export class MatrixAdapter {
  private readonly pressed = new Set<string>();
  private readonly rows: readonly number[];
  private readonly columns: readonly number[];

  constructor(readonly machine: FirmwareMachine, board: BoardKind = 'kyria-rev4') {
    this.rows = board === 'elora-rev2' ? ELORA_ROW_PINS : KYRIA_ROW_PINS;
    this.columns = board === 'elora-rev2'
      ? (machine.half === 'left' ? ELORA_LEFT_COLUMN_PINS : ELORA_RIGHT_COLUMN_PINS)
      : (machine.half === 'left' ? KYRIA_LEFT_COLUMN_PINS : KYRIA_RIGHT_COLUMN_PINS);
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

  get isReady(): boolean {
    return this.rows.every((pin) => this.machine.rp2040.gpio[pin]!.functionSelect === 5);
  }

  private columnInputValue(column: number, inputEnable: boolean, inputOverride: number): boolean {
    const connectedToLowRow = this.rows.some((rowPin, row) => {
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
    if (!Number.isInteger(row) || row < 0 || row >= this.rows.length) {
      throw new Error(`Invalid ${this.machine.half} matrix row ${row}`);
    }
    if (!Number.isInteger(column) || column < 0 || column >= this.columns.length) {
      throw new Error(`Invalid ${this.machine.half} matrix column ${column}`);
    }
  }
}
