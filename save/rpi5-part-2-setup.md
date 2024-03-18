Setting Up Kubernetes on Raspberry Pi 5: A Step-by-Step Guide
If you're looking to dive into the world of Kubernetes and experiment with it on your Raspberry Pi 5 cluster, you're in the right place. This comprehensive guide will walk you through the process, from setting up Raspberry Pi OS to deploying your first pod. Let's get started!

Prerequisites
Before we begin, make sure you have the following:

Raspberry Pi 5 cluster (at least two Pis)
SD cards for each Pi
Stable internet connection
Basic knowledge of Linux commands
1. Install Raspberry Pi OS
The first step is to install Raspberry Pi OS on each Raspberry Pi. Follow these steps:

Using Raspberry Pi Imager:
Download and install Raspberry Pi Imager.
Launch the Imager and select Raspberry Pi OS Lite (64-bit) from the Raspberry Pi OS (other) section.
Click on CHOOSE SD CARD and select the appropriate SD card.
Configure advanced options such as hostname and SSH access.
Write the image to the SD card.
Repeat these steps for each Raspberry Pi, ensuring you use a different hostname for each one.

2. Update Raspberry Pi OS
Once Raspberry Pi OS is installed on all Pis, SSH into each Pi and update the OS:

bash
Copy code
$ sudo apt update -y && sudo apt dist-upgrade -y
$ sudo reboot
3. Prepare for Kubernetes Installation
Add cgroup Flags:
Edit the /boot/cmdline.txt file and add the following flags:

bash
Copy code
$ sudo echo " cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1" | sudo tee -a /boot/cmdline.txt
Disable and Uninstall Swap:
Disable and uninstall the swap file:

bash
Copy code
$ sudo dphys-swapfile swapoff
$ sudo dphys-swapfile uninstall
$ sudo apt purge -y dphys-swapfile
$ sudo apt autoremove -y
4. Install Container Runtime (containerd)
Install containerd and necessary plugins:

bash
Copy code
$ sudo apt install -y containerd containernetworking-plugins
Configure containerd with cgroup:

Replace the content of /etc/containerd/config.toml with:

toml
Copy code
version = 2
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
Forwarding IPv4 and Letting iptables See Bridged Traffic:
Execute the following commands:

bash
Copy code
$ sudo echo "overlay" | sudo tee -a /etc/modules-load.d/k8s.conf
$ sudo echo "br_netfilter" | sudo tee -a /etc/modules-load.d/k8s.conf
$ sudo modprobe overlay
$ sudo modprobe br_netfilter
$ sudo echo "
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
" | sudo tee /etc/sysctl.d/k8s.conf
$ sudo sysctl --system
5. Install kubeadm, kubelet, and kubectl
Add Kubernetes repository and install necessary packages:

bash
Copy code
$ sudo apt update
$ sudo apt install -y apt-transport-https ca-certificates curl
$ sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
$ echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
$ sudo apt update
$ sudo apt install -y kubelet kubeadm kubectl
$ sudo apt-mark hold kubelet kubeadm kubectl
6. Install Cluster Networking (Flannel)
Download and configure Flannel:

bash
Copy code
$ wget https://github.com/flannel-io/flannel/releases/download/v0.19.2/flanneld-arm64
$ sudo chmod +x flanneld-arm64
$ sudo cp flanneld-arm64 /usr/local/bin/flanneld
$ sudo mkdir -p /var/lib/k8s/flannel/networks
7. Initialize Kubernetes Cluster (Main Host Only)
Run the following command on the main host:

bash
Copy code
$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16
After the initialization completes, follow the instructions provided to set up the kubeconfig:

bash
Copy code
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
8. Deploy Flannel and Other Add-ons
Apply the Flannel YAML:

bash
Copy code
$ kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
And that's it! You've successfully set up Kubernetes on your Raspberry Pi 5 cluster. You can now start deploying and managing containers using Kubernetes. Enjoy your journey into the world of container orchestration!


2 / 2




User
I also installed Kata containers, and updated the containerd configuration - then redeplyed ping deployment using kata containers. Can you add that also?
ChatGPT
Sure! Here's how you can deploy the ping deployment using Kata Containers after installing Kata Containers and updating the containerd configuration:

Deploy Ping Deployment with Kata Containers
1. Install Kata Containers
Follow the official documentation to install Kata Containers on your Raspberry Pi cluster. This typically involves adding the Kata Containers repository, installing the necessary packages, and configuring containerd to use Kata Containers as the runtime.

2. Update Containerd Configuration for Kata Containers
Edit the /etc/containerd/config.toml file to configure containerd to use Kata Containers as the runtime:

toml
Copy code
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
  runtime_type = "io.containerd.kata.v2"
Save the file and restart the containerd service:

bash
Copy code
$ sudo systemctl restart containerd
3. Redeploy Ping Deployment with Kata Containers
Assuming you have already deployed the ping deployment using standard containers, you can now redeploy it using Kata Containers. If you haven't deployed it yet, follow these steps:

Create Ping Deployment YAML
Create a YAML file named ping-deployment.yaml with the following content:

yaml
Copy code
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ping-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ping
  template:
    metadata:
      labels:
        app: ping
    spec:
      containers:
      - name: ping-container
        image: alpine
        command: ["ping", "8.8.8.8"]
Apply the Deployment
Apply the deployment YAML to deploy the ping pods:

bash
Copy code
$ kubectl apply -f ping-deployment.yaml
Verify Deployment
Verify that the ping pods are running:

bash
Copy code
$ kubectl get pods
4. Update Ping Deployment to Use Kata Containers
To use Kata Containers for the ping deployment, you need to modify the deployment YAML to specify the runtimeClassName as kata:

yaml
Copy code
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ping-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ping
  template:
    metadata:
      labels:
        app: ping
    spec:
      runtimeClassName: kata
      containers:
      - name: ping-container
        image: alpine
        command: ["ping", "8.8.8.8"]
Apply the updated deployment YAML:

bash
Copy code
$ kubectl apply -f ping-deployment.yaml
5. Verify Ping Pods with Kata Containers
Verify that the ping pods are running using Kata Containers:

bash
Copy code
$ kubectl get pods
You should now see the ping pods running with Kata Containers. This confirms that the ping deployment has been successfully redeployed using Kata Containers on your Raspberry Pi cluster.