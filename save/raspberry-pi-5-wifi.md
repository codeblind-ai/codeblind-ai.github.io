---
title: "Setting Up WiFi on Raspberry Pi from the Command Line"
linkTitle: "Setting Up WiFi on Raspberry Pi from the Command Line"
date: 2024-03-11
description: >
 Setting up Raspberry Pi WiFi from the command line is quick and easy. This guide will walk you through the process step by step.
---

## Configuring WiFi from the Command Line on Raspberry Pi

Setting up WiFi on your Raspberry Pi can be done quickly and easily from the command line. Whether you're connecting for the first time or updating your network settings, this guide will walk you through the process step by step.

### Step 1: Scan for Available Networks

First, log in to your Raspberry Pi using PuTTY or any other SSH client. Once logged in, you can scan for available WiFi networks by running the following command:

```bash
sudo iwlist wlan0 scan
```

This command will generate a list of all wireless networks available in your area. Look for the "ESSID" line to identify the name of your WiFi network.

### Step 2: Edit wpa_supplicant.conf
Now that you have the name of your WiFi network, you need to add it to the wpa_supplicant.conf file. Open the file in a text editor by running:

```bash
sudo vim /etc/wpa_supplicant/wpa_supplicant.conf
```

If the file already contains network configurations, edit them accordingly. Otherwise, add the following lines to the bottom of the file:

```bash
network={
    ssid="YOUR_NETWORK_NAME"
    psk="YOUR_WIFI_PASSWORD"
}
```

> Replace "YOUR_NETWORK_NAME" with the name of your WiFi network and "YOUR_WIFI_PASSWORD" with your WiFi password.

### Step 3: Restart WiFi Adapter
Save and exit the text editor by pressing Ctrl + X, then Y to confirm. Now, restart the WiFi adapter by running the following commands:

```bash
sudo wpa_cli -i wlan0 reconfigure
```

If the WiFi adapter doesn't start, you may need to reboot the Raspberry Pi using `sudo shutdown -r now`.

### Step 4: Find the New IP Address (Optional)

If you're configuring WiFi via SSH and an ethernet connection, the local IP address will change once connected to WiFi. Use a network scanning tool like Advanced IP Scanner to find the new local IP address of the Pi. You can then use this IP to reconnect via SSH.

With these steps, you can easily set up and configure WiFi on your Raspberry Pi from the command line, enabling wireless connectivity for your projects.

---

Securing the password
=====================
It is possible to secure the WiFi password in the `wpa_supplicant.conf` file by encrypting it. One approach is to use the `wpa_passphrase` command-line utility to generate an encrypted passphrase, which can then be used in the configuration file.

Here's how you can use `wpa_passphrase` to generate an encrypted passphrase:

```bash
wpa_passphrase YOUR_NETWORK_NAME YOUR_WIFI_PASSWORD
```

> Replace `YOUR_NETWORK_NAME` with the name of your WiFi network and `YOUR_WIFI_PASSWORD` with your WiFi password. Running this command will output an encrypted passphrase that you can use in your wpa_supplicant.conf file.

For example, the output might look something like this:

```bash
network={
    ssid="YOUR_NETWORK_NAME"
    #psk="YOUR_WIFI_PASSWORD"
    psk=5d41402abc4b2a76b9719d911017c5928b4683c5a2
}
```

You can copy the psk value from the output and use it as the password in your `wpa_supplicant.conf` file. This way, even if someone gains access to your wpa_supplicant.conf file, they won't be able to retrieve your WiFi password directly.

Remember to remove or comment out the plain text password (psk="YOUR_WIFI_PASSWORD") from your wpa_supplicant.conf file once you've replaced it with the encrypted passphrase.