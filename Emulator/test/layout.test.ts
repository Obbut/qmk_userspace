import { describe, expect, it } from 'vitest';
import { resolve } from 'node:path';
import { KyriaLayout } from '../src/kyria/layout.js';

describe('Kyria layout', () => {
  const layout = new KyriaLayout(resolve(import.meta.dirname, 'fixtures/kyria-layout.json'));

  it('maps logical left keys to their local matrix', () => {
    expect(layout.resolve('Q')).toMatchObject({ half: 'left', row: 0, column: 5 });
  });

  it('maps logical right keys to the right local matrix', () => {
    expect(layout.resolve('J')).toMatchObject({ half: 'right', row: 0, column: 1 });
  });

  it('does not treat synthetic module positions as GPIO matrix keys', () => {
    expect(() => layout.resolve('RM1')).toThrow(/module position/);
  });
});
