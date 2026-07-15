import { readFileSync } from 'node:fs';
import type { Half } from '../machine.js';

interface LayoutEntry {
  label: string;
  matrix: [number, number];
}

interface LayoutFile {
  layouts: Record<string, { layout: LayoutEntry[] }>;
}

export interface MatrixLocation {
  readonly half: Half;
  readonly row: number;
  readonly column: number;
  readonly label: string;
}

const aliases: Record<string, string> = {
  tab: 'L06', q: 'L05', w: 'L04', f: 'L03', p: 'L02', b: 'L01',
  esc: 'L12', a: 'L11', r: 'L10', s: 'L09', t: 'L08', g: 'L07',
  shift: 'L20', z: 'L19', x: 'L18', c: 'L17', d: 'L16', v: 'L15',
  j: 'R01', l: 'R02', u: 'R03', y: 'R04', semicolon: 'R05', backspace: 'R06',
  m: 'R07', n: 'R08', e: 'R09', i: 'R10', o: 'R11', quote: 'R12',
  k: 'R15', h: 'R16', comma: 'R17', dot: 'R18', slash: 'R19', enter: 'R20',
};

export class KyriaLayout {
  private readonly locations = new Map<string, MatrixLocation>();

  constructor(path: string) {
    const contents = JSON.parse(readFileSync(path, 'utf8')) as LayoutFile;
    const layout = contents.layouts.LAYOUT_split_3x6_5_hlc?.layout;
    if (!layout) throw new Error(`${path} does not define LAYOUT_split_3x6_5_hlc`);
    for (const entry of layout) {
      const half: Half = entry.label.startsWith('L') ? 'left' : 'right';
      const localRow = half === 'left' ? entry.matrix[0] : entry.matrix[0] - 5;
      this.locations.set(entry.label.toUpperCase(), {
        half,
        row: localRow,
        column: entry.matrix[1],
        label: entry.label,
      });
    }
  }

  resolve(identifier: string): MatrixLocation {
    const label = aliases[identifier.toLowerCase()] ?? identifier;
    const location = this.locations.get(label.toUpperCase());
    if (!location) throw new Error(`Unknown Kyria key identifier: ${identifier}`);
    if (location.row >= 4) {
      throw new Error(`${identifier} is a module position, not a GPIO matrix key`);
    }
    return location;
  }
}
