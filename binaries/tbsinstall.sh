#!/bin/bash
export $(cat /root/.env | xargs)

if [ -z "$COMPLETE" ]
then
    printf "\n\n\n***********Starting installation of TBS $BUILD_SERVICE_VERSION ...*************\n"

    printf "\n\n\nTBS will be installed on the below cluster:\n"
    kubectl get ns

    printf "\n\n\nAdjusting cluster with needed permissions...\n"
    kubectl create clusterrolebinding default-tkg-admin-privileged-binding --clusterrole=psp:vmware-system-privileged --group=system:authenticated
    kubectl apply -f ~/kubernetes/allow-runasnonroot-clusterrole.yaml

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