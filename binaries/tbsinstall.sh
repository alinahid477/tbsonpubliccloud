#!/bin/bash
export $(cat /root/.env | xargs)


printf "\n\n\n***********Checking cluster ...*************\n"

isexist=$(kubectl get ns | grep -w build-service)

if [[ -n $isexist ]]
then
    printf "\nFound namespace builder-service in the cluster. Assuming build service is already installed on the cluster.\n"
    printf "\nMarking as complete.\n"
    printf "\nIf this is not desired please remove build-service namespace.\n"
    printf "\nCOMPLETE=YES" >> /root/.env
    COMPLETE='y'
fi


if [ -z "$COMPLETE" ]
then
    printf "\n\n\n***********Starting installation of TBS $BUILD_SERVICE_VERSION ...*************\n"

    printf "\n\n\nTBS will be installed on the below cluster:\n"
    kubectl get ns

    printf "\n\n\nAdjusting cluster with needed permissions...\n"
    
    printf "\nPOD security policy:\n"
    unset tbspsp
    isvmwarepsp=$(kubectl get psp | grep -w vmware-system-privileged)
    if [[ -n $isvmwarepsp ]]
    then
        printf "found existing vmware-system-privileged as psp\n"
        tbspsp=vmware-system-privileged
    else
        istmcpsp=$(kubectl get psp | grep -w vmware-system-tmc-privileged)
        if [[ -n $istmcpsp ]]
        then
            printf "found existing vmware-system-tmc-privileged as psp\n"
            tbspsp=vmware-system-tmc-privileged
        # else
        #     printf "Will create new psp called tbs-psp-privileged using ~/kubernetes/tbs-psp.priviledged.yaml\n"
        #     tbspsp=tbs-psp-privileged
            # kubectl apply -f ~/kubernetes/tbs-psp.priviledged.yaml
        fi
    fi
    if [[ -z $SILENTMODE || $SILENTMODE == 'n' ]]
    then
        unset pspprompter
        printf "\nList of available Pod Security Policies:\n"
        kubectl get psp
        if [[ -n $tbspsp ]]
        then
            printf "\nSelected existing pod security policy: $tbspsp"
            printf "\nPress/Hit enter to accept $tbspsp"
            pspprompter=" (selected $tbspsp)"  
        else 
            printf "\nHit enter to create a new one"          
        fi
        printf "\nOR\nType a name from the available list\n"
        while true; do
            read -p "pod security policy$pspprompter: " inp
            if [[ -z $inp ]]
            then
                if [[ -z $tbspsp ]]
                then 
                    printf "\ncreating new psp called tbs-psp-privileged using ~/kubernetes/tbs-psp.priviledged.yaml\n"
                    tbspsp=tbs-psp-privileged
                    kubectl apply -f ~/kubernetes/tbs-psp.priviledged.yaml
                    sleep 2
                    break
                else
                    printf "\nAccepted psp: $tbspsp"
                    break
                fi
            else
                isvalidvalue=$(kubectl get psp | grep -w $inp)
                if [[ -z $isvalidvalue ]]
                then
                    printf "\nYou must provide a valid input.\n"
                else 
                    tbspsp=$inp
                    printf "\nAccepted psp: $tbspsp"
                    break
                fi
            fi
        done
    fi
    
    if [[ -n $SILENTMODE && $SILENTMODE == 'y' ]]
    then
        if [[ -z $tbspsp ]]
        then
            printf "\ncreating new psp called tbs-psp-privileged using ~/kubernetes/tbs-psp.priviledged.yaml\n"
            tbspsp=tbs-psp-privileged
            kubectl apply -f ~/kubernetes/tbs-psp.priviledged.yaml
            sleep 2
        fi
    fi
    printf "\n\nusing psp $tbspsp to create ClusterRole and ClusterRoleBinding\n"
    awk -v old="POD_SECURITY_POLICY_NAME" -v new="$tbspsp" 's=index($0,old){$0=substr($0,1,s-1) new substr($0,s+length(old))} 1' ~/kubernetes/allow-runasnonroot-clusterrole.yaml > /tmp/allow-runasnonroot-clusterrole.yaml
    kubectl apply -f /tmp/allow-runasnonroot-clusterrole.yaml
    printf "Done.\n"
    # kubectl create clusterrolebinding default-tkg-admin-privileged-binding --clusterrole=psp:vmware-system-privileged --group=system:authenticated
    # kubectl apply -f ~/kubernetes/allow-runasnonroot-clusterrole.yaml

    printf "\n\n\n**********Docker login...*************\n"

    if [ -z "$PVT_REGISTRY" ]
    then
        export PVT_REGISTRY=$(echo $PVT_REGISTRY_USERNAME | xargs)
        echo "Docker login: DockerHub for user $PVT_REGISTRY_USERNAME"
    else
        export PVT_REGISTRY_URL=$(echo $PVT_REGISTRY | xargs)
        echo "Docker login: $PVT_REGISTRY_URL"
    fi
    # if [ -z "$PVT_REGISTRY" ]
    # then
    #     echo "Docker login: DockerHub for user $PVT_REGISTRY_USERNAME"
    # else
    #     export PVT_REGISTRY_URL=$(echo $PVT_REGISTRY | xargs)
    #     echo "your private registry is: $PVT_REGISTRY"
    # fi
    docker login -u $PVT_REGISTRY_USERNAME $PVT_REGISTRY_URL -p $PVT_REGISTRY_PASSWORD 

    echo "Docker login: registry.pivotal.io"
    docker login -u $TANZUNET_USERNAME registry.pivotal.io -p $TANZUNET_PASSWORD


    printf "\n\n\n**********Relocating images fron TanzuNet to PVT registry...***************\n"
    imgpkg copy -b "registry.pivotal.io/build-service/bundle:$BUILD_SERVICE_VERSION" --to-repo $PVT_REGISTRY/build-service

    printf "\n\n\n**********Getting ready for TBS installation on k8s cluster...*****************\n"    
    imgpkg pull -b "$PVT_REGISTRY/build-service:$BUILD_SERVICE_VERSION" -o /tmp/bundle

    printf "\n\n\n**********Deploying TBS on k8s cluster...***************\n"    
    ytt -f /tmp/bundle/values.yaml \
        -f /tmp/bundle/config/ \
        -v docker_repository="$PVT_REGISTRY" \
        -v docker_username="$PVT_REGISTRY_USERNAME" \
        -v docker_password="$PVT_REGISTRY_PASSWORD" \
        -v tanzunet_username="$TANZUNET_USERNAME" \
        -v tanzunet_password="$TANZUNET_PASSWORD" \
        | kbld -f /tmp/bundle/.imgpkg/images.yml -f- \
        | kapp deploy -a tanzu-build-service -f- -y

    printf "\n\n\n**********Configuring TBS with build dependencies...***************\n"
    kp import -f ~/tbsfiles/descriptor.yaml

    printf "\n\n\n**********DONE. Here's the list of clusterbuilders...**************\n"
    kp clusterbuilder list




    # printf "\n\n\n**********Starting configuration for deployed TBS with default-builder...**************\n"

    # if [ -z "$GCR_SERVICE_ACCOUNT_PATH" ]
    # then
    #     echo "Registry is NOT GCR."
    # else
    #     echo "Registry is GCR."
    #     export BUILT_REGISTRY_BUILDER_URL=$BUILT_REGISTRY\\/builder
    #     sed -ri 's/^(\s*)(tag\s*:\s*builtregistryurl\s*$)/\1tag: '$BUILT_REGISTRY_BUILDER_URL'/' /usr/local/default-builder.yaml

    #     printf "\n\n\n**********Creating k8s secret for container registry access...***************\n"
    #     kp secret create built-registry-secret
    # fi

    # if [ -z "$BUILT_REGISTRY" ]
    # then
    #     echo "Registry is DockerHub."

    #     export BUILT_REGISTRY_BUILDER_URL=$BUILT_REGISTRY_USERNAME\\/builder
    #     sed -ri 's/^(\s*)(tag\s*:\s*builtregistryurl\s*$)/\1tag: '$BUILT_REGISTRY_BUILDER_URL'/' /usr/local/default-builder.yaml

    #     export DOCKER_PASSWORD=$BUILT_REGISTRY_PASSWORD
    #     printf "\n\n\n**********Creating k8s secret for container registry access...***************\n"
    #     kp secret create built-registry-secret --dockerhub $BUILT_REGISTRY_USERNAME
    # else
    #     echo "Registry is either: ACR, Artifactory, Harbor, JFrog etc"

    #     export BUILT_REGISTRY_BUILDER_URL=$BUILT_REGISTRY\\/builder
    #     sed -ri 's/^(\s*)(tag\s*:\s*builtregistryurl\s*$)/\1tag: '$BUILT_REGISTRY_BUILDER_URL'/' /usr/local/default-builder.yaml

    #     export REGISTRY_PASSWORD=$BUILT_REGISTRY_PASSWORD
    #     printf "\n\n\n**********Creating k8s secret for container registry access...***************\n"
    #     kp secret create built-registry-secret --registry $BUILT_REGISTRY --registry-user $BUILT_REGISTRY_USERNAME
    # fi


    # kubectl apply -f ~/tbsfiles/registry-service-account.yaml

    # printf "\n\n\n**********Deploying default-builder...****************\n"
    # kubectl apply -f /usr/local/default-builder.yaml

    printf "\nCOMPLETE=YES" >> /root/.env

    printf "\n\n"
    printf "***********************************************************************************\n"
    printf "*COMPLETE. Please follow the instructions further to customise/configure this TBS.*\n"
    printf "***********************************************************************************\n"
else
    printf "\n\n\nTBS installation is already marked as complete. (If this is not desired please change COMPLETE=\"\" or remove COMPLETE in the .env for new registration)\n"
    printf "\n\n\nGoing straight to shell access.\n"
fi