import { describe, expect, it } from 'vitest';
import { validateScenario } from '../src/scenario.js';

describe('scenario validation', () => {
  it('accepts a bounded version-one Kyria scenario', () => {
    expect(validateScenario({
      version: 1,
      board: 'kyria-rev4',
      name: 'tap',
      steps: [{ action: 'tap', key: 'Q', holdMs: 12 }],
    }).name).toBe('tap');
  });

  it('rejects unknown steps and unbounded waits', () => {
    expect(() => validateScenario({
      version: 1,
      board: 'kyria-rev4',
      name: 'unknown',
      steps: [{ action: 'teleport' }],
    })).toThrow('unknown action');
    expect(() => validateScenario({
      version: 1,
      board: 'kyria-rev4',
      name: 'too long',
      steps: [{ action: 'wait', milliseconds: 5_001 }],
    })).toThrow('milliseconds');
  });
});
