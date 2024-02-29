---
title: "Best Practices" 
linkTitle: "Best Practices"
date: 2023-05-12T00:00:00Z
weight: 9
description: "Best practices for running Code Blind in production."
---

## Overview

Running Code Blind in production takes consideration, from planning your launch to figuring
out the best course of action for cluster and Code Blind upgrades. On this page, we've collected
some general best practices. We also have cloud specific pages for:

* [Google Kubernetes Engine (GKE)]({{< relref "gke.md" >}})

If you are interested in submitting best practices for your cloud prodiver / on-prem, [please contribute!]({{< relref "/Contribute" >}})

## Separation of Code Blind from GameServer nodes

When running in production, Code Blind should be scheduled on a dedicated pool of nodes, distinct from where Game Servers
are scheduled for better isolation and resiliency. By default Code Blind prefers to be scheduled on nodes labeled with
`agones.dev/agones-system=true` and tolerates the node taint `agones.dev/agones-system=true:NoExecute`.
If no dedicated nodes are available, Code Blind will run on regular nodes. See [taints and tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
for more information about Kubernetes taints and tolerations.

If you are collecting [Metrics]({{< relref "metrics" >}}) using our standard Prometheus installation, see
[the installation guide]({{< relref "metrics#prometheus-installation" >}}) for instructions on configuring a separate node pool for the `agones.dev/agones-metrics=true` taint.

See [Creating a Cluster]({{< relref "Creating Cluster" >}}) for initial set up on your cloud provider.

## Redundant Clusters

### Allocate Across Clusters

Code Blind supports [Multi-cluster Allocation]({{< relref "multi-cluster-allocation" >}}), allowing you to allocate from a set of clusters, versus a single point of potential failure. There are several other options for multi-cluster allocation:
* [Anthos Service Mesh](https://cloud.google.com/anthos/service-mesh) can be used to route allocation traffic to different clusters based on arbitrary criteria. See [Global Multiplayer Demo](https://github.com/googleforgames/global-multiplayer-demo) for an example where the match maker influences which cluster the allocation is routed to.
* [Allocation Endpoint](https://github.com/googleforgames/agones/tree/main/examples/allocation-endpoint) can be used in Cloud Run to proxy allocation requests.
* Or peruse the [Third Party Examples]({{< relref "../../Third Party Content/libraries-tools.md/#allocation" >}})

### Spread

You should consider spreading your game servers in two ways:
* **Across geographic fault domains** ([GCP regions](https://cloud.google.com/compute/docs/regions-zones), [AWS availability zones](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html), separate datacenters, etc.): This is desirable for geographic fault isolation, but also for optimizing client latency to the game server.
* **Within a fault domain**: Kubernetes Clusters are single points of failure. A single misconfigured RBAC rule, an overloaded Kubernetes Control Plane, etc. can prevent new game server allocations, or worse, disrupt existing sessions. Running multiple clusters within a fault domain also allows for [easier upgrades]({{< relref "Upgrading#upgrading-agones-multiple-clusters" >}}).
