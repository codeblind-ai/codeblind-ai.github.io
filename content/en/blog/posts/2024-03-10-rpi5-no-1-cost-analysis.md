---
title: "Becoming a Cloud Native 👽"
linkTitle: "👾 The Cloud Natives"
date: 2024-03-10
description: >
    This is the first installment of building a private cloud, in your home, using Raspberry Pi 5s. Together we will learn the value of cloud native technologies, and how to build a cloud from the ground up. I also want to dedicate this to the amazing team at NetPlane who taught me so much about networking and virtualization (see dedication below).
---

<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>

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


💡 My journey to Cloud Native started over 24 years. In the early days, I built backbone networking protocols, switch and router virtualization software for Netplane systems right out of college. This was before [SDN](https://en.wikipedia.org/wiki/Software-defined_networking) was a thing. Later we built blade server and rack hardware. This gave me a keep at the hardware level of Datacenters - which is the foundation of this blog series.

Later I was lucky enough to work on both hardware and cloud infrastructure virtualization software enabling multi-tenancy of racks and data centers at a little company called Egenera. Goldman Sachs funded us, and if not for our virtualization technology - a lot of data would have been lost in Sept of 2001. _Note this was way before AWS was even on the map!_ 

These days, I spend most of my time working with cloud native technologies. To achieve these deep learnings, earned in nearly a quarter century, came at great cost. There was no ChatGPT or Google like we know them today. Everything was in books or in the minds of my peers. I had to work for every bit (pun intended).

Lucky for you... I am going to share my secrets over the course of a few blog posts, so you can be a cloud native too. Let's Go! 🚀

---

Engineering by the Numbers 🧮
=============================

<i>Before we jump off, let's talk a little about money.</i> 🤑

As an Engineer, it is important to understand the costs of my designs. A bad design is expensive, or hard to own. Depending on what the market is willing to pay for my service, makes the difference between being profitable, or looking for a new job.

When I worked Cisco, my role was Product & Security Architecture. I enjoyed doing system level design work, and spreading knowledge to engineers across 63 teams! That is no light task! I will take a start-up over that any day! 😅 But that is another topic.

📣 <i><u><b>The goal, of any product, is to generate a 90% margin at a minimum; hopefully much more.</b></u> This base number is designed to cover all development, marketing, administrative, sales, and delivery costs. If the market is willing to pay $10 per-user per-year for our service; as an engineer I must do everything possible to ensure running the service costs less than $1 per-user per-year to run.</i> This is not including people costs, but a bad design which causes a lot in people hours to own is a similar story.

This sounds way easier than it really is 🙈,  and unfortunately _most young engineers_ don't think this way. Dazzled by the shiny new tech, they forget the incremental additional costs and find themselves surprised when the business if failing and cutting jobs. 

I always try to keep the 90% rule in mind when designing a system, and remember to measure... everything. Because after all, if you are not making money... it is just a hobby. 

Thus research the market, identify the value of your service, and engineer accordingly. It guarantees Uncle Sam gets his slice of your heaven, and you can innovate with your pals keeping everyone gainfully employed. 🚀


## What we are Building

We will be making a [Private Cloud](https://aws.amazon.com/compare/the-difference-between-public-cloud-and-private-cloud/#:~:text=In%20a%20private%20cloud%2C%20a,%2C%20data%20storage%2C%20and%20CPU.) in our office (aka the living room). The diagram below shows the base foundation of our "data center". Although we start with a single node, which is not much of a cloud, we will expand it over the course of the coming blog posts. 

<img src="/images/blogs/7/rpi5-cloud.png" style="width: 90%; display: block; margin-left: auto; margin-right: auto;">

Before building anything, let's start by looking at the cost analysis of running a private cloud (at home).

<details open>
  <summary>1. Identify the cost of Electricity</summary>

   I looked at my power bill, and can quickly identify a the cost of electricity per kWh:

   | Description             | Rate       |
   | ----------------------- | ---------- |
   | Power Generation Cost   | 0.39924/kW |
   | Power Distribution Cost | 0.59444/kW |
   | Total Charge per kWh    | 0.99368/kW |

   > _Expectedly these values will vary depending on where you live, and in some cases, the time of the day. I live in Brasil, and these are the local rates in the NE. Note all calculations unless specified are in Brasilain Real, which is 1/5 the value of the USD. However $5 Real here buys what $5 USD buys in the US. So all thing being equal...You can find your rates on your power bill._
</details>

<details open>
  <summary>2. Computing the cost of running a single machine</summary>

  <br/>
  
  **Calculate Power Requirement using the formula:**

  $$
  \begin{flalign*}
  & \text{kWh} = \frac{\text{Power (Watts)} \times \text{Time (hours)}}{1000} &
  \end{flalign*}
  $$


  > Given that the `RPi5 has a 27W power supply requirement` and we will use it for 24 hours a day, the calculation would be:

  $$
  \begin{flalign*}
  & \text{kWh} = \frac{27 \text{ Watts} \times 24 \text{ hours}}{1000} = 0.648 \text{ kW/day } &
  \end{flalign*}
  $$


  <br/>

  **Calculate Total Cost using the formula:**

  $$
  \begin{flalign*}
  & \text{Total Cost} = \text{kWh} \times \text{Price per kWh} &
  \end{flalign*}
  $$

  > Let's say the price per kWh is $0.99368 as in my case, then:

  $$
  \begin{flalign*}
  & \text{Total Cost} = 0.648 \text{ kWh } \times \$0.99368R = \$0.64354R \text{ per day } &
  \end{flalign*}
  $$

  **SUMMARY**

   | Description        | Charge        |
   | ------------------ | ------------  |
   | ⚡ per Node(hr)     | $0.0027R/hr   |
   | ⚡ per Node(day)    | $0.0648R/day  |
   | ⚡ per Node(month)  | $1.971R/month |
   | ⚡ per Node(year)   | $23.652R/year |
   | ⚡ kWh/day          | 0.65 kWh/day  |

  Thus, if we wanted to create a Cloud using 15 machines, we are looking at the following costs:

  * $$
  \begin{flalign*}
  & \text{Total Cost} = 15 \text{ nodes } \times \$0.0648\text{ day} = \$0.772\text{ day } & 
  \end{flalign*}
  $$

  * $$
  \begin{flalign*}
  & \text{Total Cost} = 15 \text{ nodes } \times \$1.9\text{ mo } = \$29.55\text{ mo } &
  \end{flalign*}
  $$

  * $$
  \begin{flalign*}
  & \text{Total Cost} = 15 \text{ nodes } \times \$23.65\text{ mo } = \$354.75\text{ mo } &
  \end{flalign*}
  $$
   
  >  Are we done? Heck No! We have other costs too which should be accounted for! We need to calculate the bootstrapping costs (sunken costs) of various hardware and services.
</details>

<details open>
  <summary>3. The internet is a series of Pipes</summary>

No cloud would be possible without the internet... and we need to provide access to our cloud.

Here in Brasil, the average internet service costs around $100 Real per month, which is approximately $20 USD, for nearly a 1Gbs service. The nice thing about this is, it is a fixed cost and does not change with the number of nodes unlike running in a public cloud provider. We will just hit the QoS wall, and slow down to allowed rates.

I have a 900 Mega download and 450 Mega upload connection for $109.99 Real. Incoming traffic is limited to 900Mbps (ingress), and outgoing traffic is limited to 450Mbps (egress). Thus, like any good PaaS, we must calculate the cost of bandwidth -- focusing on egress costs -- in our bandwidth cost calculations:

* $$
  \begin{flalign*}
  & \text{Seconds in a year} = 24 \times 60 \times 60 \times 365 = 31,536,000\text{ sec per year } &
  \end{flalign*}
  $$


* $$
  \begin{flalign*}
  & \text{Total Gb per year} = 0.45 \text{ Gbps } \times 31,536,000\text{s} = 14,191,200 \text{ Gb per year } &
  \end{flalign*}
  $$

* $$
  \begin{flalign*}
  & \text{Total Gb per mo} = 14,191,200 \text{ Gby } / 12 = 1,182,600 \text{ Gb per mo } &
  \end{flalign*}
  $$
* $$
  \begin{flalign*}
  & \text{Total GB per mo} = 1,182,600 \text{ Gbm } / 8 = 148,325 \text{ GB per mo } &
  \end{flalign*}
  $$

* $$
  \begin{flalign*}
  & \text{Cost per Gb} = \frac{\$109.99 \text{ per mo }}{1,182,600 \text{ Gb/mo}} = \$0.0000930069 \text{ per Gb } &
  \end{flalign*}
  $$


* $$
  \begin{flalign*}
  & \text{Cost Per GBh} = 0.0000930069 \text{ cost per GB} \times 3600 \text{ seconds in hour} = \$0.33455448 \text{ per GBh} &
  \end{flalign*}
  $$


**SUMMARY**
| Description                 | Rate          |
| --------------------------- | ------------- |
| Cost per Gb                 | $0.0000930069 |
| Cost per GB (x8)            | $0.0007440535 |
| Bandwidth Gb/hour  possible | 1620          |
| Bandwidth GB/hour  possible | 202.5         |
| Cost per hour @ max speed   | $0.1506708378 |

Thus, the cost of traffic alone is cheap when compared to a public cloud provider! Albeit if we did this at scale we'd need a bigger pipe! Especially because traffic is typically spiky.

To put this in perspective, the cost of traffic _using AWS's pricing calculator -- as of March 2024-- AWS’s monthly data transfer costs for outbound data to the public internet in Sõa Paulo region are $0.15 per GB for the first 10 TB._ 

> Thus for the same 1620Gbh, is 202.5GBh (which his how AWS calculates) costing:

$$202.5 \text{GB} \times 0.15\text{USD per GB} = \$30.275 \text{USD per hour!}$$

Converting to Real, this is approximately $151.88 Real per hour. _This is a significant cost savings for the same amount of bits!_ 

Our savings using local internet, theoretically, is saving us $121.88 Real per hour, or $2,925.12R per day, or $1,067,668.8R per year. 🤯🤯🤯 Especially since we have a fixed cost of `$109.99 * 12 = $1319.99 per year`. We blow past that in a few hours on AWS at max capacity!

> Obviously these calculations are theoretical; and unlikely to mirror reality. Operate at max capacity all the time on our local ISP provided internet may attract unwanted attention. But the idea is sound, and more importantly the take away is that the cost of traffic is significant. _As we design services, we need to be conscious of the cost of traffic; crafting our APIs to deliver the most value at the least amount of traffic as these costs add up quickly._

</details>

<details open>
  <summary>4. Hosting Domain and Routing Costs</summary>

  With any cloud, we want a hosting domain (eg. `app.domain.com`) where we can reach any of our services. 
  
  I have a domain name that I use for my personal website. I pay $70 per year for it, since it is a `.ai` domain, but one can be acquired for much lower.
  
  This is a fixed yearly cost. So amortizing this over 365 days * 24 hours, the costs about $0.008 per hour. This is a fixed cost and does not change with the number of nodes. Furthermore, depending on the domain provider, you can get DNS routing for free. Thus for DNS (unlike Route53) we will not have a cost to wire in our domain names.:

  **SUMMARY**
| Description      | Rate       |
| ---------------- | ---------- |
| Cost/Domain(hr)  | $0.008/hr  |
</details>

<details open>
  <summary>5. Sunken hardware costs</summary>

  Hardware is a sunken cost. However the cost can be amortized over the life of the hardware. The RPi5 is expected to last 5 years - but we are likely to replace it as soon at the RPi6 comes out.

  **SUMMARY**
  | Description            | Features                                             |  Cost              |
  | ---------------------- | ---------------------------------------------------- | ------------------ |
  | 1 RPi5 w/ 8GB kit      | * Raspberry Pi 5<br/>* Quad-Core Arm Cortex-A76 processor at 2.4GHz<br/>* Samsung EVO+ 128GB MicroSD Card pre-loaded with Raspberry Pi OS<br/>* CanaKit Turbine Case for the Pi 5<br/>* CanaKit MEGA Heat Sink for the Pi 5<br/>* CanaKit Low-Noise PWM Fan for the Pi 5<br/>* USB-C PD Power Supply (Black or White)<br/>* Set of 2 Micro HDMI to HDMI Cables (6-foot each)<br/>                                                              | $159               |
  | 1TB MicroSDxC upgrade  | more memory for disk (since we will use containers)  | $139.99            |
  | Tax                    | 10\% in Washington state (for Uncle Sam)             | $29.99             |
  | Total                  | Expected cost for 1 node                             | $328.98 USD        |
  | Total R                | Expected cost for 1 node in Real                     | $1644.90R          |
  | Cost per month         | 2 years duty cycle                                   | $13.7075 USD/month |
  | Cost per month         | 2 years duty cycle                                   | $68.5375 R/month   |
  | Cost per day           | 2 years duty cycle                                   | $2.65947802 R/day  |
  | Cost per day           | 2 years duty cycle                                   | $0.09414492 R/hr   |

</details>

## COST SUMMARY

All of these little things add up. Here is a summary of our operational costs

| Cost Bucket      | Description                           | Rate/mo (in real)   | Rate/mo (in USD)    |
| ---------------- | ------------------------------------- | ------------------- | ------------------- |
| Machine ($/mo)   | hardware ($68.54R) and power ($1.97R) | $70.51R per mo      | $14.102 per mo      |
| Bandwidth ($/mo) | internet ($109.99R)                   | $109.99R per mo     | $21.998 per mo      |
| Domain ($/mo)    | domain ($0.008R/hr)                   | $5.824R per mo      | $1.1648 per mo      |
| **Total ($/mo)** |                                       | **$186.324R per mo**| **$37.2648 per mo** |


---

Now, let's compare against AWS
==============================

The diagram below outlines the simplest of AWS deployments. We will compare the costs of running a similar service in AWS. However like any comparison, it is not apples to apples. We are comparing a single node to a shared instance. We are also comparing a local ISP to AWS's hyperplane network. But it is a good starting point to understand the costs of running a cloud in your home.

<img src="/images/blogs/7/aws-cloud.png" style="width: 90%; display: block; margin-left: auto; margin-right: auto;">


<details open>
  <summary>1. EC2 Compute Costs</summary>

  The hardest part of AWS is finding the comparison of ec2 instance with the RPi5. The RPi5 is a 4 core 1.8GHz processor with 8GB of memory. The following AWS EC2 in Sõa Paulo region are available:
  
  | Instance name | On-Demand hourly rate |  vCPU | Memory  | Storage           | Network performance |
  | ------------- | --------------------- | ----- | ------- | ----------------- | ------------------- |
  | c4.xlarge     | $0.309  USD/hr        | 4    | 7.5 GiB |  EBS Only         | High
  | c6in.xlarge   | $0.3486 USD/hr        | 4    | 8 GiB   |  EBS Only         | Up to 30000 Megabit
  | c6g.xlarge    | $0.2096 USD/hr        | 4    | 8 GiB   |  EBS Only         | Up to 10 Gigabit
  | inf1.xlarge   | $0.377  USD/hr        | 4    | 8 GiB   |  EBS Only         | Up to 25 Gigabit
  | c5d.xlarge    | $0.298  USD/hr        | 4    | 8 GiB   |  1 x 100 NVMe SSD | Up to 10 Gigabit
  | c6gn.xlarge   | $0.266  USD/hr        | 4    | 8 GiB   |  EBS Only         | Up to 25 Gigabit
  | c5ad.xlarge   | $0.268  USD/hr        | 4    | 8 GiB   |  1 x 150 NVMe SSD | Up to 10 Gigabit
  | c6a.xlarge    | $0.2358 USD/hr        | 4    | 8 GiB   |  EBS Only         | Up to 12500 Megabit
  | c7i.xlarge    | $0.2751 USD/hr        | 4    | 8 GiB   |  EBS Only         | Up to 12500 Megabit
  | c6i.xlarge    | $0.262  USD/hr        | 4    | 8 GiB   |  EBS Only         | Up to 12500 Megabit
  | c6gd.xlarge   | $0.238  USD/hr        | 4    | 8 GiB   |  1 x 237 NVMe SSD | Up to 10 Gigabit
  | c5a.xlarge    | $0.236  USD/hr        | 4    | 8 GiB   |  EBS Only         | Up to 10 Gigabit
  | c5.xlarge     | $0.262  USD/hr        | 4    | 8 GiB   |  EBS Only         | Up to 10 Gigabit
  
  > Note 1: These are on demand pricing, and we could get a better rate for a commitment. 
  >
  > Note 2: These are shared instances, not dedicated hardware. Dedicated instance pricing is MUCH higher.
  > 
  > Note 3: Since the RPi5 is a 4 core 1.8GHz processor with 8GB of memory and the closest/cheapest match is the `c6g.xlarge`; I am using for the comparison for lack of a better ability to match one-to-one for equal performance per cost.
  
  **Doing the math using the calculator, the monthly cost of our ec2 instance for the month is: $153.01 USD**.

</details>


<details open>
  <summary>2. EBS Storage Cost (1TB)</summary>

  We allocated 1TB of storage per node. The cost of 1TB of EBS storage in Sõa Paulo region for SSD is as follows:

  * **Storage amount:** `1 TB x 1024 GB in a TB = 1024 GB`
  * `1 volumes x 730 instance hours = 730.00 total instance hours`
  * `730.00 instance hours / 730 hours in a month = 1.00 instance months`
  * `1,024 GB x 1.00 instance months x 0.19 USD = 194.56 USD (EBS Storage Cost)`

  Holy Mary, Mother of God! That is expensive! And worse we are dealing with Network attached storage which is slower (even at AWS hyperplane speeds). We will use the SD card storage. This is a significant savings! 🤯

</details>

<details open>
  <summary>3. Data Transfer Costs</summary>
  Here is where things get really spicy. No matter what we will be paying $0.15USD per GB egress in SP. _Using AWS pricing calculator -- as of March 2024-- AWS’s monthly data transfer costs for outbound data to the public internet in Sõa Paulo region  for 148325GB/mo:

  * Internet: Tiered pricing for 148325 GB:
  * 10240 GB x 0.15 USD per GB = 1536.00 USD
  * 40960 GB x 0.138 USD per GB = 5652.48 USD
  * 97125 GB x 0.126 USD per GB = 12237.75 USD
  * **Data Transfer cost (monthly): 19,426.23 USD**

   I just died a little inside. 😭 But this is not strange, [others experience this problem too](https://medium.com/life-at-chime/how-we-reduced-our-aws-bill-by-seven-figures-5144206399cb)! So much so, there are [entire projects dedicates](https://fck-nat.dev/v1.3.0/) to working the egress costs as low as possible. 

   > Note, we are not likely to fill the entire pipe of our local ISP, and it is unlikely we will use this much egress traffic costs from our AWS account. However it is important to pay attention to this problem. It is a significant cost, and it is a cost that is not present in our local ISP provided internet.

</details>

<details open>
  <summary>4. IP Address Costs</summary>

  Assuming we have exactly 1 and use a reverse proxy to handle all of our traffic, the cost of 1 in-use public IPv4 address in Sõa Paulo region is as follows:

  * `1 in-use public IPv4 address x 730 hours in a month x 0.005 USD = 3.65 USD (Total In-use public IPv4 address charge)`
</details>


## Summary


The theoretical cost per month to run our AWS environment is: `$19,777.44 USD`.
The theoretical cost per month to run our Pi5 environment is:     `$37.26 USD`.

<aside>
  <img src="/images/blogs/7/wasted.gif" style="width: 45%; display: block; margin-left: auto; margin-right: auto;">
</aside>

Even if we ignore the egress costs and disk costs of AWS completely, the cost of running a single node in AWS is 530 times more expensive than running a single node in our home. We'd be shelling out `$153.01 USD per month` for `1 ec2 instance`. 
 
Where as our entire setup at this time only costs us $37.26 USD per month.

This signifies a savings of $115.75 USD per month, or $1,389 USD per year. 🤯 I can buy my kid a bike with that kind of loot!


---


### Special Dedication

---

<img src="/images/blogs/7/netplane.jpeg" style="width: 75%; display: block; margin-left: auto; margin-right: auto;">

---

I have fond memories of my time at Netplane. Those years grew my skills - but not without the help of many mentors along the way. Working with my colleges were transformational in my skills and approach to life. 

**We were changing the world -- without even knowing it.**

1. All those years ago making networking stacks, which were reused over and over again, and I bet, are still in use today.
2. We virtualized networking stacks with our PowerCode (java script engine) which allowed us to virtualize routers and control & data plane switching on 800MHz pentiums when everyone else was doing it on bare metal. For the audience, this was back in 2001 when such things didn't really exist yet.
3. Those experiments lead to what I believe was the first of it's kind Video streaming (RTSP) over MPLS for NTT DoCoMo. 

To all my friends [Deepak](https://www.linkedin.com/in/deepak-shahane-2a588212/), [Anil](https://www.linkedin.com/in/grovor/), [Steve #1](https://www.linkedin.com/in/stephen-atkinson/) and [Steve #2](https://www.linkedin.com/in/stephen-mills-bb286915/), [Bill #1](https://www.linkedin.com/in/bill-herbst-8b61498/) and [Bill #2](https://www.linkedin.com/in/bill-friedeborn-64100a12/), [Alan](https://www.linkedin.com/in/alan-kullberg-3054148/), [Bruce](https://www.linkedin.com/in/brucemayer/), [Debi](https://www.linkedin.com/in/debileach/), [Nancy](https://www.linkedin.com/in/nancy-stoddard-guardione-30b9ab9/), [Mark](https://www.linkedin.com/in/mark-monet-396a9710/), [Seth](https://www.linkedin.com/in/seth-miller-8247063/), and the rest of the gang; I want to say _**Thank You**_. _**Your mentorship and friendship meant the world to me. Thanks for taking a chance on a kid from the sticks of Washington state. Because of you, here I am.**_
