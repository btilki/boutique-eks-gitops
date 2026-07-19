# Root application

Points Argo CD at `gitops/apps/` (platform + workload ApplicationSets).

```bash
# After substituting <GITLAB_REPO_URL>:
kubectl apply -f gitops/bootstrap/root/application.yaml
```

Requires: Argo installed, GitLab repo credential registered (Step 6.3).
