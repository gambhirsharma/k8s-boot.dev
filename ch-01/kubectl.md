# Kubectl

### Deploying an Image
The kubectl create deployment command will create a "deployment" for us. We'll talk more about the nuances of "deployments" later. But to put it simply, we only need to provide two things:

The name of the deployment (this can be anything, it's used to identify the deployment)
The ID of the Docker image we want to deploy (it would be a full URL if we weren't hosting the image on Docker Hub, which is the default)
```bash
kubectl create deployment synergychat-web --image=docker.io/bootdotdev/synergychat-web:latest
```

This command will deploy a container built from this Docker image to your local k8s cluster.

Viewing Deployments
To make sure the deployment was successful, run:

```bash
kubectl get deployments
```

#### Accessing the Web Page
By default, resources inside of Kubernetes run on a private, isolated network. They're visible to other resources within the cluster, but not to the outside world.

In order to access the application from your local network, you'll need to use kubectl to do some port forwarding. First, run:

```bash 
kubectl get pods
```

We'll talk more about pods later, but for now, a pod is an abstraction over a container, and remember, a container is just a running instance of an image. To oversimplify, a pod is a running application.

You should see something like this:

```bash 
NAME                                   READY   STATUS    RESTARTS   AGE
synergychat-web-679cbcc6cd-cq6vx       1/1     Running   0          20m
```
Next, run:

```bash 
kubectl port-forward PODNAME 8080:8080
```

Be sure to replace `PODNAME` with your pod's name. In my case, it was `synergychat-web-679cbcc6cd-cq6vx`.

Next, open your browser and navigate to `http://localhost:8080`. You should see a webpage titled "SynergyChat"! Keep in mind, that we haven't configured all the resources the page needs yet, so the forms won't work, but the page should load.

---

