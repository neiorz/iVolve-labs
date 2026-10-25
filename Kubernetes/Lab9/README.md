# Lab 9: Deploy Kubernetes cluster using Kubeadm

- **Environment:** Killercoda playground (killercoda.com/playgrounds → Kubernetes), two browser terminals: `controlplane` and `node01`.
- **Cluster:** built by hand with kubeadm — containerd runtime, Calico CNI, one control plane, one worker.

## Lab Tasks

- [ ] Install and configure containerd as the container runtime on all nodes.
- [ ] Install kubeadm, kubelet, and kubectl on the control plane and worker nodes.
- [ ] Configure kubectl to communicate with the Kubernetes cluster.
- [ ] Install the Calico CNI plugin to enable pod networking across the cluster.
- [ ] Initialize the control plane node using kubeadm init.
- [ ] Join the worker nodes to the cluster using the kubeadm join command.
- [ ] Verify that all nodes are in the Ready state and that the cluster components are running correctly.

## Screenshot Moments

| File | What it shows |
|---|---|
| `images/lab9-playground.png` | The Killercoda playground with the controlplane and node01 terminals |
| `images/lab9-containerd.png` | containerd installed and configured on the nodes |
| `images/lab9-packages.png` | kubeadm, kubelet and kubectl installed |
| `images/lab9-init.png` | kubeadm init finished successfully on controlplane |
| `images/lab9-kubectl.png` | kubectl configured and talking to the cluster |
| `images/lab9-calico.png` | Calico pods running and the control plane node Ready |
| `images/lab9-join.png` | The worker node joined with kubeadm join |
| `images/lab9-nodes.png` | Both nodes in Ready state |
| `images/lab9-pods.png` | All cluster components Running |
| `images/lab9-instructions.png` | The lab slide |
