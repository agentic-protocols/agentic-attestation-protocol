---
title: Local Agent Profiles for the Agent Attestation Protocol
abbrev: AAP Local Agents
docname: draft-aap-local-agent-latest
category: std
ipr: trust200902
submissiontype: IETF
date: 2026-08-12
keyword:
  - attestation
  - agent
  - device-resident agent
  - key endorsement
stand_alone: yes
pi: [toc, sortrefs, symrefs, comments]
author:
  - ins: R. Drapeau
    name: Ryan Drapeau
    org: Stripe
    email: drapeau@stripe.com
  - ins: D. Pettersson
    name: David Pettersson
    org: Shopify
    email: david.pettersson@shopify.com
normative:
  RFC2119:
  RFC6454:
  RFC7638:
  RFC8174:
  RFC9421:
  RFC9530:
  I-D.ietf-oauth-attestation-based-client-auth:
  AAP-CORE:
    title: "Agent Attestation Protocol (AAP)"
    author:
      - { ins: R. Drapeau, name: Ryan Drapeau }
      - { ins: D. Pettersson, name: David Pettersson }
    date: false
    target: https://agentic-protocols.github.io/agentic-attestation-protocol/draft-agent-attestation-protocol.html
informative:
  RFC2606:
  RFC9577:
  I-D.ietf-oauth-client-id-metadata-document:
  I-D.meunier-web-bot-auth-architecture:
  AAP-CLAIMS:
    title: "Identity Claims for the Agent Attestation Protocol"
    author:
      - { ins: R. Drapeau, name: Ryan Drapeau }
      - { ins: D. Pettersson, name: David Pettersson }
    date: false
    target: https://agentic-protocols.github.io/agentic-attestation-protocol/draft-aap-identity-claims.html

--- abstract

This document defines the local-agent module of the Agent Attestation Protocol (AAP). The AAP core assumes an agent whose request-signing key the agent platform controls and publishes. An agentic platform commonly ships two surfaces for one product: a hosted agent running on the platform's infrastructure, and a device-resident agent — a desktop or command-line application — running on hardware the platform does not control, whose signing key is generated locally and appears in no platform directory.

This document specifies how the core's enrollment, linking, and issuance cover both surfaces of one platform, and defines two profiles for trusting a locally-held agent key: a platform-endorsed profile, in which the platform vouches for the key it issued to its device-resident agent, and a self-operated profile, for an agent with no platform at all. This module layers on the AAP core and requires it.

--- middle

# Introduction {#intro}

The AAP core ({{AAP-CORE}}) binds every attested request to an agent key: the Web Bot Auth signature made with that key proves possession of the AAT and confines the token to the signed request. The core's common case is a hosted agent — the platform runs the software on its own infrastructure, holds the key, and publishes it in its Web Bot Auth directory, so a verifier resolves the signer to a named operator.

A platform's product is often not one agent but two surfaces of the same agent: a hosted, online surface reached through the platform's web application, and a device-resident surface — a desktop or CLI application — running on the principal's own hardware. The two surfaces share the platform, the principal, and the linking grant; they do not share key custody. The device-resident agent generates its signing key locally, on hardware the platform does not control, so that key appears in no platform directory and its signature would otherwise chain to nothing.

This document closes that gap twice over:

- **Platform duality** ({{duality}}): how one enrollment and one linking grant cover both surfaces, and how a device-resident agent fills its token pool without weakening the core's blind-issuance property.

- **Key trust profiles**: the platform-endorsed profile ({{endorsed}}), in which the platform signs a statement that it issued the local key to its agent, so the verifier can chain the signature to a platform it already trusts; and the self-operated profile ({{self-operated}}), for an agent operated by the principal directly, with no platform to endorse anything.

## Scope {#scope}

This module layers on the AAP core and does not stand alone: an implementation of this document MUST implement {{AAP-CORE}}. The core does not require the device-resident case; an implementation that never encounters it need not implement this module. Nothing here changes the AAT, its issuance protocol, or its verification checklist — the module adds surface-management rules and a key-endorsement profile beside them.

## Requirements Language {#requirements-language}

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 {{RFC2119}} {{RFC8174}} when, and only when, they appear in all capitals, as shown here.

## Terminology {#terminology}

