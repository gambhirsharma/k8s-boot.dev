## Top
We've already learned how to look at logs for k8s pods, but sometimes that's not enough when it comes to debugging. Sometimes we want to know about the resources that a pod is using.

To get metrics working, we need to enable the metrics-server addon. Run:

```bash
minikube addons enable metrics-server

# Take a look inside the kube-system namespace:
kubectl -n kube-system get pod
```

You should see a new "metrics-server" pod. It might take a couple of minutes to get started, but once that pod is ready, you should be able to run:

```bash 
[I] ➜ kubectl top pod
NAME                               CPU(cores)   MEMORY(bytes)
synergychat-api-6b498b87cc-xf74z   1m           4Mi
synergychat-web-5c8f566867-47rp4   1m           2Mi
synergychat-web-5c8f566867-kwzxq   1m           2Mi
synergychat-web-5c8f566867-mrqg8   1m           2Mi

```

The kubectl top command (just like the [unix top command](https://en.wikipedia.org/wiki/Top_(software))) will show you the resources that each pod is using. In the example above, each pod is using about 1 milliCPU and 15 megabytes of memory.

---
## Vertical and Horizontal Scaling
Generally speaking, there are two ways to scale an application: vertically and horizontally. When I say "Scaling", I'm talking about increasing the capacity of an application. For example, maybe we have a web server, and to handle roughly 1000 requests per second, it uses about:

- 1/2 of a CPU core
- 1 GB of RAM

If we want to "scale up" to handle 2000 requests per second, we could double the CPU and RAM:

- 1 CPU core
- 2 GB of RAM

This is called "vertical scaling" because we're increasing the capacity of the application by increasing the resources available to it. We're scaling up. Scaling up works until it doesn't. You can only scale up as much as your hardware will allow (the maximum number of CPUs and amount of RAM your node has).

The other way to scale is horizontally. Instead of increasing the resources available to the application, we increase the number of instances of the application (pods). Pods can be distributed across nodes, so we can scale horizontally until we run out of nodes. When working in a system like Kubernetes, it's generally better to scale horizontally than vertically.

---
## Resource Limits
None of our current deployments have any resource limits set. We have very little traffic, so it's not currently an issue, but in a production environment, we would want to set resource limits to ensure that our pods don't consume too many resources.

We wouldn't want a pod to hog all the CPU and RAM on its node, suffocating all of the other pods on the node.

##### **Setting Limits**
We can set [resource limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) in our deployment files. Here's an example:

```yaml
spec:
  containers:
    - name: <container-name>
      image: <image-name>
      resources:
        limits:
          memory: <max-memory>
          cpu: <max-cpu>
```

Memory is measured in bytes, so we can use the suffixes Ki, Mi, and Gi to specify kilobytes, megabytes, and gigabytes, respectively. For example, 512Mi is 512 mebibytes.

CPU is [measured in cores](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-cpu) so we can use the suffix m to specify milli-cores. For example, 500m is 500 milli-cores, or 0.5 cores.


##### **Assignment**
It would be really hard to test resource limits with our SynergyChat web application because we have no production traffic. Instead, I've created a couple of custom applications we can use to test and debug resource limits.

The `bootdotdev/synergychat-testcpu:latest` image on Docker Hub is an application that simply consumes as much CPU power as it can.

Create a new file called `testcpu-deployment.yaml` with the following:


```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: synergychat-testcpu
  name: synergychat-testcpu
spec:
  replicas: 1
  selector:
    matchLabels:
      app: synergychat-testcpu
  template:
    metadata:
      labels:
        app: synergychat-testcpu
    spec:
      containers:
        - image: bootdotdev/synergychat-testcpu:latest
          name: synergychat-testcpu
```

Add a CPU limit of 50m to the deployment.

Apply the deployment, then make sure the pod is running:

```bash 
kubectl get pod

# It might take a minute or so, but soon you should be able to see its metrics with top:

kubectl top pod
```

Assuming everything is working properly, you should see that the pod is using about 50 milli-cores of CPU. That's because k8s is throttling the pod to ensure that it doesn't use more than 50 milli-cores.


---
## Limits - RAM
We've successfully throttled the CPU usage of our testcpu pod, but what about RAM?

Create a new file called testram-deployment.yaml with the following:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: synergychat-testram
  name: synergychat-testram
spec:
  replicas: 1
  selector:
    matchLabels:
      app: synergychat-testram
  template:
    metadata:
      labels:
        app: synergychat-testram
    spec:
      containers:
        - image: bootdotdev/synergychat-testram:latest
          name: synergychat-testram
```

Add a memory limit of 256Mi (256 Megabytes) to the deployment. Remember, this is the [syntax](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) to do so:

```yaml
spec:
  containers:
    - name: <container-name>
      image: <image-name>
      resources:
        limits:
          memory: <max-memory>
          cpu: <max-cpu>
```

Additionally, create a ConfigMap called `testram-configmap.yaml` with the name "synergychat-testram-configmap" for this deployment that specifies a single environment variable:

- MEGABYTES: "200"

That will tell the application to allocate 200 megabytes of memory. Update the deployment to use the config map, then apply both.

Make sure the pod is healthy:

```bash
kubectl get pods

# After a minute or so, you should be able to see the memory usage of the pod:

kubectl top pods
```

The memory usage should be a little over 200 megabytes, but not more than 256 megabytes.

---

## Breaking the Limits
You may have noticed that with the testcpu application, we never "told" the application how much CPU to use. That's because generally speaking, applications don't know how much CPU they should use. They just go as "fast" as they can when they're doing computations.

Memory is different, applications allocate memory based on a variety of factors, and while an application can have its CPU throttled and just "go slower", if an application runs out of available memory, it will crash.

Let's test that!

Update the `MEGABYTES` environment variable for the `testram` application to `500` and apply the change.

Delete the testram pod so that the new environment variable takes effect. Assuming you did everything correctly, the pod should crash. You'll be able to check with:

```bash
kubectl get pods

# result 
[I] ➜ kgp
NAME                                   READY   STATUS      RESTARTS        AGE
synergychat-api-6b498b87cc-xf74z       1/1     Running     3 (3m28s ago)   38h
synergychat-testcpu-948d9c798-jcq77    1/1     Running     2 (3m28s ago)   28h
synergychat-testram-7f66595b8f-48plg   0/1     OOMKilled   0               20s
synergychat-web-5c8f566867-47rp4       1/1     Running     3 (3m27s ago)   38h
synergychat-web-5c8f566867-kwzxq       1/1     Running     3 (3m27s ago)   38h
synergychat-web-5c8f566867-mrqg8       1/1     Running     3 (3m28s ago)   38h

```


Command to change the env form the terminal 

```bash 
kubectl set env deployment/synergychat-testram MEGABYTES=500
```


<details>
    <summary>Details output</summary>
    
```bash
# details about the pod 
 k describe pod synergychat-testram-7f66595b8f-48plg 

# result
Name:             synergychat-testram-7f66595b8f-48plg
Namespace:        default
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       Wed, 04 Jun 2025 19:05:44 +0200
Labels:           app=synergychat-testram
                  pod-template-hash=7f66595b8f
Annotations:      <none>
Status:           Running
IP:               10.244.1.106
IPs:
  IP:           10.244.1.106
Controlled By:  ReplicaSet/synergychat-testram-7f66595b8f
Containers:
  synergychat-testram:
    Container ID:   docker://4daf2f290ae081661be58c7ada06821c21ccd4bd6de13494f7a4e569fbf84254
    Image:          bootdotdev/synergychat-testram:latest
    Image ID:       docker-pullable://bootdotdev/synergychat-testram@sha256:7b42d76850ce3df8ddbb0602700a44a1703d2d755f9c467cd4b13a0e0942028d
    Port:           <none>
    Host Port:      <none>
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Wed, 04 Jun 2025 19:07:09 +0200
      Finished:     Wed, 04 Jun 2025 19:07:19 +0200
    Ready:          False
    Restart Count:  3
    Limits:
      cpu:     100m
      memory:  256Mi
    Requests:
      cpu:     100m
      memory:  256Mi
    Environment:
      MEGABYTES:  500
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-glv6q (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-glv6q:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Guaranteed
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  113s                default-scheduler  Successfully assigned default/synergychat-testram-7f66595b8f-48plg to minikube
  Normal   Pulled     111s                kubelet            Successfully pulled image "bootdotdev/synergychat-testram:latest" in 1.908s (1.908s including waiting). Image size: 1961957 bytes.
  Normal   Pulled     93s                 kubelet            Successfully pulled image "bootdotdev/synergychat-testram:latest" in 1.662s (1.662s including waiting). Image size: 1961957 bytes.
  Normal   Pulled     69s                 kubelet            Successfully pulled image "bootdotdev/synergychat-testram:latest" in 1.866s (1.866s including waiting). Image size: 1961957 bytes.
  Normal   Pulling    31s (x4 over 113s)  kubelet            Pulling image "bootdotdev/synergychat-testram:latest"
  Normal   Created    29s (x4 over 109s)  kubelet            Created container: synergychat-testram
  Normal   Started    29s (x4 over 108s)  kubelet            Started container synergychat-testram
  Normal   Pulled     29s                 kubelet            Successfully pulled image "bootdotdev/synergychat-testram:latest" in 1.65s (1.65s including waiting). Image size: 1961957 bytes.
  Warning  BackOff    4s (x5 over 81s)    kubelet            Back-off restarting failed container synergychat-testram in pod synergychat-testram-7f66595b8f-48plg_default(3720d8d4-10d8-4e35-a161-62f576d61a01)
```
</details>

```bash
# output for the k8s-boot.dev course 

Containers:
  synergychat-testram:
    Container ID:   docker://453facc1515e05ec553ad755c6a0edffd3e67b62c14b4ddb328cc0f8d5c67250
    Image:          bootdotdev/synergychat-testram:latest
    Image ID:       docker-pullable://bootdotdev/synergychat-testram@sha256:a127779899f29d7b2e1fc80ed75e001eaed8e7cec0985707a802319fcdd9bec1
    Port:           <none>
    Host Port:      <none>
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       XXX
```

The reason for this pod failure is `OOMKilled` (out of memory kill)

---
## Fix the Limits

I don't want the pod to be consuming too much of your machine's resources, nor do I want you to have a constantly crashing pod, so before moving on, let's just reduce the memory usage of the `testram` pod.

Set the `MEGABYTES` environment variable to `10` and apply the change, then delete the pod so that the new environment variable takes effect.

Use `get pods` and `top pods` to make sure the pod is healthy and is using less than 10 megabytes of memory.

```bash 
kubectl set env deployment/synergychat-testram MEGABYTES=10
```
---
## Horizontal Pod Autoscaling (HPA)

A [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) can automatically scale the number of Pods in a Deployment based on observed CPU utilization or other custom metrics. It's very common in a Kubernetes environment to have a low number of pods in a deployment, and then scale up the number of pods automatically as CPU usage increases.

##### **Assignment**
First, delete the replicas: 1 line from the testcpu deployment. This will allow our new autoscaler to have full control over the number of pods.

Create a new file called `testcpu-hpa.yaml.` Add the following YAML to it:


```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: testcpu-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: x
  minReplicas: x
  maxReplicas: x
  targetCPUUtilizationPercentage: x
```

Set the following values:

- name: The name of the testcpu deployment
- minReplicas: 1
- maxReplicas: 4
- targetCPUUtilizationPercentage: 50

This hpa will monitor the CPU usage of the pods in the testcpu deployment. Its goal is to scale up or down the number of pods in the deployment so that the average CPU usage of all pods is around 50%. As CPU usage increases, it will add more pods. As CPU usage decreases, it will remove pods. You can find the algorithm it uses [here](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#algorithm-details) if you're interested.

Apply the hpa, then run the following commands every few seconds to watch as the number of pods scales up:

```bash
kubectl get pods
kubectl top pods
```

> An hpa is just another resource, so you can also use kubectl get hpa to see the current state of the autoscaler.


---
## HPA - Web
Now that you've seen how an application that chews through CPU will quickly scale up from a single pod to multiple pods, let's see what happens with an application that doesn't have much going on in terms of compute resources.

##### **Assignment**
Delete the line "replicas: 3" from the web deployment. This will allow our new autoscaler to have full control over the number of pods.

Copy your `testcpu-hpa.yaml` file and call it web-hpa.yaml. Update the following values:

- name: web-hpa
- Target the "web" deployment
- Keep the scaling values the same
Apply the hpa, then use the following commands to see if any scaling happens:

```bash
kubectl get pods
kubectl top pods
```


---
## HPA Fix
Let's stop the testcpu deployment from eating a big chunk of your machine's resources.

Set its resource limit to cpu: 10m, and update the max replicas in the hpa to 1. Apply the changes and watch as the number of pods scales down.
