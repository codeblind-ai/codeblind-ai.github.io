---
title: "Mighty Pi PaaS: 🚀 Unleashing MicroK8s"
linkTitle: "🫙 Canning Clouds"
date: 2024-03-15
description: >
  Let's embarking on an exhilarating journey to transform our RPi 5 private cloud infrastructure into an operational PaaS using Kubernetes; or canning the cloud as I like to call it. We will be setting up a Kubernetes version named MicroK8s. MicroK8s is a powerful and lightweight Kubernetes cluster for all your container orchestration needs.
  
  Are you ready? I know, I am! Let's dive in!  
---

Infrastructure as a Service (IaaS) is a cloud computing model that provides users with virtualized computing resources such as servers, storage, networking, and virtualization on-demand over the internet.

Platform as a Service (PaaS) is a cloud computing model that offers a complete development and deployment environment in the cloud. It provides developers with tools and resources to build, deploy, and manage applications without having to worry about underlying infrastructure management.

At this stage, we are setting up a working Kubernetes cluster on our Raspberry Pi 5, which serves as our IaaS foundation. Kubernetes enables us to access computing resources such as servers, networking, and compute (containers) on our Pi cluster.

With Kubernetes installed, we can deploy and manage containers and services on our cluster. Additionally, we can access these services from our home network, laying the groundwork for our IaaS infrastructure.

MicroK8s is a lightweight and easy-to-use Kubernetes distribution that is perfect for running on resource-constrained environments like Raspberry Pi. In this guide, we'll walk through the process of setting up a MicroK8s cluster on Raspberry Pi devices, enabling you to harness the power of Kubernetes for your projects.

## Prerequisites

Before we begin, ensure you have the following:

* Raspberry Pi devices (at least two for setting up a cluster)
* Ubuntu 23.04 LTS installed and configured
* Internet connectivity on Raspberry Pi devices
* Basic familiarity with the command line interface

## 1. Update the Operating System Packages

Ensure your Raspberry Pi devices are up to date and have necessary packages installed:

```bash
sudo apt update
sudo apt upgrade
sudo apt install linux-modules-extra-raspi
```

## 2. Configure Network Settings

Use [Netplan](https://netplan.io/) to configure network settings to ensure connectivity.

```bash
# Set up Ethernet connection (if not already enabled)
sudo ip link set dev eth0 up
sudo dhclient eth0 -v
sudo vi /etc/netplan/50-cloud-init.yaml
sudo netplan apply
```

## 2. Disable Swap

Disabling swap in Kubernetes environments is crucial for maintaining performance, stability, and effective resource management by preventing unnecessary swapping of memory to disk..

```bash
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo apt purge -y dphys-swapfile
sudo apt autoremove -y
```

## 3. Configuring the Kernel CGroup Support

1. enable cgroups in the kernel by running the following command:
    ```bash
    sudo sed -i '/^console.*=BL/s/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/firmware/cmdline.txt
    ```

2. now reboot the RPi to activate these settings:
    ```bash
    sudo reboot
    ```
   
## 4. Installing MicroK8s
Install MicroK8s using Snap:

```bash
sudo snap install microk8s --classic
```

## 5. Configure the MicroK8s user without requiring sudo:

After navigating to the home directory and creating the `.kube` directory, use the microk8s config command to configure the MicroK8s user settings.

```bash
cd $HOME
mkdir .kube
cd .kube
sudo microk8s config > config
```

## 6. Configure the User for MicroK8s
Configure the a microk8s group so sudo is not required by the user:

```bash
sudo usermod -aG microk8s "$USER"
```

> If you are provisioning more than one RPi 5 to be part of the cluster, such as in my case I have five, you will want to repeat steps 1 through 6 on each RPi.


## 7. Clustering Workers
Decide which Raspberry Pi will be the master and which ones will be workers. Add worker nodes to the cluster.

1. On the master node run the following command to identify the worker join command:
    ```bash
    microk8s add-node
    ```
    
    Example output:
    ```bash
    From the node you wish to join to this cluster, run the following:
    microk8s join 192.168.1.56:25000/0f112c22f3bbdb062abaab9a3d65c0a2f/421deadbeef

    Use the '--worker' flag to join a node as a worker not running the control plane, eg:
    microk8s join 192.168.1.56:25000/0f112c22f3bbdb062abaab9a3d65c0a2f/421deadbeef --worker

    If the node you are adding is not reachable through the default interface you can use one of the following:
    microk8s join 192.168.1.56:25000/0f112c22f3bbdb062abaab9a3d65c0a2f/baddeadbeef
    microk8s join 192.168.1.57:25000/0f112c22f3bbdb062abaab9a3d65c0a2f/421deadbeef
    ```

2. Since we are only adding workers, and don't plan to add more controller nodes, we only want to run the following command from above on each worker:
    ```bash
    microk8s join 192.168.1.56:25000/0f112c22f3bbdb062abaab9a3d65c0a2f/421deadbeef --worker
    ```
    > note you will get a different value for `microk8s join <master-ip>:25000/<token>/<hash> --worker`

3. Validate the nodes have joined the cluster
   ```
   $ microk8s kubectl get nodes
    NAME    STATUS     ROLES    AGE   VERSION
    pi5p0   Ready      <none>   18d   v1.28.7
    pi5p1   Ready      <none>   18d   v1.28.7
    pi5p2   Ready      <none>   18d   v1.28.7
    pi5p3   Ready      <none>   18d   v1.28.7
    pi5p4   Ready      <none>   18d   v1.28.7
   ```
  > Each node should be listed and ready

## 7. Configuring Aliases
Set up aliases for easier command-line usage.

```bash
echo "alias kubectl='microk8s kubectl'" >> ~/.bashrc
echo "alias ctr='ctr kubectl'"" >> ~/.bashrc
source ~/.bashrc
```

> I recommend doing this on all nodes.


## Enabling Add-ons
Enable essential add-ons for your MicroK8s cluster, such as the dashboard, DNS, and community.

```bash
sudo microk8s enable dashboard dns community
```

## Test your deployment

Deploy a hello world application and verify its status.

1. Deploy a hello world application
    ```bash
    kubectl create deployment hello-node --image=registry.k8s.io/e2e-test-images/agnhost:2.39 -- /agnhost netexec --http-port=8080
    ```

2. Check to see if the pod is ready
    ```
    kubectl get deployments
    ```
  > note sometimes it may take a second to pull the image

3. Inspect the pods
    ```bash
    kubectl get pods
    ```
4. Check the events of the deployment
    ```bash
    kubectl get events
    ```


# Summary 

In this guide, we've successfully transformed our Raspberry Pi 5 devices into a powerful Kubernetes cluster using MicroK8s. By following the step-by-step instructions, we've laid the foundation for our PaaS infrastructure, enabling us to deploy and manage containerized applications with ease. We've learned how to configure network settings, install MicroK8s, add worker nodes, and enable essential add-ons.

Next, we'll explore adding the MetalLB add-on and configuring our Home Router to expose our services to our LAN, taking our PaaS infrastructure to the next level. Stay tuned for more exciting developments in our journey to canning clouds with Raspberry Pi!