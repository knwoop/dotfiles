# Platform Engineering Radar — Source List

This file defines the radar's sources. All additions, removals, and tier changes happen here.

## Tier meanings

- **core**: always fetched on a default radar run (the main sources)
- **featured**: added when the user asks for "in detail", "broader", or "full coverage"
- **archive**: consulted only when a specific topic calls for it (long-tail)

Entry format: `- [tier] **Source name** — URL — note`

Entries are kept organization-neutral. If a team wants to annotate "we use this in production", that belongs in a separate overlay file, not here.

---

## 1. 🌐 Cloud Native / CNCF

- [core] **CNCF Blog** — https://www.cncf.io/blog/ — project updates, incubation / graduation announcements
- [core] **CNCF Announcements** — https://www.cncf.io/announcements/ — press and official announcements
- [core] **Kubernetes Blog** — https://kubernetes.io/blog/ — official SIG updates and release notes
- [featured] **CNCF TAG App Delivery (Platforms WG)** — https://tag-app-delivery.cncf.io/ — home of the Platform Engineering whitepaper
- [featured] **Kubernetes GitHub Releases** — https://github.com/kubernetes/kubernetes/releases — detailed release notes
- [featured] **CNCF Landscape Changes** — https://landscape.cncf.io/ — project additions and tier changes
- [archive] **KubeCon Schedules** — https://www.cncf.io/kubecon-cloudnativecon-events/ — read the industry trend from session titles
- [archive] **CNCF TAG Observability** — https://github.com/cncf/tag-observability — observability whitepapers

## 2. 🔭 Observability / OpenTelemetry

- [core] **OpenTelemetry Blog** — https://opentelemetry.io/blog/ — official announcements and GA status
- [core] **OpenTelemetry Spec Releases** — https://github.com/open-telemetry/opentelemetry-specification/releases — spec release notes
- [core] **OpenTelemetry Spec CHANGELOG** — https://github.com/open-telemetry/opentelemetry-specification/blob/main/CHANGELOG.md — unreleased diff included
- [core] **OpenTelemetry Status** — https://opentelemetry.io/status/ — maturity per signal / language / component
- [featured] **Semantic Conventions CHANGELOG** — https://github.com/open-telemetry/semantic-conventions/blob/main/CHANGELOG.md — attribute-name standardization
- [featured] **OpenTelemetry Collector Releases** — https://github.com/open-telemetry/opentelemetry-collector/releases — Collector release notes
- [featured] **OpenTelemetry Collector Contrib Releases** — https://github.com/open-telemetry/opentelemetry-collector-contrib/releases — new receivers / exporters / processors
- [featured] **OpenTelemetry Go Releases** — https://github.com/open-telemetry/opentelemetry-go/releases — Go SDK
- [archive] **OTEP (Enhancement Proposals)** — https://github.com/open-telemetry/oteps — larger design-change discussions

Related observability vendor blogs:

- [featured] **Honeycomb Blog** — https://www.honeycomb.io/blog — essays from Charity Majors / Liz Fong-Jones
- [featured] **Grafana Labs Blog** — https://grafana.com/blog/ — LGTM stack updates
- [archive] **Datadog Engineering** — https://www.datadoghq.com/blog/engineering/ — large-scale operations insight
- [archive] **New Relic Blog** — https://newrelic.com/blog — OTel adoption tracking

## 3. 🐹 Go

- [core] **The Go Blog** — https://go.dev/blog/ — release announcements and proposal explainers
- [core] **Go Release History** — https://go.dev/doc/devel/release — release notes per version
- [featured] **Go GitHub Releases** — https://github.com/golang/go/releases — tagged changes
- [featured] **Go Proposals (Active)** — https://github.com/golang/go/issues?q=is%3Aissue+is%3Aopen+label%3AProposal — active proposals
- [archive] **Go Accepted Proposals** — https://github.com/golang/proposal — accepted proposal design docs

## 4. 🦀 Rust

- [core] **Rust Blog** — https://blog.rust-lang.org/ — release announcements, Edition news
- [core] **This Week in Rust** — https://this-week-in-rust.org/ — weekly digest (most efficient single source)
- [featured] **Rust Releases** — https://github.com/rust-lang/rust/releases — detailed release notes
- [archive] **Inside Rust Blog** — https://blog.rust-lang.org/inside-rust/ — contributor-facing internal updates
- [archive] **RFC Book** — https://rust-lang.github.io/rfcs/ — accepted RFCs

## 5. 🟦 TypeScript

