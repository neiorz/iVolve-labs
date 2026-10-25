# Lab 9: Deploy Kubernetes cluster using Kubeadm

![Lab instructions](images/lab9-instructions.png)

I have no cloud account (no bank card), so I did this lab on the free **Killercoda** playground, signed in with my GitHub account. The playground gives two machines in the browser, and I built the cluster on them with kubeadm by hand.

- Kubernetes version: **v1.37.1** on both nodes
- containerd version: **v2.2.1** on both nodes
- CNI: **Calico v3.29.1**
- Cluster: 1 control plane (`controlplane`, 172.30.1.2) + 1 worker (`node01`, 172.30.2.2)

## The environment

The Kubernetes playground on Killercoda opened with two tabs. Both tabs start as the `controlplane` machine, so I used `ssh node01` to work on the worker machine in Tab 1.

![controlplane terminal](images/lab9-playground_controlPlane.png)

![worker terminal](images/lab9-playground_worker.png)

## Clean the old cluster first

The playground comes with an old cluster already inside. So before I built my own, I cleaned both machines: `kubeadm reset -f`, deleted `/etc/cni/net.d` (and `/root/.kube` on controlplane), and flushed the iptables rules.

Controlplane:

![kubeadm reset on controlplane](images/lab9-clean-old-cluster1.png)

Node01:

![kubeadm reset on node01](images/lab9-clean-old-cluster2.png)

## Install and configure containerd (both nodes)

I installed containerd, wrote the default config, set `SystemdCgroup = true`, restarted and enabled the service. I also loaded the `overlay` and `br_netfilter` modules and set the sysctls that Kubernetes needs (bridge-nf-call-iptables, ip_forward).

Controlplane:

![containerd on controlplane](images/lab9-containerd1.png)

Node01:

![containerd on node01](images/lab9-containerd2.png)

`containerd --version` printed `containerd github.com/containerd/containerd/v2 2.2.1` on both machines.

## Install kubeadm, kubelet, kubectl (both nodes)

I added the pkgs.k8s.io apt repository and installed the three packages on both nodes. On the playground the newest version was already 1.37.1, so apt kept that version.

Controlplane:

![packages on controlplane](images/lab9-packages1.png)

Node01:

![packages on node01](images/lab9-packages2.png)

`kubeadm version` and `kubectl version --client` both show v1.37.1.

## Initialize the control plane

First `kubeadm init` did not start: the preflight check said the machine has 1 CPU and it wants 2 (the playground machines are small). So I ran init again with that one check ignored, and it finished successfully.

```bash
kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=NumCPU
```

![kubeadm init success](images/lab9-init.png)

## Configure kubectl

Then I put the admin config in place so kubectl can talk to the cluster:

```bash
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
```

`kubectl get nodes` showed the control plane node. It was `NotReady` at this point, which is normal because the network plugin was not installed yet. (I typed `kbectl` by mistake the first time.)

![kubectl configured](images/lab9-kubectl.png)

## Install the Calico CNI plugin

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/calico.yaml
```

All the Calico resources were created. After about a minute the calico pods were `Running` and the control plane node changed to `Ready`. One CoreDNS pod was still `Pending` here, it started after the worker joined.

![Calico pods running](images/lab9-calico.png)

## Join the worker node

On the control plane I created a fresh join command:

```bash
kubeadm token create --print-join-command
```

![join command created](images/lab9-join1.png)

Then on node01 (I reached it with `ssh node01`) I pasted that whole `kubeadm join ...` line, and it answered: `This node has joined the cluster`.

![worker joined the cluster](images/lab9-join2.png)

## Verify the cluster

Both nodes are `Ready`:

![both nodes Ready](images/lab9-nodes.png)

And all cluster components are `Running` — calico on both nodes, CoreDNS, etcd, apiserver, controller-manager, scheduler, kube-proxy:

![all pods running](images/lab9-pods.png)

The lab is done. The playground machines die when the timer ends, the cluster only lived for this lab.
