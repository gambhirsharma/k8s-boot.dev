# Pods

> "Pods are the smallest deployable units of computing that you can create and manage in Kubernetes."
> 
> -- The Kubernetes team

A Pod is the smallest and simplest unit in the Kubernetes object model that you create or deploy. It represents one (or sometimes more) running container(s) in a cluster. In a simple web application, you might have one single pod: the web server. As traffic grows, you might deploy that same code to multiple pods to handle the increased load. Several pods, one codebase. In a more complex backend system, you might have several pods for the web server and several pods that handle video processing. Multiple pods, multiple codebases.

![Diagram](https://storage.googleapis.com/qvault-webapp-dynamic-assets/course_assets/dK2fL05.png)

Pods are just wrappers around containers. You can think of it as a Docker container with a little extra Kubernetes magic. The container is the actual application, and the Pod is the Kubernetes abstraction that manages the container and the resources it needs to run.

```bash 
# edit the deployment yaml file
kubectl edit deployment synergychat-web
```

---

<details>
    <summary>**Tips**</summary>
    
If you want to set VS Code as your default text editor, you can add:

```bash 
export EDITOR="code -w"
```

to your `.zshrc` or `.bashrc` file, and restart your terminal. `code` is the command to open VS Code, and -w tells it to wait until you're done editing the file before continuing.
</details>

