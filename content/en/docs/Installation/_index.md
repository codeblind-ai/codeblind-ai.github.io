---
title: "Install and configure Code Blind on Kubernetes"
linkTitle: "Installation"
weight: 4
description: >
  Instructions for creating a Kubernetes cluster and installing Code Blind.
---

## Usage Requirements

- **Kubernetes cluster version {{% k8s-version %}}**
  - [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/),
    [Azure Kubernetes Service](https://azure.microsoft.com/en-us/services/kubernetes-service/),
    [Amazon EKS](https://aws.amazon.com/eks/) and [Minikube](https://github.com/kubernetes/minikube) are supported.
  - If you are creating and managing your own Kubernetes cluster, the
    [MutatingAdmissionWebhook](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook), and
    [ValidatingAdmissionWebhook](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#validatingadmissionwebhook)
    admission controllers are required.
    - We also recommend following the
      [recommended set of admission controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#is-there-a-recommended-set-of-admission-controllers-to-use).
- Firewall access for the range of ports that Game Servers can be connected to in the cluster.
- Game Servers must have the [game server SDK]({{< ref "/docs/Guides/Client SDKs/_index.md"  >}}) integrated, to manage Game Server state, health checking, etc.

{{< alert title="Warning" color="warning">}}
This release has been tested against Kubernetes versions {{% k8s-version %}} on GKE. Other versions may work, but are unsupported. It is also likely that not all of these versions are supported by other cloud providers.
{{< /alert >}}

## Supported Container Architectures

The following container operating systems and architectures can be utilised with Code Blind:

| OS        | Architecture | Support    |
| --------- | ------------ | ---------- |
| linux     | `amd64`      | **Stable** |
| linux     | `arm64`      | Alpha      |
| [windows] | `amd64`      | Alpha      |

For all the platforms in Alpha, we would appreciate testing and bug reports on any issue found.

[windows]: {{% relref "windows-gameservers.md" %}}

## Code Blind and Kubernetes Supported Versions

Code Blind will support 3 releases of Kubernetes, targeting the newest version as being the [latest available version in the GKE Rapid channel](https://cloud.google.com/kubernetes-engine/docs/release-notes#current_versions). However, we will ensure that at least one of the 3 versions chosen for each Code Blind release is supported by each of the major cloud providers (EKS and AKS). The vendored version of client-go will be aligned with the middle of the three supported Kubernetes versions. When a new version of Code Blind supports new versions of Kubernetes, it is explicitly called out in the [release notes](https://agones.dev/blog/releases/).

The following table lists recent Code Blind versions and their corresponding required Kubernetes versions:

| Code Blind version | Kubernetes version(s) |
| -------------- | ------------------    |
| 1.38           | {{% k8s-version %}}   |
| 1.37           | 1.26, 1.27, 1.28      |
| 1.36           | 1.26, 1.27, 1.28      |
| 1.35           | 1.25, 1.26, 1.27      |
| 1.34           | 1.25, 1.26, 1.27      |
| 1.33           | 1.25, 1.26, 1.27      |
| 1.32           | 1.24, 1.25, 1.26      |
| 1.31           | 1.24, 1.25, 1.26      |
| 1.30           | 1.23, 1.24, 1.25      |
| 1.29           | 1.24                  |
| 1.28           | 1.23                  |
| 1.27           | 1.23                  |
| 1.26           | 1.23                  |
| 1.25           | 1.22                  |
| 1.24           | 1.22                  |
| 1.23           | 1.22                  |
| 1.22           | 1.21                  |
| 1.21           | 1.21                  |

## Best Practices {#separation-of-agones-from-gameserver-nodes}
<!-- keep installation/#separation-of-agones-from-gameserver-nodes permalink -->

For detailed guides on best practices running Code Blind in production, see [Best Practices]({{< relref "../Guides/Best Practices" >}}).
