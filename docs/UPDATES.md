# Updates (maintained by Nils)

Update log for haumea and moon (macOS side). `CHANGELOG.md` in this repo is gitignored, so this file is the tracked record. IDs are from the news-digest ledger (`infra/updates.jsonl`). Times are Europe/Berlin (CET).

## OrbStack on haumea (2026-11-03, read-only check, no ledger item)

Read on haumea (macOS 26.6.2, 25G83) at about 07:40:

| Component | Version | Notes |
|---|---|---|
| OrbStack | 2.2.5 (2020500), commit bf842321 | Latest (2026-10-23, "Important security fixes"). `orb update --check`: up to date. No Linux machines. |
| VM kernel | 7.2.12-orbstack-00394-gbecdd6130068 | Not affected by CVE-2026-98432 (fixed in 7.2.10) or CVE-2026-46300 (fixed in 7.0.10 and 7.1). |
| Docker Engine | 29.8.2 | Upstream 29.9.0 to 29.9.2 add Go runtime fixes (HTTP/2 daemon DoS, cert chain) and containerd 2.4.2. |
| containerd | v2.3.6 | Four medium advisories of 2026-10-13, fixed in 2.3.7: CVE-2026-95839 (GHSA-vwhp-8p66-mq4f), GHSA-8647-2jxj-p2rc, GHSA-hc94-p972-ch66, GHSA-5p7c-hggf-c748. |
| runc | 1.5.2 | Latest upstream; no open advisory. |
| Compose / Buildx | v5.5.0 / v0.37.2 | |

Docker, containerd and runc ship inside OrbStack and only update with it. No ledger item was opened: OrbStack is current, the kernel is fixed, and the open containerd and Docker items are medium DoS bugs. The daily scan opens an item when an OrbStack release ships Docker 29.9.x or containerd 2.3.7 or newer.

## Hermes on haumea

Hermes Agent v0.22.6 runs in hermes-stack on OrbStack (upstream `f0d94882`, verified live 2026-11-04). It was rebuilt on 2026-11-03 during the pw-browser rollout on the unpinned `nousresearch/hermes-agent:latest` base, so UPD-2026-11-03-005 is in fact done on haumea (closed as superseded). v0.22.7 (UPD-2026-11-04-003) is researched; the v0.22.6 → v0.22.7 work order waits on Axel's go. Correction 2026-11-04: this line earlier said v0.22.5 runs and v0.22.6 was not applied. See the hermes-stack CHANGELOG.

## herdr

- moon (Omarchy side): herdr 0.8.2-1, update to v0.9.5 is optional and still proposed (UPD-2026-10-31-004). Logged in moon-omarchy.
- haumea: no herdr version in the inventory. Unknown.
