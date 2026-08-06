# xcp-ng-ce-iso

Build tooling for the **XCP-ng HomeLab Edition ISO** — a respin of the official XCP-ng installation ISO that ships the community `xo-lite-ce` + `xoa-proxy` packages instead of the stock XO Lite, so the in-host "Deploy XOA" button targets the community-built XOA image. It also bakes in `xcp-hl-release`, so a host installed from this ISO has the XCP-HL yum repository and its signing key configured out of the box: no manual `.repo` curling needed, and XCP-HL updates show up in Xen Orchestra's Patches tab.

## Contents

- `configs/repo/CUSTOMREPO.tmpl` — yum repo template injected into the ISO build so the community packages are pulled in alongside the official XCP-ng repos.
- `patches/multi-key-support.patch` — patch against the upstream `xcp/xcp-ng-build-env` ISO scripts (`create-installimg.sh`) fixing package erasure with `--allmatches`, enabling multiple RPM signing keys.
- `sign-script.sh` — GPG-signs the repo metadata (`repodata/repomd.xml`), exports the public key as `RPM-GPG-KEY-xcp-ng-ce` into the ISO, and points `.treeinfo` at it. Expects `GPG_KEY_ID` in the environment and `gpg1`.
- `debug/create-iso.sh`, `debug/create-installimg.sh` — patched copies of the upstream ISO build scripts, kept for local debugging of the build.

## How it fits together

The ISO is normally produced by CI (triggered as the final stage of `../buildorchestration` once `xolite-ce` and `xoa-proxy` builds succeed). The flow is the upstream XCP-ng ISO tooling plus:

1. the custom repo (with `xo-lite-ce`, `xoa-proxy`, and `xcp-hl-release`) added via `CUSTOMREPO.tmpl`,
2. the multi-key patch applied so both the official and the community signing keys are accepted,
3. `sign-script.sh` signing the resulting repo with the `xcp-ng-ce` key,
4. the ce counter stamped into `.treeinfo` so the installed host can name the ISO it came from.

`xcp-hl-release` is fetched and baked in the same way as the other two components, and reaches the media, and installed hosts, as a `Requires:` of `xo-lite-ce` — the same dependency route `xoa-proxy` already takes (`xcp-ng-deps` → `xo-lite`, provided by `xo-lite-ce`). It was previously also staged by name with `--extra-packages`; that became redundant once the dependency existed, since `create-iso.sh` resolves the ISO's package set with `get_rpms --depends xcp-ng-deps`, and having two ways in only obscured which one was doing the work.

That `Requires:` was previously avoided on the grounds that it would break `yum update xo-lite-ce` on a host with the component repos configured but not `xcp-hl-base`. That case cannot arise through any supported path: the bootstrap `.repo` published at the site root configures all three sections together (`xcp-hl-base`, `xcp-hl-xolite`, `xcp-hl-xoa-proxy`), and `xcp-hl` CI keeps it in lockstep with the packaged copy. Only a hand-rolled partial repo config could hit it, and that has never been shipped.

Staging alone was never enough: nothing depended on the package, so it sat in the ISO's repo and was never selected for install. Note that `install.img` is the installer's own ramdisk, not the installed host's filesystem, so adding the package to `packages.lst` does not put it on the host either. The verification step asserts the RPM made it into the ISO, since the dependency is now the only route in — dropping the `Requires:`, or pinning an `xolite-ce` release from before it existed, would otherwise still produce a green build that silently ships without XCP-HL repo configuration. `build-iso.yml` accepts a `xcp_hl_release_tag` workflow_dispatch input to pin an exact release, alongside the existing `xolite_tag` and `xoa_proxy_tag` inputs.

## Identifying the ISO a host was installed from

Each build stamps its ce counter into the media's `.treeinfo` (`[build] number`), replacing the `cloud` placeholder upstream ships. `host-installer` reads that key and writes it to `BUILD_NUMBER` in `/etc/xensource-inventory`, so the value follows the install onto the host:

```
$ grep BUILD_NUMBER /etc/xensource-inventory
BUILD_NUMBER='ce23'
```

Because xapi reads that inventory, it also surfaces remotely — no need to log into the host:

```
$ xe host-param-get uuid=<host-uuid> param-name=software-version
... build_number: ce23; ...
```

Nothing else on an installed host records which media it came from: the ISO volume label does not survive the install, and the installer logs kept in `/var/log/installer/` do not mention it. The build asserts the stamp reached the finished ISO, so a silent regression fails CI rather than shipping an unidentifiable image.

Released ISOs are published on this repo's GitHub Releases page and documented at `../xcp-hl`.
