# Agent Attestation Protocol / Token

This repository contains the Internet-Draft sources for the **Agent Attestation Protocol (AAP)**
and its **Agent Attestation Token (AAT)**, structured as a freestanding core plus two modules:

| Document | Scope |
|---|---|
| [`draft-agent-attestation-protocol.md`](./draft-agent-attestation-protocol.md) | **Core.** The attestation layer: AAT format, platform enrollment, identity linking, blind issuance, presentation, offline verification. Freestanding; implementable alone. |
| [`draft-aap-identity-claims.md`](./draft-aap-identity-claims.md) | **Identity claims module.** Consent-gated disclosure of facts about the principal: the two lanes, disclosure policy, asynchronous approval, claims discovery, requester keys and encryption. Requires the core. |
| [`draft-aap-local-agent.md`](./draft-aap-local-agent.md) | **Local-agent module.** Platform duality (hosted and device-resident surfaces of one platform), the platform-endorsed key profile, and the self-operated agent profile. Requires the core. |

Sources are authored in [kramdown-rfc](https://github.com/cabo/kramdown-rfc) Markdown and rendered
with Martin Thomson's [`i-d-template`](https://github.com/martinthomson/i-d-template) toolchain.
Sequence diagrams use [`aasvg`](https://github.com/martinthomson/aasvg) so one width-safe ASCII
source produces both SVG artwork for HTML/PDF and ASCII artwork for plaintext RFC output.

## Build and validate

```sh
make
```

The first build bootstraps `i-d-template` into the ignored `lib/` directory and uses the pinned
pnpm version to install `aasvg@0.4.3` from `package.json`. If pnpm is not already available,
`make` bootstraps it with npx or Corepack. A successful build produces `.txt` and `.html`
renderings of each draft; generated files are not source.

Nothing in this repository commits or publishes automatically from local tooling.
