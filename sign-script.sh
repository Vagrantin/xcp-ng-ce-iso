#!/bin/bash
set -e
ISODIR="$1"
KEYID="${GPG_KEY_ID}"
KEYNICK="xcp-ng-ce"

gpg1 --default-key="${KEYID}" --armor --detach-sign \
  "${ISODIR}/repodata/repomd.xml"

gpg1 --armor -o "${ISODIR}/RPM-GPG-KEY-${KEYNICK}" \
  --export "${KEYID}"

sed -i "s,key1 = .*,key1 = RPM-GPG-KEY-${KEYNICK}," \
  "${ISODIR}/.treeinfo"
