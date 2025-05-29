## Deployments
A [ Deployment ](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) provides declarative updates for Pods and ReplicaSets.

You describe your desired state in a Deployment, and the Deployment Controller's job is to make the current state match the desired state. You declare your hopes and dreams, and it's Kubernetes' job to make them come true.

```bash 
#  YAML file for your current deployment in the CLI
kubectl get deployment synergychat-web -o yaml

# editing current deployment
kubectl edit deployment synergychat-web
```

```bash
# run the k-proxy
kubectl proxy

# check details about deployments at this location
http://localhost:8001/apis/apps/v1/namespaces/default/deployments/synergychat-web
```

---
## Replica Sets
A [ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) maintains a stable set of replica Pods running at any given time. It's the thing that makes sure that the number of Pods you want running is the same as the number of Pods that are actually running.

You might be thinking, "I thought that's what a Deployment does." Well...yes.

A Deployment is a higher-level abstraction that manages the ReplicaSets for you. You can think of a Deployment as a wrapper around a ReplicaSet. Here's the rub:

You will probably never use ReplicaSets directly. I just need to mention what they are because you'll hear the term thrown around, and might even see them referenced in logs and such.

```bash 
# check for replicasets
kubectl get replicasets
```

---

## YAML config
> Details: [YAML config](./docs/yaml-config.md)

```bash 
# get the deployments yaml file and save it
kubectl get deployment synergychat-web -o yaml > web-deployment.yaml
```

There are 5 top-level fields in the file:

- **apiVersion**: apps/v1 - Specifies the version of the Kubernetes API you're using to create the object (e.g., apps/v1 for Deployments).
- **kind**: Deployment - Specifies the type of object you're configuring
- **metadata** - Metadata about the deployment, like when it was created, its name, and its ID
- **spec** - The desired state of the deployment. Most impactful edits, like how many replicas you want, will be made here.
- **status** - The current state of the deployment. You won't edit this directly, it's just for you to see what's going on with your deployment.

```bash 
# apply changes from the .yaml file
kubectl apply -f web-deployment.yaml
```

---
## API service
> Details: [api-deployment.md](./docs/api-service.md)

We've deployed one service, and we've deployed multiple instances of it. Time to deploy a second service!

This service doesn't serve a webpage! It's a JSON API. It's the backend for our chat application. By deploying the API and configuring the front-end to talk to it, we'll have a functional chat application!

---
## Thrashing Pods
One of the most common problems you'll run into when working with Kubernetes is Pods that keep crashing and restarting. This is called "thrashing" and it's usually caused by one of a few things:

- The application recently had a bug introduced in the latest image version
- The application is misconfigured and can't start properly
- A dependency of the application is misconfigured and the application can't start properly
- The application is trying to use too much memory and is being killed by Kubernetes

#### What Is “CrashLoopBackoff”?
When a pod's status is **CrashLoopBackoff,** that means the container is crashing (the program is exiting with error code **1** ).

Because Kubernetes is all about building self-healing systems, it will automatically restart the container. However, each time it tries to restart the container, if it crashes again, it will wait longer and longer in between restarts. That's why it's called a "backoff".

To fix a thrashing pod, you need to find out why it's crashing. We'll do that in a later lesson.

---
