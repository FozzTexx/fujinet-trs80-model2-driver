# FujiNet TRS-80 Model II Driver

A **Pickles & Trout CP/M driver** for using a [FujiNet](https://fujinet.online/) as a disk drive on the **TRS-80 Model II**.

The driver installs as a CP/M TSR and hooks the system BIOS disk routines. Requests for the FujiNet drive are handled by FujiNet, while requests for the existing drives are passed through to the original BIOS.

```text
CP/M
  |
BIOS
  |
  +-- Existing drives -> Model II BIOS
  |
  +-- FujiNet drive -> SIO -> FujiNet
```

## Status

This is experimental software under active development. It has been tested on a real TRS-80 Model II running CP/M.

The driver currently supports the Model II's CP/M disk formats, including the different sector layouts used for single-density and double-density tracks.

## Building

The project uses [z88dk](https://github.com/z88dk/z88dk).

```sh
make
```

This produces the CP/M installer:

```text
fujitsr2.com
```

## Installation

Before installing, configure CP/M with **[LA] Last Address set to `$BFFF`**. This reserves the memory above `$BFFF` for the resident driver.

Copy `fujitsr2.com` to the Model II and run it from CP/M:

```text
A>FUJITSR2
```

The installer copies the resident driver into memory above `$BFFF` and patches the CP/M BIOS to intercept disk operations for the FujiNet drive.

Rebooting the system removes the driver.

## Hardware

The driver communicates with FujiNet through the Model II's Z80 SIO using the Model II serial interface.

## Related Projects

* [FujiNet](https://fujinet.online/) — FujiNet project
* [z88dk](https://github.com/z88dk/z88dk) — Z80 development tools
* [TRS-80 Model II Archive](https://github.com/pski/model2archive) — Model II documentation and software

## License

See `LICENSE`.
