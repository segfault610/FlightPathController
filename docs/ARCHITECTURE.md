# Architecture

## Data flow and rates
One sample arrives every 1/1024 s as a one-clock `sample_valid` pulse with two words. The estimator updates on
that pulse; the PID updates one clock later; the PWM latches the new duty at the next PWM period boundary.
Using 1024 Hz makes `dt = 2^-10`, so integration is a shift, not a multiplier.

| Signal | Format | Meaning |
|---|---|---|
| `gyro`, `rate` | Q5.11 signed, rad/s | range +-16 rad/s, step 4.9e-4 |
| `meas_angle`, `angle_est`, `setpoint` | Q3.13 signed, rad | range +-4 rad, step 1.2e-4 |
| internal angle / bias | Q3.29, 32 bit | extra fraction bits so tiny gyro rates are not truncated away |
| `ctrl_out` | signed 12 bit, +-2047 | PWM period is 2048 clocks |

## Choices
- **Fixed-gain (alpha-beta) Kalman instead of a full EKF.** No division or matrix maths, tiny area, and it behaves
  as the steady-state Kalman filter. The gains are `2^-4` (angle) and `2^-9` (bias). Upgrade path: a full
  covariance filter once real IMU noise data exists.
- **Derivative on measurement** (uses the bias-corrected rate), so setpoint steps do not kick the output.
- **Safety is separate hardware**, not part of the PID, so a bug in the control path cannot disable the watchdog.
- **Single clock, one synchronised reset**, no latches, no tristates, no vendor primitives. That keeps the
  design portable between FPGA, open-source and Synopsys flows.

## Limits to know
- `angle` is one axis; the accelerometer-to-angle step (an `atan2`, usually a CORDIC) is not here. The
  testbench supplies the angle directly. This is the first block to add.
- The PID's three multipliers sit in one clock cycle. That is fine at the placeholder 50 MHz; pipeline them
  if timing fails at the real target.
- Gains are parameters, not registers. A bus-attached register bank is the next integration step.
