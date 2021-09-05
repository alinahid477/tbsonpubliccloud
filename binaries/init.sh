#!/bin/bash

unset doinstall

printf "\n\nsetting executable permssion to all binaries sh\n\n"
ls -l /root/binaries/*.sh | awk '{print $9}' | xargs chmod +x

printf "\n\nChecking connected k8s cluster\n\n"
kubectl get ns
printf "\n"
while true; do
    read -p "Confirm if you are seeing expected namespaces to proceed further? [y/n]: " yn
    case $yn in
        [Yy]* ) printf "\nyou confirmed yes\n"; break;;
        [Nn]* ) printf "\n\nYou said no. \n\nExiting...\n\n"; exit 1;;
        * ) echo "Please answer y or n.";;
    esac
done

export $(cat /root/.env | xargs)
printf "\n\nChecking if TBS is already installed on k8s cluster"
isexist=$(kubectl get ns | grep -w build-service)
if [[ -z $isexist ]]
then
    printf "\n\nTanzu Build Service is not found in the k8s cluster.\n\n"
    if [[ -z $COMPLETE || $COMPLETE == 'n' ]]
    then
        isexist="n"    
    fi
else
    printf "\n\nNamespace build-service found in the k8s cluster.\n\n"
    if [[ -z $COMPLETE || $COMPLETE == 'n' ]]
    then
        printf "\n\n.env is not marked as complete. Marking as complete.\n\n"
        printf "\nCOMPLETE=YES" >> /root/.env
    fi
fi

printf "$isexist\n\n"

if [[ $isexist == "n" ]]
then
    while true; do
        read -p "Confirm if you like to deploy Tanzu Build Service on this k8s cluster now [y/n]: " yn
        case $yn in
            [Yy]* ) doinstall="y"; printf "\nyou confirmed yes\n"; break;;
            [Nn]* ) printf "\n\nYou said no.\n"; break;;
            * ) echo "Please answer y or n.";;
        esac
    done
fi

if [[ $doinstall == "y" ]] 
then
    source ~/binaries/tbsinstall.sh
    unset inp
    while true; do
        read -p "Confirm if TBS deployment/installation successfully completed and cluster builder list is displayed [y/n]: " yn
        case $yn in
            [Yy]* ) inp="y"; printf "\nyou confirmed yes\n"; break;;
            [Nn]* ) printf "\n\nYou said no.\n"; break;;
            * ) echo "Please answer y or n.";;
        esac
    done
    printf "\n\nGreat! Now that TBS is installed you can use tbsbuilderwizard to configuer TBS with your pipeline or code and container registry\n\n"
    unset inp2
    if [[ $inp == "y" ]]
    then
        while true; do
            read -p "Confirm if you would like to configure a default builder now [y/n]: " yn
            case $yn in
                [Yy]* ) inp2="y"; printf "\nyou confirmed yes\n"; break;;
                [Nn]* ) printf "\n\nYou said no.\n"; break;;
                * ) echo "Please answer y or n.";;
            esac
        done   
    fi
    if [[ $inp2 == "y" ]]
    then
        printf "\n\nLaunching TBS Builder Wizard to create default-builder in namespace: default...\n\n"
        source ~/binaries/tbsbuilderwizard.sh -n default-builder -k default --wizard
    fi
fi

printf "\nYour available wizards are:\n"
echo -e "\t~/binaries/tbsinstall.sh"
echo -e "\t~/binaries/tbsbuilderwizard.sh --help"

cd ~

/bin/bash