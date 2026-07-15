# Third-party notices

## rp2040js

The emulator uses `rp2040js` 1.3.3, Copyright (c) 2021 Uri Shaked,
under the MIT License.

The compatibility adapter in this repository works around three missing
RP2040 register behaviours without copying or vendoring `rp2040js` source.

## uf2

The emulator uses `uf2` 2.0.0, Copyright (c) 2021 Uri Shaked, under the MIT
License.

The MIT license text for both packages follows:

> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
> THE SOFTWARE.

## Raspberry Pi RP2040 boot ROM

The boot ROM is built locally from Raspberry Pi's official
`pico-bootrom-rp2040` source at tag `b2` / commit
`ef22cd8ede5bc007f81d7f2416b48db90f313434`. Neither its source nor its binary
is committed, uploaded as an artifact, or attached to a release by this
repository.

Most of the source is BSD-3-Clause. `bootrom/mufplib.S` and
`bootrom/mufplib-double.S` are used under their GPLv2 alternative for
emulation. See <https://github.com/raspberrypi/pico-bootrom-rp2040>.
