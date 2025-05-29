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
