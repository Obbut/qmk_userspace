import { describe, expect, it } from 'vitest';
import { decodeWS2812Words } from '../src/kyria/rgb.js';

describe('WS2812 logical DMA decoding', () => {
  it('decodes the RP2040 vendor driver GRB words without timing assumptions', () => {
    expect(decodeWS2812Words([0x22001100, 0xff804000])).toEqual([
      { red: 0, green: 0x22, blue: 0x11 },
      { red: 0x80, green: 0xff, blue: 0x40 },
    ]);
  });
});
