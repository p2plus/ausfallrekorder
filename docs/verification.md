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

Public [GitHub CI run 40933690678](https://github.com/p2plus/ausfallrekorder/actions/runs/40933690678)
passed both jobs: macOS and Ubuntu 24.04 x86_64, including builds, tests, live smoke
checks and downloadable artifacts. Ubuntu ARM64 was additionally verified locally.
A fresh Ubuntu container without Swift installed also passed the ARM64 binary's
live smoke suite. The temporary Linux VM was stopped and removed after verification.

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
