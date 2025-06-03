## Storage in Kubernetes

Storage in Kubernetes
By default, containers running in pods on Kubernetes have access to the filesystem, but as we're about to find out, there are some big limitations to this.

##### **Assignment**
The api application in SynergyChat can be configured to save its data (the messages) to a file on the filesystem. That way, even if the program is restarted, the messages will still be there.

Update the api service's ConfigMap to include a new environment variable:

- `API_DB_FILEPATH:` `/var/lib/synergychat/api/db.json`
Next, update the api service's deployment to use the new value.

Take a look at the logs of the new pod (kubectl logs <podname>). You should see a message saying that the filesystem will be used for the database. If you do, everything is working as intended!

Now, let's test the persistent storage:

0. Open a webpage to http://synchat.internal.
0. Create a few messages as different users.
0. Refresh the page
0. The messages should still be there because they're saved in the server's memory.
0. Now, delete the api pod
0. Once k8s replaces the deleted pod with a new one, refresh the page again.

Perhaps to your surprise, the messages are gone! What??? Why??? We saved them to the filesystem, didn't we? Well, we did, but in Kubernetes the filesystem is ephemeral. That means that when a pod is deleted, the filesystem is deleted with it.

This has to do with the philosophy behind Kubernetes and even containers in general: when we spin up a new one, it should always be a blank slate, which makes reproducing and debugging issues much easier. No messy state to worry about.


---
## Ephemeral Volumes
On-disk files in a container are ephemeral as we saw in the last lesson. This presents some problems for applications that want to save long-lived data across restarts. For example, user data in a database.

