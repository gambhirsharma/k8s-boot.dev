## Namespaces

To quote the [Zen of Python](https://www.python.org/dev/peps/pep-0020/):
> Namespaces are one honking great idea -- let's do more of those!

[Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) are a way to isolate cluster resources into groups. They're a bit like directories on your computer, but instead of containing files, they contain Kubernetes objects. As you've already learned, every resource in Kubernetes has a name. Some of our names include:

- synergychat-api-configmap
- api-service
- api-deployment
- web-deployment
- ...

You can only use a name once. It is a unique identifier. That's how kubectl apply knows when it should create a new resource and when it should update an existing one. Namespaces allow us to use the same name for different resources, as long as they're in different namespaces.

Run the following command:

```bash 
kubectl get namespaces

# shorter form
kubectl get ns
```

---
## Moving Namespaces
Up until this point, we've been working in the default namespace. When using kubectl commands, you can specify the namespace with the --namespace or -n flag. If you don't, it will use the default namespace.

```bash 
[I] ✦ ➜ kubectl get pod
NAME                                   READY   STATUS    RESTARTS      AGE
synergychat-api-778fb858f4-kdnnl       1/1     Running   0             21m
synergychat-crawler-85646dd776-zr6rc   3/3     Running   0             19m
synergychat-web-5fcfdbbbb6-222qc       1/1     Running   5 (13h ago)   42h
synergychat-web-5fcfdbbbb6-flpzx       1/1     Running   5 (13h ago)   42h
synergychat-web-5fcfdbbbb6-jr56c       1/1     Running   5 (13h ago)   42h

# VS

[I] ✦ ➜ kubectl -n kube-system get pod
NAME                               READY   STATUS    RESTARTS       AGE
coredns-674b8bbfcf-664wb           1/1     Running   18 (13h ago)   7d8h
etcd-minikube                      1/1     Running   18 (13h ago)   7d8h
kube-apiserver-minikube            1/1     Running   18 (12h ago)   7d8h
kube-controller-manager-minikube   1/1     Running   18 (13h ago)   7d8h
kube-proxy-xzjf7                   1/1     Running   18 (13h ago)   7d8h
kube-scheduler-minikube            1/1     Running   18 (13h ago)   7d8h
storage-provisioner                1/1     Running   41 (12h ago)   7d8h
```

The `kube-system` namespace is where all the core Kubernetes components live, it's created automatically when you install Kubernetes. You don't want to mess with it.


##### **Making a New Namespace**
If you have a small cluster with only a few applications, you can probably get away with just using the default namespace. However, if you have a large cluster with many applications, and in particular many teams working on those applications, namespaces are a great way to keep things organized.

For the sake of learning, let's assume that we have a separate development team responsible for the crawler service at SynergyChat, and they want to have their own namespace.

##### **Assignment**
Create a new namespace called crawler:

```bash 
kubectl create ns crawler

# ✅verify it
kubectl get ns
```

Next, add `namespace: crawler` to the `metadata` section of each of the crawler resources and apply them. Interestingly, you should see that the resources are "created" not "updated". That's because they're now in a new namespace, and the unique identifier of a resource in Kubernetes is the combination of its name and its namespace.

Make sure your resources are now redeployed in the crawler namespace:

```bash 
kubectl -n crawler get pods
kubectl -n crawler get svc
kubectl -n crawler get configmaps
```

Then go delete the old resources in the default namespace:
```bash 
kubectl delete deployment <deployment-name>
kubectl delete service <service-name>
kubectl delete configmap <configmap-name>
```

---

## Intra-Cluster DNS
The front-end of SynergyChat communicates with the api application via an external ingress:

```
Domain name http://synchatapi.internal -> ingress -> service -> pod
```

It's now time to connect the crawler and api applications. The api needs to be able to make HTTP requests directly to the crawler so that it can get the latest data to power the "stats" slash command.

front-end -> api -> crawler

The HTTP communication between the api and crawler is strictly internal to the cluster, there's no need for an external domain name or ingress. That makes it simpler, faster and more secure.

##### **Slash Command**
With the tunnel open (`minikube tunnel -c`) open `http://synchat.internal/` in your browser. Post a new message with `/stats` as the message text. You should see a response that says:

```
crawler-bot: Crawler worker not configured
```

That's because the api doesn't know how to communicate with the crawler yet. Let's fix that.

##### **DNS**
Kubernetes automatically creates [DNS entries](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) for each service that can be used to route HTTP traffic between services. The format is:

```
<service-name>.<namespace>.svc.cluster.local
```

##### **Assignment**
Update the api application's ConfigMap and Deployment to add a new environment variable called CRAWLER_BASE_URL its value should be:

```
http://<service-name>.<namespace>.svc.cluster.local
```

Replace `<service-name>` and `<namespace>` with the appropriate values for the crawler service. This will allow the api to make HTTP requests to the crawler service.

Apply your changes, restart the pod, then post a new message to SynergyChat with /stats as the message text and answer the question on the right.


---
## Namespace and Routing Review
Namespaces are used to separate resources into logical groups. They also impact how internal DNS works.

At Boot.dev, we have all of our production backend services in a namespace, let's pretend it's called "backend". Each time I use kubectl to work with the backend services, I have to specify the namespace:

```bash
kubectl -n backend get pods
```

##### **Internal Routing**
Kubernetes makes it really easy for pods to communicate with each other. It does this by automatically creating DNS entries for each service. The format is:

```bash 
<service-name>.<namespace>.svc.cluster.local
```

In reality, the `.svc.cluster.local` isn't needed in most scenarios. If you just use `http://<service-name>.<namespace>` for the api->crawler communication, it will work. When working in the same namespace, you can even just use `http://<service-name>.` That wouldn't work for us in our scenario just because the crawler is in its own separate namespace.


##### **Internal Is Better Than External**
Unless a service really needs to be made available to the outside world, it's better to keep it internal to the cluster. Internal communications are great because:

- It's faster (assuming nodes are close to each other physically)
- No public DNS is required
- Communication is inherently more secure because it runs on an internal network (usually don't even need HTTPS)

The architecture of SynergyChat is a good example of this. We expose a single JSON API to the outside world, and if the pod that serves those HTTP requests doesn't have all the info it needs locally, it makes internal HTTP requests to other services.
