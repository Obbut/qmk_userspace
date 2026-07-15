import type { FirmwareMachine } from '../machine.js';

const CHIP_SELECT = 13;
const STATUS = 0x02;
const SYSTEM_CONFIG = 0x03;
const FEED_CONFIG = 0x04;
const CAL_CONFIG = 0x07;
const Z_IDLE = 0x0a;
const PACKET_START = 0x12;
const EXT_VALUE = 0x1b;
const EXT_ADDR_HIGH = 0x1c;
const EXT_ADDR_LOW = 0x1d;
const EXT_CONTROL = 0x1e;
const DATA_READY = 0x04;

export class CirqueAdapter {
  private readonly host = new Uint8Array(32);
  private readonly extended = new Uint8Array(0x200);
  private command: 'read' | 'write' | undefined;
  private address = 0;
  private readFillerCount = 0;

  constructor(readonly machine: FirmwareMachine) {
    this.resetRegisters();
    machine.rp2040.gpio[CHIP_SELECT]!.addListener((state) => {
      if (state !== 0) this.command = undefined;
    });
    // QMK's RP2040 ChibiOS port names hardware SPI1 as SPID1.
    machine.rp2040.spi[1]!.onTransmit = (value) => this.transmit(value);
  }

  injectAbsolute(x: number, y: number, pressure = 32, buttons = 0): void {
    if (x < 0 || x > 0xfff || y < 0 || y > 0xfff) {
      throw new Error('Cirque coordinates must fit in 12 bits');
    }
    this.host[PACKET_START] = buttons & 0x3f;
    this.host[PACKET_START + 1] = 0;
    this.host[PACKET_START + 2] = x & 0xff;
    this.host[PACKET_START + 3] = y & 0xff;
    this.host[PACKET_START + 4] = ((x >> 8) & 0x0f) | ((y >> 4) & 0xf0);
    this.host[PACKET_START + 5] = pressure & 0x3f;
    this.host[STATUS]! |= DATA_READY;
  }

  get ready(): boolean {
    return Boolean(this.host[FEED_CONFIG]! & 0x01);
  }

  private transmit(value: number): void {
    const selected = this.machine.rp2040.gpio[CHIP_SELECT]!.outputEnable
      && !this.machine.rp2040.gpio[CHIP_SELECT]!.outputValue;
    if (!selected) {
      this.command = undefined;
      this.machine.rp2040.spi[1]!.completeTransmit(0);
      return;
    }
    if (!this.command) {
      if ((value & 0xe0) === 0xa0) {
        this.command = 'read';
        this.address = value & 0x1f;
        this.readFillerCount = 0;
      } else if ((value & 0xe0) === 0x80) {
        this.command = 'write';
        this.address = value & 0x1f;
      }
      this.machine.rp2040.spi[1]!.completeTransmit(0);
      return;
    }
    if (this.command === 'write') {
      this.write(this.address, value & 0xff);
      this.command = undefined;
      this.machine.rp2040.spi[1]!.completeTransmit(0);
      return;
    }
    let response = 0;
    if (this.readFillerCount++ >= 2) {
      response = this.host[this.address++ & 0x1f]!;
    }
    this.machine.rp2040.spi[1]!.completeTransmit(response);
  }

  private write(address: number, value: number): void {
    if (address === SYSTEM_CONFIG && value & 1) {
      this.resetRegisters();
      return;
    }
    if (address === STATUS) {
      this.host[STATUS] = value;
      return;
    }
    if (address === CAL_CONFIG) value &= ~1;
    this.host[address] = value;
    if (address !== EXT_CONTROL) return;
    const extendedAddress = (this.host[EXT_ADDR_HIGH]! << 8) | this.host[EXT_ADDR_LOW]!;
    if (value & 0x01) {
      this.host[EXT_VALUE] = this.extended[extendedAddress] ?? 0;
      if (value & 0x04) this.setExtendedAddress(extendedAddress + 1);
    } else if (value & 0x02) {
      if (extendedAddress < this.extended.length) this.extended[extendedAddress] = this.host[EXT_VALUE]!;
    }
    this.host[EXT_CONTROL] = 0;
  }

  private setExtendedAddress(address: number): void {
    this.host[EXT_ADDR_HIGH] = (address >> 8) & 0xff;
    this.host[EXT_ADDR_LOW] = address & 0xff;
  }

  private resetRegisters(): void {
    this.host.fill(0);
    this.host[CAL_CONFIG] = 0x3e;
    this.host[Z_IDLE] = 30;
    this.extended[0x187] = 0x4e;
    this.extended[0x149] = 0x06;
    this.extended[0x168] = 0x05;
    this.command = undefined;
  }
}
