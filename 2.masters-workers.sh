
{
#Disable Firewall (in my case-not useful for production as you know)
ufw disable
#Disable swap
swapoff -a; sed -i '/swap/d' /etc/fstab
}


#Update sysctl settings for k8s networking
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

{
#Requirments:
  apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt update && apt install -y docker-ce containerd.io
}


{
#google key
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
  apt update
}

{
#Intall k8s components
apt install -y kubeadm kubelet kubectl
apt-mark hold kubelet kubeadm kubectl docker
}

{
#cgroupdriver
cat >>/etc/docker/daemon.json<<EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"]
}

EOF
}

{
systemctl daemon-reload
systemctl restart docker
systemctl restart kubelet
}


{
echo -e "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd
}


#sudo apt-get install -y \
#    apt-transport-https \
#    ca-certificates \
#    curl \
#    gnupg-agent \
#    software-properties-common
#	
#sudo usermod -aG docker ubuntu


