---
title: "Mighty Pi IaaS 🫙"
linkTitle: "🫙 Canning Clouds"
date: 2024-03-16
description: >
  Let's embarking on an exhilarating journey to build the foundation of our private cloud Infrastructure as a Service (IaaS) using the Raspberry Pi 5 and Kubernetes; or canning the cloud as I like to call it. Are you ready? I know I am. Let's dive right in!
---

<style>
  aside {
    width: 40%;
    padding-left: 0.5rem;
    margin-left: 0.5rem;
    float: right;
    box-shadow: inset 5px 0 5px -5px #29627e;
    font-style: italic;
    color: #29627e;
  }

  aside > p {
    margin: 0.5rem;
  }

  summary {
    font-weight: bold;
    font-size: 1.1em;
  }

  details > summary {
    list-style-type: '✅ ';
    color: #666666;
  }

  details[open] > summary {
    list-style-type: '🟩 ';
    color: #333333;
  }
  
  table {
    margin-left: 30px;
  }

</style>

Infrastructure as a Service (IaaS) is a cloud computing model that provides users with virtualized computing resources such as servers, storage, networking, and virtualization on-demand over the internet.

Platform as a Service (PaaS) is a cloud computing model that offers a complete development and deployment environment in the cloud. It provides developers with tools and resources to build, deploy, and manage applications without having to worry about underlying infrastructure management.

At this stage, we are setting up a working Kubernetes cluster on our Raspberry Pi 5, which serves as our IaaS foundation. Kubernetes enables us to access computing resources such as servers, networking, and compute (containers) on our Pi cluster.

With Kubernetes installed, we can deploy and manage containers and services on our cluster. Additionally, we can access these services from our home network, laying the groundwork for our IaaS infrastructure.

In our [previous post]({{< ref "/blog/posts/rpi5-no-2-the-mighty-pi-hw-prep.md" >}}), we prepared our Raspberry Pi 5 for this setup. If you will need to prepare your Raspberry Pi 5, please refer to that post, then come back here to continue.

## Installing Kubernetes on Raspberry Pi 5

<details open>
  <summary>1. Update your Raspberry Pi</summary>

  Before we install Kubernetes, we need to update the OS. This is important to ensure that your Raspberry Pi 5 is up to date with the latest packages and security fixes.

  <img src="/images/blogs/rpi5-cloud/rpi5-k8s-1.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">

  ```bash
  ssh -i ~/.ssh/id_pidev_rsa devl@192.168.1.57
  sudo apt update -y && sudo apt dist-upgrade -y
  sudo reboot
  ```
  > <i class="fa fa-exclamation-triangle" aria-hidden="true" style="color: orange;">&nbsp;</i> use your previously configured  SSH key, username, and IP address.

</details>


<details open>
  <summary>2. Enable Linux Kernel cgroups support</summary>

  Add `cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1` to the end of the `/boot/firmware/cmdline.txt` file. The content of this file is one line without any line breaks. This file provides the kernel parameters at boot time for the Operating System.

  > <i class="fa fa-exclamation-triangle" aria-hidden="true" style="color: orange;">&nbsp;</i>On RPi4 the file you should edit is `/boot/firmware/cmdline.txt`, however on RPi5 the file is `/boot/cmdline.txt`. Adjust the command below depending on your Raspberry Pi model.
 
  <img src="/images/blogs/rpi5-cloud/rpi5-k8s-2.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">

  ```bash
  echo " cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1" | sudo tee -a  /boot/firmware/cmdline.txt
  ```
  > <i class="fa fa-exclamation-triangle" aria-hidden="true" style="color: orange;">&nbsp;</i>Don't forget the leading space!
 
  Now reboot, and then log back in to continue.
  ```bash
  sudo shutdown -r now
  ```
