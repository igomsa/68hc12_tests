# HCS12 / Dragon12 Assembly Experiments

Assembly-language experiments for the **Wytec Dragon12** evaluation board (Freescale
**HCS12 / 68HCS12**, S12 family). They cover small algorithms and on-board peripheral
drivers, using the board's **D-Bug12** monitor routines for console I/O.

## Contents

1. [Layout](#layout)
2. [Requirements](#requirements)
3. [Build & run](#build--run)
4. [Status](#status)

## Layout

| Path | Topic |
|------|-------|
| `src/array_handle/`           | Array routines: `sort` (ordering), `xor` (bit masking), `div4` (filter divisible-by-4). |
| `src/babylonian_algorithm/`   | Integer square root via the Babylonian method. |
| `src/atd/`                    | Analog-to-digital conversion (potentiometer input). |
| `src/keyboard/`               | 4x4 matrix keypad input. |
| `src/screens/`                | 7-segment / LCD display output. |
| `src/i2c_rtc/`                | I²C real-time-clock interface. |
| `src/kb_screen_integration/`  | Combined keypad + display + ATD application. |
| `include/registers.inc`       | Register map, D-Bug12 entry points and memory layout. |

## Requirements

- A **68HCS12 assembler** that accepts Freescale/`as12` syntax (e.g. AsmIDE, or the
  assembler bundled with the tool below).
- A **Dragon12** board running the **D-Bug12** monitor (the programs call its
  `get_char` / `put_char` routines and rely on its interrupt vector table).

## Build & run

The programs are assembled to S-records and loaded onto the board over serial.
The [`bash-dragon-12-tool`](https://github.com/jeancahu/bash-dragon-12-tool) wraps
that flow (assemble → load → run via D-Bug12).

> These targets a physical board: there is no host-side simulator in this repo, so
> the programs are exercised on real Dragon12 hardware rather than in CI.

## Status

Working coursework, kept for reference. Comments are being translated from Spanish
to English (the source was originally written with Spanish comments in a Latin-1
encoding).
