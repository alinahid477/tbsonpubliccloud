# Tanzu Build Service on Public Cloud

<img src="images/logo.png" alt="Tanzu Build Service Wizard" width=200 height=210/>

Tanzu build service is a pretty cool tool for automating build process and segregating devlopmenet and operations. (Read more about TBS here: https://tanzu.vmware.com/build-service)

The official guide to install TBS is here: https://docs.pivotal.io/build-service/1-2/installing.html

However, There're a lot of steps to get TBS going in a k8s cluster.

In this repository I have created a bootstraped docker container that will
- On the first run will launch tbsinstall wizard. This will install/deploy TBS on a K8S cluster, saving you at least 4-5 hours worth of tasks and lots of binaries installtion on your host machine.
- Provide you with an intuitive UI to deploy TBS Builder (`~/binaries/tbsbuilderwizard --help`). This wizard can also work via parameters. This makes this docker suitable for pipeline automation too.
- It also provides you bash access (from 2nd run onwards) for interacting with the TBS on a k8s cluster as well as the k8s cluster itself. 

**This should simplify the Day0 tasks of installing a TBS on a k8s cluster.**

**Please note:** *This installer does not work with ECR*

**Please note:** *If TBS is being deployed/installed on k8s running on vSphere, mount a 50GB volume at /var/lib to the worker nodes in the TanzuKubernetesCluster resource (Cluster yaml file). Follow instructions show how to configure storage on worker nodes: https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-4E68C7F2-C948-489A-A909-C7A1F3DC545F.html*


## Pre-Requisit


### vSphere Tanzu Kubernetes Grid Environment

***This step is ONLY required for TKG on vSphere envieonment. Skip this section if you are deploying Tanzu Build Service (TBS) on a public cloud cluster***


Ensure that all worker nodes have at least 50 GB of ephemeral storage allocated to them.
- To do this on TKGs (vSphere with Tanzu), mount a 50GB volume at /var/lib to the worker nodes in the TanzuKubernetesCluster resource that corresponds to your TKGs cluster. [These instructions](https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-4E68C7F2-C948-489A-A909-C7A1F3DC545F.html) show how to configure storage on worker nodes.


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


### TBS Descriptor
- Download updated descriptor from https://network.pivotal.io/products/tbs-dependencies/ 
- `mv ~/Downloads/descriptor-100.0.xx.yaml tbsfiles/`)
- ***Make sure that in the tbsfiles dir only 1 descriptor exists***


