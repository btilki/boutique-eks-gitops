# ADR-0008: Argo CD AppProjects + deferred SSO/notifications

- **Status:** Accepted (scaffold)  
- **Date:** 2026-07-25  
- **Setup:** Topic 17  

## Context

Pilot Argo CD used the built-in **`default`** AppProject and local `admin` login (`dex.enabled: false`, `notifications.enabled: false`). That is enough for a short cost-capped pilot, but it does not limit blast radius (platform vs workloads) or provide SSO/audit-friendly identity.

## Decision

1. **AppProjects (in Git, synced):**
   - `boutique-platform` — platform Helm/manifest apps (controllers, Kyverno, monitoring, …)
   - `boutique-workloads` — Boutique apps only in `dev` / `stage` / `prod` with a tight resource allowlist
2. **Root app + ApplicationSet objects** may remain on `default` so AppProjects can be bootstrapped; **child Applications** use the named projects.
3. **SSO (Dex + GitLab OIDC)** and **Notifications** ship as **example values/ConfigMaps only**. Bootstrap `values.yaml` keeps them **disabled** until IdP apps and secrets exist after rebuild.
4. **RBAC** examples map GitLab groups to Argo roles; default policy toward `role:readonly` once SSO is enabled.

## Consequences

- **Positive:** Clear separation of platform vs app sync rights; path to remove shared admin password; hooks for sync-failure alerts.
- **Negative:** Mis-ordered sync (apps before AppProjects) fails; Dex adds IdP operational burden; notifications need secret hygiene.
- **Follow-ups:** Wire Dex group names to real GitLab groups; optionally delete `default` destinations for workloads; IP allowlist / WAF on Argo UI ([ADR-0010](0010-edge-waf-and-falco.md) / Topic 19).
