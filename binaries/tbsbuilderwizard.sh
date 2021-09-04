#!/bin/bash
printf "\n\n\n**********Starting TBS Builder Configuration Wizard...**************\n"

unset RESITRY_TYPE
unset REGISTRY_URL
unset GCR_SERVICE_ACCOUNT_PATH
unset REPO_URL

printf "\n**********Lets get some details...**************\n\n"


printf "\nWhat would you like to call this builder..\n"
printf "\nHint:"
echo -e "\tThe name can contain the these characters only '-','_',[A-Z][a-z][0-9]."
while true; do
    read -p "TBS Builder Name: " inp
    if [[ -z $inp ]]
    then
        printf "\nThis is a required field. You must provide a value.\n"
    else
        if [[ ! $inp =~ ^[A-Za-z0-9-_]+$ ]]
        then
            printf "\nYou must provide a valid value.\n"
        else
            BUILDER_NAME=$inp
            break
        fi
    fi
done


printf "\nCollecting image registry details..\n"
printf "\nHint:"
echo -e "\tLeave empty for dockerhub. Hit enter to leave empty."
echo -e "\tProvide path to .json or .p12 (GCP Service Account File) file for GCR (Google Container Registry). eg: ~/tbsfiles/projmerlin-325002-936c605cc234.json"
echo -e "\tFor any other registry type enter url of the image registry (not just the domain name of the registry) that you would normally use for docker push. eg: my-pvt-harbor.wizard.com/merlinapp"
dobreak="n"
while true; do

    if [[ -z $RESITRY_TYPE ]]
    then
        read -p "Registry URL:(press enter to keep to leave it empty for dockerhub) " inp
        if [ -z "$inp" ]
        then
            RESITRY_TYPE="--dockerhub"
        else 
            basename=$(basename $inp)
            if [[ $basename == *@(".json"|".p12")* ]]
            then
                RESITRY_TYPE="--gcr"
                if test -f "$inp"; then
                    GCR_SERVICE_ACCOUNT_PATH=$inp
                fi            
            else 
                RESITRY_TYPE="--registry"
                REGISTRY_URL=$inp
            fi
        fi  
    fi    
    
    if [[ $RESITRY_TYPE == "--gcr" && -n $GCR_SERVICE_ACCOUNT_PATH ]]
    then
        dobreak="y"
        printf "\n\nCreating k8s secret for GCR...\n\n"
        printf "kp secret create $BUILDER_NAME-registry-cred --gcr"
        # kp secret create $BUILDER_NAME-registry-cred --gcr
    fi



    unset inp
    unset DOCKER_PASSWORD
    unset DOCKERHUB_ID
    if [[ $RESITRY_TYPE == "--dockerhub" && -z $REGISTRY_URL ]]
    then
        while true; do
            read -p "Dockerhub Username: " inp
            if [[ -z $inp ]]
            then
                printf "\nThis is a required field. You must provide a value.\n"
            else
                DOCKERHUB_ID=$inp
                break
            fi
        done
        prompt="Dockerhub password "
        while true; do
            while IFS= read -p "$prompt" -r -s -n 1 char
            do
                if [[ $char == $'\0' ]]
                then
                    break
                fi
                prompt='*'
                inp+="$char"
            done
            if [[ -z $inp ]]
            then
                printf "\nThis is a required field. You must provide a value.\n"
            else
                DOCKER_PASSWORD=$inp
                dobreak="y"
                printf "\n\nCreating k8s secret for Dockerhub...\n\n"
                printf "kp secret create $BUILDER_NAME-registry-cred --dockerhub $DOCKERHUB_ID"
                # kp secret create $BUILDER_NAME-dockerhub-creds --dockerhub $DOCKERHUB_ID
                break
            fi
        done
    fi


    unset inp
    unset REGISTRY_PASSWORD
    if [[ $RESITRY_TYPE == "--registry" && -n $REGISTRY_URL ]]
    then
        while true; do
            read -p "Registry Username: " inp
            if [[ -z $inp ]]
            then
                printf "\nThis is a required field. You must provide a value.\n"
            else
                REGISTRY_USER=$inp
                break
            fi
        done
        prompt="Registry password "
        while true; do
            while IFS= read -p "$prompt" -r -s -n 1 char
            do
                if [[ $char == $'\0' ]]
                then
                    break
                fi
                prompt='*'
                inp+="$char"
            done
            if [[ -z $inp ]]
            then
                printf "\nThis is a required field. You must provide a value.\n"
            else
                REGISTRY_PASSWORD=$inp
                dobreak="y"
                printf "\n\nCreating k8s secret for Image Registry...\n\n"
                printf "kp secret create $BUILDER_NAME-registry-cred --registry $REGISTRY_URL --registry-user $REGISTRY_USER"
                kp secret create $BUILDER_NAME-registry-cred --registry $REGISTRY_URL --registry-user $REGISTRY_USER
                break
            fi
        done
    fi
    
    if [[ dobreak == "y" ]]
    then
        break
    else
        printf "\nValidation failed. Please try again...\n"
        unset RESITRY_TYPE
        unset REGISTRY_URL
        unset GCR_SERVICE_ACCOUNT_PATH
    fi
done








printf "\nCollecting source code repository details..\n"
printf "\nHint:"
echo -e "\tProvide URL of the source code repository in the form of git@repourl.com for ssh key file based authentication. eg: git@github.com or git@bitbucket.org etc"
echo -e "\tOR Provide URL of the source code repository in the form of https://domainname.com for username password based authentication. eg: https://github.com or https://bitbucket.org"
dobreak="n"
while true; do
    if [[ -z $REPO_URL ]]
    then
        read -p "Source code repository URL: " inp
        if [ -z "$inp" ]
        then
            printf "\nThis is a required field. You must provide a value.\n"
        else 
            if [[ $inp == *"@"* ]]
            then
                GIT_AUTH_TYPE="ssh"                
            else 
                GIT_AUTH_TYPE="basic"                
            fi
            REPO_URL=$inp
        fi  
    fi

    if [[ GIT_AUTH_TYPE == "ssh" ]]
    then
        while true; do
            read -p "ssh private key file path: " inp
            if [[ -z $inp ]]
            then
                printf "\nThis is a required field. You must provide a value.\n"
            else
                if test -f "$inp"; then
                    GIT_SSH_FILE_PATH=$inp
                    dobreak="y"
                    printf "\n\nCreating k8s secret for Source code repository...\n\n"
                    printf "kp secret create $BUILDER_NAME-repo-cred --git-url $REPO_URL --git-ssh-key $GIT_SSH_FILE_PATH"
                    # kp secret create $BUILDER_NAME-repo-cred --git-url $REPO_URL --git-ssh-key $GIT_SSH_FILE_PATH
                    break
                else
                    printf "\nYou must provide a valid file path (eg: ~/tbsfiles/mygithubkey.pem)...\n"
                fi
                
            fi
        done
    fi

    if [[ GIT_AUTH_TYPE == "basic" ]]
    then
    fi

    if [[ dobreak == "y" ]]
    then
        break
    else
        printf "\nValidation failed. Please try again...\n"
        unset REPO_URL
        unset GIT_AUTH_TYPE
        unset GIT_SSH_FILE_PATH
        unset GIT_USERNAME
        unset GIT_PASSWORD
    fi
done