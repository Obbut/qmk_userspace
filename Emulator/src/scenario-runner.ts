import type { KyriaBoard } from './kyria/board.js';
import type { RGBColor } from './kyria/rgb.js';
import type { USBReport } from './kyria/usb-host.js';
import type { Scenario, ScenarioStep } from './scenario.js';

const MINIMUM_STEP_EVENT_BUDGET = 50_000_000;
const EVENTS_PER_MILLISECOND_BUDGET = 125_000;

export interface ScenarioResult {
  readonly name: string;
  readonly simulatedMilliseconds: number;
  readonly emulatorEvents: number;
  readonly reports: { timestampMilliseconds: number; endpoint: number; hex: string }[];
}

export class ScenarioRunner {
  private reportCursor = 0;

  constructor(readonly board: KyriaBoard) {}

  run(scenario: Scenario): ScenarioResult {
    if (scenario.board !== this.board.paths.board) {
      throw new Error(`Scenario targets ${scenario.board}, but the emulated board is ${this.board.paths.board}`);
    }
    this.board.boot(scenario.host ?? 'default', scenario.bootTimeoutMs ?? 2_000);
    this.reportCursor = this.board.usb.reports.length;
    for (const [index, step] of scenario.steps.entries()) {
      try {
        this.execute(step);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        throw new Error(`Scenario step ${index + 1} ${JSON.stringify(step)}: ${message}`);
      }
    }
    const diagnostics = this.board.diagnostics();
    if (diagnostics.length) {
      throw new Error(`Unexpected emulator diagnostics:\n${diagnostics.join('\n')}`);
    }
    return {
      name: scenario.name,
      simulatedMilliseconds: this.board.clock.nanos / 1_000_000,
      emulatorEvents: this.board.scheduler.eventCount,
      reports: this.board.usb.reports.map((report) => ({
        timestampMilliseconds: report.timestampNanos / 1_000_000,
        endpoint: report.endpoint,
        hex: Buffer.from(report.data).toString('hex'),
      })),
    };
  }

  private execute(step: ScenarioStep): void {
    if ('action' in step) {
      switch (step.action) {
        case 'press':
        case 'release':
          this.board.setKey(step.key, step.action === 'press');
          this.board.scheduler.runFor(step.settleMs ?? 12);
          return;
        case 'tap':
          this.board.setKey(step.key, true);
          this.board.scheduler.runFor(step.holdMs ?? 12);
          this.board.setKey(step.key, false);
          this.board.scheduler.runFor(step.settleMs ?? 12);
          return;
        case 'wait':
          this.board.scheduler.runFor(step.milliseconds, this.eventBudget(step.milliseconds));
          return;
        case 'rotate':
          this.board.encoder.rotate(step.direction, step.detents ?? 1, this.board.scheduler);
          return;
        case 'encoder-button':
          this.board.encoder.setButton(step.pressed);
          this.board.scheduler.runFor(step.settleMs ?? 12);
          return;
        case 'pointer':
          this.board.cirque.injectAbsolute(step.x, step.y, step.pressure, step.buttons);
          this.board.scheduler.runFor(step.settleMs ?? 20);
          return;
        case 'raw-hid':
          this.board.usb.queueRawHID(this.hex(step.hex));
          this.board.scheduler.runFor(step.settleMs ?? 20);
          return;
      }
    }

    switch (step.assert) {
      case 'keyboard': {
        const usages = [...step.usages].sort((a, b) => a - b);
        this.expectReport((report) => {
          if (report.data.length !== 8) return false;
          const actual = [...report.data.subarray(2)].filter(Boolean).sort((a, b) => a - b);
          return report.data[0] === (step.modifiers ?? 0)
            && actual.length === usages.length
            && actual.every((usage, index) => usage === usages[index]);
        }, step.timeoutMs ?? 100, `keyboard usages [${usages.join(', ')}]`);
        return;
      }
      case 'mouse': {
        this.expectReport((report) => {
          if (report.data.length !== 6 || report.data[0] !== 2) return false;
          return (step.buttons === undefined || report.data[1] === step.buttons)
            && (step.x === undefined || this.int8(report.data[2]!) === step.x)
            && (step.y === undefined || this.int8(report.data[3]!) === step.y)
            // QMK's report_mouse_t wire order after the report ID is buttons,
            // x, y, vertical, horizontal.
            && (step.horizontal === undefined || this.int8(report.data[5]!) === step.horizontal)
            && (step.vertical === undefined || this.int8(report.data[4]!) === step.vertical);
        }, step.timeoutMs ?? 100, 'mouse report');
        return;
      }
      case 'consumer': {
        this.expectReport(
          (report) => report.data.length === 3
            && report.data[0] === 4
            && (report.data[1]! | (report.data[2]! << 8)) === step.usage,
          step.timeoutMs ?? 100,
          `consumer usage ${step.usage}`,
        );
        return;
      }
      case 'raw-hid': {
        this.expectReport(
          (report) => this.isProtocolReport(report, step.messageType)
            && (step.layoutID === undefined || this.uint32(report.data, 6) === step.layoutID),
          step.timeoutMs ?? 100,
          `protocol-v5 message ${step.messageType}`,
        );
        return;
      }
      case 'layer': {
        const activeMask = this.layerMask(step.active);
        const defaultMask = step.defaults === undefined ? undefined : this.layerMask(step.defaults);
        this.expectReport(
          (report) => this.isProtocolReport(report, 2)
            && this.uint32(report.data, 10) === activeMask
            && (defaultMask === undefined || this.uint32(report.data, 14) === defaultMask),
          step.timeoutMs ?? 150,
          `layers active [${step.active.join(', ')}]`,
        );
        return;
      }
      case 'report': {
        const expected = this.hex(step.hex);
        this.expectReport(
          (report) => report.endpoint === step.endpoint && Buffer.from(report.data).equals(expected),
          step.timeoutMs ?? 100,
          `endpoint ${step.endpoint} report ${step.hex}`,
        );
        return;
      }
      case 'no-report': {
        const before = this.board.usb.reports.length;
        this.board.scheduler.runFor(step.durationMs, this.eventBudget(step.durationMs));
        if (this.board.usb.reports.length !== before) {
          throw new Error(`Expected no USB report for ${step.durationMs} ms`);
        }
        return;
      }
      case 'rgb': {
        const colors = step.half === 'left' ? this.board.leftRGB.colors : this.board.rightRGB.colors;
        const actual = colors[step.index];
        if (!actual || !this.matchesColor(actual, step, step.tolerance ?? 0)) {
          const nonzero = colors.flatMap((color, index) =>
            color.red || color.green || color.blue ? [`${index}:${color.red},${color.green},${color.blue}`] : [],
          );
          throw new Error(
            `Expected ${step.half} RGB ${step.index} to be (${step.red},${step.green},${step.blue}); `
            + `got ${JSON.stringify(actual)}; nonzero LEDs: ${nonzero.join(' ') || 'none'}; `
            + `${step.half === 'left' ? this.board.leftRGB.state() : this.board.rightRGB.state()}`,
          );
        }
        return;
      }
      case 'diagnostics-clean': {
        const diagnostics = this.board.diagnostics();
        if (diagnostics.length) throw new Error(`Unexpected emulator diagnostics:\n${diagnostics.join('\n')}`);
        return;
      }
    }
  }

