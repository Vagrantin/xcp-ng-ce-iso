# xcp-ng-ce-iso

Build tooling for the **XCP-ng HomeLab Edition ISO** — a respin of the official XCP-ng installation ISO that ships the community `xo-lite-ce` + `xoa-proxy` packages instead of the stock XO Lite, so the in-host "Deploy XOA" button targets the community-built XOA image.

## Contents

- `configs/repo/CUSTOMREPO.tmpl` — yum repo template injected into the ISO build so the community packages are pulled in alongside the official XCP-ng repos.
- `patches/multi-key-support.patch` — patch against the upstream `xcp/xcp-ng-build-env` ISO scripts (`create-installimg.sh`) fixing package erasure with `--allmatches`, enabling multiple RPM signing keys.
- `sign-script.sh` — GPG-signs the repo metadata (`repodata/repomd.xml`), exports the public key as `RPM-GPG-KEY-xcp-ng-ce` into the ISO, and points `.treeinfo` at it. Expects `GPG_KEY_ID` in the environment and `gpg1`.
- `debug/create-iso.sh`, `debug/create-installimg.sh` — patched copies of the upstream ISO build scripts, kept for local debugging of the build.

## How it fits together

The ISO is normally produced by CI (triggered as the final stage of `../buildorchestration` once `xolite-ce` and `xoa-proxy` builds succeed). The flow is the upstream XCP-ng ISO tooling plus:

1. the custom repo (with `xo-lite-ce`, `xoa-proxy`) added via `CUSTOMREPO.tmpl`,
2. the multi-key patch applied so both the official and the community signing keys are accepted,
3. `sign-script.sh` signing the resulting repo with the `xcp-ng-ce` key.

Released ISOs are published on this repo's GitHub Releases page and documented at `../xcp-hl`.
