import { describe, expect, it } from 'vitest';
import { RP2040 } from 'rp2040js';
import { DeterministicClock } from '../src/clock.js';
import { applyQMKCompatibility } from '../src/compatibility.js';

describe('QMK RP2040 compatibility adapter', () => {
  it('enables GPIO input buffers at reset', () => {
    const rp2040 = new RP2040(new DeterministicClock());
    applyQMKCompatibility(rp2040);
    expect(rp2040.gpio.every((pin) => pin.inputEnable)).toBe(true);
  });

  it('reports completed DMA abort and accepts SIO FIFO status clears', () => {
    const rp2040 = new RP2040(new DeterministicClock());
    const stats = applyQMKCompatibility(rp2040);
    expect(rp2040.dma.readUint32(0x444)).toBe(0);
    rp2040.sio.writeUint32(0x50, 0x0c);
    expect(stats.dmaStatusReads).toBe(1);
    expect(stats.sioFIFOStatusClears).toBe(1);
  });

  it('disables rp2040js wall-clock PIO execution', () => {
    const rp2040 = new RP2040(new DeterministicClock());
    applyQMKCompatibility(rp2040);
    rp2040.pio[0]!.run();
    expect(rp2040.pio[0]!.stopped).toBe(false);
    expect(rp2040.pio[0]!.machines.every((machine) => !machine.enabled)).toBe(true);
  });
});
