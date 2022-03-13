{
#Pre configs:
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i '/PermitRootLogin yes/s/^#//g' /etc/ssh/sshd_config
sed -i '/Port 22/s/^#//g' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i '/PasswordAuthentication yes/s/^#//g' /etc/ssh/sshd_config
}
service ssh reload
cp /home/ubuntu/.ssh/authorized_keys  .ssh

{
cat <<EOF >> /etc/hosts
185.1.1.1 lb
185.1.1.2 mone
185.1.1.3 mtwo
185.1.1.4 mthree
185.1.1.5 worker
185.1.1.6 workertwo 
185.1.1.7 workerthree
EOF
}


{
##Aliases:
cat <<EOF >> ~/.bashrc
alias k='kubectl'
alias kga='watch -x kubectl get all -o wide'
alias kgad='watch -dx kubectl get all -o wide'
alias kcf='kubectl create -f'
alias wk='watch -x kubectl'
alias wkd='watch -dx kubectl'
alias kd='kubectl delete'
alias kcc='k config current-context'
alias kcu='k config use-context'
alias kg='k get'
alias kdp='k describe pod' 
alias kdes='k describe'
alias kdd='k describe deployment'
alias kds='k describe svc'
alias kdr='k describe replicaset'
#alias kk='k3s kubectl'
alias vk='k --kubeconfig'
alias kcg='k config get-contexts'
alias kgaks='watch -x kubectl get all -o wide -n kube-system'
alias kapi='kubectl api-resources'

EOF
}
exec bash

echo -e "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1