</details>
<details open>
  <summary>3. Disable and uninstall swap</summary>

  <img src="/images/blogs/rpi5-cloud/rpi5-k8s-3.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">

  ```bash
  sudo dphys-swapfile swapoff
  sudo dphys-swapfile uninstall
  sudo apt purge -y dphys-swapfile
  sudo apt autoremove -y
  ```

  > <i class="fa fa-lightbulb" aria-hidden="true" >&nbsp;</i> This section focuses on optimizing performance in Kubernetes deployments. The primary goal of Kubernetes is to maximize resource utilization by tightly packing instances. It is crucial to set CPU and memory limits for all deployments. By doing so, pods should never rely on swap space, as swapping can significantly degrade performance. Avoiding swap usage is essential for maintaining optimal speed and efficiency in your Kubernetes cluster.

  Test that swap has been disabled by running `free -m`.

  <img src="/images/blogs/rpi5-cloud/rpi5-k8s-4.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">

</details>

<details open>
  <summary>4. Install the Container Runtime</summary>

  <img src="/images/blogs/rpi5-cloud/rpi5-k8s-5.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">

  The following steps will install containerd and necessary plugins for networking:

  ```bash
  sudo apt install -y containerd containernetworking-plugins
  ```

</details>

<details open>
  <summary>5. Configure the Container Runtime</summary>

  Here we are configuring containerd with cgroup support.

  After installation, containerd will come with a default configuration file in `/etc/containerd/config.toml`.  We need to modify this file to enable cgroup support.

  <img src="/images/blogs/rpi5-cloud/rpi5-k8s-6.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">

  Run the following to _**replace**_ the contents:

  ```bash
  cat <<EOF | sudo tee /etc/containerd/config.toml
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
  ```

  <i class="fa fa-circle-info" aria-hidden="true" style="color: lightblue;">&nbsp;</i> Whats going on here?

  > The configuration instructs containerd to use the runc runtime with cgroup support enabled for systemd. This setup ensures compatibility with Kubernetes and allows containers to be managed effectively using containerd. <details>
  > <ul>
  >   <li><code>[plugins]</code> > Defines containerd plugins.</li>
  >   <li><code>[plugins."io.containerd.grpc.v1.cri"]</code> > Specifies CRI plugin for gRPC v1.</li>
  >   <li><code>[plugins."io.containerd.grpc.v1.cri".containerd]</code> > Configures containerd settings for CRI plugin.</li>
  >   <li><code>[plugins."io.containerd.grpc.v1.cri".containerd.runtimes]</code> > Defines runtimes used by containerd in CRI context.</li>
  >   <li><code>[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]</code> > Specifies runc runtime, default for Kubernetes.</li>
  >   <li><code>runtime_type = "io.containerd.runc.v2"</code> > Sets runtime type to io.containerd.runc.v2.</li>
  >   <li><code>[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]</code> > Contains additional options for runc runtime.</li>
  >   <li><code>SystemdCgroup = true</code> > Enables cgroup support for systemd in runc.</li>
  > </ul>
  > </details>

</details>


<details open>
  <summary>6. Configure IPv4 Forwarding and enable iptables to see bridged traffic</summary>

  <img src="/images/blogs/rpi5-cloud/rpi5-k8s-7.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">

  ```bash
  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
  overlay
  br_netfilter
  EOF
  
  sudo modprobe overlay
  sudo modprobe br_netfilter
  
  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
  net.bridge.bridge-nf-call-iptables  = 1
  net.bridge.bridge-nf-call-ip6tables = 1
  net.ipv4.ip_forward                 = 1
  EOF
  
  sudo sysctl --system
  ```
  <i class="fa fa-circle-info" aria-hidden="true" style="color: lightblue;">&nbsp;</i> Whats going on here?
  * `overlay` and `br_netfilter` are kernel modules that need to be loaded for Kubernetes to work.
  * `modprobe` is used to add a module from the Linux kernel without restarting.
  * `net.bridge.bridge-nf-call-iptables` and `net.bridge.bridge-nf-call-ip6tables` are set to 1 to enable iptables to see bridged traffic within the cluster configuration.
    * `net.ipv4.ip_forward` is set to 1 to enable IPv4 forwarding.
  * `sysctl --system` is used to reload the configuration file.
  
</details>


