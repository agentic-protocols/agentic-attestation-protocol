---
title: Identity Claims for the Agent Attestation Protocol
abbrev: AAP Identity Claims
docname: draft-aap-identity-claims-latest
category: std
ipr: trust200902
submissiontype: IETF
date: 2026-08-12
keyword:
  - attestation
  - agent
  - identity disclosure
  - consent
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
  RFC7515:
  RFC7516:
  RFC7517:
  RFC7518:
  RFC7519:
  RFC7638:
  RFC7748:
  RFC7800:
  RFC8037:
  RFC8174:
  RFC8725:
  RFC9110:
  RFC9421:
  RFC9457:
  RFC9901:
  I-D.ietf-oauth-sd-jwt-vc: I-D.ietf-oauth-sd-jwt-vc-18
  SP800-56A:
    title: Recommendation for Pair-Wise Key-Establishment Schemes Using Discrete Logarithm Cryptography
    author:
      - org: National Institute of Standards and Technology
    date: 2018-04
    target: https://doi.org/10.6028/NIST.SP.800-56Ar3
  OIDC-IA:
    title: OpenID Connect for Identity Assurance 1.0
    author:
      - { org: OpenID Foundation }
    date: false
    target: https://openid.net/specs/openid-connect-4-identity-assurance-1_0-final.html
  AAP-CORE:
    title: "Agent Attestation Protocol (AAP)"
    author:
      - { ins: R. Drapeau, name: Ryan Drapeau }
      - { ins: D. Pettersson, name: David Pettersson }
    date: false
    target: https://agentic-protocols.github.io/agentic-attestation-protocol/draft-agent-attestation-protocol.html
informative:
  RFC2606:
  AAP-LOCAL:
    title: "Local Agent Profiles for the Agent Attestation Protocol"
    author:
      - { ins: R. Drapeau, name: Ryan Drapeau }
      - { ins: D. Pettersson, name: David Pettersson }
    date: false
    target: https://agentic-protocols.github.io/agentic-attestation-protocol/draft-aap-local-agent.html
  RFC8414:
  RFC8628:
  RFC9396:
  RFC9577:
  I-D.meunier-http-message-signatures-directory:
  I-D.irtf-cfrg-bbs-signatures:
  OIDC:
    title: OpenID Connect Core 1.0
    author:
      - { ins: N. Sakimura, name: Nat Sakimura }
      - { ins: J. Bradley, name: John Bradley }
      - { ins: M. Jones, name: Michael B. Jones }
      - { ins: B. de Medeiros, name: Breno de Medeiros }
      - { ins: C. Mortimore, name: Chuck Mortimore }
    date: 2014
    target: https://openid.net/specs/openid-connect-core-1_0.html
  CIBA:
    title: OpenID Connect Client-Initiated Backchannel Authentication Flow - Core 1.0
    author:
      - { org: OpenID Foundation }
    date: false
    target: https://openid.net/specs/openid-client-initiated-backchannel-authentication-core-1_0.html
  OIDC-Discovery:
    title: OpenID Connect Discovery 1.0
    author:
      - { org: OpenID Foundation }
    date: false
    target: https://openid.net/specs/openid-connect-discovery-1_0.html
  XACML:
    title: eXtensible Access Control Markup Language (XACML) Version 3.0
    author:
      - { org: OASIS }
    date: 2013
    target: http://docs.oasis-open.org/xacml/3.0/xacml-3.0-core-spec-os-en.html
  OCAP:
    title: "Robust Composition: Towards a Unified Approach to Access Control and Concurrency Control"
    author:
      - { ins: M. Miller, name: Mark S. Miller }
    date: 2006
    target: https://papers.agoric.com/assets/pdf/papers/robust-composition.pdf

--- abstract

This document defines the identity claims module of the Agent Attestation Protocol (AAP). The AAP core admits an agent anonymously: the Agent Attestation Token (AAT) proves an accountable principal stands behind the agent while carrying no fact about anyone. When an interaction needs a fact about the principal — a verified email to open an account, an address to ship to, an age to clear a gate — this module supplies it: the service requests a specific claim, the principal's consent gates the disclosure, and the agent brokers the answer.

Claims travel on two lanes: a pre-provisioned, holder-presented lane the issuer is blind to, and an issuer-mediated lane that mints audience-bound claims tokens under live consent. The principal's standing disclosure policy, held at the issuer, governs both lanes and selects between them. This module layers on the AAP core and requires it.

--- middle

# Introduction {#intro}

The AAP core ({{AAP-CORE}}) makes the front door anonymous: a service admits an agent on the accountability bit alone, and the credential presented there carries no fact about the principal and no handle that resolves to one. Identity is a separate matter, needed only on the interactions that genuinely call for it. This document defines that separate matter.

When a service needs a specific fact — and only then — it asks the agent for that fact, naming what it needs and why. The agent answers on the principal's behalf in one of two ways, determined by the principal's standing policy for that fact: it presents a credential it already holds, with the issuer not contacted at all, or it fetches a freshly minted, audience-bound claims token, released under the principal's standing grant or a live approval as that policy dictates. Either way the service receives an issuer-signed fact bound to its own request — a verified claim, not a self-asserted form field, and not standing access to anything beyond what it asked for.

Because the AAT is anonymous and carries no resolvable handle, the service cannot obtain claims by calling the issuer on its own: it holds nothing the issuer can resolve to a person. The agent, which alone holds a standing relationship with the issuer, brokers every disclosure. This is a deliberate consequence of the anonymous front door: removing the resolvable handle removes the direct service-to-issuer flow, and identity moves to lanes the agent mediates.

## Scope {#scope}

This document defines: the claims-required challenge a service uses to request claims; the two disclosure lanes and their wire formats; the consent model and asynchronous approval; the principal's disclosure policy; the discovery surfaces for claims (issuer metadata members, claims capability, requester keys); and the encryption profile that keeps claim values out of the brokering agent's hands.

## Relationship to the AAP Core {#core-relationship}

This module layers on the AAP core and does not stand alone: an implementation of this document MUST implement {{AAP-CORE}}. The module uses the core's platform enrollment, linking grant, and agent key unchanged, and adds no requirement to the core's attestation layer — an AAT never carries a claim ({{AAP-CORE}}).

The module amends the core in one place. The core's linking ceremony establishes the standing grant under which agents act; because the anonymous front door leaves the issuer no later handle to attach preferences to, an issuer that offers this module MUST capture the principal's standing disclosure policy ({{disclosure-policy}}) at or before linking, at its own surfaces. This is the module amendment anticipated by the core's linking section ({{AAP-CORE}}).

An issuer MAY offer either lane of this module, both, or neither (conforming to the core alone). An issuer that offers only the pre-provisioned lane is **wallet-only**: it provisions a wallet of claims and never runs an interactive approval or an issuer-mediated disclosure. Because that lane enforces consent at minting, a wallet-only issuer serves only claims releasable under a standing grant and free of the agent-blind condition ({{policy-behavior}}); its metadata names a `credential_endpoint` and no `claims_endpoint` ({{issuer-metadata-members}}).

## Requirements Language {#requirements-language}

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 {{RFC2119}} {{RFC8174}} when, and only when, they appear in all capitals, as shown here.

## Terminology {#terminology}

The terms Principal, Agent, Agent Platform, Issuer, Verifier, Edge, Service, and AAT are used as defined in {{AAP-CORE}}. This document adds:

- Requester: a party that consumes identity claims about the principal — in this revision, the Service, since the agent brokers every claim ({{overview}}).

- Claims credential: a pre-provisioned, holder-presented credential carrying identity claims ({{pre-provisioned-disclosure}}).

- Claims token: an audience-bound credential carrying identity claims, minted per request by the issuer ({{issuer-mediated-disclosure}}).

- Disclosure policy: the principal's standing disclosure preferences, held and evaluated by the issuer ({{disclosure-policy}}).

Examples use domain names reserved by {{RFC2606}} and identifiers that are not registered assignments.

# Overview {#overview}

This section is non-normative.

A service that needs to know something about the principal (to match an account, put a name on an order, or check an age requirement) obtains exactly the claims it needs, under the principal's consent, and never from the AAT. Which claims an issuer can attest, and the shared vocabulary their names are drawn from, is defined in Claims Capability ({{claims-capability}}); a service consults it to decide what to ask for before it sends a claims-required challenge.

This document defines two lanes. The principal's disclosure policy ({{disclosure-policy}}) selects between them: a claim released under a standing grant can travel either lane, and a claim that requires approval per use, or that the agent must not see, travels the issuer-mediated lane.

- **Pre-provisioned disclosure** ({{pre-provisioned-disclosure}}): the issuer mints holder-bound credentials into the agent's wallet ahead of use; at use the agent presents a selective disclosure directly to the service, with the issuer not in the loop. Fast (no issuer call) and issuer-blind, at the cost that consent is fixed at issuance and the agent handles the values. The lane for standing facts whose handling tolerates the agent holding the value.

