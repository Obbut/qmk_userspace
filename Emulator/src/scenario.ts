import { readFileSync } from 'node:fs';
import type { HostProfile } from './kyria/usb-host.js';

export type BoardKind = 'kyria-rev4' | 'elora-rev2';

export type ScenarioStep =
  | { action: 'press' | 'release'; key: string; settleMs?: number }
  | { action: 'tap'; key: string; holdMs?: number; settleMs?: number }
  | { action: 'wait'; milliseconds: number }
  | { action: 'rotate'; direction: 'clockwise' | 'counterclockwise'; detents?: number }
  | { action: 'encoder-button'; pressed: boolean; settleMs?: number }
  | { action: 'pointer'; x: number; y: number; pressure?: number; buttons?: number; settleMs?: number }
  | { action: 'raw-hid'; hex: string; settleMs?: number }
  | { assert: 'keyboard'; usages: number[]; modifiers?: number; timeoutMs?: number }
  | { assert: 'mouse'; buttons?: number; x?: number; y?: number; horizontal?: number; vertical?: number; timeoutMs?: number }
  | { assert: 'consumer'; usage: number; timeoutMs?: number }
  | { assert: 'raw-hid'; messageType: number; layoutID?: number; timeoutMs?: number }
  | { assert: 'layer'; active: number[]; defaults?: number[]; timeoutMs?: number }
  | { assert: 'report'; endpoint: number; hex: string; timeoutMs?: number }
  | { assert: 'no-report'; durationMs: number }
  | { assert: 'rgb'; half: 'left' | 'right'; index: number; red: number; green: number; blue: number; tolerance?: number }
  | { assert: 'diagnostics-clean' };

export interface Scenario {
  readonly version: 1;
  readonly board: BoardKind;
  readonly name: string;
  readonly host?: HostProfile;
  readonly bootTimeoutMs?: number;
  readonly steps: ScenarioStep[];
}

const actions = new Set(['press', 'release', 'tap', 'wait', 'rotate', 'encoder-button', 'pointer', 'raw-hid']);
const assertions = new Set(['keyboard', 'mouse', 'consumer', 'raw-hid', 'layer', 'report', 'no-report', 'rgb', 'diagnostics-clean']);
const timingFields = ['milliseconds', 'settleMs', 'holdMs', 'timeoutMs', 'durationMs'] as const;
const MAX_BOOT_TIMEOUT_MS = 5_000;
const MAX_SCENARIO_TIME_MS = 5_000;
const MAX_SCENARIO_STEPS = 256;

export function readScenario(path: string): Scenario {
  return validateScenario(JSON.parse(readFileSync(path, 'utf8')), path);
}

export function validateScenario(value: unknown, path = '<scenario>'): Scenario {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`${path}: scenario must be a JSON object`);
  }
  const scenario = value as Partial<Scenario>;
  if (scenario.version !== 1) throw new Error(`${path}: scenario version must be 1`);
  if (scenario.board !== 'kyria-rev4' && scenario.board !== 'elora-rev2') {
    throw new Error(`${path}: board must be kyria-rev4 or elora-rev2`);
  }
  if (!scenario.name || !Array.isArray(scenario.steps)) throw new Error(`${path}: name and steps are required`);
  if (scenario.host && !['default', 'macos', 'windows'].includes(scenario.host)) {
    throw new Error(`${path}: invalid host profile ${scenario.host}`);
  }
  if (scenario.bootTimeoutMs !== undefined) {
    if (!Number.isFinite(scenario.bootTimeoutMs) || scenario.bootTimeoutMs <= 0 || scenario.bootTimeoutMs > MAX_BOOT_TIMEOUT_MS) {
      throw new Error(`${path}: bootTimeoutMs must be greater than zero and at most ${MAX_BOOT_TIMEOUT_MS}`);
    }
  }
  if (scenario.steps.length > MAX_SCENARIO_STEPS) {
    throw new Error(`${path}: scenarios are limited to ${MAX_SCENARIO_STEPS} steps`);
  }

  let explicitMilliseconds = 0;
  for (const [index, candidate] of scenario.steps.entries()) {
    if (!candidate || typeof candidate !== 'object' || Array.isArray(candidate)) {
      throw new Error(`${path}: step ${index + 1} must be an object`);
    }
    const step = candidate as unknown as Record<string, unknown>;
    const action = step.action;
    const assertion = step.assert;
    if ((typeof action === 'string') === (typeof assertion === 'string')) {
      throw new Error(`${path}: step ${index + 1} must contain exactly one action or assertion`);
    }
    if (typeof action === 'string' && !actions.has(action)) {
      throw new Error(`${path}: step ${index + 1} has unknown action ${action}`);
    }
    if (typeof assertion === 'string' && !assertions.has(assertion)) {
      throw new Error(`${path}: step ${index + 1} has unknown assertion ${assertion}`);
    }
    for (const field of timingFields) {
      const timing = step[field];
      if (timing === undefined) continue;
      if (typeof timing !== 'number' || !Number.isFinite(timing) || timing < 0 || timing > MAX_SCENARIO_TIME_MS) {
        throw new Error(`${path}: step ${index + 1} ${field} must be from 0 through ${MAX_SCENARIO_TIME_MS}`);
      }
      explicitMilliseconds += timing;
    }
    if (step.detents !== undefined && (!Number.isInteger(step.detents) || (step.detents as number) < 1 || (step.detents as number) > 100)) {
      throw new Error(`${path}: step ${index + 1} detents must be an integer from 1 through 100`);
    }
  }
  if (explicitMilliseconds > MAX_SCENARIO_TIME_MS) {
    throw new Error(`${path}: explicit waits and timeouts total more than ${MAX_SCENARIO_TIME_MS} ms`);
  }
  return scenario as Scenario;
}
