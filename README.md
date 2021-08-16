# Tanzu Build Service on Public Cloud

<img src="images/logo.png" alt="Tanzu Build Service Wizard" width=200 height=220/>

Tanzu build service is a pretty cool tool for automating build process and segregating devlopmenet and operations. (Read more about TBS here: https://tanzu.vmware.com/build-service)

The official guide to install TBS is here: https://docs.pivotal.io/build-service/1-2/installing.html

However, There're a lot of steps to get TBS going in a k8s cluster.

In this repository I have created a bootstraped docker container that will
- On the first run will install TBS on a K8S cluster, saving you at least 4-5 hours worth of tasks and lots of binaries installtion on your host machine.
- Then give you shell access (from 2nd run onwards) for interacting with the TBS on a k8s cluster as well as the k8s cluster itself. 

***This should simplify the Day0 tasks of installing a TBS on a k8s cluster.***

**Please note:** *This installer does not work with ECR*

## Pre-Requisit
The host computer with docker-ce installed.


## Prepare
This docker container is bootstrapped with TBS version 1.2. 

At the time of writing/creating this tbs 1.2 was the latest version. 

**Tanzu net access**
For this installation you will need access to registry.pivotal.io which is now under VMware Tanzu Network.
- If you already have access then please login  
OR
- Signup to create login (sign up is free)

You will need login into Tanzu Net to accept EULA when you download the below in later section of this documentation
- Build service dependency (aka descriptor)
- Tanzu Build Service (aka kpack or kp)


**TBS Descriptor**
`tbsfiles/descriptor.yaml` may need updating (The one in this repo is version 100.0.24). Download updated descriptor from https://network.pivotal.io/products/tbs-dependencies/ and rename to descriptor.yaml (eg `mv ~/Downloads/descriptor-100.0.xx.yaml tbsfiles/descriptor.yaml`)


**files requirements:**
- bianaries/tmc ---> This is optional. Needed only if you are accessing cluster through the TMC kubeconfig then download the tmc binary and place it in the bianaries directory. If tmc cli is not needed please comment the lines (#39, #40) in the `Dockerfile`.
- binaries/kp ---> download `kp-linux` from https://network.pivotal.io/products/build-service/ into binaries directory and rename to kp (`mv ~/Downloads/kp-linux binaries/kp`)


**A k8s Cluster**
- Either create a dedicated cluster for TBS (using TMC, TKG, EKS, AKS, GKE)
- OR, use an existing one to deploy TBS on it

**K8S Cluster access:**
A Kubeconfig file is needed to access the cluster. In this case:
- I created the cluster using Tanzu Mission Control (TMC)
- Downlaod the kubeconfig file from TMC
- ***Place the configuration in a file named `config` in the `.kube` folder.***
- You may also want to have the TMC apitoken handy. I placed it in an env file that I did not commit.


**.env file**

Rename the .env.sample to .env. (eg: `mv .env.sample .env`)

And populate the below values:

- PIVOTAL_REGISTRY_USERNAME="{tanzu net username}"
- PIVOTAL_REGISTRY_PASSWORD="{tanzu net username}"
- PVT_REGISTRY="{private registry url. for dockerhub leave empty.}"
- PVT_REGISTRY_USERNAME="{private registry username. for dockerhub same value as before}"
- PVT_REGISTRY_PASSWORD="{private registry password}"
- BUILD_SERVICE_VERSION={build service version. eg: 1.2.1}
- BUILT_REGISTRY={the url of the registry where you want the build service to store built images}
- BUILT_REGISTRY_USERNAME={username of the above registry}
- BUILT_REGISTRY_PASSWORD="{password against the above username}"


## Install TBS on k8s cluster

The docker file 
- has all necessary dependencies (eg> kubectl, ytt, kapp, docker, awscli, stern etc) resolved
- has a install.sh that reads input needed from the .env file

All you need to do is run.

```
docker build . -t tbsonpubliccloud
docker run -it --rm -v ${PWD}:/root/ -v /var/run/docker.sock:/var/run/docker.sock --name tbsonpubliccloud tbsonpubliccloud /bin/bash
```

The build command will build the docker container with all necessary elements for TBS installation on your k8s cluster.
The run command will execute the installation process. It may ask from TMC api token. So please have it handy.

***The installation process will run for few mins. Please be patient and check the output to spot any error***. 

*I have tested several times installing on a EKS and AKS clusters and it worked without any error.*

The installation process will
- Install TBS on the k8s cluster
- Configure TBS to connect to your private code repository (so TBS can get the code to build)
- Configure TBS to connect to your private registry (where you would like TBS to push image after build is complete)
- Confgure TBS with a `default-builder` to build and create image.

This is just some default/sample builder I created to kick start things.

You can create your own builders to build and create containers and push to different registries (or same registry) later on through interacting with TBS.


## Interact with TBS on k8s cluster

Once the above docker run finishes your k8s cluster should have TBS installed/deployed in it and configured with a sample/default builder and ready to build. The container then also proceeds to give shell access.

When you get the shell access you can run commands to interact with the newly installed TBS.


Create a yaml to tell TBS what to do. eg: ~/tbsfiles/sample-build.yaml

Then simply apply

`kubectl apply -f ~/tbsfiles/sample-build.yaml`


To watch how our build is progressing

`kubectl get pods` --> to get the pod name created to perform the build.

Since, the pod is going to have several containers performing the build `kubectl logs` won't be enought to see the build in action. For this we need `stern`. This dockerimage is also bootstrapped with `stern`. So just run:

`stern calcaddservice-build-1-624t7-build-pod`



# That's it
Simple enough.





## Handy commands

**Incase you need to the delete TBS from the cluster** : `kapp delete -a tanzu-build-service -y`