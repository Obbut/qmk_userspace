import { GPIOPinState } from 'rp2040js';
import type { DeterministicClock, EmulatorAlarm } from '../clock.js';
import type { FirmwareMachine } from '../machine.js';

export interface RGBColor { red: number; green: number; blue: number }

const KYRIA_RGB_LED_COUNT = 62;
const DMA_WRITE_ADDRESS = 0x004;
const DMA_DEBUG_TRANSFER_COUNT = 0x804;
const DMA_READ_ADDRESS_OFFSETS = new Set([0x000, 0x014, 0x028, 0x03c]);

export function decodeWS2812Words(words: readonly number[]): RGBColor[] {
  return words.map((word) => ({
    red: (word >>> 16) & 0xff,
    green: (word >>> 24) & 0xff,
    blue: (word >>> 8) & 0xff,
  }));
}

export class WS2812Sink {
  private readonly bits: number[] = [];
  private readonly resetAlarm: EmulatorAlarm;
  private readonly pulseWidths = new Map<number, number>();
  private highSince: number | undefined;
  private lowSince = 0;
  colors: RGBColor[] = [];
  private wireColors: RGBColor[] = [];

  constructor(machine: FirmwareMachine, readonly clock: DeterministicClock) {
    this.resetAlarm = clock.createAlarm(() => this.finishFrame());
    machine.rp2040.gpio[3]!.addListener((state) => this.transition(state));
    for (const channel of machine.rp2040.dma.channels) {
      let configuredSource = 0;
      const originalWrite = channel.writeUint32.bind(channel);
      channel.writeUint32 = (offset, value) => {
        if (DMA_READ_ADDRESS_OFFSETS.has(offset)) configuredSource = value;
        originalWrite(offset, value);
      };
      const originalStart = channel.start.bind(channel);
      channel.start = () => {
        const count = channel.readUint32(DMA_DEBUG_TRANSFER_COUNT);
        const destination = channel.readUint32(DMA_WRITE_ADDRESS);
        if (!channel.active && count === KYRIA_RGB_LED_COUNT && this.isPIOTxFIFO(destination)) {
          const words = Array.from(
            { length: count },
            (_, index) => machine.rp2040.readUint32(configuredSource + index * 4),
          );
          this.colors = decodeWS2812Words(words);
        }
        originalStart();
      };
    }
  }

  state(): string {
    const widths = [...this.pulseWidths.entries()]
      .sort(([left], [right]) => left - right)
      .map(([width, count]) => `${width}ns:${count}`)
      .join(',');
    return `logicalColors=${this.colors.length}; wireColors=${this.wireColors.length}; `
      + `pendingBits=${this.bits.length}; highPulses=${widths || 'none'}`;
  }

  private transition(state: GPIOPinState): void {
    if (state === GPIOPinState.High) {
      this.resetAlarm.cancel();
      if (this.clock.nanos - this.lowSince >= 50_000) this.finishFrame();
      this.highSince = this.clock.nanos;
    } else if (state === GPIOPinState.Low && this.highSince !== undefined) {
      const highNanos = this.clock.nanos - this.highSince;
      const roundedWidth = Math.round(highNanos);
      this.pulseWidths.set(roundedWidth, (this.pulseWidths.get(roundedWidth) ?? 0) + 1);
      this.bits.push(highNanos >= 550 ? 1 : 0);
      this.highSince = undefined;
      this.lowSince = this.clock.nanos;
      // QMK may transmit only one frame after a logical change. Finalize it
      // when the WS2812 reset-low interval completes instead of waiting for a
      // later frame's first edge.
      this.resetAlarm.schedule(50_000);
    }
  }

  private finishFrame(): void {
    if (this.bits.length < 24) {
      this.bits.length = 0;
      return;
    }
    const colors: RGBColor[] = [];
    for (let offset = 0; offset + 23 < this.bits.length; offset += 24) {
      const green = this.byte(offset);
      const red = this.byte(offset + 8);
      const blue = this.byte(offset + 16);
      colors.push({ red, green, blue });
    }
    this.wireColors = colors;
    this.bits.length = 0;
  }

  private isPIOTxFIFO(address: number): boolean {
    const peripheralOffset = address & 0xffff;
    const peripheralBase = address & 0xffff_0000;
    return (peripheralBase === 0x5020_0000 || peripheralBase === 0x5030_0000)
      && peripheralOffset >= 0x10 && peripheralOffset <= 0x1c;
  }

  private byte(offset: number): number {
    let result = 0;
    for (let bit = 0; bit < 8; bit++) result = (result << 1) | this.bits[offset + bit]!;
    return result;
  }
}