### Binary files
- bianaries/tmc ---> This is optional. Needed only if you are accessing cluster through the TMC kubeconfig then download the tmc binary and place it in the bianaries directory. If tmc cli is not needed please comment the lines (#39, #40) in the `Dockerfile`.
- binaries/kp ---> download `kp-linux` from https://network.pivotal.io/products/build-service/ into binaries directory and rename to kp (`mv ~/Downloads/kp-linux binaries/kp`)


### k8s Cluster
- Either create a dedicated cluster for TBS (using TMC, TKG, EKS, AKS, GKE)
- OR, use an existing one 
to deploy TBS on

### kubeconfig file

***Skip this section if you are deploying TBS on a vSphere with Tanzu (TKGs) cluster using vSphere SSO. In which case fill in the TKG variables in the .env file (as described in the next section)***

A Kubeconfig file is needed to access the cluster. In this case:
- I created the cluster using Tanzu Mission Control (TMC), hence I Downlaod the kubeconfig file from TMC and added TMC_API_TOKEN in .env file. *You can generate yours whichever way suits best*
- ***Place the kubeconfig in a file named `config` in the `.kube` folder. Filenale MUST be 'config' (no extension).***


## .env file

Rename the .env.sample to .env. (eg: `mv .env.sample .env`)

And populate the below values:
- BASTION_HOST={(Optional) ip of bastion/jump host. *Leave empty if you have direct connection*}
- BASTION_USERNAME={(Optional) if the above is present then the username for the above. *Leave empty if you have direct connection*}
- TKG_VSPHERE_SUPERVISOR_ENDPOINT={(Optional) find the supervisor endpoint from vsphere (eg: Menu>Workload management>clusters>Control Plane Node IP Address). *Leave empty if you are providing your own kubeconfig file in the .kube directory*}
- TKG_VSPHERE_CLUSTER_NAME={(Optional) the k8s cluster your are trying to access. *Leave empty if you are providing your own kubeconfig file in the .kube directory*}
- TKG_VSPHERE_CLUSTER_ENDPOINT={(Optional) endpoint ip or hostname of the above cluster. Grab it from your vsphere environment. (Menu>Workload Management>Namespaces>Select the namespace where the k8s cluster resides>Compute>VMware Resources>Tanzu Kubernetes Clusters>Control Plane Address[grab the ip of the desired k8s]). *Leave empty or ignore if you are providing your own kubeconfig file in the .kube directory*}
- TKG_VSPHERE_USERNAME={(Optional) username for accessing the cluster. *Leave empty or ignore if you are providing your own kubeconfig file in the .kube directory*}
- TKG_VSPHERE_PASSWORD={(Optional) password for accessing the cluster. *Leave empty or ignore if you are providing your own kubeconfig file in the .kube directory*}
- TANZUNET_USERNAME="{tanzu net username}"
- TANZUNET_PASSWORD="{tanzu net password}"
- PVT_REGISTRY="{private registry url. for dockerhub leave empty.}"
- PVT_REGISTRY_USERNAME="{private registry username. for dockerhub same value as before}"
- PVT_REGISTRY_PASSWORD="{private registry password}"
- BUILD_SERVICE_VERSION=1.2.2 {build service version. eg: 1.2.2}
- TMC_API_TOKEN={*optional.* needed only if using TMC to access k8s cluster. Otherwise please ignore or delete.}


## Install TBS on k8s cluster

The docker file 
- has all necessary dependencies (eg> kubectl, ytt, kapp, docker, awscli, stern etc) resolved
- has a install.sh that reads input needed from the .env file

To run on windows

```
start.bat tbs
```

OR

To run on Mac or Linux
```
chmod +x start.sh
./start.sh tbs
```

***Optionally use a second parameter `forcebuild` to force docker build (eg: `start.sh tbs forecebuild`). Otherwise if the image exists it will ignore building.***


***The installation process will run for few mins. Please be patient and check the output to spot any error***. 

*I have tested several times installing on a EKS, AKS, TKG clusters and it worked without any error.*

**The TBSInstall wizard installation process will**
- will first ask for confirmation by displaying namespaces of the connected k8s cluster.
- it will also verify is k8s cluster already has tbs installed/deployed. If it finds an existing instance running it will mark it for NOT installing and display in the prompt.
- If it does not find an existing installation it will ask for final confirmation before it starts installing.
- Finally, it will start the installation process and display its progress in the prompt.


## TBS Builder Wizard

TBS installation enables the ability to process build. However, TBS still need a definition construct to
- What type of codes should it build
- Where to get the codes from
- Once process where to put it.
AND that's the Builder Definition.

Using this wizard you will be able to
- Visually create TBS Builder Definition
- Deploy the builder on the connected cluster

To run the wizard do
```
~/binaries/tbsbuilderwizard.sh --wizard
```

Run the below command to see the what options are available
```
~/binaries/tbsbuilderwizard.sh --help
```

***You can also use this tbsbuilderwizard (`~/binaries/tbsbuilderwizard.sh --wizard`) to deploy other builders on the k8s cluster later on***


## Run a sample build

Once the above docker run finishes your k8s cluster should have TBS installed/deployed and a default builder configure which is ready to build.

Once you get the bash access you can run commands to interact with the newly installed TBS.

Create a yaml to tell TBS what to do. eg: ~/tbsfiles/sample-build.yaml

*Do not forget to replace {container-registry} with your container registry*

Then simply apply

`kubectl apply -f ~/tbsfiles/sample-build.yaml`

or

`kp image save vmw-calculator-addservice-build --git https://github.com/alinahid477/vmw-calculator-addservice.git --git-revision main --tag PVT_REGISTRY_URL/calcaddservice --builder default-builder --wait`


To watch how our build is progressing

`kubectl get pods` --> to get the pod name created to perform the build.

Since, the pod is going to have several containers performing the build `kubectl logs` won't be enought to see the build in action. For this we need `stern`. This dockerimage is also bootstrapped with `stern`. So just run:

`stern calcaddservice-build-1-624t7-build-pod`


# That's it
Simple enough.



## Handy commands

**Incase you need to the delete TBS from the cluster** : `kapp delete -a tanzu-build-service -y`