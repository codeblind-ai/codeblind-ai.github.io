---
title: "Comparing the Berries 🍓"
linkTitle: "🤖 Berry Pis"
date: 2024-03-03
description: >
    I am in love with making things, and want to buy a Raspberry Pi 5 to use for local development. This blog takes a quick look at processors used in Raspberry Pi models and how they compare to processors used in IaaS machine instances.
---


BCM2711
===========

This is the Broadcom chip used in the Raspberry Pi 4 Model B, the Raspberry Pi 400, and the Raspberry Pi Compute Module 4. The architecture of the BCM2711 is a considerable upgrade on that used by the SoCs in earlier Raspberry Pi models. It continues the quad-core CPU design of the BCM2837, but uses the more powerful ARM A72 core. It has a greatly improved GPU feature set with much faster input/output, due to the incorporation of a PCIe link that connects the USB 2 and USB 3 ports, and a natively attached Ethernet controller. It is also capable of addressing more memory than the SoCs used before.

The ARM cores are capable of running at up to 1.5 GHz, making the Raspberry Pi 4 about 50% faster than the Raspberry Pi 3B+. The new VideoCore VI 3D unit now runs at up to 500 MHz. The ARM cores are 64-bit, and while the VideoCore is 32-bit, there is a new Memory Management Unit, which means it can access more memory than previous versions.

The BCM2711 chip continues to use the heat spreading technology started with the BCM2837B0, which provides better thermal management.

*Processor:*  Quad-core https://en.wikipedia.org/wiki/ARM_Cortex-A72[Cortex-A72] (ARM v8) 64-bit SoC @ 1.5 GHz.

*Memory:* Accesses up to 8GB LPDDR4-2400 SDRAM (depending on model)

*Caches:* 32kB data + 48kB instruction L1 cache per core. 1MB L2 cache.

*Multimedia:* H.265 (4Kp60 decode); H.264 (1080p60 decode, 1080p30 encode); OpenGL ES, 3.0 graphics

*I/O:* PCIe bus, onboard Ethernet port, 2 × DSI ports (only one exposed on Raspberry Pi 4B), 2 × CSI ports (only one exposed on Raspberry Pi 4B), up to 6 × I2C, up to 6 × UART (muxed with I2C), up to 6 × SPI (only five exposed on Raspberry Pi 4B), dual HDMI video output, composite video output.

The https://datasheets.raspberrypi.com/bcm2711/bcm2711-peripherals.pdf[datasheet for the BCM2711] contains further details.

BCM2712
===========

Broadcom BCM2712 is the 16nm application processor at the heart of Raspberry Pi 5. It is the successor to the BCM2711 device used in Raspberry Pi 4, and shares many common architectural features with other devices in the BCM27xx family, used on earlier Raspberry Pi products.

Built around a quad-core Arm Cortex-A76 CPU cluster, clocked at up to 2.4GHz, with 512KB per-core L2 caches and a 2MB shared L3 cache, it integrates an improved 12-core VideoCore VII GPU; a hardware video scaler and HDMI controller capable of driving dual 4kp60 displays; and a Raspberry Pi-developed HEVC decoder and Image Signal Processor. A 32-bit LPDDR4X memory interface provides up to 17GB/s of memory bandwidth, while x1 and x4 PCI Express interfaces support high-bandwidth external peripherals; on Raspberry Pi 5 the latter is used to connect to the Raspberry Pi RP1 south bridge, which provides the bulk of the external-facing I/O functionality on the platform.

Headline features include: 

* Quad-core Arm Cortex-A76 @ 2.4GHz
** ARMv8-A ISA
** 64KByte I and D caches
** 512KB L2 per core, 2MB shared L3
* New Raspberry Pi-developed ISP
** 1 gigapixel/sec
* Improved HVS and display pipeline
** Dual 4Kp60 support
* VideoCore V3D VII
** ~2-2.5× faster (more hardware, 1GHz versus 600MHz on Pi 4)
** OpenGL ES 3.1, Vulkan 1.3
* 4Kp60 HEVC hardware decode
** Other CODECs run in software
** H264 1080p24 decode ~10–20% of CPU
** H264 1080p60 decode ~50–60% of CPU
** H264 1080p30 encode (from ISP) ~30–40% CPU

In aggregate, the new features present in BCM2712 deliver a performance uplift of 2-3x over Raspberry Pi 4 for common CPU or I/O-intensive use cases.

---

Whats in the Cloud
===================

Previously we looked at Cloud provider costs. We blindly selected the cheapest instance type (c6g.xlarge) and went with it. But what is really running on those instances? What is the processor? How does it compare to the Raspberry Pi?

The c6g instance family provides the Graviton2 processor, featuring 64 ARM Neoverse N1 cores and a clock speed of 2.5 GHz, is designed for scalable cloud computing. In the case of the c6g.xlarge instance type, which typically provides access to four virtual CPUs, the allocation of cache resources plays a significant role in determining overall performance.

Here's the breakdown of cache allocation for each c6g.xlarge instance:

* L1 Cache: The Graviton2 processor has 32 KB of L1 cache per core. With four cores allocated to each instance, the total L1 cache available per instance is 32 KB * 4 = 128 KB. In comparison, the RPi5 gives us 128 KiB (64 KiB I-cache with parity, 64 KiB D-cache) per core of L1 cache. This is the same as the c6g.xlarge instance!

* L2 Cache: Each core of the Graviton2 processor is equipped with 1 MB of L2 cache. With four cores per instance, the total L2 cache available per instance is 1 MB * 4 = 4 MB. In comparison, the RPi5 gives us 512 KiB per core of L2 cache. So the c6g.xlarge instance has 8x more L2 cache than the RPi5. This would make a big difference in compute performance for memory or IO intense workloads.

* L3 Cache: The Graviton2 processor features a shared L3 cache of 32 MB. Allocating this cache across multiple instances requires careful consideration. Assuming equal distribution, if we divide the total L3 cache equally among, for example, 10 c6g.xlarge instances, each instance would receive 32 MB / 10 = 3.2 MB of L3 cache. The RPi5 has a 2MB shared L3 cache. So the c6g.xlarge instance has more L3 cache than the RPi5 - but not a whole lot more.

It's essential to note that this allocation is simplified and theoretical. In practice, cloud providers dynamically manage resource allocation based on workload demands and system optimization strategies. Understanding these allocation principles enables users to make informed decisions when configuring and optimizing their cloud deployments.

By contrast, Raspberry Pi's BCM2711 and BCM2712 chips offer dedicated cache resources for standalone computing tasks, emphasizing performance in single-board computing and hobbyist projects. While these chips provide consistent performance within their designated environments, the shared infrastructure of cloud instances like the c6g.xlarge demands a nuanced understanding of resource allocation for optimal utilization.