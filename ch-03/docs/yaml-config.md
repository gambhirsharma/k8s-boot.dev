# YAML Config

Kubernetes resources are primarily configured using YAML files. We've used the kubectl edit command to edit resources in the cluster on-demand, but let's inspect our deployment's YAML file a bit more closely.

```bash 
# yaml file for synergychat-web deployment
kubectl get deployment synergychat-web -o yaml > web-deployment.yaml
```

There are 5 top-level fields in the file:

- **apiVersion**: apps/v1 - Specifies the version of the Kubernetes API you're using to create the object (e.g., apps/v1 for Deployments).
- **kind**: Deployment - Specifies the type of object you're configuring
- **metadata** - Metadata about the deployment, like when it was created, its name, and its ID
- **spec** - The desired state of the deployment. Most impactful edits, like how many replicas you want, will be made here.
- **status** - The current state of the deployment. You won't edit this directly, it's just for you to see what's going on with your deployment.

To apply the changes, run:

```bash 
kubectl apply -f web-deployment.yaml
```

You should get a warning that lets you know that you're missing the last-applied-configuration annotation. That's okay! we got that warning because we created this deployment the quick and dirty way, by using kubectl create deployment instead of creating a YAML file and using kubectl apply -f.

However, because we've now updated it with kubectl apply, the annotation is now there, and we won't get the warning again.

Download the YAML file again and take a look at it. You should see the annotation now.
