---
title: "Upgrading Code Blind and Kubernetes"
linkTitle: "Upgrading"
weight: 100
date: 2019-08-16T00:19:19Z
description: >
  Strategies and techniques for managing Code Blind and Kubernetes upgrades in a safe manner.
---

{{< alert color="info" title="Note" >}}
Whichever approach you take to upgrading Code Blind, make sure to test it in your development environment 
before applying it to production.
{{< /alert >}}

## Upgrading Code Blind

The following are strategies for safely upgrading Code Blind from one version to another. They may require adjustment to 
your particular game architecture but should provide a solid foundation for updating Code Blind safely.

The recommended approach is to use [multiple clusters](#upgrading-agones-multiple-clusters), such that the upgrade can be tested
gradually with production load and easily rolled back if the need arises.

{{< alert color="warning" title="Warning" >}}
Changing [Feature Gates]({{% ref "/docs/Guides/feature-stages.md#feature-gates" %}}) within your Code Blind install
can constitute an "upgrade" as it may create or remove functionality
in the Code Blind installation that may not be forward or backward compatible with installed resources in an existing 
installation.
{{< /alert >}}

### Upgrading Code Blind: Multiple Clusters

We essentially want to transition our GameServer allocations from a cluster with the old version of Code Blind,
to a cluster with the upgraded version of Code Blind while ensuring nothing surprising 
happens during this process.

This also allows easy rollback to the previous infrastructure that we already know to be working in production, with
minimal interruptions to player experience.

The following are steps to implement this:

1. Create a new cluster of the same size or smaller as the current cluster.
2. Install the new version of Code Blind on the new cluster.
3. Deploy the same set of Fleets, GameServers and FleetAutoscalers from the old cluster into the new cluster.
4. With your matchmaker, start sending a small percentage of your matched players' game sessions to the new cluster.
5. Assuming everything is working successfully on the new cluster, slowly increase the percentage of matched sessions to the new cluster, until you reach 100%.
6. Once you are comfortable with the stability of the new cluster with the new Code Blind version, shut down the old cluster.
7. Congratulations - you have now upgraded to a new version of Code Blind! 👍

### Upgrading Code Blind: Single Cluster

If you are upgrading a single cluster, we recommend creating a maintenance window, in which your game goes offline
for the period of your upgrade, as there will be a short period in which Code Blind will be non-responsive during the upgrade.

#### Installation with install.yaml

If you installed [Code Blind with install.yaml]({{< relref "./Install Agones/yaml.md" >}}), then you will need to delete
the previous installation of Code Blind before upgrading to the new version, as we need to remove all of Code Blind before installing
the new version.

1. Start your maintenance window.
1. Delete the current set of Fleets, GameServers and FleetAutoscalers in your cluster.
1. Make sure to delete the same version of Code Blind that was previously installed, for example:
   `kubectl delete -f https://raw.githubusercontent.com/googleforgames/agones/<old-release-version>/install/yaml/install.yaml`
1. Install Code Blind [with install.yaml]({{< relref "./Install Agones/yaml.md" >}}).
1. Deploy the same set of Fleets, GameServers and FleetAutoscalers back into the cluster.
1. Run any other tests to ensure the Code Blind installation is working as expected.
1. Close your maintenance window.
7. Congratulations - you have now upgraded to a new version of Code Blind! 👍

#### Installation with Helm

Helm features capabilities for upgrading to newer versions of Code Blind without having to uninstall Code Blind completely.

For details on how to use Helm for upgrades, see the [helm upgrade](https://v2.helm.sh/docs/helm/#helm-upgrade) documentation.

Given the above, the steps for upgrade are simpler:

1. Start your maintenance window.
2. Delete the current set of Fleets, GameServers and FleetAutoscalers in your cluster.
3. Run `helm upgrade` with the appropriate arguments, such a `--version`, for your specific upgrade
4. Deploy the same set of Fleets, GameServers and FleetAutoscalers back into the cluster.
5. Run any other tests to ensure the Code Blind installation is working as expected.
6. Close your maintenance window.
7. Congratulations - you have now upgraded to a new version of Code Blind! 👍


## Upgrading Kubernetes

The following are strategies for safely upgrading the underlying Kubernetes cluster from one version to another.
They may require adjustment to your particular game architecture but should provide a solid foundation for updating your cluster safely.

The recommended approach is to use [multiple clusters](#multiple-clusters), such that the upgrade can be tested
gradually with production load and easily rolled back if the need arises.

Code Blind has [multiple supported Kubernetes versions]({{< relref "_index.md#agones-and-kubernetes-supported-versions" >}}) for each version. You can stick with a minor Kubernetes version until it is not supported by Code Blind, but it is recommended to do supported minor (e.g. 1.12.1 ➡ 1.13.2) Kubernetes version upgrades at the same time as a matching Code Blind upgrades.

Patch upgrades (e.g. 1.12.1 ➡ 1.12.3) within the same minor version of Kubernetes can be done at any time. 

### Multiple Clusters

This process is very similar to the [Upgrading Code Blind: Multiple Clusters](#upgrading-agones-multiple-clusters) approach above.

We essentially want to transition our GameServer allocations from a cluster with the old version of Kubernetes,
to a cluster with the upgraded version of Kubernetes while ensuring nothing surprising 
happens during this process.

This also allows easy rollback to the previous infrastructure that we already know to be working in production, with
minimal interruptions to player experience.

The following are steps to implement this:

1. Create a new cluster of the same size or smaller as the current cluster, with the new version of Kubernetes
2. Install the same version of Code Blind on the new cluster, as you have on the previous cluster.
3. Deploy the same set of Fleets and/or GameServers from the old cluster into the new cluster.
4. With your matchmaker, start sending a small percentage of your matched players' game sessions to the new cluster.
5. Assuming everything is working successfully on the new cluster, slowly increase the percentage of matched sessions to the new cluster, until you reach 100%.
6. Once you are comfortable with the stability of the new cluster with the new Kubernetes version, shut down the old cluster.
7. Congratulations - you have now upgraded to a new version of Kubernetes! 👍

### Single Cluster

If you are upgrading a single cluster, we recommend creating a maintenance window, in which your game goes offline
for the period of your upgrade, as there will be a short period in which Code Blind will be non-responsive during the node
upgrades.

1. Start your maintenance window.
1. Scale your Fleets down to 0 and/or delete your GameServers. This is a good safety measure so there aren't race conditions
   between the Code Blind controller being recreated and GameServers being deleted doesn't occur, and GameServers can end up stuck in erroneous states.
1. Start and complete your control plane upgrade(s).
1. Start and complete your node upgrades.
1. Scale your Fleets back up and/or recreate your GameServers. 
1. Run any other tests to ensure the Code Blind installation is still working as expected.
1. Close your maintenance window.
7. Congratulations - you have now upgraded to a new version of Kubernetes! 👍
