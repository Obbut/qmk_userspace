import { createHash } from 'node:crypto';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { KyriaBoard, type KyriaPaths } from './kyria/board.js';
import { readScenario } from './scenario.js';
import { ScenarioRunner } from './scenario-runner.js';

interface Arguments extends KyriaPaths {
  scenarios: string[];
  repeat: number;
}

function argumentValue(name: string): string | undefined {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

function argumentsFromCommandLine(): Arguments {
  const leftUF2 = argumentValue('--left');
  const rightUF2 = argumentValue('--right');
  const bootROM = argumentValue('--boot-rom') ?? '/opt/bootrom/bootrom.bin';
  const layout = argumentValue('--layout') ?? '/workspace/kyria-layout.json';
  const scenario = argumentValue('--scenario');
  const suite = argumentValue('--suite');
  const repeat = Number(argumentValue('--repeat') ?? 1);
  if (!leftUF2 || !rightUF2 || (!scenario && !suite)) {
    throw new Error('Usage: --left LEFT.uf2 --right RIGHT.uf2 (--scenario FILE | --suite DIRECTORY) [--repeat COUNT] [--boot-rom FILE] [--layout FILE]');
  }
  if (!Number.isInteger(repeat) || repeat < 1 || repeat > 10) throw new Error('--repeat must be an integer from 1 through 10');
  const scenarios = scenario
    ? [scenario]
    : readdirSync(suite!).filter((file) => file.endsWith('.json')).sort().map((file) => resolve(suite!, file));
  for (const path of [leftUF2, rightUF2, bootROM, layout, ...scenarios]) {
    if (!existsSync(path)) throw new Error(`Required emulator input does not exist: ${path}`);
  }
  return { leftUF2, rightUF2, bootROM, layout, scenarios, repeat };
}

function sha256(path: string): string {
  return createHash('sha256').update(readFileSync(path)).digest('hex');
}

try {
  const args = argumentsFromCommandLine();
  console.log(`left UF2:  ${args.leftUF2}\nleft SHA:  ${sha256(args.leftUF2)}`);
  console.log(`right UF2: ${args.rightUF2}\nright SHA: ${sha256(args.rightUF2)}`);

  for (const scenarioPath of args.scenarios) {
    const scenario = readScenario(scenarioPath);
    let result: ReturnType<ScenarioRunner['run']> | undefined;
    let canonical: string | undefined;
    for (let repetition = 1; repetition <= args.repeat; repetition++) {
      const candidate = new ScenarioRunner(new KyriaBoard(args)).run(scenario);
      const candidateCanonical = JSON.stringify(candidate);
      if (canonical !== undefined && candidateCanonical !== canonical) {
        throw new Error(`${scenarioPath} produced a non-deterministic trace on repetition ${repetition}`);
      }
      result = candidate;
      canonical = candidateCanonical;
    }
    console.log(JSON.stringify({ status: 'passed', scenario: scenarioPath, repetitions: args.repeat, ...result! }));
  }
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  console.error(JSON.stringify({ status: 'failed', error: message }));
  process.exitCode = 1;
}