The terms Principal, Agent, Agent Platform, Issuer, Verifier, Edge, Service, and AAT are used as defined in {{AAP-CORE}}. This document adds:

- Hosted surface: an agent instance running on the platform's infrastructure, signing with a platform-held key published in the platform's Web Bot Auth directory.

- Device-resident surface (or device-resident agent): an agent instance running on hardware the platform does not control — the principal's desktop, laptop, or server — signing with a key generated and held locally.

- Endorsement: the platform-signed statement that it issued a specific local key to its agent ({{endorsed}}).

- Self-operated agent: an agent the principal runs directly, with no agent platform ({{self-operated}}).

Examples use domain names reserved by {{RFC2606}} and identifiers that are not registered assignments.

# Platform Duality {#duality}

This section defines how the core's per-platform and per-principal relationships extend over a platform that ships both a hosted and a device-resident surface. The rule throughout: the platform's relationships are per operator, and the agent's artifacts are per instance.

## One Enrollment, One Grant {#one-enrollment}

Enrollment ({{AAP-CORE}}) is the issuer's vetting of an operator, and it covers every surface that operator ships: the enrolled OAuth client identity, issuance policy, and software-identity metadata belong to the platform, not to a surface. A platform does not enroll its desktop application separately from its web application.

The linking grant is likewise one per (principal, platform) pair, covering every surface. A principal who links a platform authorizes its agents — hosted and device-resident alike — to obtain attestations under the grant. Because a device-resident agent acts unattended on hardware the issuer never sees, the linking ceremony MUST disclose, where the platform ships a device-resident surface, that the grant covers agents running on the principal's own devices. This device-coverage disclosure is a module amendment to the core's linking ceremony, of the kind that section anticipates ({{AAP-CORE}}). Revocation is the core's: revoking the grant ends issuance under it for every surface at once.

## Issuance to the Device Surface {#device-issuance}

The device-resident agent fills its token pool through the platform, not around it: the platform relays the agent's issuance traffic to the issuer under the linking grant. The core's issuance custody rules ({{AAP-CORE}}) make the relay safe to insert: the device-resident agent blinds and unblinds locally, the platform is forbidden from requiring unblinded token material as a condition of relay, and tokens do not move between surfaces or instances. This module adds nothing to those rules; it specifies how the relay carries the traffic.

- The platform relays the blinded requests to the issuer's `token_issuance_endpoint` ({{AAP-CORE}}), authenticating under its enrolled client identity and the linking grant, and relays the blinded signatures back. To the issuer, the exchange is indistinguishable from the platform's own issuance; the issuer's per-principal rate and batch policy applies unchanged.

- In the key-bound mode ({{AAP-CORE}}), the `redemption_context` commits the device-resident agent's own key. The agent constructs the `TokenChallenge` from its local key before blinding; the relay carries it opaquely. Key-bound pools are therefore per instance by construction.

- Each surface is a distinct agent instance under the core's custody rule: the hosted and device-resident surfaces each obtain and spend their own tokens, and a token that crosses between them is indistinguishable from a stolen one ({{security}}).

The relay costs one privacy property, and only against the platform: the platform observes the device agent's issuance cadence and volume, as any relay observes traffic it carries. It learns nothing about redemption — the tokens it relays are blinded — and nothing the issuer does not also learn. See {{privacy}}.

Provisioning of claims credentials to a device-resident wallet ({{AAP-CLAIMS}}) is not blind — the credential carries claim values — so the relay above does not extend to it; how a device wallet is provisioned without exposing values to the platform is an open item ({{open-items}}).

## Keys per Surface {#keys-per-surface}

The hosted surface signs with platform-held keys resolved through the platform's Web Bot Auth directory, as in the core; this module adds nothing there. The device-resident surface signs with locally-generated keys that no directory holds, and a verifier trusts such a key through one of the two profiles below: the platform's endorsement ({{endorsed}}), or, where no platform exists, the self-operated profile ({{self-operated}}). The core's per-origin key discipline ({{AAP-CORE}}) applies to both surfaces.

# Platform-Endorsed Keys {#endorsed}

This profile is RECOMMENDED for the device-resident agent of an enrolled platform. Its requirements bind any implementation that adopts it.

## Scope and Claim {#scope-and-claim}

