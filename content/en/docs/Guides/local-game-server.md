---
title: "Local Game Server"
linkTitle: "Local Game Server"
date: 2019-02-19T08:00:00Z
weight: 40
description: >
  Register your local game server with Code Blind.
---

You can register a local game server with Code Blind. This means you can run an experimental build of your game server in the Code Blind environment without the need of packaging and deploying it to a fleet. This allows you to quickly iterate on your game server code while still being able to plugin to your Code Blind environment.

## Register your server with Code Blind

To register your local game server you'll need to know the IP address of the machine running it and the port. With that you'll create a game server config like the one below.

```yaml
apiVersion: "agones.dev/v1"
kind: GameServer
metadata:
  name: my-local-server
  annotations:
    # Causes Code Blind to register your local game server at 192.1.1.2, replace with your server's IP address.
    agones.dev/dev-address: "192.1.1.2"
spec:
  ports:
  - name: default
    portPolicy: Static
    hostPort: 17654
    containerPort: 17654
  # The following is ignored but required due to validation.
  template:
    spec:
      containers:
      - name: simple-game-server
        image: {{< example-image >}}
```

Once you save this to a file make sure you have `kubectl` configured to point to your Code Blind cluster and then run `kubectl apply -f dev-gameserver.yaml`. This will register your server with Code Blind.

Local Game Servers has a few limitations:

 * PortPolicy must be `Static`.
 * The game server is not managed by Code Blind. Features like autoscaling, replication, etc are not available.

When you are finished working with your server, you can remove the registration with `kubectl delete -f dev-gameserver.yaml`

## Next Steps:

- Review the specification of [GameServer]({{< ref "/docs/Reference/gameserver.md" >}}).
- Read about `GameServer` allocation.
  - Review the flow of how [allocation]({{< ref "/docs/Integration Patterns/allocation-from-fleet.md" >}}) is done.
  - Review the specification of [GameServerAllocation]({{< ref "/docs/Reference/gameserverallocation.md" >}}).
  - Check out the [Allocator Service]({{< ref "/docs/Advanced/allocator-service.md" >}}) as a richer alternative to `GameServerAllocation`.
- Learn how to connect your local development game server binary into a running Code Blind Kubernetes cluster for even more live development options with an [out of cluster dev server]({{< ref "/docs/Advanced/out-of-cluster-dev-server.md" >}}).
