
---
In this tutorial (it is more of a step-by-step guide than an article), I will show you how you can install Kubernetes on a Raspberry PI 4 cluster.


Install Raspberry PI OS on each Raspberry
First of all, you need to install the OS on each Raspberry. Use the Raspberry Pi Imager to write the image on an SD Card.

Raspberry Pi Imager
Click the CHOOSE OS button and select Raspberry PI OS Lite (64-bit) from the Raspberry PI OS (other) section.

select Raspberry PI OS Lite (64-bit)
In the Advanced options (the gear icon/button) set the hostname and your username, enable SSH and click SAVE.

settings menu
Now insert the SD Card into a card reader, choose it and write the image.

Repeat these steps for all SD Cards, but choose a different hostname for each one. When you are done with all SD Cards, insert them into the Raspberry PIs and boot them.

You must perform the following steps on all Raspberry PIs you want to add to your cluster.

I wrote an Ansible Playbook for the following steps. Scroll down to see how to run it and save some time.

Update the OS
Before we install Kubernetes, we need to update the OS. To do so, login into each Raspberry via SSH and run the following command:

$ sudo apt update -y && sudo apt dist-upgrade -y
Sometimes you get a new Kernel, so rebooting the Raspberry is a good idea.

$ sudo reboot
Add cgroup flags
Add cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 to the end of the /boot/cmdline.txt file. The content of this file is one line without any line breaks.

$ echo " cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1" | sudo tee -a  /boot/cmdline.txt
Disable and uninstall swap
Run the following commands to disable and uninstall the swap file:

$ sudo dphys-swapfile swapoff
$ sudo dphys-swapfile uninstall
$ sudo apt purge -y dphys-swapfile
$ sudo apt autoremove -y
You can test that swap has been disabled with free -m.

swap disabled
Install and set up the Container Runtime
See also Container Runtimes in the Kubernetes Documentation

Install containerd
$ sudo apt install -y containerd containernetworking-plugins
Set up containerd with cgroup
See also https://github.com/containerd/containerd/issues/4203#issuecomment-651532765

Replace the content of /etc/containerd/config.toml:

$ cat <<EOF | sudo tee /etc/containerd/config.toml
version = 2
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
EOF
/etc/containerd/config.toml
Forwarding IPv4 and letting iptables see bridged traffic
See also Forwarding IPv4 and letting iptables see bridged traffic

$ cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
 
$ sudo modprobe overlay
$ sudo modprobe br_netfilter
 
$ cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
$ sudo sysctl --system
Install kubeadm
See also Installing kubeadm

$ sudo apt update
$ sudo apt install -y apt-transport-https ca-certificates curl

// Download the Google Cloud public signing key:
$ sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

// Add the Kubernetes apt repository:
$ echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

// Update `apt` package index, install kubelet, kubeadm and kubectl, and pin their version:
$ sudo apt update
$ sudo apt install -y kubelet kubeadm kubectl
$ sudo apt-mark hold kubelet kubeadm kubectl
Install Cluster Networking
Flannel is a simple and easy way to configure a layer 3 network fabric designed for Kubernetes. (Flannel)

$ wget https://github.com/flannel-io/flannel/releases/download/v0.19.2/flanneld-arm64
$ sudo chmod +x flanneld-arm64
$ sudo cp flanneld-arm64 /usr/local/bin/flanneld
$ sudo mkdir -p /var/lib/k8s/flannel/networks
In a later step, we will add Flannel to the cluster.

Ansible for lazy people
Ansible is an IT automation tool. It can configure systems, deploy software, and orchestrate more advanced IT tasks such as continuous deployments or zero downtime rolling updates. (Ansible Documentation)

I wrote an Ansible Playbook to automate all the steps above. To run the playbook, you first need to install Ansible. On macOS, you can install it with brew install ansible (what I did). You also need an inventory. Mine looks like this:

[raspis]
10.0.0.[11:14]

[raspis:vars]
ansible_user=ralph

[k8s_main]
10.0.0.11

[k8s_worker]
10.0.0.[12:14]
The playbook uses the IP addresses from the raspis group to run all the tasks on these hosts.

