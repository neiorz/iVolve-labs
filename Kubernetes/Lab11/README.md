# Lab 11: Namespace Management and Resource Quota Enforcement

- **Environment:** Killercoda Kubernetes playground (new one, so no taints from earlier labs). All commands run on the controlplane tab.
- **Goal:** isolate resources in the namespace `ivolve`, cap it at 3 pods with the ResourceQuota `ivolveQuota`, and watch Kubernetes refuse the 4th pod.

## Lab Tasks

- [ ] Create a Kubernetes namespace named `ivolve` to isolate application resources.
- [ ] Create a ResourceQuota named `ivolveQuota` in the ivolve namespace to limit the total number of pods to 3.
- [ ] Verify that the ResourceQuota is applied correctly and confirm that Kubernetes prevents the creation of additional pods when the limit is reached.

## Screenshot Moments

| File | What it shows |
|---|---|
| `images/lab11-instructions.png` | The lab slide |
| `images/lab11-namespace.png` | The namespace `ivolve` created and Active |
| `images/lab11-quota.png` | The ResourceQuota `ivolveQuota` created, pods limit 3, used 0 |
| `images/lab11-pods.png` | The 3 pods of the ivolve namespace, the quota is full |
| `images/lab11-forbidden.png` | The 4th pod refused with the quota Forbidden error, used pods=3/3 |
