# Verification

Verified on 2026-10-29:

- macOS / Apple Silicon / Swift 6.4: 20 tests passed.
- Ubuntu 24.04 ARM64 / Swift 6.2: the same 20 tests passed.
- Live CLI smoke tests passed on both platforms: real probes, HTML export,
  comparison, invalid options, no-clobber output and Ctrl+C finalization.
- English and Simplified Chinese reports checked by the smoke suite.
- The Mac UI was inspected running, including visible Export and Quit actions.
- Documentation images are rendered from the actual SwiftUI view with a saved
  live recording; its router address was replaced with a documentation address.

Initial private GitHub jobs did not start because the owner's account hit a
billing/spending restriction. Local Linux verification used an isolated VM instead.
The workflow also targets Ubuntu 24.04 x86_64; this architecture is not covered
by the local ARM64 measurements.

## Resource check

Release CLI, default 15-second interval, 45.79-second live run, 3 checks:

```text
0.04 seconds user CPU
0.05 seconds system CPU
17,973,248 bytes maximum resident set size (17.1 MiB)
6,324,944 bytes peak memory footprint
0 swaps
```

The earlier window-based Mac UI measured about 57 MiB RSS at idle. This is not a
measurement of the final menu bar UI; UI/framework allocations differ from the CLI.
Neither value is a long-duration memory-growth test.

Resource measurements are short-run observations, not a battery-life benchmark.
Wi-Fi power use depends on hardware, signal, and other traffic. No zero-impact claim.
