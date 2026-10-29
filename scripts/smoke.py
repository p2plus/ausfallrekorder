#!/usr/bin/env python3
"""Run the built product. No mocked network, no dependency packages."""
import json
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path

binary = str(Path(sys.argv[1]).resolve())
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    def run(*args, ok=True):
        result = subprocess.run([binary, *args], capture_output=True, text=True, timeout=20)
        assert (result.returncode == 0) == ok, (args, result.stdout, result.stderr)
        return result

    assert 'record' in run('--help').stdout
    run('record', '--interval', '0', ok=False)
    run('record', '--duration', 'nan', ok=False)
    run('record', '--output', str(root / 'missing' / 'test.afr'), ok=False)
    recording = root / 'live.afr'
    run('record', '--duration', '4', '--label', '<test>', '--output', str(recording))
    rows = [json.loads(line) for line in recording.read_text().splitlines()]
    assert rows[-1].get('ended') is not None
    assert any('sample' in row for row in rows)
    report = recording.with_suffix('.html').read_text()
    assert '&lt;test&gt;' in report and '<test>' not in report
    run('record', '--duration', '1', '--output', str(recording), ok=False)
    run('compare', str(recording), str(recording), '--output', str(root / 'compare.html'))
    run('report', str(recording), '--output', str(root / 'new.html'))
    run('report', str(recording), '--output', str(root / 'new.html'), ok=False)
    interrupted = root / 'interrupt.afr'
    process = subprocess.Popen([binary, 'record', '--output', str(interrupted)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(0.8)
    process.send_signal(signal.SIGINT)
    stdout, stderr = process.communicate(timeout=8)
    assert process.returncode == 0, (stdout, stderr)
    assert json.loads(interrupted.read_text().splitlines()[-1]).get('ended') is not None
    print('Smoke passed: live probes, report, compare, validation, no clobber, Ctrl+C.')
