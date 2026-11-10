# IHP SG13G2 (open PDK) RTL-to-GDS result

Flow: LibreLane 3.0.16 (Docker) with Yosys, OpenROAD, KLayout and Magic. PDK: IHP-Open-PDK `ihp-sg13g2`,
version `5e6d592e4002946a4616f798c357f0f3c06cf3b6`, standard-cell library `sg13g2_stdcell`.
Inputs: `rtl/*.v` and `constraints/fpc_top.sdc` (20 ns clock, 6 ns I/O delays). Run with `flow/ihp_sg13g2/run.sh`.

| Item | Result |
|---|---|
| Die size | 267 x 286 um (about 0.076 mm^2) |
| Standard cells | 2,579 cells, 36,186 um^2 (163 flip-flops) |
| Core utilisation | 56 % |
| Setup slack (worst of 3 corners) | +3.26 ns at 20 ns clock |
| Hold slack (worst of 3 corners) | +0.12 ns |
| Routing DRC / Magic DRC / KLayout DRC | 0 / 0 / 0 |
| LVS errors | 0 |
| Antenna violations | 0 |
| Total power | about 8 mW (default switching activity: a rough figure) |

Layout: `docs/ihp_sg13g2_layout.png`.

Caveats:
- Pad ring, I/O cells and seal ring are not included; this is a core macro, not a tape-out-ready chip.
- Power is estimated with default activity, not from simulation activity.
- Checks are the open-source ones (Magic, KLayout, Netgen LVS). A real shuttle submission runs IHP's own
  sign-off DRC deck and has more requirements (density, metal fill, pads); check IHP's submission guide.
- Timing used the 3 typical, fast and slow corners that LibreLane provides, not a full signoff corner set.
