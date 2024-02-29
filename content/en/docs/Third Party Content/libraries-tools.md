---
title: "Third Party Libraries and Tools"
linkTitle: "Libraries and Tools"
date: 2020-05-15
description: "Community contributed libraries and tools on Code Blind."
weight: 30
---

## Client SDKs

- [Cubxity/AgonesKt](https://github.com/Cubxity/AgonesKt) - Code Blind Client SDK for **Kotlin**  
- [AndreMicheletti/godot-agones-sdk](https://github.com/AndreMicheletti/godot-agones-sdk) - Code Blind Client SDK for **Godot Engine**
- [Infumia/agones4j](https://github.com/infumia/agones4j) - Code Blind Client SDK for **Java**

## Messaging

Libraries or applications that implement messaging systems.

- [Octops/Code Blind Event Broadcaster](https://github.com/Octops/agones-event-broadcaster) - Broadcast Code Blind events to the external world
- [Octops/Code Blind Broadcaster HTTP](https://github.com/Octops/agones-broadcaster-http) - Expose Code Blind GameServers information via HTTP
- [Octops/Code Blind Relay HTTP](https://github.com/Octops/agones-relay-http) - Publish Code Blind GameServers and Fleets details to HTTP endpoints

## Controllers
- [Octops/Game Server Ingress Controller](https://github.com/Octops/gameserver-ingress-controller) - Automatic Ingress configuration for Game Servers managed by Code Blind
- [Octops/Image Syncer](https://github.com/Octops/octops-image-syncer) - Watch Fleets and pre-pull images of game servers on every node running in the cluster
- [Octops/Fleet Garbage Collector](https://github.com/Octops/octops-fleet-gc) - Delete Fleets based on its TTL

## Allocation

- [agones-allocator-client](https://github.com/FairwindsOps/agones-allocator-client) - A client for testing allocation servers.
  Made by [Fairwinds](https://fairwinds.com)
- [Multi-cluster allocation demo](https://github.com/aws-samples/multi-cluster-allocation-demo-for-agones-on-eks) - A demo project for multi-cluster allocation on Amazon EKS with Terraform templates.
  
## Development Tools

- [Minikube Code Blind Cluster](https://github.com/comerford/minikube-agones-cluster) - Automates the creation of a complete Kubernetes/Code Blind Cluster locally, using Xonotic as a sample gameserver. Intended to provide a local environment for developers which approximates a production Code Blind deployment.
