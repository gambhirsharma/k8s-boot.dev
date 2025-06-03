## Ingress
An [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) resource exposes services to the outside world and is used often in production environments. From the docs:

> An Ingress may be configured to give Services externally-reachable URLs, load balance traffic, terminate SSL / TLS, and offer name-based virtual hosting. An Ingress controller is responsible for fulfilling the Ingress, usually with a load balancer, though it may also configure your edge router or additional frontends to help handle the traffic.
> An Ingress does not expose arbitrary ports or protocols. Exposing services other than HTTP and HTTPS to the internet typically uses a service of type Service.Type=NodePort or Service.Type=LoadBalancer.

**Key Concepts**
- Ingress acts as an entry point to your cluster.
- It routes HTTP/S traffic to internal Kubernetes Services based on rules.
- Works with an Ingress Controller (e.g., NGINX, Traefik) that does the actual load balancing and proxying.

![diagram](https://storage.googleapis.com/qvault-webapp-dynamic-assets/course_assets/4Bu6KOe.png)
In the diagram above, the "client" can be anything. It doesn't live inside of k8s. It might just be a web browser or a mobile app. The "Ingress-managed load balancer" can be a bit confusing, we'll talk about it more later. For now, just know that it's a load balancer that lives outside the cluster and routes traffic through the ingress to a service.


##### **Assignment**

To work with an ingress first we need to enable it in minikube:

```bash 
minikube addons enable ingress
```

Next, create a new file. We'll call it `app-ingress.yaml` because it will be an ingress for the entire synergychat application, not just a specific service.

First, we need to add some metadata:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
```

The `annotations` section is where we can add extra configuration for our ingress. In this case, we're telling it to rewrite the target URL to `/` so that it will work with our web app.

Next, we need to add a `spec/rules` section. This is where we define the routing rules for our ingress. We only need 2 rules:

```yaml
spec:
  rules:
    - host: synchat.internal
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-service
                port:
                  number: 80
    - host: synchatapi.internal
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 80
```

This says that any traffic to the `synchat.internal` domain name should be routed to the `web-service` and any traffic to `synchatapi.internal` domain name should be routed to the `api-service`.

---
## DNS
Now that we've configured the ingress to route the domains:

- `synchat.internal` to the `web-service`
- `synchatapi.internal` to the `api-service`

We need to configure our local machine to resolve those domains to the ingress load balancer. We won't be setting up global DNS so that anyone on the internet can access our app! We'll just be configuring our local machine to resolve those domains to the ingress load balancer.

##### **Assignment**
There is a file called /etc/hosts on your local machine that is used to resolve domain names to IP addresses. We can add entries to that file to resolve our domains to the ingress load balancer.

Open /etc/hosts in your favorite text editor and add the following lines:

```bash 
127.0.0.1        synchat.internal
127.0.0.1        synchatapi.internal
```

You'll probably need to provide your password to save the file. Now both synchat.internal and synchatapi.internal should resolve to the IP address 127.0.0.1 (which is just localhost).

To make sure it's working, run:

```bash 
ping synchat.internal
```

---
## Tunnel
In production, once you have an ingress configured and have pointed your domain name to it (and perhaps its load balancer), you can access your application from anywhere in the world. The trouble is, we're using Minikube and the cluster is running on our local machine, and not only that, it's running in an isolated virtual machine.

Fear not! Minikube has a command that will forward the ingress to your local machine.

Assignment
Open a tunnel to your cluster (You might need to enter your password):

```bash 
minikube tunnel -c
```

We'll be using the tunnel a lot in the rest of the course, I recommend you keep it open in a separate terminal window.

The tunnel should expose the ingress controller's load balancer to your local machine on 127.0.0.1:80, which we mapped to the synchat.internal and synchatapi.internal domains in the previous exercise.

While the tunnel is open, navigate to http://synchat.internal in your browser. You should see the web app! The JSON API should also be available at http://synchatapi.internal (the root of the API should return a 404, but /healthz should return a 200).

Once you've confirmed that you can access the web app via a web browser, answer the question on the right.

---
## Ingress Types
You may have noticed that at the top of all our resources we have this in the yaml:

```yaml
apiVersion: v1
```

This is the API version of the resource, and because those resources are core to Kubernetes, they're in the standard v1 API group.

However, ingress isn't a core Kubernetes resource, it's an extension of sorts. That's why it has:

```yaml
apiVersion: networking.k8s.io/v1
```

You can think of the networking.k8s.io API group as a core extension. It's not third-party (it's on k8s.io for heaven's sake), but it's not part of the core Kubernetes API either.

##### **Annotations**
You probably noticed that we used a single annotation on our ingress resource:

```yaml
annotations:
  nginx.ingress.kubernetes.io/rewrite-target: /
```

This is a really common pattern in Kubernetes. The core Kubernetes API is intentionally kept small, but there are a lot of things that people want to do with Kubernetes that aren't part of the core API. So, instead of adding a bunch of new fields to the core API, Kubernetes allows you to add arbitrary annotations to your resources, and then various extensions can read those annotations and do things with them.

For example, the Boot.dev Kubernetes cluster uses an ingress extension specific to Google Cloud Platform. We use the following annotations so that our controller knows which static IP address to use, which SSL certificate to use, and how to route traffic to our ingress:

```yaml
annotations:
  kubernetes.io/ingress.global-static-ip-name: static-ip-name-here
  networking.gke.io/managed-certificates: cert-name-here
  kubernetes.io/ingress.class: gce
```

If you're curious about the specifics, [the docs are](https://cloud.google.com/kubernetes-engine/docs/how-to/load-balance-ingress) here. In a nutshell, however, the important take-away is that in most production deployments you'll be using annotations specific to the cloud provider you're using. Each major cloud provider has their own products, so you need to use k8s annotations and extensions specific to that cloud provider.

Now that you understand the basic concepts of ingress, in the future, it's just a matter of following the documentation for your cloud provider to get it set up.

---
## Chat
Now that everything is accessible via ingress (at least while the tunnel is open), let's connect the web application front-end to the API.

##### **Assignment**
1. Create a new ConfigMap for the web service. Add two new environment variables:
  1. WEB_PORT: `8080` (this was already the default, now we're just making it explicit)
  2. API_URL: `http://synchatapi.internal`
Update the web application's deployment to use the new ConfigMap.
Once all that's applied to your cluster, you should be able to open the web application and actually use the chat interface (notice it's "synchat", not "synchatapi"):

```bash 
http://synchat.internal
```

Make sure that you can enter a username and a message, and send a message as that user! Assuming it works, that's because the webpage is now sending messages via fetch requests to the api service. The api service saves those messages locally in memory.

To see what I mean, try the following:

0. Create a few messages as different users.
0. Refresh the page
0. The messages should still be there because they're saved in the server's memory.
0. Now, delete the api pod
0. Once k8s replaces the deleted pod with a new one, refresh the page again.

