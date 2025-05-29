# api-deployment.yaml

### Create a Deployment Configuration
Let's write a deployment from scratch.

Feel free to reference the k8s docs here as you go for examples of the proper structure.

1. Create a new file called api-deployment.yaml.
2. Add the apiVersion and kind fields. The apiVersion is apps/v1 and, since this is a deployment, the kind is Deployment.
3. Add a metadata/name field, and let's name our deployment synergychat-api for consistency.
4. Add a metadata/labels/app field, and also set it to synergychat-api. This will be used to select the pods that this deployment manages.
5. Add a spec/replicas field and let's set it to 1. We can always scale up to more pods later.
6. Add a spec/selector/matchLabels/app field and set it to synergychat-api. This should match the label we set in step 4.
7. Add a spec/template/metadata/labels/app field and set it to synergychat-api. Again, this should match the label we set in step 4. Labels are important because they're how Kubernetes knows which pods belong to which deployments.
8. Add a spec/template/spec/containers field. This actually contains a list of containers that will be deployed:
    1. Note: A hyphen is how you denote a list item in yaml
    2. Set the name of the container to synergychat-api.
    3. Set the image to bootdotdev/synergychat-api:latest. This tells k8s where to download the Docker image from.

I don't want to give you the YAML because I want you to type it out, but here's the equivalent JSON:

```json
{
  "apiVersion": "apps/v1",
  "kind": "Deployment",
  "metadata": {
    "name": "synergychat-api",
    "labels": {
      "app": "synergychat-api"
    }
  },
  "spec": {
    "replicas": 1,
    "selector": {
      "matchLabels": {
        "app": "synergychat-api"
      }
    },
    "template": {
      "metadata": {
        "labels": {
          "app": "synergychat-api"
        }
      },
      "spec": {
        "containers": [
          {
            "name": "synergychat-api",
            "image": "bootdotdev/synergychat-api:latest"
          }
        ]
      }
    }
  }
}
```

```bash 
# create the deployment
kubectl apply -f api-deployment.yaml
```
