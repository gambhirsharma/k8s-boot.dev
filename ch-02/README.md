# Pods

## **pods**:
> Details: [pods](./pods.md)
Pods are the smallest deployable units of computing that you can create and manage in Kubernetes.

A Pod (as in a pod of whales or pea pod) is a group of one or more containers, with shared storage and network resources, and a specification for how to run the containers. A Pod's contents are always co-located and co-scheduled, and run in a shared context. A Pod models an application-specific "logical host": it contains one or more application containers which are relatively tightly coupled. In non-cloud contexts, applications executed on the same physical or virtual machine are analogous to cloud applications executed on the same logical host.

As well as application containers, a Pod can contain init containers that run during Pod startup. You can also inject ephemeral containers for debugging a running Pod.

**Reference**
[Kubernetes/Documentation/Concepts/Workloads/Pods](https://kubernetes.io/docs/concepts/workloads/pods/#working-with-pods)

---
## **Ephemeral**

Pods die, they die often, and sometimes without warning.

The ephemeral (fancy word for "temporary") nature of Pods is one of the defining features of Kubernetes. Unlike traditional virtual machines (VMs) or physical servers that might run indefinitely (or until hardware failure), Pods are designed to be spun up, torn down, and restarted at a moment's notice.

- **Why are they temporary?** Flexibility and resilience. If a Pod encounters a problem, it can be easily terminated and replaced with a new, healthy instance. This model not only allows for high availability but also promotes immutability. Instead of manually patching or updating existing environments, you spin up new versions of the entire environment.
- **How does it affect me?** As a developer, it's crucial to understand that it's rarely a good idea to store persistent data on a Pod. They can be terminated and replaced, and any locally saved data will be lost. Plan on your image restarting from scratch often!


```bash
kubectl get pods

kubectl logs PODNAME

kubectl delete pod PODNAME
```

---
## **Unique IP Addresses**

Every Pod in a Kubernetes cluster has a unique internal-to-k8s IP address. By giving each Pod a unique IP, Kubernetes simplifies communication and service discovery within the cluster. Pods within the same Node or across different Nodes can easily communicate.

All the resources inside a k8s cluster are virtualized. So, the IP address of a Pod is not the same as the IP address of the Node it's running on. It's a virtual IP address that is only accessible from within the cluster.

```bash 
# It gives a few more columns of information, including the IP address of each Pod 
kubectl get pods -o wide
```

---
## kubectl proxy

The kubectl proxy command creates a local HTTP proxy server that allows you to access the Kubernetes API server securely from your local machine — without needing to handle authentication tokens or certificates manually.

```bash 
kubectl proxy
```

This will start a proxy server on your local machine, probably on `127.0.0.1:8001` Assuming that's the host, navigate to `http://127.0.0.1:8001/api/v1/namespaces/default/pods` in your browser. You should see a big nasty JSON blob that describes the pods that you have running.

