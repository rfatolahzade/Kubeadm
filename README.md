# Kubeadm
Create a Kubernetes cluster multi-master using Kubeadm
0.Pre configs (all of the nodes-masters-workers-lo):

Using 0.preconfig.sh file:
#################################################################################
```bash
sudo -i
mv /home/ubuntu/0.preconfig.sh .
chmod +x 0.preconfig.sh
./0.preconfig.sh
```
#################################################################################

1.HAProxy Load Balancer Node Config:

Using 1.lo.sh file:
#################################################################################
```bash
sudo -i
mv /home/ubuntu/1.lo.sh .
chmod +x 1.lo.sh
./1.lo.sh
```
#################################################################################


2. Master and Worker Configs:

Using 2.masters-workers.sh file:
#################################################################################
```bash
sudo -i
mv /home/ubuntu/2.masters-workers.sh .
chmod +x 2.masters-workers.sh
./2.masters-workers.sh
```
#################################################################################


3. Master1 (mone) Initial:
Before joining make sure ssh is valid to other masters:
```bash
ssh root@lb 
ssh root@mone 
ssh root@mtwo
ssh root@mthree
ssh root@worker 
ssh root@workertwo 
ssh root@workerthree 
```
We need Helm in other tasks so let install it:
```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

Let's Initial with this command:
#kubeadm init --control-plane-endpoint="<LO IP>:6443" --upload-certs --apiserver-advertise-address=<Master IP> --pod-network-cidr=192.168.0.0/16
Set <LO IP> and your current Master node ip (in my case Master1(mone)IP ):
```bash
kubeadm init --control-plane-endpoint="185.1.1.1:6443" --upload-certs --apiserver-advertise-address=185.1.1.2 --pod-network-cidr=192.168.0.0/16
```
Export the kubeconfig:
```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
```
OR:
```bash
cat <<EOF >> .profile
export KUBECONFIG=/etc/kubernetes/admin.conf
EOF
```

And then:
```bash
source .profile
```

#You have to deploy a pod network to the cluster (I used calico):
```bash
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.15/manifests/calico.yaml
```

Master joining command (in my case):
You can now join any number of the control-plane node running the following command on each as root:
NOTICE: You have to add your new master node to your haproxy on your lo node:
Like: "	server mthree 185.1.1.4:6443 check fall 3 rise 2 " and then run systemctl restart haproxy.

```bash

kubeadm join 185.1.1.1:6443 --token pe9bdq.8n5xuaz87w8i3fft \
        --discovery-token-ca-cert-hash sha256:4ee54ab2ccec2b108d1e572856708656345a589c107f7ca3867ddfc70b469a08 \
        --control-plane --certificate-key 07a361d17c0398683f61cfac174aafff100a0a4505d67605ff59afecfb35bee4


```

Worker joining command(in my case):
You can join any number of worker nodes by running the following on each as root:
```bash

kubeadm join 185.1.1.1:6443 --token pe9bdq.8n5xuaz87w8i3fft \
        --discovery-token-ca-cert-hash sha256:4ee54ab2ccec2b108d1e572856708656345a589c107f7ca3867ddfc70b469a08
```

#checkout:
On your Master (in my case mone) all of nodes will be Ready:
```bash
kubectl get nodes
```
Some useful commands:
If your init command stuck into running and you want to run in again run this command  before your inint command:
```bash
kubeadm reset
```
Packages:
```bash
apt install net-tools
```

If you have problem to pull images, do it manually:
```bash
docker pull k8s.gcr.io/kube-apiserver:v1.23.4
docker pull k8s.gcr.io/kube-proxy:v1.23.4
docker pull k8s.gcr.io/kube-controller-manager:v1.23.4
docker pull k8s.gcr.io/kube-scheduler:v1.23.4
docker pull k8s.gcr.io/etcd:3.5.1-0
docker pull k8s.gcr.io/coredns/coredns:v1.8.6 
docker pull k8s.gcr.io/pause:3.6  
#OR Run:
kubeadm config images pull
```
