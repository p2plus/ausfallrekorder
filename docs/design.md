# Ausfallrekorder

Small, boring, useful. Measure connectivity and produce a readable report.

Compact macOS menu bar popover, Linux terminal. Both use the same Swift core and versioned
JSON files. No accounts, dependencies, telemetry, background daemon, or repair button.
An app must be running to measure. Sleep and scheduling gaps are unobserved time.

Each round probes the default gateway, two external IPs, name resolution, and
HTTPS. Results are observations, not proof of who caused a fault. Gateway discovery
is refreshed every round. Two recordings can be compared by overlapping time only.
Raw recordings are appended and flushed after every round. A failed save stops recording
and shows the error. Reports are escaped HTML, readable offline, with raw JSON export.

Default: 15-second cadence, bounded probes, no overlapping rounds. A round covers
only its observed interval; the next sample does not retroactively fill a gap.
Quit/stop finishes the current recording; interrupted recordings remain readable.

Implementation order: tested classification and interval accounting; persistence,
reports and comparison; bounded real probes; terminal; macOS window; packaging and CI.

Linux ships a CLI, not a second desktop UI. Native macOS avoids a browser server.
Shared Swift avoids two implementations disagreeing about the same incident.

English, German and Simplified Chinese share a small compiled translation catalog.
No resource bundles are required beside the Linux executable.

The user explicitly authorized public publication after testing on 2026-10-29.
