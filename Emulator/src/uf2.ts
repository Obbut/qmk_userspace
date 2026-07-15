import { readFileSync } from 'node:fs';
import { decodeBlock } from 'uf2';
import type { RP2040 } from 'rp2040js';

const UF2_BLOCK_SIZE = 512;
const FLASH_START_ADDRESS = 0x1000_0000;

export function loadUF2(path: string, rp2040: RP2040): void {
  const data = readFileSync(path);
  if (data.length === 0 || data.length % UF2_BLOCK_SIZE !== 0) {
    throw new Error(`${path} is not a valid UF2 block stream`);
  }
  // A newly flashed physical RP2040 starts with erased (0xff) bytes outside
  // the UF2 payload, including QMK's wear-levelled EEPROM region. rp2040js
  // allocates its flash array as zeroes, so establish the hardware reset state
  // before applying the exact UF2 blocks.
  rp2040.flash.fill(0xff);
  for (let offset = 0; offset < data.length; offset += UF2_BLOCK_SIZE) {
    const block = decodeBlock(data.subarray(offset, offset + UF2_BLOCK_SIZE));
    const flashOffset = block.flashAddress - FLASH_START_ADDRESS;
    if (flashOffset < 0 || flashOffset + block.payload.length > rp2040.flash.length) {
      throw new Error(`UF2 block at 0x${block.flashAddress.toString(16)} is outside RP2040 flash`);
    }
    rp2040.flash.set(block.payload, flashOffset);
  }
}

export function readBootROM(path: string): Uint32Array {
  const data = readFileSync(path);
  if (data.length !== 16_384) {
    throw new Error(`RP2040 B2 boot ROM must be exactly 16384 bytes; got ${data.length}`);
  }
  const words = new Uint32Array(data.length / 4);
  for (let index = 0; index < words.length; index++) {
    words[index] = data.readUInt32LE(index * 4);
  }
  return words;
}
