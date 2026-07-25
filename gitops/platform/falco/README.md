# Falco — runtime threat detection (Topic 19 scaffold)
#
# **Not** installed until you add the ApplicationSet snippet and sync.
# Chart: https://falcosecurity.github.io/charts · pin in docs/versions.md
#
# Prerequisites after rebuild: Topics 04–08 (cluster + observability helpful).
# Cost: DaemonSet on every node — enable only when you accept the footprint.

## Enable path

1. Add Falco chart repo + `falco` destination to AppProject `boutique-platform` (Topic 19).
2. Copy element from `gitops/apps/platform-apps/falco-applicationset-snippet.yaml.example`
   into `applicationset.yaml` generators list (or apply the example ApplicationSet).
3. Sync Application `falco`; verify pods in namespace `falco`.

## Related

- Setup: `docs/setup/19-edge-runtime-waf-falco.md`
- ADR: `docs/adr/0010-edge-waf-and-falco.md`