- **Issuer-mediated disclosure** ({{issuer-mediated-disclosure}}): the agent brokers a live call to the issuer, which reviews who is asking and why, runs the principal's approval where required, and returns a fresh audience-bound claims token the agent relays. The issuer sees the disclosure — the price paid for live consent, immediate revocation, and the ability to keep the value out of the agent's hands (the token MAY be encrypted to the service). The lane for facts whose policy requires per-use approval, an enumerated audience, or agent-blind handling.

Both lanes share one consent model ({{consent}}) and, on the issuer-mediated lane, one disclosure log. Sensitivity is a common input to the policy that selects the lane, and grouping claims into sensitivity tiers ({{sensitivity-tiers}}) is one way an issuer authors that policy; the lane-selection rule itself is in {{policy-behavior}}.

~~~ aasvg
  Agent (platform)       Issuer     Service / Verifier
        AP                 I                S
         |                 |                |
[  admission per the AAP core; verifier session established  ]
         |<~~~~~~~~~~~~~~~~+~~(1)~~~~~~~~~~~|
[   ALT: pre-provisioned lane (policy: standing grant)       ]
         |--(2)------------+--------------->|
[   ELSE: issuer-mediated lane (policy: approval or blind)   ]
         |--(3)----------->|                |
         |<~(4)~~~~~~~~~~~~|                |
         |--(5)------------+--------------->|
[                        END ALT                             ]

Legend: ----> message; ~~~~> response

Messages:
(1) S ~> AP: claims-required (aud, nonce, purpose)
(2) AP -> S: credential the agent already holds
    (issuer not contacted)
(3) AP -> I: relay signed claims request (live consent)
(4) I ~> AP: aud-bound claims token
(5) AP -> S: claims token
~~~
{: #fig-claims-overview
   title="Disclosure, only when needed: the service challenges for claims and the agent answers on the lane the principal's policy selects."
   align="center"
   artwork-alt="Sequence diagram of the pre-provisioned and issuer-mediated disclosure lanes following front-door admission." }

# Pre-Provisioned Disclosure {#pre-provisioned-disclosure}

For facts releasable under a standing disclosure grant, the issuer mints a holder-bound credential into the agent's wallet ahead of use, and the agent presents a selective disclosure of it directly to the service without contacting the issuer.

The credential is an SD-JWT-VC ({{I-D.ietf-oauth-sd-jwt-vc}}, built on SD-JWT {{RFC9901}}): an issuer-signed credential whose individual claims are selectively disclosable, bound to a holder key in its `cnf` ({{RFC7800}}). On this lane that `cnf` MUST use the `jwk` confirmation method, carrying the holder key as a JWK. The holder key MUST be an agent key the agent controls; binding it to the agent's Web Bot Auth key ({{AAP-CORE}}) is RECOMMENDED, so the same key that proves the AAT and signs requests also presents the credential. That coincidence is a convenience, not a dependency: the KB-JWT is carried whether or not the two keys are the same, so neither key is pinned to the other. Provisioning happens under the linking grant and the standing disclosure grant; the issuer mints only claims that resolve to `allow` under the principal's disclosure policy ({{disclosure-policy}}). An issuer MUST include the `exp` claim in the SD-JWT-VC; the chosen lifetime bounds how long the credential remains presentable after the principal changes their disclosure policy.

An issuer MUST include the `vct` claim SD-JWT-VC requires, and MUST NOT make it selectively disclosable. Its value names the credential type: a collision-resistant URI under the issuer's control, versioned so the type can evolve, for example `https://idp.example/credentials/aap/v1`. This revision defines no Type Metadata document for that type ({{open-items}}); `vct` is a bare type identifier. It is distinct from `claims_supported` ({{claims-capability}}): `claims_supported` is an issuer-level capability hint, not credential-type metadata.

A service signals which claims it needs with a presentation request, and the agent answers from its wallet. Each entry of `claims` is a claim reference ({{claims-capability}}). The service MUST supply an `aud` naming itself and a `nonce`; the `nonce` MUST be unpredictable, MUST be accepted only once, and MUST expire, because it is the freshness the KB-JWT binds to and this lane keeps no seen-credential cache.

~~~
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Identity-Presentation
Content-Type: application/problem+json

{
  "type": "urn:aap:claims-required",
  "aud": "https://merchant.example",
  "nonce": "v8f3Qk...",
  "claims": ["email", "email_verified"],
  "purpose": "Put a contact on the order",
  "formats": ["dc+sd-jwt"],
  "trusted_issuers": ["https://idp.example"]
}
~~~

~~~
POST /checkout HTTP/1.1
Host: merchant.example
Authorization: PrivateToken token=<base64url Token>
Identity-Presentation: <issuer-jwt>~<D:email>~<D:email_verified>~<KB-JWT>
Signature-Input: agent=("@method" "@authority" "@path" "authorization" \
  "identity-presentation" "content-digest");created=1715400100; \
  expires=1715400160;keyid="agent_kid_b64url...";tag="web-bot-auth"
