#!/bin/bash
# Executed inside xcp-ng-build-env (rpm 4.11, exactly as dom0 will read them).
# Every community repo package must carry a legacy header signature. Runner
# rpm 6 writes only the new OpenPGP tag, which rpm 4.11 cannot see at all: the
# packages look unsigned, the installer aborts with "Error installing
# packages" (ce35-ce37 reached ISO ce50-ce52 that way). Fail the build.
set -u

status=0
for rpm_file in /community-repo/x86_64/*.rpm; do
    echo "── audit: ${rpm_file}"
    out=$(rpm -Kv "${rpm_file}")
    echo "${out}"
    printf '%s\n' "${out}" | grep -qiE 'Header .*[Ss]ignature' \
        || { echo "❌ ${rpm_file}: no legacy header signature readable by rpm 4.11"; status=1; }
done

test "${status}" -eq 0 \
    || { echo "❌ community repo contains packages dom0 rpm 4.11 cannot verify"; exit 1; }
echo "✅ every community RPM carries an rpm 4.11-readable header signature"