  private expectReport(predicate: (report: USBReport) => boolean, timeoutMs: number, description: string): void {
    let match = this.findReport(predicate);
    if (!match) {
      try {
        this.board.scheduler.runUntil(
          () => Boolean((match = this.findReport(predicate))),
          this.board.clock.nanos + timeoutMs * 1_000_000,
          this.eventBudget(timeoutMs),
        );
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        const observed = this.board.usb.reports.slice(this.reportCursor).map((report) =>
          `ep${report.endpoint}:${Buffer.from(report.data).toString('hex')}`,
        );
        throw new Error(`${message}; observed ${observed.join(', ') || 'no reports'}`);
      }
    }
    if (!match) throw new Error(`Expected ${description}`);
    this.reportCursor = match.index + 1;
  }

  private findReport(predicate: (report: USBReport) => boolean): { index: number; report: USBReport } | undefined {
    for (let index = this.reportCursor; index < this.board.usb.reports.length; index++) {
      const report = this.board.usb.reports[index]!;
      if (predicate(report)) return { index, report };
    }
    return undefined;
  }

  private matchesColor(actual: RGBColor, expected: { red: number; green: number; blue: number }, tolerance: number): boolean {
    return Math.abs(actual.red - expected.red) <= tolerance
      && Math.abs(actual.green - expected.green) <= tolerance
      && Math.abs(actual.blue - expected.blue) <= tolerance;
  }

  private eventBudget(milliseconds: number): number {
    return Math.max(
      MINIMUM_STEP_EVENT_BUDGET,
      Math.ceil(milliseconds * EVENTS_PER_MILLISECOND_BUDGET),
    );
  }

  private hex(value: string): Uint8Array {
    if (!/^(?:[0-9a-fA-F]{2})*$/.test(value)) throw new Error(`Invalid hexadecimal byte string: ${value}`);
    return Uint8Array.from(Buffer.from(value, 'hex'));
  }

  private int8(value: number): number {
    return value > 0x7f ? value - 0x100 : value;
  }

  private isProtocolReport(report: USBReport, messageType: number): boolean {
    const data = report.data;
    return data.length === 32
      && data[0] === 0x4b && data[1] === 0x4d && data[2] === 0x41 && data[3] === 0x50
      && data[4] === 5 && data[5] === messageType;
  }

  private uint32(data: Uint8Array, offset: number): number {
    return (data[offset]!
      | (data[offset + 1]! << 8)
      | (data[offset + 2]! << 16)
      | (data[offset + 3]! << 24)) >>> 0;
  }

  private layerMask(layers: readonly number[]): number {
    let mask = 0;
    for (const layer of layers) {
      if (!Number.isInteger(layer) || layer < 0 || layer > 31) throw new Error(`Invalid layer ${layer}`);
      mask = (mask | (1 << layer)) >>> 0;
    }
    return mask;
  }
}
