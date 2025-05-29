## Config Maps

There are several ways to manage environment variables in Kubernetes. One of the most common ways is to use [ ConfigMaps ](https://kubernetes.io/docs/concepts/configuration/configmap/). ConfigMaps allow us to decouple our configurations from our container images, which is important because we don't want to have to rebuild our images every time we want to change a configuration value.

Use for:
- Port numbers
- Hostnames
- Feature flags
- App settings
- Environment variables

In a Dockerfile we can set environment variables like this:

```bash 
ENV PORT=3000
```

The trouble is, that means that everyone using that image will have to use port 3000. It also means that if we want to change the port, we have to rebuild the image.

To solve this we will create a `api-configmap.yaml`:

Create a new file. Let's call it api-configmap.yaml. Add the following YAML to it:

**apiVersion:** v1
**kind:** ConfigMap
**metadata/name:** synergychat-api-configmap
**data/API_PORT:** "8080"

```yaml
apiVersion: v1
kind: ConfigMap
metadata: 
  name: synergychat-api-configmap
data: 
  API_PORT: "8080"
```

```bash 
# apply the config map
kubectl apply -f api-configmap.yaml

kubectl get configmaps
```

---
## Applying the config-map

Open up your `api-deployment.yaml` file. We're going to add a few things to it. Under the containers section, add the following to the first (and only) entry:

```yaml
env:
  - name: API_PORT
    valueFrom:
      configMapKeyRef:
        name: synergychat-api-configmap
        key: API_PORT
```

This tells Kubernetes to set the API_PORT environment variable to the value of the API_PORT key in the synergychat-api-configmap config map. Reference the [ official docs  ](https://kubernetes.io/docs/concepts/configuration/configmap/)if you're confused about the structure of the yaml.

Then just deploy the `api-deployment.yaml`

```bash 
# forward the api port
kubectl port-forward <pod-name> 8080:8080

# curl 
curl http://localhost:8080
# 404 error

```
---
## Config Maps Are Insecure
ConfigMaps are a great way to manage innocent environment variables in Kubernetes. Things like:

- Ports
- URLs of other services
- Feature flags
- Settings that change between environments, like DEBUG mode

However, they are not cryptographically secure. ConfigMaps aren't encrypted, and they can be accessed by anyone with access to the cluster.

If you need to store sensitive information, you should use [ Kubernetes Secrets  ](https://kubernetes.io/docs/concepts/configuration/secret/) or a third-party solution.

---
## Crawler
We've got one last application to deploy to our cluster: the crawler. This is an application that continuously crawls [ Project Gutenberg](https://www.gutenberg.org/) and exposes the juicy data that it finds via a JSON API.

#### **Assignment** 

**Add a New Config Map**
Create a copy of your `api-configmap.yaml `file and call it `crawler-configmap.yaml`. We're going to make a few changes to it.

1. Name it `synergychat-crawler-configmap` instead of `synergychat-api-configmap`.
2. Remove the API_PORT environment variable.
3. Add some new environment variables:
    - CRAWLER_PORT: "8080"
    - CRAWLER_KEYWORDS: love,hate,joy,sadness,anger,disgust,fear,surprise

It's okay that the CRAWLER_PORT in the crawler deployment is the same as the API_PORT in the api deployment. They're in different pods, and these are pod-internal ports.
