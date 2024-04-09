---
title: "Pi goes Great with Kata 🥧"
linkTitle: "🧞 Bottling Genies"
date: 2024-03-18
description: >
  Previously we built a Kubernetes cluster on Raspberry Pi 5. Now we will unlock security and efficiency with Kata Containers on Kubernetes.
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

Kata Containers offers a game-changing solution to the security and performance challenges faced in containerized environments. By seamlessly integrating lightweight VMs with Kubernetes, Kata Containers empowers developers to achieve unprecedented levels of security and efficiency.

Key Features include:
1. Enhanced isolation and security through lightweight VMs
2. Sub-second boot times
3. Hardware virtualization
4. Support for multiple hypervisors
5. GPU passthrough

In this post, we provide a step-by-step configuring of [Kata Containers on Kubernetes](https://katacontainers.io/docs/getting-started/kubernetes/).

## Prerequisites

Previously in the series we've creates a Kubernetes cluster on Raspberry Pi 5. If you haven't done so, please refer to the previous posts.

## Adding Kata Containers to Kubernetes

<details open>
  <summary>1. Install Kata Containers</summary>

  ```bash
  wget https://raw.githubusercontent.com/kata-containers/kata-containers/main/utils/kata-manager.sh
  chmod +x kata-manager.sh
  ./kata-manager.sh -o
  ```
</details>

<details open>
  <summary>2. Determine the available HyperVisor</summary>

  ```bash
  ./kata-manager.sh -L
  ```

  You should expect the following output:
  ```bash
  clh	-	packaged	golang
  dragonball	-	packaged	golang
  fc	-	packaged	golang
  qemu	default	packaged	golang
  qemu-nvidia-gpu	-	packaged	golang
  qemu-sev	-	packaged	golang
  qemu-snp	-	packaged	golang
  qemu-tdx	-	packaged	golang
  ```
  > Notice by default we have `qemu` as the default hypervisor
</details>

<details open>
  <summary>3. Install QEMU</summary>

  ```bash
  sudo apt install qemu-system
  ```
</details>

<details open>
  <summary>4. Update the containerd configuration</summary>

  #### We are **overwriting** the current containerd configuration

  ```bash
  sudo cat <<EOF > /etc/containerd/config.toml
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
  EOF
  ```

  #### Now restart containerd

  ```bash
  sudo systemctl stop containerd
  sudo systemctl daemon-reload
  sudo systemctl start containerd
  sudo systemctl status containerd
  ```

</details>

<details open>
  <summary>5. Enable Kata Containers Runtime Class</summary>

  ```bash
  cat <<EOF > runtime.yaml
  apiVersion: node.k8s.io/v1
  kind: RuntimeClass
  metadata:
    name: kata
  handler: kata
  EOF

  kubectl apply -f runtime.yaml
  ```
</details>

<details open>
  <summary>6. Redeploy PingPong using kata containers and QEMU</summary>

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
        runtimeClassName: kata
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

  Check that the nodes are running:
  ```
  kubectl get pods -n ping -o wide
  ```
</details>

<details open>
  <summary>7. Check hypervisor is running</summary>

  
  ```bash
  ps aux | grep qemu
  ```

  Expected output looks similar to the following:
  ```bash
  ps aux | grep qemu
  root       83180  6.3  1.6 2730640 135824 ?      Sl   02:16   0:02 /opt/kata/bin/qemu-system-aarch64 -name sandbox-26519d5f8744b3d582b81dd8986b591d055bf3debcd2e498e5947efb4abe60d7 -uuid...
  ```
</details>

### Conclusion
Enabling Kata Containers is a game-changer for security and performance; not to mention not terribly hard. We've seen how to install Kata Containers, determine the available hypervisor, install QEMU, update the containerd configuration, enable Kata Containers Runtime Class, and redeploy PingPong using Kata Containers and QEMU.

Stay tuned for more on how to leverage Kata Containers using Firecracker as the VM hypervisor.