Signature: agent=:<signature by the agent key>:
...
~~~
{: #fig-pre-provisioned-disclosure title="Pre-provisioned disclosure. The agent presents a selective disclosure of a wallet credential; the issuer is not contacted. <issuer-jwt> is the issuer-signed credential, <D:...> are the disclosed claims, <KB-JWT> binds the presentation to this service and nonce. The Authorization header and Web Bot Auth signature are the AAP core's admission surface." }

The presentation rides the admission surface the core defines: the `Authorization` header carries the AAT redemption ({{RFC9577}}), and the `Identity-Presentation` field travels beside it. The request's Web Bot Auth signature ({{RFC9421}}) MUST cover the `Identity-Presentation` field when the request carries one, so the presentation cannot be lifted into a different signed request. This extends the core's minimum signature coverage ({{AAP-CORE}}), which admits additional covered fields.

The service MUST verify all of the following, with no issuer call, failing closed at the first failure: (1) the issuer signature over the credential, under the issuer's published keys ({{claims-keys}}); (2) that the credential carries an `exp` claim and that the current time is before `exp`; (3) each disclosed claim's digest against the credential's `_sd` set; (4) the key-binding proof, following the steps of Section 7.3 of {{RFC9901}}: a KB-JWT is present as the final tilde-separated component, its `typ` is `kb+jwt`, its `alg` is one the verifier accepts and is not `none`, its signature verifies under the key in the credential's `cnf.jwk`, its `aud` and `nonce` match the challenge, its `iat` is within a window the verifier accepts, and its `sd_hash` equals the value the verifier recomputes over the presentation as received. AAP tightens two of those steps: the `aud` comparison is an exact string match, and a `nonce` is accepted only once. The `sd_hash` comparison is what binds the disclosed set; without it the other checks admit a set the holder never committed to.

The agent serializes the presentation as the SD-JWT+KB serialization of Section 4 of {{RFC9901}} — the issuer-signed JWT, a tilde, each selected disclosure followed by a tilde, then the key-binding JWT — and MUST include that KB-JWT, with the header parameters and payload claims Section 4.3 of {{RFC9901}} requires, secured by the key in the credential's `cnf` (Section 2.2.2.3 of {{I-D.ietf-oauth-sd-jwt-vc}}). The `sd_hash` is computed as Section 4.3.1 of {{RFC9901}} specifies: over the US-ASCII bytes of the serialization up to and including the tilde preceding the KB-JWT, under the hash algorithm the credential's `_sd_alg` names, or `sha-256` where it is absent. An agent MUST forward each disclosure exactly as the issuer produced it, since a re-encoded disclosure no longer matches its digest.

Key binding is a matter of verifier policy in SD-JWT (Section 4.3.2 of {{RFC9901}}); AAP fixes it for this lane, so the key-binding check above is unconditional and a stripped KB-JWT cannot downgrade the presentation to a bare SD-JWT (Section 9.5 of {{RFC9901}}). The request's Web Bot Auth signature is not a substitute: it binds transport, not the disclosed set, which a bare SD-JWT's can be added to or removed from and still verify (Section 9.10 of {{RFC9901}}). A deployment that treats it as the key-binding proof by private agreement is outside this profile.

The trade is explicit: the issuer is not in the loop, so the disclosure is unlinkable to it, but consent was decided when the credential was minted (the standing disclosure grant), revocation reaches only as far as the credential's `exp`, and the agent necessarily holds the claim values. Accordingly, this lane suits facts whose handling tolerates issuance-time consent and the agent holding the value — an issuer's lighter tiers ({{sensitivity-tiers}}). An issuer MUST NOT provision on this lane a claim that requires per-use approval, an enumerated audience, or agent-blind handling ({{policy-behavior}}).

The security and privacy consequences of delegating use-time disclosure decisions to the agent are discussed in {{security}} and {{privacy}}.

Revocation on this lane is expiry plus re-issuance: no status list or other post-issuance status mechanism is defined, and a minted credential remains presentable until its `exp`. An issuer SHOULD keep credential lifetimes short. An agent SHOULD provision credentials in small pools ahead of use and SHOULD present each credential at most once, discarding it after presentation, as it does AATs ({{AAP-CORE}}); single-use presentation keeps two presentations from being matched through the credential ({{privacy}}). Single-use is agent-side discipline, not a verified property: a service maintains no seen-credential cache on this lane.

The agent re-provisions credentials before they expire, under the standing linking and disclosure grants, as it refills the AAT pool ({{AAP-CORE}}). Because the issuer re-evaluates the current disclosure policy at each provisioning, a policy change takes effect at the next refresh; the credential's `exp` therefore bounds how long a superseded policy can still be presented.

# Issuer-Mediated Disclosure {#issuer-mediated-disclosure}

For a fact the principal's policy does not release under a standing grant, or that the agent must not see, the agent brokers a live call to the issuer. The issuer reviews who is asking and why, applies the standing disclosure grant or obtains the principal's interactive approval ({{consent}}, {{asynchronous-approval}}), and returns an audience-bound claims token that the agent relays to the service. The agent is a courier: it cannot forge or alter the token, and where the issuer encrypts the token to the service the agent cannot read it.

~~~ aasvg
   Service            Agent         Issuer (IDP)       Principal
      S                 A                 I               PR
      |                 |                 |                |
      |--(1)----------->|                 |                |
      |                 |--(2)----------->|                |
      |                 |                 |--(3)--+        |
      |                 |                 |<------+        |
[                     OPT: beyond standing grant                    ]
      |                 |                 |--(4)---------->|
      |                 |                 |<-(5)-----------|
[                              END OPT                              ]
      |                 |<~(6)~~~~~~~~~~~~|                |
      |<-(7)------------|                 |                |
      |--(8)--+         |                 |                |
      |<------+         |                 |                |

Legend: ----> message; ~~~~> response; +--+ self-call

Messages:
(1) S -> A: need {address}; aud=Service; nonce=N; purpose=P
(2) A -> I: relay service's signed challenge:
    claims, aud=Service, nonce=N, purpose=P
(3) I -> I: verify challenge signature; review;
    check standing grant
(4) I -> PR: approve disclosure to Service?
(5) PR -> I: approve
(6) I ~> A: claims token (aud=Service, nonce=N;
    MAY be encrypted, MUST if agent-blind)
(7) A -> S: relay claims token
(8) S -> S: decrypt (if encrypted);
    verify issuer sig + aud==self + nonce
~~~
{: #fig-issuer-mediated-disclosure
   title="Issuer-mediated disclosure. The agent brokers; the issuer decides and signs; the binding (aud, nonce) makes the courier untrustworthy but harmless. The issuer sees the disclosure, which is what lets it enforce consent live, log it, and revoke."
   align="center"
   artwork-alt="Sequence diagram in which a service requests claims, the issuer optionally obtains principal approval, and the agent relays an audience-bound claims token." }

The service signals its need exactly as in the pre-provisioned lane (`urn:aap:claims-required`), and additionally MUST supply a `nonce`, SHOULD supply a `purpose`, and MUST sign the challenge with a key resolvable from its `aud` origin ({{requester-keys}}) — because the agent relays these fields to the issuer, and the issuer MUST NOT take the requester's identity, audience, or purpose on the agent's say-so. The agent calls the issuer's claims endpoint ({{issuer-metadata-members}}) authenticating under the linking grant and relays the service's signed challenge verbatim. The issuer MUST, failing closed at the first failure:

1. Authenticate the agent under an active linking grant and resolve the principal and their disclosure policy ({{disclosure-policy}}). (There is no `session_id`; the linking grant is what identifies the principal here.)

2. Verify the service's signature over the relayed challenge and that the signing key resolves from the named `aud`, so the `aud`, `nonce`, `claims`, and `purpose` are the service's own and not the agent's. A challenge that does not verify is rejected.

3. Resolve the principal's disclosure policy for each requested claim and the named `aud` ({{disclosure-policy}}): on `allow`, release the claim; on `ask`, obtain interactive approval ({{consent}}, {{asynchronous-approval}}) and release the claim only on approval; on `deny`, withhold it.

4. Return the outcome the released set selects (below). Where that outcome is a claims token, mint it bound to `aud` and `nonce` and sign it with a key from the issuer's published set. The issuer MAY encrypt the token to the service's public key so the relaying agent cannot read the values, and MUST do so where the agent-blind condition applies ({{policy-behavior}}); the resolution and JWE profile are in {{claims-encryption}}.

A requested claim is **released** when the issuer can attest it, holds a value for this principal, and the policy resolved to `allow` or to an approved `ask`. Otherwise it is **withheld**. The released set alone selects the response, following the best-effort subset semantics of OIDC UserInfo ({{OIDC}}, Section 5.3.2), under which a claim the issuer does not return is absent and its absence is not an error:

- **Something released.** The issuer MUST return a claims token carrying exactly the released claims. A withheld claim MUST be absent from the token rather than null or empty, and the response MUST NOT indicate which claims were withheld or why.
- **Nothing released, every claim withheld for a consent reason** (`deny`, or an approval the principal declined). The issuer MUST fail closed with `urn:aap:consent-required`, or with `urn:aap:approval-denied` where the request went through an approval step ({{asynchronous-approval}}).
- **Nothing released, at least one claim withheld for a non-consent reason** (the issuer cannot attest the claim, or holds no value for this principal). The issuer MUST return a claims token carrying none of the requested claims.

Uniform omission is what keeps a claims response from becoming a per-principal probe: from a token the service cannot tell cannot-attest, no-value, denied, and declined apart. Which claim types an issuer can attest at all is an issuer-level property, not a fact about the principal, and a service can read it from `claims_supported` ({{claims-capability}}) before it challenges.

The claims token is a signed JWT (`typ` `aap-claims+jwt`) whose `aud` is single-valued and equals the service, with a `nonce` matching the challenge and a short `exp`:

~~~
{
  "iss": "https://idp.example",
  "aud": "https://merchant.example",
  "iat": 1715400100,
  "exp": 1715400400,
  "nonce": "v8f3Qk...",
  "address": { "country": "CA", "postal_code": "..." }
}
~~~
{: #fig-claims-token title="A claims token (decoded). Audience- and nonce-bound; carries no resolvable session handle. A copy that escapes carries its uselessness with it: it is inert to any party but the named aud." }

The service MUST verify the issuer signature, `aud` equal to itself, the `nonce` matches its challenge, and the validity window, failing closed at the first failure. A valid token can carry fewer claims than were requested, or none of them; the service compares the returned claims against its requirements and decides whether to proceed, re-challenge, or refuse. For claims that require evidence of how they were verified, the issuer MAY return the `verified_claims` structure of {{OIDC-IA}}. There is no direct service-to-issuer variant of this lane: the service has no handle to present, so the agent's brokering is not optional but structural.

# Consent {#consent}

Consent is enforced at disclosure, and every disclosure MUST be covered by the principal's disclosure policy ({{disclosure-policy}}), which resolves each request to `allow` (a standing disclosure grant, released without contacting the principal), `ask` (interactive approval at request time), or `deny`. On the pre-provisioned lane the policy is enforced at minting (the issuer mints only claims that resolve to `allow`); on the issuer-mediated lane it is enforced per request. The wildcard bound on what may be released under a standing grant, and the agent-attenuation and agent-blind constraints, are defined in {{disclosure-policy}}.

An interactive approval is obtained at request time on the issuer-mediated lane: before disclosing, the issuer MUST present to the principal the requester's identity, the specific claims, and the stated `purpose`, and MUST disclose only on approval. The pre-provisioned lane cannot obtain interactive approval at use (the issuer is not in the loop), which is the structural reason it is confined to claims releasable under a standing grant.

The issuer is the disclosure chokepoint for the issuer-mediated lane and logs every request there: the requester, the claims requested and released, the basis (standing grant or approval), and when. Denied and parked requests belong in the log as much as granted ones. The issuer MUST honor revocation immediately on this lane: the principal withdraws a grant and subsequent requests fail closed. On the pre-provisioned lane the issuer's visibility ends at minting, so the principal's lever there is the credential's mandatory `exp` ({{pre-provisioned-disclosure}}): a withdrawn grant stops re-issuance, and outstanding credentials lapse at expiry. This asymmetry is the cost of that lane's issuer-blindness and MUST be disclosed to the principal when the lane is used for a claim.

Because the pre-provisioned lane leaves the issuer with no record past minting, an issuer MAY offer a **usage report** on that lane: after a disclosure, the agent reports to the issuer's `usage_report_endpoint` ({{issuer-metadata-members}}) which claims it presented (by claim reference, {{claims-capability}}), to which audience (by origin), for what stated `purpose`, and when. A report MUST carry only those fields. The agent MUST NOT send a report unless the principal has opted in and an active linking grant ({{AAP-CORE}}) stands. The report is self-asserted and unverifiable: a compromised or adversarial agent can omit, delay, or falsify it, and reporting does not reduce the agent's access to the disclosed value. It is a compensating control for the lane's minting-only visibility, not a guarantee, and it does not replace keeping the value out of the agent's hands; encryption to the service on the issuer-mediated lane ({{issuer-mediated-disclosure}}) remains the only structural control on agent onward-use. Reporting reintroduces the issuer-side correlation the pre-provisioned lane is designed to avoid ({{privacy}}); at opt-in the issuer MUST disclose to the principal that reporting converts the lane from issuer-blind to issuer-visible for the claims it covers.

# Asynchronous Approval {#asynchronous-approval}

Interactive approval does not resolve at request time: the principal approves on their own device, on their own schedule. On the issuer-mediated lane, a claims request awaiting approval cannot be answered synchronously, so the issuer answers with a pending state and the agent collects the result later. The mechanics follow the Device Authorization Grant polling state machine ({{RFC8628}}) and the backchannel modes of {{CIBA}}.

When a request requires approval, the issuer responds with Problem Details ({{RFC9457}}) type `urn:aap:approval-pending`, carrying `request_id` (a handle for this approval, distinct per outstanding approval), `interval` (seconds between polls), and `expires_in` (the approval window). Completion reaches the agent by polling (the agent re-submits with `request_id` on the interval; `slow-down` throttles; approval returns the claims token, denial `urn:aap:approval-denied`, a lapsed window `urn:aap:approval-expired`) or, for an agent that registered a notification endpoint, by a ping that signals the agent to collect. The vocabulary mirrors {{RFC8628}} and {{CIBA}} so existing implementations translate directly.

A request in which some claims resolve to `allow` and others to `ask` is answered as a whole. The issuer MUST hold the response until every outstanding approval resolves, then select the outcome from the released set ({{issuer-mediated-disclosure}}), counting an approved `ask` claim as released and a declined one as withheld. `urn:aap:approval-denied` reports that the request released nothing because the principal refused; a refusal of some claims but not others is reported by omission, not by error.

TODO: handling of an approval that resolves after the service's challenge `nonce` or the agent's linking-grant context has gone stale, and which outcome ({{issuer-mediated-disclosure}}) the issuer returns in that case.

# Disclosure Policy {#disclosure-policy}

A principal's consent to identity disclosure ({{consent}}) is governed by a **disclosure policy**: the principal's standing preferences, established at the issuer (at or before linking, {{core-relationship}}, and at the issuer's own surfaces), that the issuer evaluates to decide how a claim request is handled. Because the AAT carries no resolvable handle, the issuer cannot be handed a session to attach consent to at request time; the policy is therefore the issuer's authoritative record of those preferences, and every disclosure on either lane MUST be covered by it ({{consent}}). Its shape is fine-grained, per-recipient authorization under per-claim consent, in the manner of OAuth Rich Authorization Requests ({{RFC9396}}) and OpenID Connect consent ({{OIDC}}).

This section separates the behavior a conforming issuer MUST exhibit ({{policy-behavior}}, normative) from the optional sensitivity-tier grouping ({{sensitivity-tiers}}) and one representation and evaluation procedure ({{policy-resolution}}) that satisfy it, both informative. The policy is held and evaluated entirely by the issuer and is not carried on the wire or parsed by any other party, so its representation is not an interoperability concern and does not bind; how an issuer evaluates it, however, MUST satisfy the constraints below.

## Policy Behavior and Constraints {#policy-behavior}

For each claim a requester asks for, the issuer reaches a disclosure decision from three inputs: the **claim**, the **requesting audience** (the service, by origin), and the **brokering agent platform** (identified by the linking grant the claims call or minting authenticates under, {{AAP-CORE}}). The decision is exactly one of three outcomes:

- `allow` — the issuer discloses without contacting the principal; this is the standing disclosure grant of {{consent}}. On the pre-provisioned lane it is enforced at minting (the issuer mints only `allow` claims, {{pre-provisioned-disclosure}}); on the issuer-mediated lane the issuer releases the claim without an approval step.
- `ask` — the issuer MUST obtain the principal's interactive approval before disclosing ({{consent}}, {{asynchronous-approval}}). Because the pre-provisioned lane cannot prompt at use, a claim whose decision can be `ask` for a given audience MUST be served on the issuer-mediated lane for that audience, and MUST NOT be minted into a pre-provisioned credential for it.
- `deny` — the issuer MUST withhold the claim, and MUST fail closed where the request releases nothing ({{issuer-mediated-disclosure}}).

A conforming issuer MUST observe the following, however it represents and evaluates the policy:

- **Privacy-forward by default.** Silent disclosure is the exception a principal grants, not the baseline. An issuer SHOULD reach `allow` only through an explicit element of the principal's policy, and SHOULD default an otherwise-unspecified claim to `ask`, and to `deny` for its more sensitive claims — those it would release only under per-use approval and an enumerated audience ({{sensitivity-tiers}}; evidence-bearing claims additionally carry assurance per {{OIDC-IA}}). A claim the principal has not addressed MUST resolve to `deny`. This includes predicate (boolean) claims, which an issuer MUST NOT silently `allow` absent an explicit grant.
- **Wildcard bound on sensitive claims.** An issuer MUST NOT `allow` under a wildcard (any-authenticated-audience) grant any claim whose handling requires the issuer-mediated lane, per-use approval, or an enumerated audience; such a claim requires an enumerated audience or interactive approval. A wildcard `allow` is permitted only for claims releasable under a standing grant on the pre-provisioned lane, where agent visibility and issuance-time consent are acceptable ({{sensitivity-tiers}}). The issuer MUST enforce this bound when the policy is set.
- **Agent attenuation.** A preference scoped to a specific brokering agent platform MAY only restrict, never widen. The outcome for a request brokered by a given agent MUST NOT be more permissive than the outcome that would apply to the same `(claim, audience)` absent any agent-specific preference. An agent-scoped preference can turn `allow` into `ask` or `deny`; it MUST NOT turn `deny` or `ask` into `allow`. The agent is a delegate, and a delegate cannot enlarge the principal's policy — the attenuation property of the object-capability model ({{OCAP}}).
- **Purpose is not an input to the decision.** The `purpose` a requester states on its `urn:aap:claims-required` challenge is a free-form, verifier-supplied string with no controlled vocabulary; two verifiers word the same intent differently, and a verifier can phrase a purpose to fit whatever grant is most permissive. An issuer MUST NOT resolve a disclosure outcome from the stated `purpose`, and SHOULD surface it to the principal at an `ask` so it informs the human decision.
- **Retention is out of scope.** Once a claim is disclosed it MUST be treated as disclosed; the policy governs whether to disclose and places no enforceable obligation on what happens afterward — neither on the requester nor on the brokering agent, which is an unconstrained holder of any value it can read (see the agent-blind condition below and {{security}}).
- **Lane selection.** The policy, not the claim, selects the lane. A claim is eligible for the pre-provisioned lane only where its decision for the audience is `allow` and no agent-blind condition attaches; otherwise it is served on the issuer-mediated lane (the `ask` rule above and the disclosure-conditions rule below). An issuer that offers both lanes SHOULD serve a claim on the most issuer-blind lane its policy for that claim permits.
- **Evaluation point.** An issuer MUST reach the decision at the point its lane enforces consent: at minting for the pre-provisioned lane, per request for the issuer-mediated lane ({{consent}}).
- **Revocation.** An issuer MUST honor a change to the policy immediately on the issuer-mediated lane; on the pre-provisioned lane the principal's only lever is the credential's mandatory `exp` ({{pre-provisioned-disclosure}}), and this asymmetry MUST be disclosed to the principal when that lane is used for a claim ({{consent}}).
- **No silent upgrade of sensitive claims.** An issuer MUST NOT promote a claim it handles on the issuer-mediated lane to `allow` without explicit principal agreement; a remembered approval ({{policy-resolution}}) for such a claim requires the principal's agreement at approval time, not an inference from prior use.
- **Disclosure conditions (agent-blind).** The principal's policy MAY attach a condition (an Obligation in the sense of {{XACML}}) to an `allow` or `ask` outcome that constrains *how* a claim is disclosed, not just whether. This revision defines one: **agent-blind**, which requires the claim be disclosed only on the issuer-mediated lane with the claims token encrypted to the requesting audience ({{issuer-mediated-disclosure}}, {{requester-keys}}), so the brokering agent relays ciphertext and never sees the value. A claim carrying the agent-blind condition MUST NOT be served on the pre-provisioned lane (where the agent holds the value), and MUST NOT be disclosed to an audience for which the issuer cannot obtain an encryption key. A condition, once attached, MUST be discharged or the disclosure MUST NOT occur: where it cannot be satisfied the issuer MUST fail closed rather than disclose without it. An issuer SHOULD attach agent-blind by default when it releases one of its more sensitive claims — one it handles on the issuer-mediated lane — to an enumerated audience. Consistent with agent attenuation, an agent-scoped preference MAY add the agent-blind condition (a tightening) but MUST NOT remove one set at the audience layer.

## Sensitivity Tiers {#sensitivity-tiers}

The policy above is defined per claim, but authoring a rule for every claim an issuer can attest, and asking a principal to weigh in on each, is often more granularity than either needs. A **sensitivity tier** is an optional grouping an issuer offers so policy can be set, and choices put to the principal, a few buckets at a time — "release basic profile facts freely, ask me before anything sensitive, never release regulated data without a prompt" — rather than claim by claim. A tier is a convenience for authoring policy and framing consent, not a classification this protocol requires: an issuer MAY group some, all, or none of its claims, MAY define as many or as few tiers as it likes, and MAY still write per-claim rules over and alongside them. In the representation below a tier is just a claim-class node a rule or default attaches to ({{policy-resolution}}).

The protocol fixes no tier set. What it fixes is what each disclosure lane guarantees and the consent each requires ({{pre-provisioned-disclosure}}, {{issuer-mediated-disclosure}}, {{policy-behavior}}), so those constraints hold whether an issuer reasons about a claim through a tier or on its own. A tiering tends to track the lanes' reversing trade: the pre-provisioned lane is private from the issuer but exposes the value to the agent and fixes consent at issuance, while the issuer-mediated lane exposes the disclosure to the issuer but keeps the value from the agent and gives per-use consent. More sensitive facts therefore tend to sit in tiers that route to the issuer-mediated lane under tighter consent.

An issuer MAY adopt this common framing as a starting point; the bands are illustrative, not normative categories, and an issuer is free to merge, split, rename, or ignore them:

| Example tier     | Claim characteristics                                                                                              | Usual handling                                                      |
| ---------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------- |
| Low-sensitivity  | low disclosure harm, routinely requested, acceptable for the agent to hold and to release broadly                  | pre-provisioned, standing grant, wildcard audience                  |
| High-sensitivity | identifying or personal facts the principal wants released only to known recipients and with awareness of each use | issuer-mediated, per-use approval, enumerated audience, agent-blind |
| Regulated        | claims carrying legal or compliance weight, or requiring verified evidence and point-in-time assurance             | issuer-mediated, per-use approval, evidence-bearing                 |

## Policy Representation and Resolution {#policy-resolution}

This section is informative. It gives one representation and evaluation procedure that satisfies {{policy-behavior}}; an issuer MAY use any other that yields the same outcomes.

Represent the policy as a set of tier defaults plus a sparse, ordered set of rules. A rule selects over three dimensions, and a rule omitting a dimension matches any value of it (a wildcard):

- `claim` — a claim reference ({{claims-capability}}) or a claim-class node (e.g. a sensitivity tier, {{sensitivity-tiers}}). A rule on a claim matches any path into it, and a rule on a more specific path is more specific in ranking; attenuation ({{policy-behavior}}) applies unchanged.
- `audience` — the requesting service, by origin; a rule MAY match a parent domain so that subdomains inherit it.
- `agent` — the brokering agent platform. Evaluable on both lanes, since minting and the claims call both authenticate under a linking grant.

A rule with an `allow` or `ask` outcome MAY also carry an `agent_blind` condition. It does not affect matching or the outcome; it is an obligation on the disclosure, requiring the issuer-mediated, encrypted-to-audience channel ({{policy-behavior}}).

The `audience` and `agent` dimensions are kept separate because they are different parties answering different questions: the audience is the recipient the claim flows *to* ("do I trust this service with this data"), and the agent is the delegate the request flows *through* ("do I trust this platform to act unattended on my behalf"). They are orthogonal, and the attenuation constraint applies only to the agent dimension. With a single linked platform the `agent` dimension is simply always-wildcard and the model collapses to `claim` x `audience`.

Resolve a request `(claim, audience, agent)` as follows:

1. **Match and rank.** Select every rule whose dimensions all match the request. Rank matches by specificity: an exact dimension is more specific than a parent-node match, which is more specific than an omitted (wildcard) dimension.
2. **Resolve each layer.** The audience layer (rules with no `agent`) resolves to `S`: its most specific matching rule, or the claim's tier default if none matches. The agent layer (rules naming this `agent`) resolves to `A`: its most specific matching rule, or unconstrained (`allow`) if none matches. Where two equally specific rules in a layer disagree, take the safer outcome under the order `deny > ask > allow` (a deny-overrides combining algorithm, {{XACML}}).
3. **Attenuate.** The effective outcome is `meet(S, A)` under `allow ⊐ ask ⊐ deny`. Because `S` falls back to the tier default and `A` to `allow`, the agent layer can only restrict the audience-or-tier baseline, never widen it ({{policy-behavior}}); when neither layer has a matching rule the result is the tier default.

The example below is a granular policy that exercises all three dimensions:

~~~ json
{
  "defaults": { "predicate": "ask", "low": "ask", "high": "deny",
                "regulated": "deny", "unknown": "deny" },
  "rules": [
    { "claim": "email_verified", "audience": "*",                 "outcome": "allow" },
    { "claim": "email",          "audience": "*.bigco.example",   "outcome": "allow" },
    { "claim": "email",          "audience": "*",                 "outcome": "ask"   },
    { "claim": "address",        "audience": "checkout.bigco.example",
      "outcome": "allow", "agent_blind": true },
    { "claim": "address",        "audience": "*",                 "outcome": "ask"   },
    { "claim": "address",        "agent": "platform:unverified",  "outcome": "deny"  }
  ]
}
~~~

Evaluating `(claim=email, audience=cart.bigco.example, agent=platform:acme)`: the second rule matches by parent-domain and is most specific, so `S = allow`; no agent-layer rule matches, so `A` is unconstrained (`allow`) and `meet(allow, allow) = allow`. The same claim for `audience=news.example` matches only the third rule, `ask`. And `(claim=address, agent=platform:unverified)` resolves `S = ask` and `A = deny`, so `meet(ask, deny) = deny`. The `address` rule for `checkout.bigco.example` shows the obligation: address is released to that one enumerated audience, but only issuer-mediated and encrypted to it, so the agent carries ciphertext and never sees the value.

The model degrades gracefully. An issuer MAY omit the `agent` dimension (applying every decision to all agents), the `audience` dimension (applying it to all services), or both, keeping the policy at the level of the claim or its sensitivity tier. The omitted dimensions resolve as wildcards, so such an issuer still conforms; it simply cannot express agent- or domain-specific distinctions. A coarse policy that exposes only a per-claim choice and leans on tier defaults for the rest:

~~~ json
{
  "defaults": { "predicate": "ask", "low": "ask", "high": "deny",
                "regulated": "deny", "unknown": "deny" },
  "rules": [
    { "claim": "email_verified", "outcome": "allow" },
    { "claim": "org.iso.18013.5.1.age_over_21", "outcome": "allow" }
  ]
}
~~~

Here `email_verified` and the age predicate are released to any service through any agent, and every other claim falls to its tier default: the lighter tiers prompt, the sensitive and regulated tiers are denied. There are no per-domain or per-agent rules to evaluate, and the wildcard bound is respected because only claims the issuer releases under a standing grant are exposed to a wildcard ({{policy-behavior}}).

**Remembering an approval (trust-on-first-use).** When an `ask` is approved, the issuer MAY, with the principal's agreement, persist a new more-specific `allow` rule scoped to that `(claim, audience, agent)` with a stated duration, so the same request is not re-prompted. The issuer SHOULD offer a remember-scope at approval ("this time", a bounded window, or until revoked) and SHOULD expire rules for audiences the principal has not transacted with for a long interval, to keep the policy small. The issuer MAY also present, alongside the per-audience option, an option to broaden the audience to a wildcard covering all domains — turning the approval into a standing `allow` for the claim everywhere; an issuer offering this MUST still honor the wildcard bound, so it is available only for claims releasable under a standing grant. Claims the issuer handles on the issuer-mediated lane are not auto-remembered and are never offered a wildcard scope ({{policy-behavior}}).

# Non-Adopting Verifiers {#non-adopting-verifiers}

Both lanes above assume the verifier participates: the pre-provisioned lane answers a `urn:aap:claims-required` challenge and binds its presentation to the verifier's `aud` and `nonce` ({{pre-provisioned-disclosure}}); the issuer-mediated lane returns a token bound to that same `aud` ({{issuer-mediated-disclosure}}). A site that has adopted none of this issues no challenge, so there is no audience to bind to, no `nonce` for freshness, no public key to encrypt to, and no request-time scope for consent. This module therefore provides no guarantee about a disclosure to a verifier that does not participate in it: audience binding, freshness, and consent scoping are properties the verifier's challenge confers, and absent the challenge they are simply absent.

An agent nonetheless needs this case. Acting in a browser, it may have to supply an identity value to a site that has not adopted AAP — typing an email or address into a web form, say — where the site is not a verifier, has sent no challenge, receives only a bare value, and may not even know an agent produced it. This module supports this as an explicit, lower-assurance path. Because no challenge was made, the agent is not answering a request; it decides on its own to release a claim value for unbound use, reading it from a pre-provisioned credential it already holds or, for a value it has not received, requesting release from the issuer as it would provision one ({{pre-provisioned-disclosure}}).

Such a release is subject to the following:

- It is an agent-held disclosure and is covered by the principal's disclosure policy like any other ({{consent}}, {{policy-behavior}}); it is confined to claims whose handling tolerates the agent holding the value.
- The issuer MUST NOT release a claim carrying the agent-blind condition for this use ({{policy-behavior}}): agent-blind requires the value be encrypted to a requesting audience so the agent never sees it, and here there is no audience and the agent must read the value to enter it.
- Where the release resolves to `ask`, the issuer MUST present to the principal that the agent is requesting the value for its own use — no site has challenged for it, and the agent will hold and enter it — so the principal grants a release to the agent, not a disclosure to a verifier.

The value the site receives is unauthenticated and unbound: it carries none of the issuer-signature, digest, and key-binding checks a participating verifier runs ({{pre-provisioned-disclosure}}), the site cannot tell it from a value the agent supplied on its own, and a value captured by one site can be replayed to another. Once released, the value is in the agent's hands, and this module places no control on what the agent does with it afterward ({{policy-behavior}}).

# Discovery {#discovery}

The claims module adds two discovery surfaces to the core's. The issuer's metadata document ({{AAP-CORE}}) gains the claims endpoints, keys, and capability advertisement ({{issuer-metadata-members}}, {{claims-capability}}). The one other publisher is a service on the issuer-mediated lane: it publishes a keyset, never endpoints (nothing calls the service for claims; the agent relays to it); the issuer resolves that keyset to authenticate the service's signed challenge ({{requester-keys}}) and to encrypt a claims token to it ({{claims-encryption}}).

## Issuer Metadata Members {#issuer-metadata-members}

This module registers the following members of the issuer metadata document defined by {{AAP-CORE}}. An issuer that offers this module includes the members for the lanes it offers:

~~~ json
{
  "issuer": "https://idp.example",
  "token_issuance_endpoint": "https://idp.example/aap-issuer/issue",
  "token_keys": "https://idp.example/.well-known/aap-issuer/token-keys",
  "claims_jwks_uri": "https://idp.example/.well-known/aap-issuer/jwks.json",
  "claims_endpoint": "https://idp.example/aap-issuer/claims",
  "credential_endpoint": "https://idp.example/aap-issuer/credential",
  "usage_report_endpoint": "https://idp.example/aap-issuer/usage-report",

  "claims_supported": ["email", "email_verified", "given_name", "family_name",
                       "address", "org.iso.18013.5.1.age_over_21",
                       "https://idp.example/claims/loyalty_tier"]
}
~~~

| Member | Meaning |
|---|---|
| `claims_jwks_uri` | The issuer's JWS keys for signing claims tokens and pre-provisioned credentials ({{claims-keys}}). REQUIRED if any claims lane is offered. |
| `claims_endpoint` | The issuer-mediated lane endpoint ({{issuer-mediated-disclosure}}). REQUIRED if that lane is offered. |
| `credential_endpoint` | Where the agent provisions wallet credentials ({{pre-provisioned-disclosure}}). REQUIRED if that lane is offered. |
| `usage_report_endpoint` | Where the agent sends the pre-provisioned-lane usage report ({{consent}}). OPTIONAL; present only if the issuer offers reporting. |
| `claims_supported` | Array of claim identifiers the issuer can attest ({{claims-capability}}). OPTIONAL; RECOMMENDED once any claims lane is offered. A non-binding hint; the claims-required challenge and its response are authoritative. |

The members inherit the fetch and integrity rules of the metadata document itself ({{AAP-CORE}}): same-origin as `issuer`, HTTPS, no cross-origin redirects, no IP-literal hosts. Which lanes an issuer offers is read from which endpoints are present; a wallet-only issuer ({{core-relationship}}) names a `credential_endpoint` and no `claims_endpoint`.

### Claims Keys {#claims-keys}

The `claims_jwks_uri` names the issuer's JWS keys for claims tokens and pre-provisioned credentials. They rotate additively, as the core's token keys do ({{AAP-CORE}}): the issuer publishes a successor before using it and retires a predecessor after a grace period longer than the longest outstanding artifact; for pre-provisioned credentials, the longest outstanding artifact is bounded by the credential `exp` ({{pre-provisioned-disclosure}}). Consumers MUST fetch keys over HTTPS from the named host and MUST NOT follow cross-origin redirects or resolve IP-literal URLs.

JWS-based artifacts in this module ({{RFC7515}}) — the issuer's claims tokens (JWTs, {{RFC7519}}) and pre-provisioned credentials, and the holder key-binding JWTs the agent presents against them — use EdDSA with Ed25519 ({{RFC8037}}) as the mandatory-to-implement signature algorithm; ECDSA with P-256 (ES256, {{RFC7518}}) MAY also be used.

## Claims Capability {#claims-capability}

A service decides which claims it can obtain about a principal before it sends a claims-required challenge. The issuer advertises this at the issuer level in its metadata document: the set of claims it can attest. The advertisement is capability only and carries nothing about any individual principal: an issuer MUST NOT expose, through discovery, which claims a specific principal holds, any per-principal value, or any handle that resolves to a person. This preserves the anonymous front door ({{AAP-CORE}}) at the discovery layer, and is why capability lives in a static, cacheable document rather than behind a per-principal call.

`claims_supported` is a non-binding hint, as in its OpenID Connect Discovery namesake. In OpenID Connect Discovery 1.0 ({{OIDC-Discovery}}, Section 3), `claims_supported` lists the claims a provider "MAY be able to supply values for" and "might not be an exhaustive list", because OIDC resolves what is actually available at runtime through the per-principal UserInfo endpoint ({{OIDC}}, Section 5.3). AAP has no such per-principal probe by design — discovery MUST NOT reveal anything about an individual principal — so a service cannot confirm a claim ahead of time; it learns what is disclosed only from the response to its claims-required challenge. This module aligns that response with the same best-effort subset semantics ({{issuer-mediated-disclosure}}): consented and attestable claims are present, the rest are omitted, and omission is not an error; the service compares what it receives against its requirements. `claims_supported` therefore lets a service avoid requesting a claim the issuer plainly cannot attest, but it is advisory: the issuer SHOULD keep it current, a service SHOULD NOT treat a listed claim as guaranteed or an absent one as forbidden, and the challenge and its response remain authoritative. Whether a given principal has a value for a listed claim is in any case resolved per request at disclosure, under the principal's disclosure policy ({{disclosure-policy}}), and never exposed through discovery.

Because the list is advisory, a service MAY request a claim that does not appear in `claims_supported` when it has learned of the issuer's capability out of band — through a bilateral agreement, partner onboarding, or published documentation. The claims-required challenge carries the request and the issuer's response is authoritative: the issuer attests the claim or it does not, exactly as for an advertised one. Advertisement is therefore an optimization that lets a service skip claims an issuer plainly cannot attest, not a precondition for requesting a claim.

Lane and format are not advertised per claim: which lane a claim arrives on, and therefore its wire format, depends on the principal's provisioning and the disclosure policy ({{disclosure-policy}}), while which lanes the issuer offers at all is already visible from the presence of `credential_endpoint` and `claims_endpoint` ({{issuer-metadata-members}}). A service constrains the formats it accepts in its claims-required challenge.

### Claim Vocabulary and References {#claim-vocabulary}

Claim identifiers come from a shared vocabulary so that "what this issuer can attest" means the same thing across issuers and to every service, with the following order of preference:

1. **OpenID Connect standard claims** are the primary source. A claim defined as an OpenID Connect standard claim ({{OIDC}}, Section 5.1), which is also registered in the IANA "JSON Web Token Claims" registry, MUST be named by that registered name (`email`, `email_verified`, `given_name`, `family_name`, `address`, `birthdate`).
2. **Verified-identity claims** use the OpenID Connect for Identity Assurance set (`place_of_birth`, `nationalities`, and similar), likewise IANA-registered.
3. **A claim with no registered OIDC name** SHOULD reuse the established identifier from the ecosystem that defines it, qualified by enough of its defining scope to be unambiguous: the ISO mDL age predicate is the element `age_over_21` in the mdoc namespace `org.iso.18013.5.1`, written here as `org.iso.18013.5.1.age_over_21`. Where no established identifier exists, the claim MUST use a collision-resistant name — a URI under the issuer's own domain (for example `https://idp.example/claims/loyalty_tier`) — per {{RFC7519}}.

This module does not mint its own identifier for a claim that already has a registered name; it reuses the existing one in place.

Every surface that names a claim — `claims_supported`, the `claims` member of the claims-required challenge, and the `claim` dimension of a disclosure-policy rule ({{disclosure-policy}}) — takes a **claim reference**. A claim reference is either a string naming a whole top-level claim, or a **claims path pointer** ({{I-D.ietf-oauth-sd-jwt-vc}}): a non-empty array in which a string selects an object member, a non-negative integer selects an array element, and `null` selects every element of an array. A string is equivalent to its single-element path (`"address"` is `["address"]`). The first path component MUST be a name from the vocabulary above.

A reference to a whole claim covers everything beneath it: an issuer that advertises `address` can attest any of its members, and a policy rule on `address` matches any path into it. A rule on a more specific path ranks as more specific at resolution ({{policy-resolution}}). Nested and array claims are addressed by a path, never by a flattened name.

The capability document is the issuer metadata document, so it inherits its fetch and integrity rules ({{AAP-CORE}}): served same-origin over HTTPS, no cross-origin redirects, cacheable per {{RFC9110}}. Integrity rests on TLS and the same-origin rule, as for the rest of the document; tampering with the list can only cause a request to fail or be skipped, not impersonation or disclosure (the AAT and claims tokens are independently signed), so it needs no stronger protection. A service therefore learns an issuer's claims capability offline, with no call that could reveal a principal. How a service discovers *which* issuer can attest a given claim, rather than what a known issuer attests, is a separate trust-registry concern and is out of scope for this revision ({{open-items}}).

## Requester Keys {#requester-keys}

On the issuer-mediated lane the issuer does not take the requester's identity, audience, or purpose on the agent's say-so: the service MUST sign its claims-required challenge with a key resolvable from its `aud` origin, and the issuer verifies that signature before acting ({{issuer-mediated-disclosure}}). The `aud`-binding of the minted token is a second line of defense on top of that check, not a substitute for it: a token is bound to the `aud` the service named in its signed challenge and is inert anywhere else, so a relayed token cannot be redirected. The issuer resolves two distinct service keys, each verifiably bound to the service: a signing key to authenticate that challenge, and a separate encryption key to encrypt the claims token to the service under the agent-blind condition ({{policy-behavior}}, {{claims-encryption}}). In each case the key MUST be bound to the `aud` origin — served from it — so that key authority equals the `aud` binding the claims token already carries.

### Encrypting the Claims Token to the Service {#claims-encryption}

Under the agent-blind condition ({{policy-behavior}}) the issuer-mediated claims token MUST be encrypted to the requesting `aud`, so the brokering agent relays only ciphertext. The issuer resolves the service's encryption key, then signs and encrypts the claims token to it.

An issuer resolves the service's encryption key through its requester metadata, published at a well-known location at the `aud` origin:

~~~
GET https://<aud>/.well-known/aap-requester
~~~

The document carries one REQUIRED member, `jwks_uri`, naming the service's one JSON Web Key Set ({{RFC7517}}), so a consumer caches a single JWKS per service:

~~~ json
{ "jwks_uri": "https://merchant.example/.well-known/aap-requester/jwks.json" }
~~~

The metadata document and the JWKS it names MUST be fetched under the same rules as issuer keys ({{claims-keys}}): over HTTPS, same-origin as the `aud`, with no cross-origin redirects and no IP-literal hosts. The issuer selects a key marked `"use": "enc"`, identified by its `kid`; when the JWKS carries more than one `"use": "enc"` key (across a rotation window or across curves) the issuer MAY select any current member and MUST carry the selected `kid` in the JWE protected header so the service can identify the decryption key, and a service MUST reject a JWE naming a key it has retired. This key MUST be distinct from the key that signs the service's challenge ({{issuer-mediated-disclosure}}): a key MUST NOT be shared across signing and key agreement, following the one-algorithm-per-key rule ({{RFC8725}}), regardless of whether one curve could serve both, so the service's signing key MUST NOT be repurposed as the encryption key, including by converting an Ed25519 signing key to its X25519 form. The service's `"use": "enc"` keys rotate additively, as issuer keys do ({{claims-keys}}): the service publishes a successor before using it and retains a predecessor until the last claims token encrypted to it has expired.

This profile provides no forward secrecy: the static `"use": "enc"` key is ephemeral-static ECDH, so compromise of the service's decryption key exposes past claims tokens encrypted to it, and the rotation window above is what bounds that exposure. A service that wants a narrower window rotates its encryption key faster.

The claims token is signed and then encrypted as a nested JWT ({{RFC7519}}): the issuer signs the `aap-claims+jwt` ({{issuer-mediated-disclosure}}), then encrypts the resulting JWS as the payload of a JWE ({{RFC7516}}) in Compact Serialization, with header parameters `cty` `JWT`, `alg` `ECDH-ES` (direct key agreement), and `enc` `A256GCM`. Implementations MUST support the P-256 curve ({{RFC7518}}), the suite every pair of parties is guaranteed to share, and SHOULD support X25519 ({{RFC8037}}), matching the Ed25519 signing posture of {{claims-keys}}; a service that publishes only an X25519 key reaches only issuers that implement it. The issuer encrypts to the curve of the resolved recipient key and carries its own ephemeral public key in `epk` on that curve, per {{RFC7518}}. A party MUST validate the peer public key — for the issuer, the resolved recipient key; for the service, the issuer's `epk` — before using the agreed secret: on the NIST curves the key MUST be a valid point on the stated curve, per the partial public-key validation of {{SP800-56A}}, preventing invalid-curve attacks ({{RFC8725}}); X25519 accepts any 32-octet string and has no on-curve check (Section 5 of {{RFC7748}}), so a party SHOULD instead reject an all-zero X25519 shared secret (Section 6.1 of {{RFC7748}}), or rely on a library that rejects low-order points. This profile does not use `apu` or `apv`: replay and cross-service redirection are prevented by the recipient's verification of the `nonce`, `aud`, and short `exp` in the signed inner JWS, and because ECDH-ES provides no sender authentication, folding those values into the JWE key-derivation inputs would add nothing over that signed check.

An example JWE protected header:

~~~ json
{ "alg": "ECDH-ES", "enc": "A256GCM", "cty": "JWT",
  "kid": "svc-enc-2026", "epk": { "kty": "EC", "crv": "P-256", "x": "...", "y": "..." } }
~~~

On receipt the service MUST reject the JWE unless `alg` is `ECDH-ES` and `enc` is `A256GCM` — the only values this profile defines — checking the algorithms against this allow-list before decrypting rather than trusting the header ({{RFC8725}}); it then decrypts the JWE, confirms `cty` `JWT` and the inner JWS's `typ` `aap-claims+jwt`, and verifies the inner JWS as it would an unencrypted claims token ({{issuer-mediated-disclosure}}): issuer signature, `aud` equal to itself, the `nonce` matching its challenge, and the validity window, failing closed at the first failure. Because the encryption key is served from the `aud` origin, a token the agent cannot decrypt is also inert to any recipient but the named service, matching the guarantee the `aud`-bound signed token already carries; this confidentiality reduces to TLS and Web-PKI authentication of the `aud` origin and the integrity of its published keyset, no stronger an assumption than the `aud` binding the token already relies on.

If the agent-blind condition applies and the issuer cannot resolve an encryption key bound to the `aud`, it MUST fail closed and MUST NOT disclose the claim ({{policy-behavior}}), returning `urn:aap:consent-required` as it would for any other claim it cannot release. This outcome is reachable only after the policy resolved to `allow` or `ask`, so a distinct error would reveal that disclosure would otherwise have proceeded; returning the same response as a denial keeps the outcomes indistinguishable.

TODO: whether to adopt the HTTP Message Signatures directory ({{I-D.meunier-http-message-signatures-directory}}) for service keys. For the service's challenge-signing key, this should reconcile with the service keyset in {{claims-encryption}}: if the challenge is signed as a JWS, its verifying key is the `use:sig` member of that same JWKS; if as a Web Bot Auth HTTP Message Signature, it resolves through the signature directory instead.

# Relationship to Existing Work {#related-work}

This section is informative.

| Work | What it provides | How this module uses it |
|---|---|---|
| SD-JWT-VC ({{I-D.ietf-oauth-sd-jwt-vc}}, {{RFC9901}}) | Holder-presented credentials with selective disclosure and key binding | The pre-provisioned (fast) disclosure lane ({{pre-provisioned-disclosure}}) |
| OIDC UserInfo / CIBA ({{OIDC}}, {{CIBA}}) | Issuer-held claims and backchannel user approval | The shape of the issuer-mediated (slow) disclosure lane and its asynchronous approval ({{issuer-mediated-disclosure}}) |
| OpenID Connect Discovery / OAuth AS Metadata ({{OIDC-Discovery}}, {{RFC8414}}) | Issuer-level `.well-known` capability document | The `claims_supported` advertisement ({{claims-capability}}) |
| OASIS XACML 3.0 ({{XACML}}) | Attribute-based rules with Obligations, named combining algorithms, and default-deny | The disclosure policy's `agent_blind` Obligation, its `deny > ask > allow` (deny-overrides) tiebreak, and its fail-closed default ({{disclosure-policy}}) |
| Object-capability model ({{OCAP}}) | Authority as an attenuable, non-amplifiable delegation | The agent-attenuation invariant: an agent-scoped preference may only restrict, never enlarge, the principal's policy ({{disclosure-policy}}) |
| OAuth Rich Authorization Requests ({{RFC9396}}) | Fine-grained, per-resource and per-recipient authorization | The per-`(claim, audience)` grant shape and consent-gated outcomes of the disclosure policy ({{disclosure-policy}}) |

# Privacy Considerations {#privacy}

The privacy properties of the anonymous front door are the core's ({{AAP-CORE}}). This module's privacy analysis concerns what happens when facts do move.

**The two disclosure lanes trade exposure in opposite directions.** The asymmetry is deliberate, and the principal's policy chooses per claim ({{policy-behavior}}), commonly authored by sensitivity tier ({{sensitivity-tiers}}). The pre-provisioned lane ({{pre-provisioned-disclosure}}) is issuer-blind — the issuer is not contacted at disclosure and, unless the principal has opted into usage reporting ({{consent}}), learns nothing about where a fact is presented — but the agent holds the credential and sees the fact, and consent is fixed at issuance time. The issuer-mediated lane ({{issuer-mediated-disclosure}}) is the reverse: the agent can be kept from reading the values (the claims token MAY be encrypted to the service) and consent is live, but the issuer necessarily learns that this principal disclosed to this service — issuer-side correlation that the front-door attestation deliberately avoided. Neither lane is strictly more private; sensitivity tiering routes a fact to the lane whose exposure is acceptable for it, and a sensitive fact is kept off the issuer-blind lane's standing wildcard grants ({{consent}}).

**Issuer blindness limits issuer-side auditability.** On the pre-provisioned lane the issuer provisions the credential but is not involved in its presentation; unless the principal has opted into usage reporting ({{consent}}), it therefore does not learn through this protocol whether or when the credential was presented, which claims were disclosed, or which service received them. This is the lane's intended property, and its cost: absent that opt-in the issuer cannot maintain a complete disclosure history for the principal or detect overbroad requests at presentation.

**Pre-provisioned presentations are linkable through a reused credential.** An SD-JWT-VC presented twice shows the same issuer signature and the same disclosure digests, so two services — or one service across visits — can match the copies. Single-use presentation ({{pre-provisioned-disclosure}}) removes that correlator: each presentation shows a credential minted with fresh salts and a fresh issuer signature. What single use does not remove is linkability under issuer collusion: issuance on this lane is not blind, the issuer knows which credentials it minted for which principal, and a verifier that shares a presented credential with the issuer identifies the principal. A blind issuance scheme would close that channel and is deferred ({{open-items}}).

# Security Considerations {#security}

Selective disclosure on the pre-provisioned lane ({{pre-provisioned-disclosure}}) permits the agent to disclose a subset of the claims in a credential but does not enforce that the selected subset is necessary or limited to the claims requested by the service. Once a credential has been provisioned, the issuer is not involved in its presentation and cannot prevent an erroneous, compromised, or malicious agent from disclosing additional claims available in that credential.

Even when the origin and integrity of a claims request are verified, this establishes neither that the requested claims are necessary nor that the stated purpose is truthful. A malicious service can therefore issue an overbroad claims request. A claim whose use-time disclosure cannot be entrusted to the agent's judgment therefore does not belong on the pre-provisioned lane: {{pre-provisioned-disclosure}} forbids provisioning a claim that requires per-use approval, an enumerated audience, or agent-blind handling, and the lane-routing rule of {{overview}} keeps any other such claim on the issuer-mediated lane.

What bounds an overbroad request is the disclosure policy and the issuer's position as chokepoint. On the issuer-mediated lane every request resolves against the policy ({{disclosure-policy}}): a claim outside a standing grant resolves to `ask` — putting the requester, the claims, and the stated `purpose` in front of the principal ({{consent}}) — or to `deny`, and the wildcard bound caps what a standing grant releases without approval. The issuer authenticates the requester ({{issuer-mediated-disclosure}}) and logs every request, denied ones included ({{consent}}); repeated overbroad requests from one requester are visible there, and an issuer MAY refuse further disclosure to a requester exhibiting a pattern of overbroad requests. On the pre-provisioned lane the policy acts at minting: the wallet never contains a claim the policy does not resolve to `allow`, so a request, however broad, obtains at most the wallet's contents.

The brokering agent is a trusted custodian of every value it can read. On the pre-provisioned lane the agent always holds the disclosed values; on the issuer-mediated lane it holds them unless the claims token is encrypted to the service under an agent-blind condition ({{policy-behavior}}). The module's bindings — audience, nonce and the issuer signature — prevent the agent from presenting a value as an attested claim to a service that should not receive it: a challenging service obtains a freshly issuer-signed, audience- and nonce-bound claim or nothing, and a token minted for one service is inert at another. Those bindings do not, and cannot, constrain what the agent does with a plaintext value once it can read it — it may store, aggregate, profile, or re-disclose the value out of band. Encrypting the claims token to the service (agent-blind, {{issuer-mediated-disclosure}}) is the only structural control, and it applies only where the agent need not read the value; for a claim the agent must act on — an address it uses, a predicate it evaluates — the agent necessarily holds the plaintext and no protocol mechanism removes that exposure. Confining sensitive claims to the agent-blind path follows from this.

TODO. Points to cover:

- Issuer-mediated lane requester authentication: because the agent relays the challenge, the issuer authenticates the request by verifying the service's signature over it, so `aud`, `nonce`, and `purpose` are the service's own and not the agent's ({{issuer-mediated-disclosure}}).
- Non-adopting verifiers ({{non-adopting-verifiers}}): the module confers no guarantee absent a verifier challenge. Supplying a bare claim value to a non-participating site (browser form-fill) is a supported lower-assurance path governed by the principal's disclosure policy: it excludes agent-blind claims, requires the principal be told the agent is requesting the value for its own use, and leaves the released value unauthenticated (no issuer signature the site can verify), replayable across origins, and in the agent's hands with no protocol control on its use.
- Theft of a claims token or a pre-provisioned credential; what the `aud`/`nonce` bindings and the KB-JWT do and do not bound.

# IANA Considerations {#iana}

TODO. Registrations implied by the current text, within the `urn:aap:` namespace registered by {{AAP-CORE}} and the registries it establishes:

- Problem types: `urn:aap:claims-required`, `urn:aap:consent-required`, `urn:aap:approval-pending`, `urn:aap:slow-down`, `urn:aap:approval-denied`, `urn:aap:approval-expired`.
- Media type `application/aap-claims+jwt` and JWT `typ` `aap-claims+jwt`; SD-JWT-VC `typ` `dc+sd-jwt` is reused as specified.
- HTTP field name `Identity-Presentation`.
- Issuer-metadata members: `claims_jwks_uri`, `claims_endpoint`, `credential_endpoint`, `usage_report_endpoint`, `claims_supported` ({{issuer-metadata-members}}).
- Well-known URI `aap-requester` (a service's requester metadata for the issuer-mediated lane: a document whose `jwks_uri` names the service's one JWKS, holding its `use:enc` encryption key and, if the challenge-signing choice of {{requester-keys}} lands on JWS, its `use:sig` challenge-signing key), published at the `aud` origin and fetched by the issuer ({{claims-encryption}}).

# Open Items {#open-items}

A running list of the decisions this revision defers, collected for review:

- How tightly the key-binding proof should be bound to the request it rides on: whether a verifier MUST require the request signature's `keyid` to be the {{RFC7638}} thumbprint of the credential's `cnf.jwk`, as the platform-endorsed key profile ({{AAP-LOCAL}}) does for its endorsement, and whether `cnf` equal to the agent's Web Bot Auth key should remain RECOMMENDED now that the two proofs are separate ({{pre-provisioned-disclosure}}).
- Pre-provisioned lane: whether to adopt a blind issuance scheme (for example BBS-based, {{I-D.irtf-cfrg-bbs-signatures}}) to remove issuer-collusion linkability across presentations ({{privacy}}).
- Usage-report mechanics on the pre-provisioned lane ({{consent}}): the wire mechanism (a Security Event Token per RFC 8417, delivered by HTTP push per RFC 8935, is the candidate), how the opt-in is recorded, and whether reports enter a principal-visible log.
- Stale-approval handling on the issuer-mediated lane ({{asynchronous-approval}}).
- Whether a request that releases nothing keeps two distinguishable outcomes (a consent problem type when every refusal is a consent refusal, a claims token carrying no requested claims otherwise) or collapses them into one ({{issuer-mediated-disclosure}}).
- Whether this module maintains a non-normative crosswalk annex of OIDC <-> mDL <-> eIDAS PID claim equivalences, and its scope ({{claims-capability}}).
- Whether to define an SD-JWT-VC Type Metadata document for the pre-provisioned credential's `vct` type, hosted at the `vct` URL, and its consistency requirement against `claims_supported` ({{pre-provisioned-disclosure}}).
- Issuer-of-record discovery: how a service finds which issuer(s) can attest a given claim (rather than what a known issuer attests), and at what assurance. A trusted-list / registry concern (cf. mDL trust lists, EUDI trusted lists), distinct from per-issuer capability advertisement ({{claims-capability}}).
- Service key directory: bare JWK Sets versus the Web Bot Auth signature directory for the challenge-signing key ({{requester-keys}}).

# Acknowledgments {#acknowledgments}

TODO.

--- back

# Examples {#appendix-a}

This appendix is informative.

TODO: End-to-end example flows: (1) low-sensitivity disclosure via the pre-provisioned lane; (2) high-sensitivity disclosure via the issuer-mediated lane with interactive approval. The anonymous-admission flow lives in the core ({{AAP-CORE}}).
