import { DeterministicClock } from '../clock.js';
import { FirmwareMachine } from '../machine.js';
import { DeterministicScheduler } from '../scheduler.js';
import { CirqueAdapter } from './cirque.js';
import { EncoderAdapter } from './encoder.js';
import { KyriaLayout } from './layout.js';
import { MatrixAdapter } from './matrix.js';
import { WS2812Sink } from './rgb.js';
import { QMKUSBHost, type HostProfile } from './usb-host.js';
import { connectSplitTransport } from './wire.js';
import type { BoardKind } from '../scenario.js';

export interface KyriaPaths {
  readonly board: BoardKind;
  readonly leftUF2: string;
  readonly rightUF2: string;
  readonly bootROM: string;
  readonly layout: string;
}

export class KyriaBoard {
  readonly clock = new DeterministicClock();
  readonly left: FirmwareMachine;
  readonly right: FirmwareMachine;
  readonly scheduler: DeterministicScheduler;
  readonly layout: KyriaLayout;
  readonly leftMatrix: MatrixAdapter;
  readonly rightMatrix: MatrixAdapter;
  readonly encoder: EncoderAdapter;
  readonly cirque: CirqueAdapter;
  readonly leftRGB: WS2812Sink;
  readonly rightRGB: WS2812Sink;
  usb!: QMKUSBHost;

  constructor(readonly paths: KyriaPaths) {
    this.left = new FirmwareMachine('left', this.clock, paths.leftUF2, paths.bootROM, paths.board);
    this.right = new FirmwareMachine('right', this.clock, paths.rightUF2, paths.bootROM, paths.board);
    this.layout = new KyriaLayout(paths.layout);
    this.leftMatrix = new MatrixAdapter(this.left, paths.board);
    this.rightMatrix = new MatrixAdapter(this.right, paths.board);
    this.encoder = new EncoderAdapter(this.right);
    this.cirque = new CirqueAdapter(this.left);
    this.leftRGB = new WS2812Sink(this.left, this.clock);
    this.rightRGB = new WS2812Sink(this.right, this.clock);
    connectSplitTransport(this.left, this.right);
    this.scheduler = new DeterministicScheduler(this.clock, [this.left, this.right]);
  }

  boot(profile: HostProfile, timeoutMilliseconds = 2_000): void {
    this.usb = new QMKUSBHost(this.left, this.clock, profile);
    try {
      this.scheduler.runUntil(
        () => this.usb.configured,
        this.clock.nanos + timeoutMilliseconds * 1_000_000,
        3_000_000,
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      throw new Error(
        `${message}; USB ${this.usb.state()}; left PC=0x${this.left.rp2040.core.PC.toString(16)}; `
        + `left LR=0x${this.left.rp2040.core.LR.toString(16)}; `
        + `right PC=0x${this.right.rp2040.core.PC.toString(16)}; `
        + `right LR=0x${this.right.rp2040.core.LR.toString(16)}; `
        + `PIO ${this.pioState()}`,
      );
    }
    // USB can enumerate before the non-master half finishes its ChibiOS/QMK
    // startup. Do not let scenarios begin until both real matrix scanners have
    // configured their row GPIOs; otherwise the first remote chord can land in
    // the same scan and be evaluated before its held layer key.
    try {
      this.scheduler.runUntil(
        () => this.leftMatrix.isReady
          && this.rightMatrix.isReady
          && (this.paths.board !== 'kyria-rev4' || this.cirque.ready),
        this.clock.nanos + 500_000_000,
        3_000_000,
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      throw new Error(`${message}; ${this.paths.board} peripherals did not become ready`);
    }
    this.scheduler.runFor(profile === 'default' ? 20 : 300);
  }

  setKey(identifier: string, pressed: boolean): void {
    const location = this.layout.resolve(identifier);
    const matrix = location.half === 'left' ? this.leftMatrix : this.rightMatrix;
    if (pressed) matrix.press(location.row, location.column);
    else matrix.release(location.row, location.column);
  }

  diagnostics(): string[] {
    return [this.left, this.right].flatMap((machine) =>
      machine.diagnostics.map((diagnostic) =>
        `${machine.half}:${diagnostic.level}:${diagnostic.peripheral}:${diagnostic.message}`,
      ),
    );
  }

  private pioState(): string {
    return [this.left, this.right].flatMap((machine) =>
      machine.rp2040.pio.flatMap((pio, pioIndex) =>
        pio.machines
          .filter((stateMachine) => stateMachine.enabled)
          .map((stateMachine, stateMachineIndex) =>
            `${machine.half}.${pioIndex}.${stateMachineIndex}`
            + `(wait=${stateMachine.waiting},pc=${stateMachine.pc},cycles=${stateMachine.cycles})`,
          ),
      ),
    ).join(',');
  }
}
