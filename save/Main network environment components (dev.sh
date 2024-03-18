Main network environment components (devices, routing tables, firewall rules)
What constitutes a Linux network environment, a.k.a. a networking context? Well, obviously, a set of network devices. What else? Probably, some routing rules. And, of course not to forget - netfilter hooks, including those that are defined by iptables rules. There are more components, but the above should suffice for our purposes in this tutorial.
Linux network environment visualized.
We can quickly forge a (no comprehensive) script to inspect the network environment:
inspect-net-context.sh
#!/usr/bin/env bash

echo "# Network devices"
ip link list

echo -e "\n# Route table"
ip route list

echo -e "\n# iptables rules"
iptables --list-rules
Copy to clipboard
Before running it, though, let's add a new iptables chain to make the set of rules more recognizable:
💡 All commands in this tutorial are supposed to be run as root or prefixed with sudo.
iptables --new-chain MY_CUSTOM_CHAIN
Copy to clipboard
After that, execution of the inspect script on my machine produces the following output: If we run the script on a typical Linux machine, we'll get the output similar to the following:
~/inspect-net-context.sh
Copy to clipboard
# Network devices
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
...
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 92:b2:3d:42:ed:22 brd ff:ff:ff:ff:ff:ff

# Route table
default via 172.16.0.1 dev eth0
172.16.0.0/16 dev eth0 proto kernel scope link src 172.16.0.2

# iptables rules
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
-N MY_CUSTOM_CHAIN
Copy to clipboard
Why do we need to inspect the network environment? Because we're going to start creating containers soon, and we want to make sure that each of them will get its own networking context, fully isolated from the host's and other containers' environments. For that, we'll need to get used to listing the network devices, routing and iptables rules.
👨‍🎓 For the sake of simplicity, instead of creating full-blown containers that leverage all possible Linux namespaces, in this tutorial we'll restrict the scope of virtualization to networking context only. Thus, a container and a network namespace below will be used interchangeably.
Creating the first container using a network namespace (netns)
You've likely already heard, that one of the Linux namespaces used to create containers is called netns or network namespace. From man ip-netns, "network namespace is logically another copy of the network stack, with its own routes, firewall rules, and network devices."
One of the ways to create a network namespace in Linux is to use the ip netns add command (where the ip utility comes from the de facto standard iproute2 collection):
ip netns add netns0
Copy to clipboard
To check that the new namespace has been added to the system, run the following command:
ip netns list
Copy to clipboard
netns0
Copy to clipboard
How to start using the just created namespace? There is another handy Linux utility called nsenter. It enters one or more of the specified namespaces and then executes the given program in it. For instance, here is how we can start a new shell session inside the netns0 namespace:
nsenter --net=/run/netns/netns0 bash
Copy to clipboard
The newly created bash process now lives in the netns0 namespace. If we run our inspect script in this new shell, we'll get the following output:
~/inspect-net-context.sh
Copy to clipboard
# Network devices
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00

# Route table

# Iptables rules
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
Copy to clipboard
The above output clearly shows that the bash process that runs in the netns0 namespace has a totally different network environment - there is no routing rules at all, no MY_CUSTOM_CHAIN iptables chain, and only one network device, the loopback. So far, so good!
Linux network namespace visualized
To solidify the knowledge obtained in the above section, try solving a challenge:


root@ubuntu-01:~# ip netns exec my-net-ns ip link ls
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
root@ubuntu-01:~# ip netns exec my-net-ns ip a
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 0


Connecting containers to host using virtual Ethernet devices (veth)
A new isolated network environment would be not so useful if we could not communicate with it. Luckily, Linux provides a special facility to connect network namespaces - a virtual Ethernet device or veth. From man veth, "veth devices are virtual Ethernet devices. They can act as tunnels between network namespaces to create a bridge to a physical network device in another namespace, but can also be used as standalone network devices."
Virtual Ethernet devices always go in pairs. No worries if it sounds a bit confusing, it'll be clear when we take a look at the usage example.
⚠️ The nsenter command we used above started a nested shell session in the netns0 network namespace. Don't forget to exit it or open a fresh terminal tab before proceeding to the next steps.
From the root network namespace, let's create a pair of virtual Ethernet devices:
ip link add veth0 type veth peer name ceth0
Copy to clipboard
With this single command, we just created a pair of interconnected virtual Ethernet devices. The names veth0 and ceth0 have been chosen arbitrarily:
ip link list
Copy to clipboard
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
...
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 92:b2:3d:42:ed:22 brd ff:ff:ff:ff:ff:ff
5: ceth0@veth0: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether b2:d3:e4:24:c3:f1 brd ff:ff:ff:ff:ff:ff
6: veth0@ceth0: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 4e:ac:e0:3c:d8:6e brd ff:ff:ff:ff:ff:ff
Copy to clipboard
Both veth0 and ceth0 after creation reside in the host's networking context - i.e., in the root network namespace. To connect the root namespace with the netns0 namespace that we created earlier, we need to keep one of the devices in the root namespace and move another one into the netns0:
ip link set ceth0 netns netns0
Copy to clipboard
Waiting for one or more previous tasks to complete
Let's make sure one of the devices disappeared from the root networking context:
ip link list
Copy to clipboard
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
...
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 92:b2:3d:42:ed:22 brd ff:ff:ff:ff:ff:ff
6: veth0@if5: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 4e:ac:e0:3c:d8:6e brd ff:ff:ff:ff:ff:ff link-netns netns0
Copy to clipboard
Once we turn the veth devices on and assign proper IP addresses, any packet occurring on one of the devices will immediately pop up on its peer device, effectively connecting the two network namespaces.
Let's start from the root namespace:
ip link set veth0 up
Copy to clipboard
Waiting for one or more previous tasks to complete
ip addr add 172.18.0.11/16 dev veth0
Copy to clipboard
Waiting for one or more previous tasks to complete
...and continue in the netns0 namespace:
nsenter --net=/run/netns/netns0 bash
Copy to clipboard
In the new shell session that runs in the netns0 namespace:
ip link list
Copy to clipboard
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
5: ceth0@if6: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether da:08:47:8b:8f:c7 brd ff:ff:ff:ff:ff:ff link-netnsid 0
Copy to clipboard
Seem like the loopback device is down in new namespaces, so we need to turn it on first:
ip link set lo up
Copy to clipboard
Waiting for one or more previous tasks to complete
Now, back to the ceth0 device:
ip link set ceth0 up
Copy to clipboard
Waiting for one or more previous tasks to complete
ip addr add 172.18.0.10/16 dev ceth0
Copy to clipboard
Waiting for one or more previous tasks to complete
Connecting network namespaces via veth device
And we are ready for the first connectivity check! 🎉 Let's try to ping the veth0 device from the netns0 namespace:
ping -c 2 172.18.0.11
Copy to clipboard
PING 172.18.0.11 (172.18.0.11) 56(84) bytes of data.
64 bytes from 172.18.0.11: icmp_seq=1 ttl=64 time=0.093 ms
64 bytes from 172.18.0.11: icmp_seq=2 ttl=64 time=0.075 ms

--- 172.18.0.11 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1028ms
rtt min/avg/max/mdev = 0.075/0.084/0.093/0.009 ms
Copy to clipboard
Waiting for one or more previous tasks to complete
Now leave netns0 by typing exit (or open a new terminal tab) and try to ping the ceth0 device from the root namespace:
ping -c 2 172.18.0.10
Copy to clipboard
PING 172.18.0.10 (172.18.0.10) 56(84) bytes of data.
64 bytes from 172.18.0.10: icmp_seq=1 ttl=64 time=0.012 ms
64 bytes from 172.18.0.10: icmp_seq=2 ttl=64 time=0.078 ms

--- 172.18.0.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1024ms
rtt min/avg/max/mdev = 0.012/0.045/0.078/0.033 ms
Copy to clipboard
Waiting for one or more previous tasks to complete
Success! We've just got packets flowing between the root namespace and the netns0 namespace.
But what if we try to reach any other address from the netns0 namespace? Are we going to succeed too? Let's find out!
ip addr show dev eth0
Copy to clipboard
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether ee:36:69:36:fe:bd brd ff:ff:ff:ff:ff:ff
    inet 172.16.0.2/16 brd 172.16.255.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::b0b9:11ff:fe79:613f/64 scope link
       valid_lft forever preferred_lft forever
Copy to clipboard
Note this 172.16.0.2 address - it's the IP address of another network interface on the host machine, and we are going to use it to check the connectivity from the netns0 namespace:
nsenter --net=/run/netns/netns0 bash
Copy to clipboard
Accessing the host's network interface from the netns0 namespace:
ping 172.16.0.2
Copy to clipboard
ping: connect: Network is unreachable
Copy to clipboard
What if we try something from the Internet?
ping 8.8.8.8
Copy to clipboard
ping: connect: Network is unreachable
Copy to clipboard
The failure is easy to explain, though. There is simply no record in the netns0 routing table for such packets. The only entry there shows how to reach the 172.18.0.0/16 network:
ip route list
Copy to clipboard
172.18.0.0/16 dev ceth0 proto kernel scope link src 172.18.0.10
Copy to clipboard
How did it get there? Linux has a bunch of ways to populate the routing table. One of them is to extract routes from the directly attached network interfaces. Do you remember that the routing table in netns0 was empty right after the namespace creation? But then we moved the ceth0 device into netns0 and assigned it an IP address 172.18.0.10/16. Since we were using not a simple IP address, but a combination of the address and the netmask, the network stack managed to extract the routing information from it. Because of that derived record, every packet from inside of the netns0 namespace destined to the 172.18.0.0/16 network will be sent through ceth0 device. But any other packets will be discarded.
Similarly, a new route was added to the root namespace (you may want to type exit to leave netns0 first):
ip route list
Copy to clipboard
... omitted lines ...
172.18.0.0/16 dev veth0 proto kernel scope link src 172.18.0.11
Copy to clipboard
At this point, we are ready to mark our very first question answered. We know now how to virtualize and interconnect Linux network environments.
Time to check the knowledge!


$ ip link add veth0 type veth peer name ceth0
$ ip link set ceth0 netns container-1
$ ip link set veth0 up
$ ip addr add 172.18.0.11/16 dev veth0
$ ip netns exec container-1 ip link set lo up
$ ip netns exec container-1 ip link set ceth0 up
$ ip netns exec container-1 ip addr add 172.18.0.10/16 dev ceth0



Interconnecting containers using a virtual network switch (bridge)
Luckily, Linux has a solution for the above problem, and it's yet another virtualized network facility called bridge.
The Linux bridge device behaves like a network switch. It forwards packets between interfaces that are connected to it. And since it's a switch and not a router, it doesn't care about IP addresses of the connected devices because it operates on the L2 (i.e. Ethernet) level.
Bridge vs. router
Image from Bridge vs. Switch: What I Learned From a Data Center Tour.
Let's try to play with our new toy. But first, we need to clean up the existing setup because some of the configurational changes we've made so far aren't really needed anymore. Removing network namespaces should suffice:
ip netns delete netns0
ip netns delete netns1
Copy to clipboard
However, if you still have some leftovers, you can remove them manually:
ip link delete veth0
ip link delete ceth0
ip link delete veth1
ip link delete ceth1
Copy to clipboard
To set the stage for the new experiment, let's quickly re-create two containers.11
From the root namespace:
ip netns add netns0

ip link add veth0 type veth peer name ceth0
ip link set veth0 up
ip link set ceth0 netns netns0
Copy to clipboard
Continuing from the netns0 namespace:
nsenter --net=/run/netns/netns0 bash
Copy to clipboard
ip link set lo up
ip link set ceth0 up
ip addr add 172.18.0.10/16 dev ceth0
Copy to clipboard
exit
Copy to clipboard
From the root namespace:
ip netns add netns1

ip link add veth1 type veth peer name ceth1
ip link set veth1 up
ip link set ceth1 netns netns1
Copy to clipboard
Continuing from the netns1 namespace:
nsenter --net=/run/netns/netns1 bash
Copy to clipboard
ip link set lo up
ip link set ceth1 up
ip addr add 172.18.0.20/16 dev ceth1
Copy to clipboard
exit
Copy to clipboard
👨‍🎓 Notice we don't assign any IP addresses to the host's ends of the containers (veth0 and veth1) anymore.
Make sure there is no new routes on the host:
ip route list
Copy to clipboard
default via 172.16.0.1 dev eth0
172.16.0.0/16 dev eth0 proto kernel scope link src 172.16.0.2
Copy to clipboard
Now we are ready to create a bridge device:
ip link add br0 type bridge
ip link set br0 up
Copy to clipboard
When the bridge is created, we need to connect the containers to it by attaching the host's ends (veth0 and veth1) of their veth pairs:
ip link set veth0 master br0
ip link set veth1 master br0
Copy to clipboard
Setting up routing between multiple network namespaces
It's time to check the connectivity again!
First container to the second:
nsenter --net=/run/netns/netns0 ping -c 2 172.18.0.20
Copy to clipboard
PING 172.18.0.20 (172.18.0.20) 56(84) bytes of data.
64 bytes from 172.18.0.20: icmp_seq=1 ttl=64 time=0.295 ms
64 bytes from 172.18.0.20: icmp_seq=2 ttl=64 time=0.053 ms

--- 172.18.0.20 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.053/0.174/0.295/0.121 ms
Copy to clipboard
Second container to the first:
nsenter --net=/run/netns/netns1 ping -c 2 172.18.0.10
Copy to clipboard
PING 172.18.0.10 (172.18.0.10) 56(84) bytes of data.
64 bytes from 172.18.0.10: icmp_seq=1 ttl=64 time=0.052 ms
64 bytes from 172.18.0.10: icmp_seq=2 ttl=64 time=0.103 ms

--- 172.18.0.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1019ms
rtt min/avg/max/mdev = 0.052/0.077/0.103/0.025 ms
Copy to clipboard
Lovely! Everything works great. With this new approach, we haven't configured veth0 and veth1 at all. The only two IP addresses we explicitly assigned were on the ceth0 and ceth1 ends. But since both of them are on the same Ethernet segment (remember, we connected them to the virtual switch), there is connectivity on the L2 level. Here is how we can check it:
nsenter --net=/run/netns/netns0 ip neigh
Copy to clipboard
172.18.0.20 dev ceth0 lladdr 3e:f2:8f:03:c8:1c REACHABLE
Copy to clipboard
nsenter --net=/run/netns/netns1 ip neigh
Copy to clipboard
172.18.0.10 dev ceth1 lladdr 4e:ff:98:90:d5:ea REACHABLE
Copy to clipboard
Congratulations! 🎉 We've just learned how to turn containers into friendly neighbors and teach them to talk to each other.
Challenge time!