AAP deliberately keeps agent-software identity below the AAT ({{AAP-CORE}}). The AAT says that an accountable principal stands behind the agent; Web Bot Auth says which key signed the request. A device-resident agent generates its Web Bot Auth key locally, so that key never appears as a platform-held private key in the platform's directory. The missing statement is narrower than AAT issuance:

> The agentic platform issued this Web Bot Auth key to an agent.

This profile uses OAuth Attestation-Based Client Authentication ({{I-D.ietf-oauth-attestation-based-client-auth}}, "ABCA") for that statement. The agentic platform is the ABCA Client Attester; the device-local agent key is the ABCA Client Instance Key and is also the Web Bot Auth key used for the HTTP Message Signature. The verifier accepts the platform's endorsement only if its own policy trusts that platform.

The endorsement does not say who the principal is, does not delegate authority, does not bind the AAT to the platform, and does not prove that the software is genuine or unmodified. It says only that the platform issued the endorsed key to an agent. Hardware or device attestation MAY be one input to the platform's issuance decision, but AAP does not require it beyond what ABCA itself requires.

When the platform signs requests with a platform-held Web Bot Auth key, as on the hosted surface, this profile adds nothing: the platform-controlled key and its ordinary discovery path are sufficient.

## Key and Endorsement Lifetime {#key-lifetime}

An agent using this profile MUST use a distinct Web Bot Auth key per origin, where origin is scheme, host, and port as defined for the Web platform ({{RFC6454}}). Reusing one endorsed key across origins would make the key thumbprint — the Web Bot Auth `keyid` and the ABCA `cnf` key — a cross-origin correlator.

For each origin-specific key, the agent obtains a Client Attestation JWT from the platform as defined by ABCA. The JWT's `cnf.jwk` is the public Web Bot Auth key for that origin, and its `sub` MUST be the platform's OAuth `client_id` (under CIMD, the dereferenceable HTTPS URL of the platform document, {{I-D.ietf-oauth-client-id-metadata-document}}). ABCA carries no `iss`, so this `sub` is also how a verifier locates the key that signed the attestation. The JWT MUST carry `iat` and `exp`, and `exp` MUST be no more than 3600 seconds after `iat`; AAP requires `iat` even though ABCA leaves it OPTIONAL.

The Client Attestation JWT MUST NOT carry principal identity, account handles, stable device identifiers, per-user identifiers, or any other high-cardinality value that would let a verifier correlate the principal or device across origins. Platform-specific issuance evidence, including any hardware attestation result, stays between the agent and the platform unless ABCA requires otherwise.

## Presentation {#presentation}

Agents sign requests with Web Bot Auth HTTP Message Signatures as required by {{AAP-CORE}}. An agent using this profile sends the ABCA endorsement only when it redeems an AAT, carried in the `OAuth-Client-Attestation` header. The agent MUST NOT send the `OAuth-Client-Attestation-PoP` header; the HTTP Message Signature is the proof of possession.

An example request:

~~~ http
POST /checkout HTTP/1.1
Host: merchant.example
Signature-Agent: "https://agent-platform.example"
Authorization: PrivateToken token=<base64url Token>
OAuth-Client-Attestation: <Client-Attestation-JWT>
Content-Type: application/json
Content-Digest: sha-256=:X48E9qOokqqrvdts8nOJRJN3OWDUoyWxBf7kbu9DBPE=:
Signature-Input: agent=("@method" "@authority" "@path" \
  "signature-agent" "authorization" "oauth-client-attestation" \
  "content-digest");created=1715400030;expires=1715400090; \
  keyid="<RFC7638 thumbprint of cnf.jwk>";tag="web-bot-auth"
Signature: agent=:<signature by the endorsed agent key>:

{"item": "sku-12345", "quantity": 1}
~~~

The signature `keyid` MUST be the base64url-encoded {{RFC7638}} thumbprint of the Client Attestation JWT's `cnf.jwk`, and the signature MUST verify under that `cnf.jwk`. The signature MUST cover at least `@method`, `@authority`, `@path`, `authorization`, and `oauth-client-attestation`; it MUST cover `signature-agent` when that field is present, and `content-digest` ({{RFC9530}}) when the request has a body. Covering `authorization` binds the AAT to the signed request; covering `oauth-client-attestation` binds the endorsement to it.