The Kubernetes [volume](https://kubernetes.io/docs/concepts/storage/volumes/) abstraction solves two primary problems:

1. Data persistence
2. Data sharing across containers

As it turns out, there are a lot of different types of "volumes" in Kubernetes. Some are even ephemeral as well, just like a container's standard filesystem. The primary reason for using an ephemeral volume is to share data between containers in a pod.

##### **Assignment**
It's time to shift our focus back to the [crawler service](https://github.com/bootdotdev/synergychat/#crawler-service). The crawler service continuously crawls Project Gutenberg and exposes the information that it finds via a JSON API. That data is then made available via slash commands in the chat application.

The crawler is pretty slow by default. Each instance only crawls one book every 30 seconds.

To see what I mean, run:

```bash
kubectl logs <crawler-podname>
```

You should see some logs with timestamps that show you the crawler's progress.

We can speed it up by increasing the number of concurrent crawlers. The trouble with scaling up beyond one instance is that each crawler currently stores its data in memory. We need all pods to share the same data so they can each add their findings to the same database.

Let's update the crawler deployment to use a volume that will be shared across all containers in the crawler pod, and scale up the number of containers in the pod.

1. Add a `volumes` section to `spec/template/spec`.
```yaml 
volumes:
  - name: cache-volume
    emptyDir: {}
```

2. Add a new `volumeMounts` section to the container entry. This will mount the volume we just created at the `/cache` path.
```yaml
volumeMounts:
  - name: cache-volume
    mountPath: /cache

```

3. Duplicate the entire first entry in the containers list twice (you should now have 3 total containers). Update the name of each:

- synergychat-crawler-1
- synergychat-crawler-2
- synergychat-crawler-3

Now all the containers in the pod will share the same volume at /cache. It's just an empty directory, but the crawler will use it to store its data.

4. Add a `CRAWLER_DB_PATH` environment variable to the crawler's ConfigMap. Set it to `/cache/db`. The crawler will use a directory called db inside the volume to store its data.
5. Apply the new ConfigMap and Deployment, and use kubectl get pod to see the status of your new pod.
You should notice that there's a problem with the pod! Only 1/3 of containers should be "ready". Use the logs command to get the logs for all 3 containers:

```bash 
kubectl logs <podname> --all-containers
```

You should see something like this:

```bash 
listen tcp :8080: bind: address already in use
```

Because pods share the same network namespace, they can't all bind to the same port! Hmm... let's put a bandaid on this by binding each container to a different port. 8080 is the only one that will be exposed via the service, but that's okay for now. We can add redundancy later.

6. Add two new values to the crawler's ConfigMap:
CRAWLER_PORT_2: 8081
CRAWLER_PORT_3: 8082
7. Update the crawler deployment:
Change the second and third containers to map CRAWLER_PORT_2 -> CRAWLER_PORT and CRAWLER_PORT_3 -> CRAWLER_PORT respectively (the Docker image expects a variable named "CRAWLER_PORT"). I'm not going to give you the code, but know that it's gonna be a bit tedious because you need to use env: instead of envFrom: for the second and third containers. Don't forget to continue exposing the CRAWLER_KEYWORDS and CRAWLER_DB_PATH environment variables for all containers.

When you're done, apply the changes and run kubectl get pods again. All three containers should be ready, each serving on a different port, with only the first exposed via the service.

Run:

```bash 
kubectl proxy
```

---

## Containers in Pods
Run the following command:

```bash 
kubectl get pods
```

You should see something like this:

```bash 
synergychat-api-6c7944b5c4-rp2k4      1/1     Running   0          160m
synergychat-crawler-cd4947995-ftqg4   3/3     Running   0          151m
synergychat-web-846d86c444-2m6x7      1/1     Running   0          21h
synergychat-web-846d86c444-gxztt      1/1     Running   0          21h
synergychat-web-846d86c444-s88rz      1/1     Running   0          21h
```

It's important to remember that while it's common for a pod to run just a single container, multiple containers can run in a single pod. This is useful when you have containers that need to share resources. In other words, we can scale up the instances of an application either at the container level or at the pod level.

> Note: There is only one crawler pod with 3 docker image/container

---

## Persistence
All the volumes we've worked with so far have been ephemeral, meaning when the associated pod is deleted the volume is deleted as well. This is fine for some use cases, but for most CRUD apps we want to persist data even if the pod is deleted.

If you think about it, it's not even just when pods are explicitly deleted with kubectl that we need to worry about data loss. Pods can be deleted for several reasons:

- The node they're running on could fail
- A new version of the image was published (code was updated, etc)
- A new node was added to the cluster and the pod was rescheduled

In all of these cases, we want to make sure that our data is still available. [Persistent volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) allow us to do this.

##### **Persistent Volumes (PV)**
Instead of simply adding a volume to a deployment, a persistent volume is a cluster-level resource that is created separately from the pod and then attached to the pod. It's similar to a ConfigMap in that way.

PVs can be created statically or dynamically.

- Static PVs are created manually by a cluster admin
- Dynamic PVs are created automatically when a pod requests a volume that doesn't exist yet
Generally speaking, and especially in the cloud-native world, we want to use dynamic PVs. It's less work and more flexible.

##### **Persistent Volume Claims (PVC)**
A persistent volume claim is a request for a persistent volume. When using dynamic provisioning, a PVC will automatically create a PV if one doesn't exist that matches the claim.

The PVC is then attached to a pod, just like a volume would be.

##### **Assignment**
Create a new file called api-pvc.yaml and add the following:

```bash 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: xxx
spec:
  accessModes:
    - xxx
  resources:
    requests:
      storage: xxx
```

Add the following properties:

- metadata/name: synergychat-api-pvc
- spec/accessModes: An array with one entry:
  - ReadWriteOnce
- spec/resources/requests/storage: 1Gi

This creates a new PVC called synergychat-api-pvc with a few properties that can be read from and written to by multiple pods at the same time. It also requests 1GB of storage.

Apply the PVC.

Run both of these commands:

```bash 
kubectl get pvc
kubectl get pv

# delete the pvc-volume
kubectl delete pvc <pvc-name>
```

Make sure both the PVC and PV are gone

---
## Attach Persistence
So far all we've done is create an empty persistent volume. Let's get the api application to use it.

##### **Assignment**
Use your crawler deployment and the [docs](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) as a reference. Create a new volume in the api-deployment referencing your pvc:

```yaml
volumes:
  - name: synergychat-api-volume
    persistentVolumeClaim:
      claimName: synergychat-api-pvc
```

Then mount it in the container under the /persist directory:

```yaml
volumeMounts:
  - name: synergychat-api-volume
    mountPath: /persist
```

Update the API_DB_FILEPATH environment variable you added earlier to instead use the new mount path: /persist/db.json

Apply the changes, then check to make sure all your pods are healthy:

```bash 
kubectl get pods
```

With your tunnel running (minikube tunnel -c), open http://synchat.internal/ in your browser.

1. Send some messages.
2. Delete the api pod.
3. Once the new pod is running, refresh the page and make sure your messages are still there. If they are, your persistent volume is working!

---
## Databases
Now that you know all about volumes, you might be thinking, "Awesome! I'll host my CRUD app on Kubernetes and use a volume to store my PostgreSQL database data!".

That's certainly possible, but frankly, it's not always the best idea. For example, the Boot.dev system that powers this website has the following components:

- A web application, currently served by Cloudflare (this could easily be a Kubernetes deployment if we cared to move it)
- Several backend microservices, all running on Kubernetes in Google Cloud
  - Our main JSON CRUD API
  - A Discord bot
  - A service that compiles student's Go code to WASM
  - etc
- A managed PostgreSQL database, hosted by Cloud SQL (GCP)

Why do we do this? Well, Kubernetes isn't always the simplest way to get a job done. We could certainly host a PostgreSQL database on Kubernetes, but it would require a lot of extra work to get it to work well. For example, we'd need to manually build all the configurations to:

- Create a persistent volume
- Handle Postgres version updates
- Set resource limits
- Set up automated backups

For that reason, when I need an SQL database, I typically use a managed service like Cloud SQL or RDS. There are exceptions to that rule, but it's a good rule of thumb.


##### **When Would You Use a Database on Kubernetes?**

I have used databases on Kubernetes in the past, but I've usually done it when the deployment wasn't exactly mission-critical. For example, I've deployed [Grafana](https://grafana.com/) and [Prometheus](https://prometheus.io/) on Kubernetes, and they both have out-of-the-box support for in-cluster databases. I didn't care too much about backups and automatic upgrades for my telemetry data, and I knew the data set was small and static, so it was a good fit.
