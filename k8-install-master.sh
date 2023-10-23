#!/bin/bash

# check the OS
if [ -f /etc/redhat-release ]; then
    # code for CentOS
    echo "Running on CentOS"
cat << EOF > k8.sh
#!/bin/bash

echo "

        #################################################################
        #                                                               #
        #       This Script Install Kubernetes Master Node on CentOS    #
        #                                                               #
        #################################################################


"
# Check for hardware prerequisites
mem_size=\$(cat /proc/meminfo | grep MemTotal | awk '{print \$2}')
echo "Minimum memory required : 2097152 KB"
echo "Available memory : \$mem_size KB "
if [[ \$mem_size -lt 2097152 ]]; then
  echo "Error: Your system does not meet the minimum memory requirement of 2GB " >&2
  exit 1
fi

num_cpus=\$(nproc)
echo "Minimum CPU cores required : 2 cores"
echo "Available CPU cores : \$num_cpus cores"
if [[ \$num_cpus -lt 2 ]]; then
  echo "Error: Your system does not meet the minimum CPU requirement of 2 cores " >&2
  exit 1
fi

# Confirm with the user before proceeding
read -p "Do you want to proceed with the installation ? (y/n) " -n 1 -r
echo   
if [[ ! \$REPLY =~ ^[Yy]\$ ]]
then
    exit 1
fi

# Check for software prerequisites
if ! [ -x "\$(command -v curl)" ]; then
  echo 'Error: curl is not installed.' >&2
  exit 1
fi
if ! [ -x "\$(command -v yum)" ]; then
  echo 'Error: yum is not installed.' >&2
  exit 1
fi

# Get the hostname
echo "Enter the hostname:"
read hostname
hostnamectl set-hostname \$hostname
echo "`ip route get 1 | awk '{print \$NF;exit}'` \$hostname" >> /etc/hosts


# Update the package list and upgrade all packages
yum update -y

# Install necessary packages
yum install -y yum-utils device-mapper-persistent-data lvm2

# Add Kubernetes repository
printf " 
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
 " > /etc/yum.repos.d/kubernetes.repo



#Install docker
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y update
sudo yum -y install docker-ce docker-ce-cli docker-compose-plugin --skip-broken

systemctl start docker
systemctl enable docker


# Remove containerd config file
yum install -y containerd.io
rm -f /etc/containerd/config.toml


# Restart containerd service
systemctl restart containerd
chkconfig --add containerd

# Set sysctl net.bridge.bridge-nf-call-iptables to 1
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
sysctl --system

# Set SELinux in permissive mode
setenforce 0
sed -i 's/^SELINUX=enforcing\$/SELINUX=permissive/' /etc/selinux/config

# Add ports to firewall
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --permanent --add-port=10251/tcp
sudo firewall-cmd --permanent --add-port=10252/tcp
sudo firewall-cmd --permanent --add-port=10255/tcp
sudo firewall-cmd –reload


# Install Kubernetes components
yum install -y kubelet kubeadm kubectl

# Enable and start kubelet service
systemctl enable --now kubelet

# Initialize kubeadm
kubeadm init --ignore-preflight-errors=Firewalld

# Copy kubeconfig to home directory
mkdir -p \$HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config


#Deploy a pod network
kubectl apply -f https://docs.projectcalico.org/v3.25/manifests/calico.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.49.0/deploy/static/provider/baremetal/deploy.yaml


#Cluster join link
clear
echo " Installation Successful "
echo " Run below Token on worker node to join cluster "
kubeadm token create --print-join-command




EOF

chmod +x k8.sh
./k8.sh


	
	
	
elif [ -f /etc/lsb-release ]; then
    # code for Ubuntu
    echo "Running on Ubuntu"
cat << EOF > k8.sh

#!/bin/bash

# Redirect output to log file
exec > >(tee -a script.log)

# Redirect error to log file
exec 2> >(tee -a script.log >&2)

echo "

        #################################################################
        #                                                               #
        #       This Script Install Kubernetes Master Node on Ubuntu    #
        #                                                               #
        #################################################################


"

# Check for hardware prerequisites
mem_size=\$(free -k | grep Mem | awk '{print \$2}')
echo "Minimum memory required : 2097152 KB"
echo "Available memory : \$mem_size KB "
if [[ \$mem_size -lt 2097152 ]]; then
  echo "Error: Your system does not meet the minimum memory requirement of 2GB " >&2
  exit 1
fi