This profile requires no additional nonce when an AAT is redeemed: freshness and replay defense come from the signature's `created` and `expires` parameters, the AAT's single-use double-spend check ({{AAP-CORE}}), and the signature's coverage of the AAT. A verifier MAY still require a Web Bot Auth nonce under its ordinary policy.

## Verification {#verification}

A verifier that requires or receives `OAuth-Client-Attestation` on an AAT redemption MUST perform these checks, failing closed at the first failure:

1. Verify the AAT as required by {{AAP-CORE}}.
2. Parse and validate exactly one `OAuth-Client-Attestation` header as an ABCA Client Attestation JWT.
3. Verify the Client Attestation JWT's signature under a key for an agentic platform trusted by local verifier policy.
4. Reject the JWT if it is expired, if `iat` is absent, if its lifetime exceeds one hour, or if `cnf.jwk` is absent.
5. Compute the {{RFC7638}} thumbprint of `cnf.jwk` and require it to equal the HTTP Message Signature `keyid`.
6. Verify the HTTP Message Signature under `cnf.jwk`, requiring the covered components listed in {{presentation}}.
7. Apply the verifier's ordinary Web Bot Auth and AAP admission policy.

The trust anchor is the verifier's answer to two questions: which agentic platforms it accepts, and which keys may sign endorsements for them. Verifiers SHOULD use an explicit allow-list for endorsed platforms, as they would for ordinary Web Bot Auth identities. Because the attestation carries no `iss`, the signer is located from its `sub` `client_id`: key resolution MAY be preconfigured, taken from the platform's Web Bot Auth directory ({{I-D.meunier-web-bot-auth-architecture}}), or taken from a Client ID Metadata Document ({{I-D.ietf-oauth-client-id-metadata-document}}) dereferenced from a `sub` HTTPS `client_id` that is allow-listed. Domain control or metadata discovery alone is not a trust decision; it only locates keys for a platform the verifier has already chosen to accept.

Because the endorsement rides only with an AAT redemption, a verifier MAY remember the endorsed key in the verifier session established after admission ({{AAP-CORE}}) and not require the endorsement on later requests in that session, which still carry Web Bot Auth signatures under the same session policy.

## Relationship to AAT Binding {#aat-binding}

This profile keeps platform endorsement decoupled from AAT issuance. In bearer mode the AAT is not minted to the endorsed key; the verifier learns that a valid AAT was redeemed in a request signed by a platform-endorsed key. That preserves the default Privacy Pass posture and keeps the endorsement unnecessary where Web Bot Auth already identifies a platform-controlled signer.

A deployment that needs the stronger statement — that the AAT is usable only with the endorsed key — combines this profile with the core's key-bound AAT mode ({{AAP-CORE}}). That is a separate choice with its own privacy and pooling costs, and is not the default.

## Standardization Note {#standardization}

ABCA defines a Client Attestation PoP JWT and a DPoP combined mode; it does not yet define a binding where an HTTP Message Signature ({{RFC9421}}) serves as the ABCA proof of possession. This profile defines that binding for AAP's direct-presentation surface: `OAuth-Client-Attestation` carries the attestation, the Web Bot Auth signature proves possession of the `cnf` key, and the signature covers the AAT and endorsement headers. The intended standards direction is an ABCA-compatible HTTP Message Signature PoP binding, not an AAP-specific replacement for ABCA.

# Self-Operated Agents {#self-operated}

A self-operated agent has no platform: the principal runs the software themselves — a local agent built from source, a personal server — and no operator stands behind it to enroll, to hold a linking grant as a confidential client, or to endorse its key. The Agent Platform role of {{AAP-CORE}} is vacant, and with it both halves the platform supplies: operator vetting at enrollment, and the endorsement of {{endorsed}}.

