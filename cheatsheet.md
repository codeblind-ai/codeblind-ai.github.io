  UPDATE APT PACKAGES FIRST
  sudo apt update
  sudo apt upgrade
  sudo apt install linux-modules-extra-raspi

  SETUP NETPLAN for ETH0 (only wifi is enabled at this point)  
  sudo ip link set dev eth0 up
  sudo dhclient eth0 -v
  sudo dhclient eth0 -v
  sudo vi /etc/netplan/50-cloud-init.yaml
  sudo netplan apply
  sudo netplan status
  sudo reboot
   
  sudo apt update
  echo " cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1" | sudo tee -a  /boot/firmware/cmdline.txt
  sudo reboot

  TURN OFF SWAP!
  sudo dphys-swapfile swapoff
  sudo dphys-swapfile uninstall
  sudo apt purge -y dphys-swapfile
  sudo apt autoremove -y

  INSTALL MICROK8S
  sudo snap install microk8s --classic

  SETUP THE USER FOR MICROK8S WITHOUT SUDO
  cd $HOME
  mkdir .kube
  cd .kube
  sudo microk8s config > config

  DO ALL THE ABOVE AGAIN ON THE SECOND DEVICE (WORKER)

  TO ENABLE THE WORKERS DO THE FOLLOWING ON THE MASTER:
  microk8s add-node

  USING THAT OUTPUT DO THIS ON THE WORKER:
  microk8s join 192.168.1.56:25000/cdf85f4f1ee98d2f37a974bdab8e5075/9126bb4f9f93 --worker


  ON THE MASTER:
  sudo alias kubectl='microk8s kubectl'
  sudo alias ctr='ctr kubectl'

  ENABLE ADD ONS
  sudo microk8s community
  sudo microk8s dashboard
  sudo microk8s hostpath-storage
  sudo microk8s storage
  sudo microk8s dns
  sudo microk8s ingress

  sudo microk8s metallb
  cat <<EOF > metallb-addresspool.yaml
  ---
  apiVersion: metallb.io/v1beta1
  kind: IPAddressPool
  metadata:
    name: custom-addresspool
    namespace: metallb-system
  spec:
    addresses:
    - 192.168.1.65-192.168.1.250
  ---
  apiVersion: metallb.io/v1beta1
  kind: L2Advertisement
  metadata:
    creationTimestamp: null
    name: l2advertisement1
    namespace: metallb-system
  spec:
    ipAddressPools:
    - custom-addresspool
  status: {}
  ---
  EOF
  microk8s kubectl apply -f metallb-addresspool.yaml
  
  sudo microk8s metrics-server
  sudo microk8s ha-cluster
  sudo microk8s helm
  sudo microk8s helm3

  sudo microk8s.kubectl get nodes
  sudo microk8s.kubectl get pods --all-namespaces -o wide


   80  newgrp microk8s




  185  mkdir code
  186  cd code/
  188  wget https://github.com/kata-containers/kata-containers/releases/download/3.2.0/kata-static-3.2.0-arm64.tar.xz
  193  xz -d -v  kata-static-3.2.0-arm64.tar.xz
  206  sudo tar xf kata-static-3.2.0-arm64.tar -C /
  
   // EDIT THE FILE: /var/snap/microk8s/common/addons/community/addons.yaml
  260  microk8s enable kata --runtime-path=/opt/kata/bin

  285  microk8s ctr pull docker.io/library/busybox:latest
  288  time microk8s ctr run --runtime io.containerd.run.kata.v2 -t --rm docker.io/library/busybox:latest hello true
  289  time microk8s ctr run -t --rm docker.io/library/busybox:latest hello true
  
   sudo ln -s /opt/kata/bin/containerd-shim-kata-v2 /bin/containerd-shim-kata-v2
 sudo ln -s /opt/kata/bin/firecracker /bin/firecracker
 sudo ln -s /opt/kata/bin/jailer /bin/jailer
 sudo ln -s /opt/kata/bin/kata-collect-data.sh /bin/kata-collect-data.sh
 sudo ln -s /opt/kata/bin/kata-runtime /bin/kata-runtime

 microk8s enable kata --runtime-path=/opt/kata/bin

74  sudo apt install libvirt-clients
75  virsh list


