# Analog / mixed-signal plan (ideas only, nothing is designed yet)

The digital core already treats these as external. Each idea below plugs into an existing BOUNDARY port.

| Block | Plugs into | Notes / open questions |
|---|---|---|
| ADC (or SPI/I2C IMU interface) | `sample_valid`, `gyro`, `meas_angle` | Decide: on-chip ADC reading analog sensors, or a digital IMU bus. A digital IMU needs only a serial interface block; an on-chip ADC (SAR, 12-bit) is the mixed-signal learning target. |
| Clock source / PLL | `clk` | A 1024 Hz sample tick must be derived from it. Lock-detect should gate `rst_n`. |
| Power-on-reset and brown-out | `rst_n` | Digital side already synchronises release. |
| Bandgap and LDO | none (supplies) | Needed before any ADC accuracy claim. |
| Motor / ESC gate driver | `pwm`, `dir` | Level shifting and dead-time. Dead-time insertion is digital and could be added to `fpc_pwm`. |
| Current / voltage sense | a second ADC channel | Would feed a future current loop. |

## How to integrate later without disturbing the digital core
1. Keep the port widths and formats in `docs/ARCHITECTURE.md` fixed; the analog side adapts to them.
2. Model each analog block first as a behavioural Verilog (or real-number `wreal`) model with the same ports, and
   drop it into the testbench in place of the current ideal stimulus.
3. When a real block exists, replace the model with a Verilog-AMS or schematic-based view in a mixed-signal
   simulation (Synopsys has this flow via VCS plus a SPICE engine; not tried here).
4. Add power intent (UPF) when separate supply domains appear.
