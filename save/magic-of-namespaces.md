---
title: "Unveiling Container Networking Secrets with nsenter, lsns, and ctr"
linkTitle: "Unveiling Container Networking Secrets..."
date: 2024-03-14
description: >
    Learn how to access container networking services using nsenter, lsns, and ctr.
---

# Introduction:
In the vast realm of container orchestration and management, where the only thing scarier than a broken network is a broken coffee machine, networking plays a crucial role in facilitating communication between containers, services, and the outside world.

However, there are instances where accessing a container's network services might seem like trying to cook a gourmet meal with only a spoon and a tomato. Picture yourself staring down a container named "networking-is-fun," but the fun seems to be hiding behind locked ports and missing tools.

In this blog post, I'll explore how to overcome such challenges using powerful tools like nsenter, lsns, and ctr to interact with containerd networking environments effectively.

## Understanding the Challenge:
In this (Challenge by Ivan Velichko)[https://labs.iximiuz.com/challenges/access-docker-container-with-no-published-ports], you're thrown into a container adventure where accessing an Nginx server seems as elusive as finding the perfect Wi-Fi signal on a remote island. The container, aptly named "networking-is-fun," has no published ports, AND there's no HTTP client installed inside the container. Additionally, executing commands directly within the container is restricted. How can we tackle this challenge and access the Nginx server?

## Enter the Networking Namespace:
By default, each Docker container operates within its own isolated network namespace. It's like each container has its own private bubble bath, but unfortunately, the rubber duckies aren't visible from the outside. These namespaces include network interfaces like the loopback and primary interface, essential for networking within the container. However, these interfaces are not visible from the host's main network namespace, making direct access challenging.

### Using `nsenter` and `lsns`:
To overcome these hurdles, we'll need some _container magic_! Enter `nsenter` and `lsns`, the dynamic duo of container networking. Think of nsenter as the secret agent sneaking into the container's network fortress, while lsns provides the blueprint to locate the fortress in the first place. Armed with these tools, we can locate the "networking-is-fun" container's network namespace and enter it to interact with its networking environment.

Here's a step-by-step approach:

1. Use lsns to list all namespaces:
```bash
$ lsns
```

This command provides an overview of various namespaces, including network namespaces associated with containers.

2. Find the PID of the networking-is-fun container:
```bash
$ lsns -t net | grep nginx
4026532263 net       3  7006 root          0 /run/docker/netns/87630be247ac nginx: master process nginx -g daemon off;
```

This command filters the output of `lsns` to locate the `networking-is-fun` container's (aka nginx) network namespace, revealing its PID.

3. Enter the container's network namespace using nsenter:
```bash
$ nsenter --target <PID> --net
```
> Replace `<PID>` with the PID obtained from the previous step. This command allows us to enter the container's network namespace, providing access to its networking configuration.

4. Interacting with the Nginx Server:

Once inside the container's network namespace, we gain access to its networking environment, including interfaces and services like the Nginx server. It's like sending a message in a bottle to a stranded sailor, except here, the sailor is an Nginx server and the bottle is a cleverly manipulated network namespace. From here, we can send an HTTP request to the server using tools like curl or wget, effectively bypassing the restrictions imposed within the container.

```bash
$ curl http://localhost:80
```

The above command sends an HTTP request to the Nginx server running inside the container, allowing us to interact with its services even though it has no ports published or HTTP client installed!

## Alternate Solution using `ctr`:

1. List all namespaces using ctr:
```bash
$ ctr namespace ls
NAME LABELS 
moby
```

This command provides a list of all namespaces, including the containerd namespace.

2. List all tasks within the moby namespace:
```bash
$ ctr --namespace moby task ls
TASK                                                                PID     STATUS    
3f00e340e5194dddd92f09675a359d20edc7957f0b221f3b9f920f4127c92c30    7006    RUNNING
```

This command lists all tasks within the moby namespace, revealing the PID of the networking-is-fun container.

3. Enter the container's network namespace using ctr:
```bash
$ ctr --namespace moby task exec --exec-id curl1  3f00e340e5194dddd92f09675a359d20edc7957f0b221f3b9f920f4127c92c30 ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
9: eth0@if10: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    link/ether 02:42:ac:12:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.18.0.2/16 brd 172.18.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```

This command enters the container's network namespace and executes the `ip a` command to display the network interfaces and their configurations. Notice the `eth0` interface with the IP address.

4. Interacting with the Nginx Server:
```bash
$ curl http://172.18.0.2:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

This command sends an HTTP request to the Nginx server running inside the container, allowing us to interact with its services even though it has no ports published or HTTP client installed! The trick here is to exploit the IP address of the container's network interface to access the Nginx server.

# Conclusion:
Armed with our trusty tools and a sprinkle of container magic, we emerge victorious from the labyrinth of networking challenges, ready to tackle whatever the containerverse throws our way. Whether it's sneaking into network