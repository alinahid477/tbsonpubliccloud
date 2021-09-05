#!/bin/bash

helpFunction()
{
    printf "\nProvide valid params\n\n"
    echo "Usage: ~/baniries/tbsbuilderwizard.sh"
    echo -e "\t-w | --wizard Lauch TBS Builder in interactive wizard mode"
    echo -e "\t-n | --name TBS Builder name"
    echo -e "\t-k | --k8s-namespace TBS Builder namespace"
    echo -e "\t-t | --tag for TBS Builder image tag"
    echo -e "\t-i | --image-registry-secret-name for TBS Builder"
    echo -e "\t-g | --git-secret-name for TBS Builder"
    echo -e "\t-s | --cluster-stack for TBS Builder"
    echo -e "\t-c | --cluster-store for TBS Builder"
    echo -e "\t-o | --order Language detect order of TBS"
    # exit 1 # Exit script after printing help
}

output=""

# read the options
TEMP=`getopt -o wn:k:i:g:s:c:o: --long wizard,name:,k8s-namespace:,image-registry-secret-name:,git-secret-name:,cluster-stack:,cluster-store:,order:,help,printhelp -n $0 -- "$@"`
eval set -- "$TEMP"
# echo $TEMP;
while true ; do
    # echo "here -- $1"
    case "$1" in
        -w | --wizard )
            case "$2" in
                "" ) output=$(printf "$output\nwizardmode=y") ; shift 2 ;;
                * ) output=$(printf "$output\nwizardmode=y") ; shift 2 ;;
            esac ;;       
        -n | --name )
            case "$2" in
                "" ) output=$(printf "$output\ndefaultvalue_name=") ; shift 2 ;;
                * ) output=$(printf "$output\ndefaultvalue_name=$2") ; shift 2 ;;
            esac ;;
        -k | --k8s-namespace )
            case "$2" in
                "" ) output=$(printf "$output\ndefaultvalue_k8s_namespace=") ; shift 2 ;;
                * ) output=$(printf "$output\ndefaultvalue_k8s_namespace=$2") ; shift 2 ;;
            esac ;;
        -i | --image-registry-secret-name )
            case "$2" in
                "" ) shift 2 ;;
                * ) output=$(printf "$output\ndefaultvalue_image_registry_secret_name=$2"); shift 2 ;;
            esac ;;
        -g | --git-secret-name )
            case "$2" in
                "" ) shift 2 ;;
                * ) output=$(printf "$output\ndefaultvalue_git_secret_name=$2"); shift 2 ;;
            esac ;;
        -s | --cluster-stack )
            case "$2" in
                "" ) shift 2 ;;
                * ) output=$(printf "$output\ndefaultvalue_cluster_stack=$2"); shift 2 ;;
            esac ;;
        -c | --cluster-store )
            case "$2" in
                "" ) shift 2 ;;
                * ) output=$(printf "$output\ndefaultvalue_cluster_store=$2"); shift 2 ;;
            esac ;;
        -o | --order )
            case "$2" in
                "" ) shift 2 ;;
                * ) output=$(printf "$output\ndefaultvalue_order=$2"); shift 2 ;;
            esac ;;
        -t | --tag )
            case "$2" in
                "" ) shift 2 ;;
                * ) output=$(printf "$output\ndefaultvalue_tag=$2"); shift 2 ;;
            esac ;;
        -h | --help ) printf "help"; break;; 
        -p | --printhelp ) helpFunction; break;; 
        -- ) shift; break;; 
        * ) break;;
    esac
done


printf "$output"