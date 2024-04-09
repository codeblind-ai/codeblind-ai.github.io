---
title: "Cloud Scaffolding: The Mighty Pi 🍇"
linkTitle: "🍇 Cloud Scaffolding"
date: 2024-03-05
description: >
  The new Raspberry Pi 5 is a powerful little computer. I purchased a few for local development purposes, and to help me maintain my lower level skills, as well as for building bigger things. It's a great platform for learning about cloud native technologies. In this post, we'll set up a Raspberry Pi 5 for the first time. Let's get started!
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

## Prerequisites
Before we begin, make sure you have the following:
- [ ] A laptop or workstation
- [ ] 1 - Raspberry Pi 5 (I recommend the 8G version)
- [ ] 1 - Micro SD card (at least 128GB)
- [ ] 1 - Micro SW card reader/writer
- [ ] 1 - 27W USB-C power supply
- [ ] 1 - 40mm fan
- [ ] 1 - RPi5 case
- [ ] 1 - Active Head Sink
- [ ] An internet connection (hopefully a reasonable speed)
- [ ] Admin login access to your router


## Raspberry Pi 5 Assembly

<details open>
  <summary>1. Unbox the Raspberry Pi 5</summary>

  This is the exciting part. Unbox the Raspberry Pi 5 and take a moment to appreciate the beauty of this tiny computer.

  <img src="/images/blogs/5/rp5-board-1.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">
</details>

<details open>
  <summary>2. Attach the heat sink to the board</summary>

  This is an important step. The new RPi5 can get very hot. It's important to keep it cool.

  <img src="/images/blogs/5/rp5-board-2.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">
</details>

<details open>
  <summary>3. Attach fan and place the board in the case!</summary>

  <img src="/images/blogs/5/rp5-board-3.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">
</details>

<details open>
  <summary>4. Download an install the Raspberry PI OS Installer</summary>

  The installer is available on the [Raspberry Pi website](https://www.raspberrypi.com/software/). Download the installer and install it onto your laptop or work station.
</details>

## Flashing Raspberry Pi OS
<details open>
  <summary>1. Open the Raspberry Pi OS Installer</summary>
  <img src="/images/blogs/5/rpi5-os-install-1.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">
</details>

<details open>
  <summary>2. Select the Raspberry Pi Device</summary>

  This is an important step. The new RPi5 can get very hot. It's important to keep it cool.

  <img src="/images/blogs/5/rpi5-os-install-2.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">
</details>

<details open>
  <summary>3. Select the Operating System</summary>
  **For Raspberry Pi 4 or 5 I recommend the current Ubuntu 23.04 LTS.** This will allow us to deploy Canonical's MicroK8s which is much simpler to use than a Kubeadm installed Kubernetes.
</details>

<details open>
  <summary>4. Select the Storage Media</summary>
  <img src="/images/blogs/5/rpi5-os-install-4.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">
</details>

<details open>
  <summary>4. Click Next, then `Edit Settings`</summary>

  <img src="/images/blogs/5/rpi5-os-install-5-edit-1.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">
</details>

<details open>
  <summary>5. Configure the default values for first Boot</summary>

  <img src="/images/blogs/5/rpi5-os-install-5-edit-2.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">

  1. Make sure you set the hostname
  2. Make sure to configure the `user` with a `strong` password
  3. Configure the `WiFi` settings to your local network. This allows you to find and access the RPi5 on your network without needing to connect a monitor and keyboard.
  4. Set the locale settings to your local settings
   
  > <i class="fa fa-exclamation-triangle" aria-hidden="true" style="color: orange;">&nbsp;</i> Don't click save yet. We need to configure the `SSH` settings.
</details>

<details open>
  <summary>5. Customize Services (SSH)</summary>

  <img src="/images/blogs/5/rpi5-os-install-5-edit-3.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">

  1. Select `Enable SSH`
  2. Add your public key. If you don't have an SSH Key, you can generate one using the `ssh-keygen` command. [Follow the github instructions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent). I think they are the clearest. 
  3. Click `Save`
</details>


<details open>
  <summary>5. Apply the settings changes</summary>

  <img src="/images/blogs/5/rpi5-os-install-5-edit-4.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">
</details>

<details open>
  <summary>5. Confirm the updates</summary>

  <img src="/images/blogs/5/rpi5-os-install-5-edit-5.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">
</details>

<details open>
  <summary>5. Wait...</summary>

  <img src="/images/blogs/5/rpi5-os-install-5-edit-6.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">
</details>

At the end of this process, you can install the SD card into the RPi5 and power it up. You should be able to find it on your network and SSH into it.


## First Access

<details open>
  <summary>1. Discover the IP address of your machine</summary>
  After the RPi5 boots up, you should be able to find it on your network. You can use the `arp` command to find it. 


  ```bash
  arp -a
  ```

  <img src="/images/blogs/5/rpi5-discovery.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">
</details>

<details open>
  <summary>2. SSH to the machine</summary>
  Once you have the IP address, you can SSH into the machine using the SSH certificate you provisioned, you can SSH into the machine.

  ```bash
  ssh -i ~/.ssh/id_<your key> <user>@<ip address>
  ```
  >  <i class="fa fa-exclamation-triangle" aria-hidden="true" style="color: orange;">&nbsp;</i>Replace the `<your key>` with the name of your SSH key, `<user>` with the user you configured, and `<ip address>` with the IP address you discovered.

  <img src="/images/blogs/5/rpi5-login.png" alt="Raspberry Pi 5" style="width: 70%; display: block; margin-left: auto; margin-right: auto;">
</details>

## Summary
 🎉🎉🎉 Congratulations! You've successfully set up your Raspberry Pi 5 for the first time. You can now start exploring the world of cloud native technologies on this powerful little computer. Enjoy your journey into the world of cloud computing and container orchestration!

## Next Steps

Now that you have your Raspberry Pi 5 set up, you can start exploring various cloud native technologies such as Kubernetes, Containerd, ctr, nerdctl, and more. You can also start deploying and managing containers using Kubernetes. Enjoy your journey into the world of cloud computing and container orchestration!
