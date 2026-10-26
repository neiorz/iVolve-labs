# Lab 10: Node Isolation Using Taints and Labels in Kubernetes

- **Environment:** new Killercoda Kubernetes playground (killercoda.com/playgrounds → Kubernetes). The cluster there is already running: `controlplane` + `node01`, both Ready. Every command runs on the controlplane tab.
- **Goal:** isolate the worker node with a taint, mark it with a label, and prove both are there.

## Lab Tasks

- [ ] Apply a taint to the worker node with key `workload`, value `ivolveApp`, and effect `NoSchedule`, so pods without a matching toleration cannot be scheduled there.
- [ ] Label the same worker node with `project=ivolve` to identify it for targeted pod scheduling.
- [ ] Verify the taint and the label with `kubectl describe node` and `kubectl get nodes --show-labels`.

## Screenshot Moments

| File | What it shows |
|---|---|
| `images/lab10-instructions.png` | The lab slide |
| `images/lab10-nodes.png` | `kubectl get nodes` before the changes, both nodes Ready |
| `images/lab10-taint.png` | The taint command answering `node/node01 tainted` |
| `images/lab10-label.png` | The label command answering `node/node01 labeled` |
| `images/lab10-describe.png` | `kubectl describe node node01` with the Taints line and the label |
| `images/lab10-showlabels.png` | `kubectl get nodes --show-labels` showing `project=ivolve` |
