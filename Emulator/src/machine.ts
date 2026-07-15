import { RP2040, type Logger } from 'rp2040js';
import { applyQMKCompatibility, type CompatibilityStats } from './compatibility.js';
import type { DeterministicClock } from './clock.js';
import type { BoardKind } from './scenario.js';
import { loadUF2, readBootROM } from './uf2.js';

const FLASH_START_ADDRESS = 0x1000_0000;

export type Half = 'left' | 'right';

export interface EmulatorDiagnostic {
  level: 'warning' | 'error';
  peripheral: string;
  message: string;
}

export class FirmwareMachine {
  readonly rp2040: RP2040;
  readonly diagnostics: EmulatorDiagnostic[] = [];
  readonly compatibility: CompatibilityStats;

  constructor(
    readonly half: Half,
    readonly clock: DeterministicClock,
    uf2Path: string,
    bootROMPath: string,
    board: BoardKind = 'kyria-rev4',
  ) {
    this.rp2040 = new RP2040(clock);
    this.rp2040.logger = this.logger();
    this.rp2040.loadBootrom(readBootROM(bootROMPath));
    loadUF2(uf2Path, this.rp2040);
    this.compatibility = applyQMKCompatibility(this.rp2040);

    for (const pin of this.rp2040.gpio) pin.setInputValue(true);
    this.rp2040.gpio[1]!.setInputValue(half === 'left');
    this.rp2040.gpio[board === 'elora-rev2' ? 23 : 24]!.setInputValue(half === 'left');

    // rp2040js does not yet model enough of the ROM's clock/XIP setup to run
    // it. Start at the production UF2's boot2 entry, as Wokwi/rp2040js demos
    // do; the ROM is still loaded for firmware calls into its public table.
    this.rp2040.core.PC = FLASH_START_ADDRESS;
  }

  private logger(): Logger {
    return {
      debug: () => undefined,
      info: () => undefined,
      warn: (peripheral, message) => {
        if (this.isExpectedModelGap(peripheral, message)) return;
        this.diagnostics.push({ level: 'warning', peripheral, message });
      },
      error: (peripheral, message) => {
        this.diagnostics.push({ level: 'error', peripheral, message });
      },
    };
  }

  private isExpectedModelGap(peripheral: string, message: string): boolean {
    if (
      [
        'PLL_SYS_BASE',
        'PLL_USB_BASE',
        'IO_QSPI_BASE',
        'SSI',
        'VREG_AND_CHIP_RESET_BASE',
        'ROSC_BASE',
      ].includes(peripheral)
      && message.startsWith('Unimplemented peripheral ')
    ) return true;
    if (peripheral === 'USB' && message.startsWith('Unimplemented peripheral ')) return true;
    if (peripheral === 'TIMER_BASE' && message.startsWith('Unimplemented peripheral write to ')) return true;
    if ((peripheral === 'PIO0' || peripheral === 'PIO1') && message === 'clkDivRestart not implemented') {
      return true;
    }
    if (peripheral === 'RP2040') {
      return [
        'Read from invalid memory address: ffffff8',
        'Read from invalid memory address: ffffffc',
        'Read from invalid memory address: 14000004',
        'Write to undefined address: 14000004',
        'Write to undefined address: 14002000',
      ].includes(message);
    }
    return false;
  }
}
