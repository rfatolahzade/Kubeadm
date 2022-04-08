#LO Settings:
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd
echo -e "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1

#Install haproxy:
apt update && apt install -y haproxy
#coonfig:
cat <<EOF >> /etc/haproxy/haproxy.cfg
frontend kubernetes-frontend
    bind *:8443
    mode tcp
    option tcplog
    default_backend kubernetes-backend

backend kubernetes-backend
    mode tcp
    balance roundrobin
    server mone 185.1.1.1:6443 check fall 3 rise 2
    server mtwo 185.1.1.2:6443 check fall 3 rise 2
    server mthree 185.1.1.3:6443 check fall 3 rise 2

EOF

#reset service:
systemctl restart haproxy
#startup the service:
systemctl enable haproxy

