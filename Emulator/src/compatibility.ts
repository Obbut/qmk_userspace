import type { RP2040 } from 'rp2040js';

const GPIO_PAD_RESET_WITH_INPUT_ENABLE = 0x56;
const DMA_FIFO_LEVELS = 0x440;
const DMA_CHAN_ABORT = 0x444;
const SIO_FIFO_ST = 0x50;

export interface CompatibilityStats {
  dmaStatusReads: number;
  sioFIFOStatusClears: number;
}

/**
 * Narrow RP2040 conformance shims required by current QMK/ChibiOS.
 * No firmware bytes are changed and no rp2040js source is vendored.
 */
export function applyQMKCompatibility(rp2040: RP2040): CompatibilityStats {
  const stats: CompatibilityStats = { dmaStatusReads: 0, sioFIFOStatusClears: 0 };

  for (const pin of rp2040.gpio) pin.padValue = GPIO_PAD_RESET_WITH_INPUT_ENABLE;

  const dma = rp2040.dma;
  const originalDMARead = dma.readUint32.bind(dma);
  dma.readUint32 = (offset: number): number => {
    if (offset === DMA_FIFO_LEVELS || offset === DMA_CHAN_ABORT) {
      stats.dmaStatusReads++;
      return 0;
    }
    return originalDMARead(offset);
  };

  const sio = rp2040.sio;
  const originalSIOWrite = sio.writeUint32.bind(sio);
  sio.writeUint32 = (offset: number, value: number): void => {
    if (offset === SIO_FIFO_ST) {
      stats.sioFIFOStatusClears++;
      return;
    }
    originalSIOWrite(offset, value);
  };

  // rp2040js normally advances PIO with setTimeout(). The shared scheduler
  // below owns PIO stepping so two halves see edges on one virtual timeline.
  for (const pio of rp2040.pio) {
    pio.run = () => {
      pio.stopped = false;
    };
  }

  return stats;
}