<details open>
  <summary>7. Install kubeadm</summary>
  
  ```bash
  sudo apt update
  
  # apt-transport-https may be a dummy package; if so, you can skip that package
  sudo apt-get install -y apt-transport-https ca-certificates curl gpg

  # Download the public signing key for the Kubernetes package repositories. The same signing key is used for all repositories so you can disregard the version in the URL
  # If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
  # sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  # Add the appropriate Kubernetes apt repository. Please note that this repository have packages only for Kubernetes 1.29; for other Kubernetes minor versions, you need to change the Kubernetes minor version in the URL to match your desired minor version (you should also check that you are reading the documentation for the version of Kubernetes that you plan to install).
  # This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

  # Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version:
  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm kubectl
  sudo apt-mark hold kubelet kubeadm kubectl

  # (Optional) Enable the kubelet service before running kubeadm:
  sudo systemctl enable --now kubelet
  ```
  > <i class="fa fa-circle-info" aria-hidden="true" style="color: lightblue;">&nbsp;</i>`kubelet` is now restarting every few seconds. It waits in a crashloop for `kubeadm` to tell it what to do.

</details>

<details open>
  <summary>8. Install Cluster Networking</summary>

  Flannel is a simple, and easy way to configure a layer 3 network fabric designed for Kubernetes. Other options include:

  * [Calico](https://docs.tigera.io/calico/latest/about) - Calico is a L3 networking (CNI) and security (policy) solution that enables Kubernetes workloads and non-Kubernetes/legacy workloads to communicate seamlessly and securely. 
  * [Cilium](https://cilium.io/#networking) - eBPF-based Networking, Observability, Security, and Load-Balancing

  <!--[Learn more about Calico differences on this blog post](https://medium.com/@jain.sm/flannel-vs-calico-a-battle-of-l2-vs-l3-based-networking-5a30cd0a3ebd) -->
  Flannel is an overlay network mechanism where as Calico is a pure L3 solution.
  
  Flannel works by using a `vxlan` device in conjunction with a software switch like linux bridge or ovs.
  > Learn more about [vxlan here](https://www.juniper.net/us/en/research-topics/what-is-vxlan.html).

  <img src="/images/blogs/rpi5-cloud/flannel-overlay.png" alt="Flannel" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">

  Container A when tries to reach container B on different host the traffic is pushed to the bridge on host A via the VETH pair. The bridge then based on ARP tries to get the mac of container B. Since container B is not on the host the traffic by bridge is forwarded at L2 to the vxlan device (software TAP device) which then allows flannel daemon software to capture those packets and then wrap then into a L3 packet for transport over a physical network using UDP. Also vxlan tagging is added to the packet to isolate them between tenants.

  ```bash
  sudo wget https://github.com/flannel-io/flannel/releases/download/v0.24.3/flanneld-arm64 \
    -O /usr/local/bin/flanneld && sudo chmod +x /usr/local/bin/flanneld && \
    sudo mkdir -p /var/lib/k8s/flannel/networks
  ``` 
</details>


<details open>
  <summary>8. Initialize Kubernetes Cluster (Main Host Only)</summary>

  > <i class="fa fa-circle-info" aria-hidden="true" style="color: lightblue;">&nbsp;</i> If you are building a cluster, with more than one RPi, this step is only necessary on the main host of the cluster.

  ```bash
  sudo kubeadm init --pod-network-cidr=10.244.0.0/16
  ```

  #### Usage of 192.168.xxx, 172.xxx and 10.xxx in private networks</summary>
  
  > [RFC 1918](https://www.rfc-editor.org/rfc/rfc1918) allocates private address space to allow for internal IP address ranges to prevent external routing collisions:
  > * `10.0.0.0/8`
  > * `172.16.0.0/12` (not 172.0.0.0/8!!!)
  > * `192.168.0.0/16`
  > 
  > These are private ranges which allow us to engineer the network, often using NAT, to allow services on those networks to reach internet resources.
  > 
  > We can't simply chose any range we wish outside of those as they are likely real IP addresses associated with real domains. This would cause either internal or external routing issues. Could we break the internet? not likely - but out services would not work.
  > 
  > For example, If we used `8.0.0.0/8` for private address space, we would not be able to reach the google DNS server address `8.8.8.8`, because we would have an internal route for that block.
  > 
  > In addition, even if our "private" servers did not need to reach the internet at all, if some external entity (eg. A user) tried to reach your public webapp, and our webapp had an internal routing table (with an 8-net route), the replies would not get back to the caller.


  <img src="/images/blogs/rpi5-cloud/rpi5-k8s-8.png" alt="Raspberry Pi 5" style="width: 90%; display: block; margin-left: auto; margin-right: auto;">

  ##### Copy the Kubernetes config into your home directory

  Copying the Kubernetes configuration file into your home directory allows you to use `kubectl` without needing to be root.

  ```bash
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  ```
  > <i class="fa fa-warning" aria-hidden="true" style="color: orange;">&nbsp;</i> This file can also be copied to your local machine to use `kubectl` from your local terminal. Be aware, at this time the file contains sensitive information, so be careful where you copy it to. Also we have not added any type of authentication to the cluster, so anyone with this file can control the cluster. We will do that in a later post.
</details>

<details open>
  <summary>9. Add Flannel to the cluster</summary>
  Earlier we installed the FlannelD binary, now we need to apply the Flannel YAML to the cluster.

  <img src="/images/blogs/rpi5-cloud/rpi5-k8s-9.png" alt="Raspberry Pi 5" style="width: 90%; display: block; margin-left: auto; margin-right: auto;">

  ```bash
  kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
  ```
</details>

<details open>
  <summary>10. Install MetalLB</summary>
  
  [MetalLB](https://metallb.universe.tf/) is a load-balancer implementation for bare metal Kubernetes clusters, using standard routing protocols. Kubernetes, out of the box, does not offer an implementation of network load balancers ([Services of type LoadBalancer](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/)) for bare-metal clusters.

  Bare-metal cluster operators are left with two lesser tools to bring user traffic into their clusters, “NodePort” and “externalIPs” services. Both of these options have significant downsides for production use, which makes bare-metal clusters second-class citizens in the Kubernetes ecosystem.

  MetalLB allows our Kubernetes cluster to behave just like any other public IaaS provider, so that external services on bare-metal clusters “just work”.

  <img src="/images/blogs/rpi5-cloud/rpi5-k8s-10.png" alt="Raspberry Pi 5" style="width: 90%; display: block; margin-left: auto; margin-right: auto;">

  #### Enable ARP advertisement in IPVS mode for kube-proxy
  ```bash
  # see what changes would be made, returns nonzero returncode if different
  kubectl get configmap kube-proxy -n kube-system -o yaml | \
  sed -e "s/strictARP: false/strictARP: true/" | \
  kubectl diff -f - -n kube-system

  # actually apply the changes, returns nonzero returncode on errors only
  kubectl get configmap kube-proxy -n kube-system -o yaml | \
  sed -e "s/strictARP: false/strictARP: true/" | \
  kubectl apply -f - -n kube-system
  ```

  #### Add metallb to the cluster
  ```bash
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
  ```

  #### Configure MetalLB
  ```bash
  cat <<EOF > metallb-config.yaml
  apiVersion: metallb.io/v1beta1
  kind: IPAddressPool
  metadata:
    creationTimestamp: null
    name: default
    namespace: metallb-system
  spec:
    addresses:
    - 192.168.1.65-192.168.1.250
  status: {}
  ---
  apiVersion: metallb.io/v1beta1
  kind: L2Advertisement
  metadata:
    creationTimestamp: null
    name: l2advertisement1
    namespace: metallb-system
  spec:
    ipAddressPools:
    - default
  status: {}
  ---
  EOF
  kubectl apply -f metallb-config.yaml
  ```

  > <i class="fa fa-exclamation-triangle" aria-hidden="true" style="color: orange;">&nbsp;</i> The `addresses` range should be within the same subnet as your personal LAN network. For example, I login to the admin console on my ISP provided router. In the DHCP settings, I can limit the block of addresses on my network (for example from 192.168.1.2 to 192.168.1.64). This allows me to use address ranges outside of that for LoadBalancer IP addresses assigned by MetalLB. 
  >
  > Thus, you should log into your router, and find the DHCP settings to see what range of addresses are being used. Then you can use the remaining addresses for MetalLB. You may want to adjust the range, but note that the changes will not automatically reassign IP addresses to existing devices (such as your TV), so you may need to reboot devices to get a new IP address.
  >
  > *Additionally* - this is using L2 ARP to advertise the IP addresses. This is the simplest way to get MetalLB working, but it may not work in all environments. I might recommend becoming familiar with the differences. BGP is much more efficient, but our scale is not large enough to warrant the complexity of BGP. Read more about the [differences here](https://metallb.universe.tf/concepts/layer2/).

</details>

## _Almost done_ - Let's give it a test!

To this point you have only configured a controller. We can't schedule work on the controller because it is not a worker node. However we can enable it to run containers by running the following command:

```bash
kubectl taint nodes <node-name> node-role.kubernetes.io/control-plane-
```
> `node-name` is the name of the node you want to revert. For example my controller is named `pi4p0`.

Later, when you add worker nodes, once we have added more nodes, we can revert this by running:
  
```bash
kubectl taint nodes pi4p0 node-role.kubernetes.io/control-plane=effect:NoSchedule
```

Validate that the controller is now a worker node by running:

```bash
kubectl get nodes -o wide
```

<img src="/images/blogs/rpi5-cloud/rpi5-k8s-11.png" alt="Raspberry Pi 5" style="width: 90%; display: block; margin-left: auto; margin-right: auto;">

##### Now that we can run a workload on the controller, let's deploy a simple web server!

<details open>
  <summary>11. Deploy a simple web server</summary>

  Let's install a simple pod to test the cluster. The pod does nothing more than respond immediately with ping? pong!

  ```bash
  cat <<EOF > pingpong-service.yaml
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
  kubectl apply -f pingpong-service.yaml
  ```

  The script installs the pod two times and creates a service for that. Your cluster should now look like this:

  <img src="/images/blogs/rpi5-cloud/rpi5-k8s-12.png" alt="Raspberry Pi 5" style="width: 90%; display: block; margin-left: auto; margin-right: auto;">

  ```bash
  kubectl --namespace ping get pods -o wide
  kubectl --namespace ping get services -o wide
  ```

  Now, let's test we can get to the services from our network! On another machine on the network, for example your laptop. Open a console and run:

  ```bash
  curl http://192.168.1.65/ping
  ```
  > **Note:** The IP address will be different for you. You can find the IP address by running `kubectl get services -o wide` and looking for the `EXTERNAL-IP` address.


  You should see a response like this:

  ```bash
  ping? pong!
  ```

  That's it! You have a working Kubernetes cluster on your Raspberry Pi 5! Notice a couple of really cool things:
  1. You are running a service on a Raspberry Pi 5!
  2. Your pods are getting assigned IP addresses within your home LAN - making them accessible without any special configuration (ie. ip, veths, routes, namespace bridging, and iptables).
</details>

<details open>
  <summary>12. Clean up</summary>

  Earlier we deployed a simple web server. Now let's clean up the cluster by removing the deployment and service.

  ```bash
  kubectl delete -f pingpong-service.yaml
  ```

  Also we tainted our controller node. In the next post we will be adding more nodes to the cluster, so let's revert the taint on the controller.

  ```bash
  kubectl taint nodes <node-name> node-role.kubernetes.io/control-plane=effect:NoSchedule
  ```
  > `node-name` is the name of the node you want to revert. For example my controller is named `pi4p0`.

</details>


# Conclusion
In this exciting journey, we completed the task of building the foundation of our private cloud Infrastructure as a Service (IaaS) using the Raspberry Pi 5 and Kubernetes.

What we have accomplished:
* Successfully updated the Raspberry Pi's operating system and configured the container runtime.
* Deployed essential components like ContainerD, KubeAdmin, and Flannel and MetalLB enhancing the functionality of our Kubernetes cluster.
* Established a robust IaaS infrastructure, laying the groundwork for future expansion and deployment of workloads.

Stay tuned as we continue to explore the possibilities and push the boundaries of what's possible with our Mighty Pi IaaS.