---
- name: Playbook to install the necessary things to run k8s on Raspberry PIs
  hosts: raspis
  become: yes
  gather_facts: no
  tasks:
    - name: Update repositories cache and upgrade system
      ansible.builtin.apt:
        update_cache: yes
        upgrade: dist
        cache_valid_time: 3600
        autoclean: yes
        autoremove: yes

    - name: Check if a reboot is needed
      register: reboot_required_file
      stat:
        path: /var/run/reboot-required
        get_md5: no

    - name: Reboot if needed
      ansible.builtin.reboot:
        msg: "Reboot initiated by Ansible for kernel updates"
        connect_timeout: 5
        reboot_timeout: 300
        pre_reboot_delay: 0
        post_reboot_delay: 30
        test_command: uptime
      when: reboot_required_file.stat.exists

    - name: Install vim and aptitude
      ansible.builtin.apt:
        pkg:
          - vim
          - aptitude

    - name: Create Aptitude config directory
      ansible.builtin.file:
        path: /root/.aptitude/
        state: directory
        recurse: yes
        owner: root
        group: root
        mode: '0700'

    - name: Configure Aptitude
      ansible.builtin.copy:
        content: |
          aptitude "";
          aptitude::Keep-Unused-Pattern "";
          aptitude::Delete-Unused-Pattern "";
          aptitude::UI "";
          aptitude::UI::Prompt-On-Exit "false";
          aptitude::UI::Default-Grouping "task,status";
          aptitude::AutoClean-After-Update "true";
          aptitude::Clean-After-Install "true";
          aptitude::Forget-New-On-Update "true";
        dest: /root/.aptitude/config
        backup: yes
        owner: root
        group: root
        mode: '0644'

    - name: Modify ls alias
      ansible.builtin.lineinfile:
        path: /home/ralph/.bashrc
        backup: yes
        regexp: '^    alias ls=''ls --color=auto''$'
        line: '    alias ls=''ls --color=auto -lahpG'''


    # disable swap

    - name: Check whether a package called dphys-swapfile is installed
      ansible.builtin.package_facts:
        manager: auto

    - name: Turn off "dphys-swapfile"
      ansible.builtin.command: dphys-swapfile swapoff
      when: "'dphys-swapfile' in ansible_facts.packages"

    - name: Uninstall "dphys-swapfile"
      ansible.builtin.command: dphys-swapfile uninstall
      when: "'dphys-swapfile' in ansible_facts.packages"

    - name: Remove and purge "dphys-swapfile" package
      ansible.builtin.apt:
        pkg: dphys-swapfile
        state: absent
        purge: yes
        autoclean: yes
        autoremove: yes
      when: "'dphys-swapfile' in ansible_facts.packages"


    # Configure cgroup

    - name: Enable cgroup in /boot/cmdline.txt
      ansible.builtin.lineinfile:
        path: /boot/cmdline.txt
        backrefs: yes
        regexp: '^console(.*) rootwait$'
        line: '\g<0> cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1'


    # Install and configure Container Runtime

    - name: Install Container Runtime
      ansible.builtin.apt:
        pkg:
          - containerd
          - containernetworking-plugins

    - name: Configure containerd
      ansible.builtin.copy:
        content: |
          version = 2
          [plugins]
            [plugins."io.containerd.grpc.v1.cri"]
              [plugins."io.containerd.grpc.v1.cri".containerd]
                [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
                  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
                    runtime_type = "io.containerd.runc.v2"
                    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
                      SystemdCgroup = true
        dest: /etc/containerd/config.toml
        backup: yes
        owner: root
        group: root
        mode: '0644'


    # Forwarding IPv4 and letting iptables see bridged traffic

    - name: create /etc/modules-load.d/k8s.conf
      ansible.builtin.copy:
        content: |
          overlay
          br_netfilter
        dest: /etc/modules-load.d/k8s.conf
        backup: yes
        owner: root
        group: root
        mode: '0644'

    - name: modprobe overlay
      ansible.builtin.command: modprobe overlay

    - name: modprobe br_netfilter
      ansible.builtin.command: modprobe br_netfilter

    - name: Create /etc/sysctl.d/k8s.conf
      ansible.builtin.copy:
        content: |
          net.bridge.bridge-nf-call-iptables  = 1
          net.bridge.bridge-nf-call-ip6tables = 1
          net.ipv4.ip_forward                 = 1
        dest: /etc/sysctl.d/k8s.conf
        backup: yes
        owner: root
        group: root
        mode: '0644'

    - name: sysctl --system
      ansible.builtin.command: sysctl --system


    # Install kubeadm

    - name: Install apt-transport-https ca-certificates
      ansible.builtin.apt:
        pkg:
          - apt-transport-https
          - ca-certificates
          - curl

    - name: Download the Google Cloud public signing key
      ansible.builtin.get_url:
        url: https://packages.cloud.google.com/apt/doc/apt-key.gpg
        dest: /usr/share/keyrings/kubernetes-archive-keyring.gpg
        owner: root
        group: root
        mode: '0644'

    - name: Add the Kubernetes apt repository
      ansible.builtin.apt_repository:
        repo: "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main"
        state: present
        filename: kubernetes
        update_cache: yes

    - name: Install kubelet kubeadm kubectl
      ansible.builtin.apt:
        pkg:
          - kubelet
          - kubeadm
          - kubectl

    - name: Hold kubelet
      dpkg_selections:
        name: kubelet
        selection: hold

    - name: Hold kubeadm
      dpkg_selections:
        name: kubeadm
        selection: hold

    - name: Hold kubectl
      dpkg_selections:
        name: kubectl
        selection: hold


    # Download and install Flannel

    - name: Download and install Flannel
      ansible.builtin.get_url:
        url: https://github.com/flannel-io/flannel/releases/download/v0.19.2/flanneld-arm64
        dest: /usr/local/bin/flanneld
        owner: root
        group: root
        mode: '0755'

    - name: Create Flannel networks directory
      ansible.builtin.file:
        path: /var/lib/k8s/flannel/networks
        state: directory
        recurse: yes
        owner: root
        group: root
        mode: '0755'


    # reboot

    - name: reboot
      reboot:
You can then run the playbook:

$ ansible-playbook <filename>.yaml
Perform the following steps only on the main host in your cluster.

Initialize the Kubernetes cluster
$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16
I found nothing about the pod-network-cidr parameter and what IP address it needs to be…. but it works so far.

kubeadm init
In the log, you will see a kubeadm join command. Save it in a secure space. You need it later to let the hosts join your cluster. But everyone with this command and internet access to your cluster can also join the cluster with this command.

Copy the Kubernetes config into your home directory:

$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
Add Flannel to the cluster
$ kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
Install MetalLB (External LoadBalancer)
MetalLB hooks into your Kubernetes cluster, and provides a network load-balancer implementation. In short, it allows you to create Kubernetes services of type LoadBalancer in clusters that don’t run on a cloud provider, and thus cannot simply hook into paid products to provide load balancers. (MetalLB)

In short: you need it to access the pods in your cluster from outside.

Add MetalLB to the cluster
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
Configure MetalLB
$ cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 10.0.0.200-10.0.0.250
---
EOF
The addresses must be from the range of your local network. You must also reserve these IP addresses so that your DHCP server can’t assign them to other clients in your network.

Mostly done: add the hosts to the cluster
Now it’s time to add the hosts to the cluster. On each host run the kubeadm join command you got earlier.

add hosts to the cluster
kubectl get nodes -o wide shows all hosts in your cluster


You are now done. The cluster is set up, and you can start using it.

A simple test
Install a small and straightforward pod to test the cluster. The pod does nothing more than respond immediately with ping? pong!

$ cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ping
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ping
  namespace: ping
  labels:
    app: ping
spec:
  selector:
    matchLabels:
      app: ping
  replicas: 2
  template:
    metadata:
      labels:
        app: ping
    spec:
      containers:
        - name: ping
          image: dasralph/ping:arm64_0.0.5
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: ping
  namespace: ping
  labels:
    app: ping
spec:
  type: LoadBalancer
  selector:
    app: ping
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
---
EOF
The script installs the pod two times and creates a service for that. Your cluster should now look like this:


The ping service got an EXTERNAL IP, in this case 10.0.0.200. You can invoke the ping service with curl 10.0.0.200/ping -v. It will also return the IP address of the pod that responded to your request. You will get different IP addresses if you call the curl command repeatedly. This means that not always the same pod responds to your request.


If you want, you can delete the whole ping service with all of its pods with:

$ kubectl delete namespace ping
Kubernetes
K8s
---


FOLLOWED: https://medium.com/karlmax-berlin/how-to-install-kubernetes-on-raspberry-pi-53b4ce300b58


Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.1.63:6443 --token 67x9yz.gd21tqn3qfuw2q4v \
	--discovery-token-ca-cert-hash sha256:691bd225c1658d7c234339e64fbcedf68f68c613d3ec09471beb66791d0b012e


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 10.0.0.200-10.0.0.250
---
EOF

** Adjust the IP ranges to match your network of unasigned IP blocks ()

sudo -E kubectl taint nodes --all node-role.kubernetes.io/control-plane-


cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ping
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ping
  namespace: ping
  labels:
    app: ping
spec:
  selector:
    matchLabels:
      app: ping
  replicas: 2
  template:
    metadata:
      labels:
        app: ping
    spec:
      containers:
        - name: ping
          image: dasralph/ping:arm64_0.0.5
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: ping
  namespace: ping
  labels:
    app: ping
spec:
  type: LoadBalancer
  selector:
    app: ping
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
---
EOF



kubectl get pods --all-namespaces -o wide

kubectl get pods --all-namespaces -o wide
NAMESPACE        NAME                            READY   STATUS    RESTARTS   AGE     IP             NODE    NOMINATED NODE   READINESS GATES
kube-flannel     kube-flannel-ds-872tx           1/1     Running   0          5m50s   192.168.1.63   pi5p1   <none>           <none>
kube-system      coredns-76f75df574-l85tr        1/1     Running   0          6m29s   10.244.0.7     pi5p1   <none>           <none>
kube-system      coredns-76f75df574-v95sj        1/1     Running   0          6m29s   10.244.0.8     pi5p1   <none>           <none>
kube-system      etcd-pi5p1                      1/1     Running   7          6m43s   192.168.1.63   pi5p1   <none>           <none>
kube-system      kube-apiserver-pi5p1            1/1     Running   9          6m43s   192.168.1.63   pi5p1   <none>           <none>
kube-system      kube-controller-manager-pi5p1   1/1     Running   8          6m43s   192.168.1.63   pi5p1   <none>           <none>
kube-system      kube-proxy-ljzqt                1/1     Running   0          6m30s   192.168.1.63   pi5p1   <none>           <none>
kube-system      kube-scheduler-pi5p1            1/1     Running   8          6m43s   192.168.1.63   pi5p1   <none>           <none>
metallb-system   controller-8d6664589-qz7cm      1/1     Running   0          5m44s   10.244.0.9     pi5p1   <none>           <none>
metallb-system   speaker-n75h5                   1/1     Running   0          2m4s    192.168.1.63   pi5p1   <none>           <none>
ping             ping-ccbcdc548-bcwbl            1/1     Running   0          2m44s   10.244.0.10    pi5p1   <none>           <none>
ping             ping-ccbcdc548-d8zwn            1/1     Running   0          2m44s   10.244.0.11    pi5p1   <none>           <none>


kubectl get pods -n ping -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP            NODE    NOMINATED NODE   READINESS GATES
ping-ccbcdc548-9l7fx   1/1     Running   0          5s    10.244.0.13   pi5p1   <none>           <none>
ping-ccbcdc548-zw9jc   1/1     Running   0          5s    10.244.0.12   pi5p1   <none>           <none>
devl@pi5p1:~ $ kubectl get services -n ping -o wide
NAME   TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)        AGE   SELECTOR
ping   LoadBalancer   10.102.212.149   192.168.1.65   80:31567/TCP   11s   app=ping
                                          ^
                                          |
                                          |

