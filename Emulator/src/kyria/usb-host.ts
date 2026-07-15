import {
  DataDirection,
  DescriptorType,
  SetupRecipient,
  SetupRequest,
  SetupType,
  createSetupPacket,
  getDescriptorPacket,
  setDeviceAddressPacket,
  setDeviceConfigurationPacket,
} from 'rp2040js';
import type { DeterministicClock } from '../clock.js';
import type { FirmwareMachine } from '../machine.js';

export type HostProfile = 'default' | 'macos' | 'windows';

export interface USBReport {
  readonly timestampNanos: number;
  readonly endpoint: number;
  readonly data: Uint8Array;
}

interface USBEndpoint {
  readonly number: number;
  readonly direction: 'in' | 'out';
  readonly maxPacketSize: number;
}

type EnumerationPhase = 'address' | 'config-header' | 'config-full' | 'fingerprint' | 'set-config' | 'ready';

export class QMKUSBHost {
  readonly reports: USBReport[] = [];
  readonly endpoints: USBEndpoint[] = [];
  configured = false;
  descriptorTotalLength = 0;
  usbEnableCount = 0;
  resetCount = 0;
  private phase: EnumerationPhase = 'address';
  private configurationBytes: number[] = [];
  private fingerprintLengths: number[] = [];
  private readonly pendingRawHID: Uint8Array[] = [];
  private rawOutEndpoint: number | undefined;

  constructor(
    readonly machine: FirmwareMachine,
    readonly clock: DeterministicClock,
    readonly profile: HostProfile,
  ) {
    const usb = machine.rp2040.usbCtrl;
    usb.onUSBEnabled = () => {
      this.usbEnableCount++;
      usb.resetDevice();
    };
    usb.onResetReceived = () => {
      this.resetCount++;
      this.phase = 'address';
      this.configurationBytes = [];
      this.descriptorTotalLength = 0;
      usb.sendSetupPacket(setDeviceAddressPacket(1));
    };
    usb.onEndpointWrite = (endpoint, buffer) => this.endpointWrite(endpoint, buffer);
    usb.onEndpointRead = (endpoint, size) => {
      if (endpoint > 0 && size >= 32) this.rawOutEndpoint = endpoint;
      const next = this.pendingRawHID.shift();
      if (next) usb.endpointReadDone(endpoint, this.pad(next, size));
    };
  }

  queueRawHID(data: Uint8Array): void {
    if (data.length > 32) throw new Error('QMK raw-HID reports are at most 32 bytes');
    this.pendingRawHID.push(data);
    if (this.rawOutEndpoint !== undefined) {
      this.machine.rp2040.usbCtrl.endpointReadDone(this.rawOutEndpoint, this.pad(data, 32));
      this.pendingRawHID.shift();
    }
  }

  private endpointWrite(endpoint: number, buffer: Uint8Array): void {
    if (endpoint !== 0) {
      this.reports.push({ timestampNanos: this.clock.nanos, endpoint, data: Uint8Array.from(buffer) });
      return;
    }

    if (this.phase === 'address' && buffer.length === 0) {
      this.phase = 'config-header';
      this.machine.rp2040.usbCtrl.sendSetupPacket(getDescriptorPacket(DescriptorType.Configration, 9));
      return;
    }

    if (this.phase === 'config-header' && buffer.length >= 4 && buffer[1] === DescriptorType.Configration) {
      this.descriptorTotalLength = buffer[2]! | (buffer[3]! << 8);
      this.phase = 'config-full';
      this.machine.rp2040.usbCtrl.sendSetupPacket(
        getDescriptorPacket(DescriptorType.Configration, this.descriptorTotalLength),
      );
      return;
    }

    if (this.phase === 'config-full' && buffer.length > 0) {
      this.configurationBytes.push(...buffer);
      // rp2040js 1.3.3 does not complete TinyUSB's second packet for a
      // multi-packet configuration descriptor in device mode. The real host
      // request still uses wTotalLength; parse the first packet (which holds
      // the boot interfaces) and continue enumeration. Runtime endpoints are
      // also discovered from actual transfers below.
      const configuration = Uint8Array.from(
        this.configurationBytes.slice(0, this.descriptorTotalLength),
      );
      this.parseEndpoints(configuration);
      this.fingerprintLengths = this.profileFingerprint();
      this.phase = 'fingerprint';
      this.sendNextFingerprintOrConfigure();
      return;
    }

    if (this.phase === 'fingerprint') {
      this.sendNextFingerprintOrConfigure();
      return;
    }

    if (this.phase === 'set-config' && buffer.length === 0) {
      this.phase = 'ready';
      this.configured = true;
    }
  }

  state(): string {
    return `${this.phase}; enabled=${this.usbEnableCount}; resets=${this.resetCount}; `
      + `configuration=${this.configurationBytes.length}/${this.descriptorTotalLength}`;
  }

  private sendNextFingerprintOrConfigure(): void {
    const length = this.fingerprintLengths.shift();
    if (length !== undefined) {
      this.machine.rp2040.usbCtrl.sendSetupPacket(createSetupPacket({
        dataDirection: DataDirection.DeviceToHost,
        type: SetupType.Standard,
        recipient: SetupRecipient.Device,
        bRequest: SetupRequest.GetDescriptor,
        wValue: (DescriptorType.String << 8) | 1,
        wIndex: 0x0409,
        wLength: length,
      }));
      return;
    }
    this.phase = 'set-config';
    this.machine.rp2040.usbCtrl.sendSetupPacket(setDeviceConfigurationPacket(1));
  }

  private profileFingerprint(): number[] {
    switch (this.profile) {
      case 'windows': return [0xff, 0x04, 0xff];
      case 'macos': return [0x02, 0x02, 0x40, 0x40, 0xff];
      case 'default': return [];
    }
  }

  private parseEndpoints(configuration: Uint8Array): void {
    let offset = 0;
    while (offset + 1 < configuration.length) {
      const length = configuration[offset]!;
      const type = configuration[offset + 1]!;
      if (length < 2 || offset + length > configuration.length) break;
      if (type === DescriptorType.Endpoint && length >= 7) {
        const address = configuration[offset + 2]!;
        const maxPacketSize = configuration[offset + 4]! | (configuration[offset + 5]! << 8);
        this.endpoints.push({
          number: address & 0x0f,
          direction: address & 0x80 ? 'in' : 'out',
          maxPacketSize,
        });
      }
      offset += length;
    }
  }

  private pad(data: Uint8Array, length: number): Uint8Array {
    const result = new Uint8Array(length);
    result.set(data.subarray(0, length));
    return result;
  }
}