A profile for this case must define, at minimum: how linking and issuance work when the issuer is the only operator of record; what anchors the agent key when no platform endorses it and no directory publishes it (the core's key-bound mode, which commits the key into the token itself, is the natural anchor); and how the key reaches the verifier without a platform directory. It must do so without making self-operated agents distinguishable at redemption, which would turn the profile into a de-facto label on the token's anonymity set.

TODO: this profile is under active design and is not specified in this revision; see the corresponding open item ({{open-items}}).

# Privacy Considerations {#privacy}

**The endorsement must not become a correlator.** Where a device-resident agent's key is endorsed by its platform ({{endorsed}}), the same per-origin discipline that governs the key carries the endorsement's privacy: a distinct key and a fresh endorsement per origin, carrying nothing instance-stable ({{key-lifetime}}), so the endorsement is no more of a cross-origin correlator than the signing key already is. The prohibition on principal identity, device identifiers, and other high-cardinality values in the Client Attestation JWT is what makes this hold; a platform that leaks a stable value into its endorsements has rebuilt the tracking surface the AAT removed.

**The relay sees cadence, not tokens.** The issuance relay of {{device-issuance}} shows the platform the device agent's issuance timing and volume — the same traffic metadata any relay carries — but blinding keeps it from recognizing any token at redemption, and it learns nothing the issuer does not. The structural properties of the core's blind issuance ({{AAP-CORE}}) are unchanged by the relay's presence.

**Surfaces should not be distinguishable at the door.** Nothing in this module puts a surface marker on the AAT: tokens issued through the relay are indistinguishable from tokens issued to the hosted surface, and the endorsement rides beside the token, visible only to the verifier that receives it. A verifier can tell an endorsed key from a directory key — that is the profile's purpose — but learns nothing further about the device or principal from it.

# Security Considerations {#security}

**Key custody moves to the principal's hardware.** A device-resident key is only as safe as the device: malware on the principal's machine can exfiltrate the key and, in bearer mode, spend the agent's pooled tokens. The core's bounds apply — single-use tokens, the double-spend cache, issuance rate limits — and the endorsement's short lifetime ({{key-lifetime}}) bounds how long a stolen key remains endorsed. Platform-side revocation of an endorsement is its non-renewal: endorsements expire within an hour, so a platform that stops endorsing a key ends its verifiable life on that schedule. Hardware-backed key storage, where available, is the deployment-quality answer and is out of scope for this profile.

**The relay is not a token custodian.** The platform-brokered issuance of {{device-issuance}} gives the platform no token material: under the core's issuance custody rules ({{AAP-CORE}}) it relays blinded requests and blinded signatures only. A compromised platform can deny relay service or throttle a device agent, but cannot mint tokens to itself under the guise of the relay beyond what the issuer's per-principal policy already permits it as the grant holder — which is the standing exposure of the core's platform model, unchanged by this module.

**The endorsement chain is only as strong as the verifier's allow-list.** The profile's trust anchor is explicit verifier policy over platforms ({{verification}}). A verifier that accepts endorsements from platforms it has not vetted has extended admission to every key those platforms endorse; discovery mechanisms locate keys and never substitute for the acceptance decision.

# IANA Considerations {#iana}

This document registers nothing. The `OAuth-Client-Attestation` header is registered by {{I-D.ietf-oauth-attestation-based-client-auth}}; the HTTP Message Signature tag `web-bot-auth` and the `PrivateToken` scheme ({{RFC9577}}) are used as registered by their defining documents and profiled by {{AAP-CORE}}.

# Open Items {#open-items}

- The self-operated profile ({{self-operated}}): linking and issuance with the issuer as sole operator of record, the key-bound anchor, and platform-less key carriage (an inline Web Bot Auth directory is the current candidate).
- Whether the self-operated profile belongs in this document or in a separate module: this document covers a platform's device-resident surface, while a self-operated agent has no platform at all. To be decided together with the profile's design.
- Claims-credential provisioning to a device-resident wallet ({{device-issuance}}): unlike AAT issuance, credential provisioning is not blind, so the issuance relay would expose claim values to the platform; whether the device agent provisions directly, or an encrypted-to-device relay is defined, is undecided ({{AAP-CLAIMS}}).
- Whether hardware or device attestation should ever be surfaced to the verifier (beyond informing the platform's endorsement decision), or remains permanently a platform-internal input ({{scope-and-claim}}).

# Acknowledgments {#acknowledgments}

TODO.

--- back

# Examples {#appendix-a}

This appendix is informative.

TODO: an end-to-end flow for a device-resident agent: local key generation, endorsement fetch, pool fill through the issuance relay, and an endorsed AAT redemption at a verifier.