curl http://192.168.1.65/ping
ping? pong!%


kubectl delete namespace ping


  334  mv ping-service.yaml ping-deployment.yaml
  335  kubectl apply -f ping-deployment.yaml
  336  kubectl get pods --all-namespaces -o wide
  337  sudo -E kubectl taint nodes --all node-role.kubernetes.io/control-plane-
  338  kubectl get pods --all-namespaces -o wide
  339  kubectl get pods -na pinf -o wide
  340  kubectl get pods -ns ping -o wide
  341  kubectl get pods -n ping -o wide
  342  kubectl delete namespace ping
  343  vi metallb-config.yaml
  344  kubectl apply -f metallb-config.yaml
  345  kubectl get nodes
  346  kubectl apply -f ping-deployment.yaml
  347  kubectl get pods -n ping -o wide
  348  kubectl get services -n ping -o wide
  349  kubectl delete namespace ping
  350  ls
  351  kubectl apply -f kata-runtime.yaml
  352  kubectl apply -f nginx-kata.yaml
  353  kubectl get pods -n ping -o wide
  354  kubectl get pods --all-namespaces -o wide
  355  kubectl get pods  -o wide
  356  kubectl logs nginx-kata
  357  kubectl get pods  -o wide
  358  ps aux | grep qemu
  359  cat nginx-kata.yaml
  360  kubectl get pods --all-namespaces -o wide
  361  kata-runtime check
  362  $ bash -c "$(curl -fsSL https://raw.githubusercontent.com/kata-containers/kata-containers/main/utils/kata-manager.sh) -o"
  363  bash -c "$(curl -fsSL https://raw.githubusercontent.com/kata-containers/kata-containers/main/utils/kata-manager.sh) -o"
  364  $ kata-manager -L
  365  kata-manager -L
  366  kata-manager.sh
  367  $ bash -c "$(curl -fsSL https://raw.githubusercontent.com/kata-containers/kata-containers/main/utils/kata-manager.sh) -h"
  368  bash -c "$(curl -fsSL https://raw.githubusercontent.com/kata-containers/kata-containers/main/utils/kata-manager.sh) -h"
  369  kata-runtime check --only-list-releases
  370  kata-ctl check only-list-releases
  371  which kata-runtime
  372  kata-runtime check --only-list-releases
  373  kata-runtime
  374  $ bash -c "$(curl -fsSL https://raw.githubusercontent.com/kata-containers/kata-containers/main/utils/kata-manager.sh) -L | grep default"
  375  bash -c "$(curl -fsSL https://raw.githubusercontent.com/kata-containers/kata-containers/main/utils/kata-manager.sh) -L | grep default"
  376  wget https://raw.githubusercontent.com/kata-containers/kata-containers/main/utils/kata-manager.sh
  377  ls
  378  chmod +x kata-manager.sh
  379  ./kata-manager.sh -L
  380  ./kata-manager.sh -L | grep default
  381  ./kata-manager.sh -e
  382  which qemu
  383  kata-manager -S qemu
  384  ./kata-manager.sh -S qemu
  385  kubectl apply -f nginx-kata.yaml
  386  kubectl get pods --all-namespaces -o wide
  387  ps aux | grep qemu
  388  kubectl delete -f nginx-kata.yaml
  389  kata-runtime --show-default-config-paths
  390  vi /etc/kata-containers/configuration.toml
  391  ls /opt/
  392  ls /opt/kata/
  393  ls /opt/kata/bin/
  394  /opt/kata/bin/firecracker --version
  395  file /opt/kata/bin/firecracker
  396  sudo /opt/kata/bin/firecracker --version
  397  which kata-runtime
  398  ls -la /usr/bin/kata-runtime
  399  kata
  400  $ command -v containerd
  401  command -v containerd
  402  vi /etc/containerd/config.toml
  403  sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup
  404  sudo vi /etc/containerd/config.toml
  405  ls opt/kata/share/defaults/kata-containers/configuration.tom
  406  ls opt/kata/share/defaults/kata-containers/
  407  ls /opt/kata/share/defaults/kata-containers/configuration.toml
  408  sudo systemctl stop containerd
  409  sudo systemctl daemon-reload
  410  sudo systemctl start containerd
  411  sudo systemctl status containerd
  412  ls
  413  kubectl apply -f nginx-kata.yaml
  414  kubectl get pods --all-namespaces -o wide
  415  ps aux | grep qemu
  416  kubectl get pods --all-namespaces -o wide
  417  cat nginx-kata.yaml
  418  kubectl get pods --all-namespaces -o wide
  419  kubectl get service --all-namespaces -o wide
  420  ps aux | grep qemu
  421  kubectl delete -f nginx-kata.yaml
  422  clear
  423  kubectl get service --all-namespaces -o wide
  424  ps aux | grep qemu
  425  sudo apt install k9s
  426  sudo snap install k9s
  427  k9s
  428  which k9s
  429  sudo snap remove k9s
  430  curl https://github.com/derailed/k9s/releases/download/v0.32.3/k9s_linux_arm64.deb
  431  wget https://github.com/derailed/k9s/releases/download/v0.32.3/k9s_linux_arm64.deb
  432  deb -i k9s_linux_arm64.deb
  433  sudo dpkg -i k9s_linux_arm64.deb
  434  k9s
  435  history


Enabling Kata Containers in Kubernetes
======================================
https://katacontainers.io/docs/getting-started/kubernetes/
version = 2

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      no_pivot = false
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          privileged_without_host_devices = false
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            BinaryName = ""
            CriuImagePath = ""
            CriuPath = ""
            CriuWorkPath = ""
            IoGid = 0
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
          runtime_type = "io.containerd.kata.v2"
          privileged_without_host_devices = true
          pod_annotations = ["io.katacontainers.*"]
          container_annotations = ["io.katacontainers.*"]
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata.options]
            ConfigPath = "/opt/kata/share/defaults/kata-containers/configuration.toml"
    [plugins."io.containerd.grpc.v1.cri".cni]
      conf_dir = "/etc/cni/net.d"
