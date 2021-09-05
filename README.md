# Tanzu Build Service on Public Cloud

<img src="images/logo.png" alt="Tanzu Build Service Wizard" width=200 height=200/>

Tanzu build service is a pretty cool tool for automating build process and segregating devlopmenet and operations. (Read more about TBS here: https://tanzu.vmware.com/build-service)

The official guide to install TBS is here: https://docs.pivotal.io/build-service/1-2/installing.html

However, There're a lot of steps to get TBS going in a k8s cluster.

In this repository I have created a bootstraped docker container that will
- On the first run will launch tbsinstall wizard. This will install/deploy TBS on a K8S cluster, saving you at least 4-5 hours worth of tasks and lots of binaries installtion on your host machine.
- Provide you with an intuitive UI to deploy TBS Builder (`~/binaries/tbsbuilderwizard --help`). This wizard can also work via parameters. This makes this docker suitable for pipeline automation too.
- It also provides you bash access (from 2nd run onwards) for interacting with the TBS on a k8s cluster as well as the k8s cluster itself. 

***This should simplify the Day0 tasks of installing a TBS on a k8s cluster.***

**Please note:** *This installer does not work with ECR*

## Pre-Requisit

#### Docker engine
The host computer must have docker-ce or docker-ee installed.

#### TanzuNet account
For this installation you will need access to registry.pivotal.io which is now under VMware Tanzu Network.

- If you already have access then please login |  https://login.run.pivotal.io/login
OR
- Signup to create login (sign up is free) | shttps://account.run.pivotal.io/z/uaa/sign-up

You will need login into Tanzu Net to accept EULA when you download the below in later section of this documentation
- Build service dependency (aka descriptor) from here: https://network.pivotal.io/products/tbs-dependencies/
- Tanzu Build Service (aka kpack or kp) from here: https://network.pivotal.io/products/build-service/


## Prepare
This docker container is bootstrapped with TBS version 1.2. 

At the time of writing/creating this tbs 1.2 was the latest version. 

**TBS Descriptor**

`tbsfiles/descriptor.yaml` may need updating (The one in this repo is version 100.0.24). Download updated descriptor from https://network.pivotal.io/products/tbs-dependencies/ and rename to descriptor.yaml (eg `mv ~/Downloads/descriptor-100.0.xx.yaml tbsfiles/descriptor.yaml`)


**files requirements:**
- bianaries/tmc ---> This is optional. Needed only if you are accessing cluster through the TMC kubeconfig then download the tmc binary and place it in the bianaries directory. If tmc cli is not needed please comment the lines (#39, #40) in the `Dockerfile`.
- binaries/kp ---> download `kp-linux` from https://network.pivotal.io/products/build-service/ into binaries directory and rename to kp (`mv ~/Downloads/kp-linux binaries/kp`)


**A k8s Cluster**
- Either create a dedicated cluster for TBS (using TMC, TKG, EKS, AKS, GKE)
- OR, use an existing one to deploy TBS on it

**kubeconfig file**

A Kubeconfig file is needed to access the cluster. In this case:
- I created the cluster using Tanzu Mission Control (TMC), hence I Downlaod the kubeconfig file from TMC and added TMC_API_TOKEN in .env file. *You can generate yours withever way suits best*
- ***Place the kubeconfig in a file named `config` in the `.kube` folder. Filenale MUST be 'config' (no extension).***


**.env file**

Rename the .env.sample to .env. (eg: `mv .env.sample .env`)

And populate the below values:

- TANZUNET_USERNAME="{tanzu net username}"
- TANZUNET_PASSWORD="{tanzu net password}"
- PVT_REGISTRY="{private registry url. for dockerhub leave empty.}"
- PVT_REGISTRY_USERNAME="{private registry username. for dockerhub same value as before}"
- PVT_REGISTRY_PASSWORD="{private registry password}"
- BUILD_SERVICE_VERSION=1.2.1{build service version. eg: 1.2.1}
- TMC_API_TOKEN={needed if using TMC to access k8s cluster. Otherwise please ignore.}


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

**The TBSInstall wizard installation process will**
- will first ask for confirmation by displaying namespaces of the connected k8s cluster.
- it will also verify is k8s cluster already has tbs installed/deployed. If it finds an existing instance running it will mark it for NOT installing and display in the prompt.
- If it does not find an existing installation it will ask for final confirmation before it starts installing.
- Finally, it will start the installation process and display its progress in the prompt.

**The tbsbuilderwizard will create TBS builder**
- After the tbsinstall wizard finish installing/deploying TBS on the k8s cluster it will ask for confirmation to install a default tbs builder.
- Once you confirm, it will lauch the intuitive wizard and guide you through the provisioning of TBS Builder.  
- It will configure a TBS default builder to connect to your code repository (so TBS can get the code to build)
- It will configure a TBS default builder to connect to your container registry (where you would like TBS to push image after build is complete)
- Finally, it will deploy a TBS builder called `default-builder` in the cluster `default namespace`.

***You can also use this tbsbuilderwizard (`~/binaries/tbsbuilderwizard.sh --wizard`) to deploy other builders on the k8s cluster later on***

## Run a sample build

Once the above docker run finishes your k8s cluster should have TBS installed/deployed and a default builder configure which is ready to build.

Once you get the bash access you can run commands to interact with the newly installed TBS.

Create a yaml to tell TBS what to do. eg: ~/tbsfiles/sample-build.yaml

*Do not forget to replace {container-registry} with your container registry*

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