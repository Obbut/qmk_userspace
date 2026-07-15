import { GPIOPinState } from 'rp2040js';
import type { FirmwareMachine } from '../machine.js';

function isHigh(state: GPIOPinState): boolean {
  return state !== GPIOPinState.Low && state !== GPIOPinState.InputPullDown;
}

export function connectSplitTransport(left: FirmwareMachine, right: FirmwareMachine): void {
  connect(left, 28, right, 29);
  connect(right, 28, left, 29);
}

function connect(source: FirmwareMachine, output: number, target: FirmwareMachine, input: number): void {
  const sourcePin = source.rp2040.gpio[output]!;
  const targetPin = target.rp2040.gpio[input]!;
  targetPin.setInputValue(isHigh(sourcePin.value));
  sourcePin.addListener((state) => targetPin.setInputValue(isHigh(state)));
}
