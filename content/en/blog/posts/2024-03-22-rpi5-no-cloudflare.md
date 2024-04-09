---
title: "Simplifying DNS Management with Cloudflare"
linkTitle: "👮🏻‍♂️ Traffic Cops"
date: 2024-03-22
description: >
  Cloudflare stands as a titan among internet networks, renowned for enhancing the security and performance of websites and online services. It tackles the challenges that once plagued website owners, offering a suite of features designed to make online content faster, safer, and more reliable.
---

In the early days of the internet, loading a website was a straightforward process: your request traveled to a server, which then delivered the requested page. However, when too many requests flooded a server, it could crash, leaving visitors stranded. Cloudflare emerged to tackle these issues head-on, leveraging a robust edge network to deliver content and services as swiftly as possible, ensuring users receive information without delay.

Moreover, Cloudflare provides robust security measures, safeguarding internet properties from various malicious activities, including DDoS attacks and intrusive bots. Additionally, features like SSL and content distribution are seamlessly integrated into Cloudflare's offerings, benefiting millions of internet properties worldwide.

# The Importance of DNS Management

DNS (Domain Name System) management is crucial for directing internet traffic to the correct destinations. Cloudflare simplifies this process, offering a comprehensive DNS service that enhances security and performance.

## Protecting Against DDoS Attacks
DDoS ([Distributed Denial of Service](https://www.cloudflare.com/learning/ddos/what-is-a-ddos-attack/)) attacks pose a significant threat to online services, disrupting operations by overwhelming servers with malicious traffic. Cloudflare's DDoS mitigation operates in four stages:

1. **Detection:** Identifying and distinguishing legitimate traffic from attack traffic.
2. **Response:** Intelligently dropping malicious bot traffic while absorbing the rest.
3. **Routing:** Efficiently directing manageable traffic chunks to prevent denial of service.
4. **Adaptation:** Analyzing traffic patterns to fortify against future attacks.

## Examples of DDoS Attacks

* [ACK Flood DDoS Attack](https://www.cloudflare.com/learning/ddos/what-is-an-ack-flood/): Overloads servers with TCP ACK packets, crippling their ability to serve legitimate users.
* **DNS Amplification Attack**: Exploits open DNS resolvers to inundate target servers with amplified traffic, rendering them inaccessible.

## Simplifying DNS Setup with Cloudflare
Transitioning your domain's DNS management to Cloudflare is a straightforward process, offering enhanced security and performance benefits. Here's how to do it:

### 1. Sign Up with Cloudflare

First you will need to [create a Cloudflare account](https://www.cloudflare.com/plans/). You will be presented with a set of plans to chose from. Since we are building a hobby project, I recommend starting with the `free` plan as show:
![](/images/blogs/10/cloudflare_01.png)


### 2. Enable Cloudflare for your domain

![](/images/blogs/10/cloudflare_02.png)

Click the `Add a Site` button in Cloudflare to add your domain.

![](/images/blogs/10/cloudflare_03.png)
Enter your site name, and click `Continue`

### 3. Select the subscription level
Since we are building a hobby site - we will select the `free` option and `Continue`.

![](/images/blogs/10/cloudflare_04.png)

### 4. Record the name server entires you will need to configure Namecheap
![](/images/blogs/10/cloudflare_05.png)

### 5. Update the Registrar DNS settings
We are using namecheap, so we can login and go to the management dashboard for our domain.
![](/images/blogs/10/namecheap_01.png)

Here we will update the `NAMESERVERS` configuration, selecting `Custom DNS`.

![](/images/blogs/10/namecheap_02.png)


Here we will update the `NAMESERVERS` configuration, selecting `Custom DNS`.

![](/images/blogs/10/namecheap_03.png)

Next we enter the data we collected in step 4.
![](/images/blogs/10/namecheap_04.png)

Then click save - and we should see a success banner.
![](/images/blogs/10/namecheap_05.png)

### 6. Update DNS in Cloudflare
By now, we should see a success banner in Cloudflare as well.

![](/images/blogs/10/cloudflare_06.png)

Navigate to the DNS settings, and add two `CNAME` records for your github pages site as shown:

![](/images/blogs/10/cloudflare_07.png)

Thats it! We are all done. The site should be working as it was before!

# Summary

We learned how to quickly add strong DDoS protection to our site using Cloudflare. Next we will setup TLS for our services using Let's Encrypt and Cloudflare. Stay tuned!