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

3. Install and configure CEPH as storage-class

#Quick Install (Operator-Cluser-SC-PV-PVC):

#################################################################################
```bash
git clone https://github.com/rfinland/rook-ceph-charts.git
cd ~/rook-ceph-charts/
chmod +x rook-ceph.sh
./rook-ceph.sh
```
#################################################################################



#Istall ROOK Operator chart:

#################################################################################
```bash
git clone https://github.com/rfinland/rook-ceph-charts.git
cd ~/rook-ceph-charts/rook-ceph/
helm install --create-namespace --namespace rook-ceph rook-ceph . -f values.yaml
```
#################################################################################

#chackout:
```bash
kubectl --namespace rook-ceph get pods -l "app=rook-ceph-operator"
```

#Istall ROOK Cluster chart:

#################################################################################
```bash
git clone https://github.com/rfinland/rook-ceph-charts.git
cd ~/rook-ceph-charts/rook-ceph-cluster/
helm install --namespace rook-ceph rook-ceph-cluster . -f values.yaml
```
#################################################################################

#chackout:
```bash
kubectl --namespace rook-ceph get cephcluster
```
#Install StorageClass,PV,PVC:

#################################################################################
```bash
cd ~/rook-ceph-charts/
kubectl create -f sc-pv-pvc-ceph-block.yaml -n  rook-ceph
```
#################################################################################

#Checkout:
```bash
kubectl get sc,pv,pvc -n rook-ceph
```

4. Deploy Nginx Ingress

#################################################################################
```bash
git clone https://github.com/rfinland/ingress-sample.git
cd ~/ingress-sample
chmod +x ingress-app.sh
./ingress-app.sh
```
#################################################################################

#Curl the app:
```bash
curl http://demo.localdev.me:8080/
```


5. Install Prometheus, Grafana to k8s cluster (Monitoring ETCD is mandatory)

#################################################################################
```bash
git clone https://github.com/rfinland/loki.git
cd ~/loki
chmod +x grafana.sh
./grafana.sh
```
#################################################################################
Admin Password and port-forwarding have been done in grafana.sh as well.

(Monitoring ETCD is mandatory)
```bash
visit: http://localhost:3000/dashboard/import?orgId=1
DashboardID = 3070
For Mariadb = 13106
```
```bash
--set-file extraScrapeConfigs=extraScrapeConfigs.yaml
cat > $PWD/test-etcd.yaml <<EOF
global:
  scrape_interval: 10s
scrape_configs:
  - job_name: test-etcd
    static_configs:
    - targets: ['185.1.1.2:2379','185.1.1.3:2379','185.1.1.4:2379']
EOF
cat $PWD/test-etcd.yaml
```

6. Install three node MariaDB galera cluster to k8s cluster

#################################################################################
```bash
git clone https://github.com/rfinland/Mariadb.git
cd ~/Mariadb/
chmod +x mariadb.sh
./mariadb.sh
```
#################################################################################

#Password:
```bash
echo "$(kubectl get secret --namespace mariadb-galera mariadb-galera -o jsonpath="{.data.mariadb-root-password}" | base64 --decode)"
```

To connect to your database run the following command:
```bash
    kubectl run mariadb-galera-client --rm --tty -i --restart='Never' --namespace mariadb-galera --image docker.io/bitnami/mariadb-galera:10.6.7-debian-10-r17 --command \
      -- mysql -h mariadb-galera -P  -uroot -p$(kubectl get secret --namespace mariadb-galera mariadb-galera -o jsonpath="{.data.mariadb-root-password}" | base64 --decode) my_database
```
To connect to your database from outside the cluster execute the following commands:
```bash
    kubectl port-forward --namespace mariadb-galera svc/mariadb-galera : &
    mysql -h 127.0.0.1 -P  -uroot -p$(kubectl get secret --namespace mariadb-galera mariadb-galera -o jsonpath="{.data.mariadb-root-password}" | base64 --decode) my_database
```
To upgrade this helm chart:
```bash
    helm upgrade --namespace mariadb-galera mariadb-galera bitnami/mariadb-galera \
      --set rootUser.password=$(kubectl get secret --namespace mariadb-galera mariadb-galera -o jsonpath="{.data.mariadb-root-password}" | base64 --decode) \
      --set db.name=my_database \
      --set galera.mariabackup.password=$(kubectl get secret --namespace mariadb-galera mariadb-galera -o jsonpath="{.data.mariadb-galera-mariabackup-password}" | base64 --decode)
```
```bash
# helm delete --purge  mariadb
# k label node workertwo app=master
# k label node workertwo  app.kubernetes.io/name=mariadb-galera
# SET/REMOVE  DAFAULT SC: 
# kubectl patch storageclass local-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
# kubectl patch storageclass ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```