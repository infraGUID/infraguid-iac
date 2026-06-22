# CloudFront — Automated Rollout

CloudFront in front of the EKS frontend pod for edge caching, then a CloudFront-only
lock on the ALB — driven by one GitHub Actions workflow.

---

## 1. Architecture

```
Browser → Route 53 → CloudFront → ALB → frontend / chat-service pods
                       └─ caches "/" responses at AWS edge locations
                       └─ ALB accepts only CloudFront IPs (origin locked, final step)
```

Two facts make it work, both already in code:
1. **Caching is driven by HTTP headers** — `frontend/nginx.conf` sends
   `Cache-Control` (HTML = no-cache, assets = 1h); CloudFront obeys it.
2. **CloudFront forwards the `Host` header** so the ALB HTTPRoute still routes by
   `nutritrack360.in` and the origin TLS handshake validates.

## 2. Why it is a pipeline, not one `terraform apply`

The ALB only exists after ArgoCD deploys the Gateway, and CloudFront needs that
ALB as its origin. So the order is inherently:
**infra → ALB (GitOps) → CloudFront (Terraform) → lock (GitOps)**. The workflow
automates that ordering; every former manual step is now automatic:

| Was manual | Now |
| --- | --- |
| `kubectl get gateway` for the ALB name | Terraform `data "aws_lb"` finds it by cluster tag |
| Paste SG id into `ingress.yaml` | SG referenced by fixed name `infraguidai-prod-alb-cloudfront` |
| Store `CLOUDFRONT_DISTRIBUTION_ID` | Invalidation looks it up by domain at runtime |
| Two separate `terraform apply` runs | One workflow, ordered + gated |

## 3. The workflow

`.github/workflows/cloudfront.yml` — Actions → "CloudFront — deploy & lock origin"
→ Run workflow.

```
Stage 1  cloudfront    terraform apply enable_cloudfront=true
                       → auto-discovers ALB, creates CloudFront + Route 53 + SG
Stage 2  verify        polls https://nutritrack360.in until X-Cache shows cloudfront
                          ⏸  pauses for approval (production-lock environment)
Stage 3  lock-origin   adds securityGroups to the Gateway in the ArgoCD repo →
                       ArgoCD locks the ALB to CloudFront IPs
```

## 4. One-time setup

1. **Environment `production-lock`** — ✅ DONE (created on `infraguid-terraform`,
   required reviewer `aswin0318`). This is the Stage 3 approval gate.
2. **`secrets.ARGOCD_DEPLOY_TOKEN`** — ✅ confirmed a GitHub PAT that can write to
   `infraguid-argocd` (the existing `_cd.yml` uses it to open PRs there). Verify in
   the org UI that this org secret's Repository access includes `infraguid-terraform`
   (can't be checked without org-admin scope; an auth error in Stage 3 means it is not).
3. **AWS auth** — ✅ no new variable. `vars.AWS_DEPLOY_ROLE_ARN` + `vars.AWS_REGION`
   already exist org-wide; the invalidation job reuses `AWS_DEPLOY_ROLE_ARN`
   (it manages the distribution, so it has CloudFront permissions). `CICD_ROLE_ARN`
   is no longer needed.

## 5. Running it

1. Ensure the frontend pod is on the current `nginx.conf` (normal CI → ArgoCD flow).
2. Actions → CloudFront — deploy & lock origin → Run workflow (`lock_origin` = true).
3. Stage 1 + 2 run automatically (CloudFront takes ~5–15 min).
4. When it pauses on `lock-origin`, open the site, confirm login + chat work, then
   click **Approve**. Stage 3 locks the origin.

## 6. Rollback

- **Undo lock:** revert the one-line `ingress.yaml` commit Stage 3 made; ArgoCD
  restores open ALB access.
- **Remove CloudFront:** `terraform apply -var="enable_cloudfront=false"` — deletes
  the distribution, Route 53 alias records, and SG; the domain falls back to the ALB.

## 7. The one risk

ALB auto-discovery relies on the `elbv2.k8s.aws/cluster` tag. If it matches zero or
multiple load balancers, `aws_lb` fails the apply with a clear error in Stage 1 — it
never silently picks the wrong origin.