- [core] **TypeScript Blog** — https://devblogs.microsoft.com/typescript/ — official RC / Beta / GA announcements
- [featured] **TypeScript GitHub Releases** — https://github.com/microsoft/TypeScript/releases — release tags
- [archive] **TypeScript Roadmap Issues** — https://github.com/microsoft/TypeScript/issues?q=is%3Aissue+is%3Aopen+label%3A%22Planning%22 — planned items

## 6. 🏗️ Platform Engineering

- [core] **Platform Engineering (platformengineering.org)** — https://platformengineering.org/blog — the community's central blog
- [featured] **Internal Developer Platform** — https://internaldeveloperplatform.org/ — IDP definitions and vendor comparisons
- [featured] **Thoughtworks Technology Radar** — https://www.thoughtworks.com/radar — semi-annual technology assessment
- [featured] **Team Topologies Blog** — https://teamtopologies.com/news-blogs-newsletters — team interaction models
- [archive] **Humanitec Blog** — https://humanitec.com/blog — IDP vendor perspective
- [archive] **Backstage Blog** — https://backstage.io/blog/ — the canonical developer portal

## 7. 🔥 SRE / Performance / Influencers

- [core] **Brendan Gregg's Blog** — https://www.brendangregg.com/blog/ — primary source on performance, eBPF, observability
- [core] **Charity Majors (charity.wtf)** — https://charity.wtf/ — observability, on-call, engineering management
- [core] **Julia Evans (jvns.ca)** — https://jvns.ca/ — deep explainers on Linux, networking, debugging
- [core] **Google SRE Resources** — https://sre.google/resources/ — addenda to the SRE book and workbook
- [featured] **Dan Luu** — https://danluu.com/ — systems, performance, industry observations
- [featured] **Lethain (Will Larson)** — https://lethain.com/ — engineering leadership, platform strategy
- [featured] **Cindy Sridharan (copyconstruct)** — https://copyconstruct.medium.com/ — distributed systems, observability
- [featured] **Martin Kleppmann** — https://martin.kleppmann.com/ — data-intensive systems
- [featured] **Jepsen Analyses** — https://jepsen.io/analyses — the definitive correctness analyses for distributed DBs
- [featured] **SRE Weekly** — https://sreweekly.com/ — weekly curation of SRE-relevant posts
- [archive] **Brendan Gregg Talks** — https://www.brendangregg.com/videos.html — conference talks
- [archive] **Kelsey Hightower (GitHub)** — https://github.com/kelseyhightower — talks and gists
- [archive] **Adrian Colyer (The Morning Paper)** — https://blog.acolyer.org/ — paper explainers (low update frequency)

## 8. ☁️ Cloud / Infra Vendor Blogs

- [core] **Google Cloud Blog** — https://cloud.google.com/blog/ — GCP across the board
- [core] **Cloudflare Blog** — https://blog.cloudflare.com/ — edge, networking, performance (consistently high-quality posts)
- [featured] **AWS Architecture Blog** — https://aws.amazon.com/blogs/architecture/ — design patterns
- [featured] **AWS Builders' Library** — https://aws.amazon.com/builders-library/ — publicized internal Amazon operations knowledge
- [featured] **Fly.io Blog** — https://fly.io/blog/ — technically strong and fun to read
- [featured] **Tailscale Blog** — https://tailscale.com/blog/ — excellent networking and NAT traversal explainers
- [featured] **Fastly Blog** — https://www.fastly.com/blog/ — CDN and Compute@Edge
- [archive] **HashiCorp Blog** — https://www.hashicorp.com/blog — Terraform, Vault, Nomad
- [archive] **Dagger Blog** — https://dagger.io/blog — programmable CI/CD

## 9. 🛡️ Security / Identity

- [featured] **OpenID Foundation Blog** — https://openid.net/blog/ — OIDC, CIMD, FAPI developments
- [featured] **IETF OAuth WG (datatracker)** — https://datatracker.ietf.org/wg/oauth/documents/ — watch drafts like `draft-oauth-ai-agents-on-behalf-of-user`
- [archive] **SPIFFE / SPIRE Blog** — https://spiffe.io/blog/ — workload identity
- [archive] **Google Security Blog** — https://security.googleblog.com/ — Google-side news on Play Integrity, WebAuthn, etc.

## 10. 📰 Newsletters / Media

- [featured] **The New Stack** — https://thenewstack.io/ — Cloud Native industry news
- [featured] **InfoQ Architecture & Design** — https://www.infoq.com/architecture-design/ — coverage of conferences and trends
- [archive] **The Pragmatic Engineer** — https://newsletter.pragmaticengineer.com/ — mostly paywalled but has free infra-adjacent posts

---

## Maintenance log

Optional: append one line per source change.

- 2026-04-24: initial version