num_cpus=\$(nproc)
echo "Minimum CPU cores required : 2 cores"
echo "Available CPU cores : \$num_cpus cores"
if [[ \$num_cpus -lt 2 ]]; then
  echo "Error: Your system does not meet the minimum CPU requirement of 2 cores " >&2
  exit 1
fi

# Confirm with the user before proceeding
read -p "Do you want to proceed with the installation ? (y/n) " -n 1 -r
echo   
if [[ ! \$REPLY =~ ^[Yy]\$ ]]
then
    exit 1
fi

# Check for software prerequisites
if ! [ -x "\$(command -v curl)" ]; then
  echo 'Error: curl is not installed.' >&2
  exit 1
fi
if ! [ -x "\$(command -v apt-get)" ]; then
  echo 'Error: apt-get is not installed.' >&2
  exit 1
fi

# Get the hostname
echo "Enter the hostname:"
read hostname
hostnamectl set-hostname \$hostname
echo "`ip route get 1 | awk '{print \$NF;exit}'` \$hostname" >> /etc/hosts


# Update the package list and upgrade all packages
apt-get update -y
apt-get -o upgrade -y

# Install necessary packages
apt-get install -y apt-transport-https
apt-get update -y


# Add Kubernetes repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list


# Install docker
echo 'Installing docker....'
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable"
apt-get -y install docker.io
apt-get update -y
apt-get -y install docker-ce docker-ce-cli docker-compose-plugin --skip-broken

systemctl start docker
systemctl enable docker


echo 'Installing containerd....'
# Remove containerd config file
apt-get install -y containerd.io
rm -f /etc/containerd/config.toml

# Restart containerd service
systemctl restart containerd
systemctl enable containerd

#sudo swapoff -a


# Set sysctl net.bridge.bridge-nf-call-iptables to 1
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
sysctl -p


# Add ports to firewall
ufw allow 6443/tcp
ufw allow 2379:2380/tcp
ufw allow 10250/tcp
ufw allow 10251/tcp
ufw allow 10252/tcp
ufw allow 10255/tcp
ufw reload


# Install Kubernetes components
echo 'Install Kubernetes components: kubelet kubeadm kubectl'
versions=`curl -s https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages | grep Version | awk '{print $2}' | grep -P '\d\.[12]\d\.'`
IFS=$'\n' versions=($versions)
echo 'Please select K8S version you want to install'
select version in "${versions[@]}"; do   if [[ -n $version ]]; then     echo "You have selected version $version";     break;   else     echo "Invalid selection. Please try again.";   fi; done


apt-get install -y kubelet=${version} kubeadm=${version} kubectl=${version}

# Enable and start kubelet service
systemctl enable --now kubelet

echo "Please select a link you want to use as K8S cluster interface:"
links=`ls /sys/class/net`
IFS=$'\n' links=($links) 
select link in "${links[@]}"; do   if [[ -n $link ]]; then     echo "You have selected $link";     break;   else     echo "Invalid selection. Please try again.";   fi; done

echo "Will use $link as K8S API interface, will add address 192.168.3.3/24 as it's address"
ip a a 192.168.3.3/24 dev $link

# Initialize kubeadm
kubeadm init \
  --pod-network-cidr=10.120.0.0/16 \
  --service-cidr=10.130.0.0/16 \
  --ignore-preflight-errors=Swap \
  --apiserver-advertise-address 192.168.3.3  ## modify this address based on your node IP.  \
  --kubernetes-version ${version}

# Copy kubeconfig to home directory
mkdir -p \$HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config


#Deploy a pod network
echo 'Will deply flannel network'
#kubectl apply -f https://docs.projectcalico.org/v3.25/manifests/calico.yaml
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.49.0/deploy/static/provider/baremetal/deploy.yaml
curl -LO https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sed -i '/"Network/s/10.244.0.0\/16/10.120.0.0\/16/' kube-flannel.yml 
kubectl apply -f kube-flannel.yml

#Cluster join link
clear
echo " Installation Successful 

		type "bash" before proceed 
		
		"
echo " Run below Token on worker node to join cluster "
kubeadm token create --print-join-command

alias k='kubectl'
alias kw='kubectl -o wide'
alias kk='kubectl -n kube-system'
alias kkw='kk -o wide'
alias |egrep '^k'

EOF

chmod +x k8.sh
./k8.sh	
	
	
else
    # code for other OS
    echo "Not a supported OS"
    exit
fi
