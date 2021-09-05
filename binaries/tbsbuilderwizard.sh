#!/bin/bash
unset RESITRY_TYPE
unset REGISTRY_URL
unset GIT_URL
unset BUILDER_NAME
unset BUILDER_NAMESPACE
unset TBS_BUILDER_IMAGE_TAG
unset TBS_CLUSTERSTACK_NAME
unset TBS_CLUSTERSTORE_NAME
unset TBS_BUILDER_IMAGE_REGISTRY_SECRET
unset TBS_BUILDER_GIT_SECRET

result=$(source ~/binaries/readparams.sh $@)
if [[ $result == *@("error"|"help")* ]]
then
    source ~/binaries/readparams.sh --printhelp
    exit
else
    export $(echo $result | xargs)
fi

if [[ -z $wizardmode ]]
then
    if [[ -z $defaultvalue_name || -z $defaultvalue_k8s_namespace || 
        -z $defaultvalue_tag || -z $defaultvalue_order ||
        -z $defaultvalue_cluster_stack || -z $defaultvalue_cluster_store ||
        -z $defaultvalue_image_registry_secret_name || -z $defaultvalue_git_secret_name ]]
    then
        printf "\n\nOne or more required value missing. Validation failed.\nconsider running in wizard mode using -w flag\n"
        source ~/binaries/readparams.sh --printhelp
        printf "\n\nexit..\n\n"
        exit
    fi
fi


printf "\n\n\n**********Starting TBS Builder Configuration Wizard...**************\n"
printf "\n\n"

unset BUILDER_NAME
if [[ -z $defaultvalue_name ]]
then
    printf "\n\nWhat would you like to call this builder.."
    printf "\nHint:"
    echo -e "\tThe name can contain the these characters only '-','_',[A-Z][a-z][0-9]."
    while true; do
        read -p "TBS Builder Name: " inp
        if [[ -z $inp ]]
        then
            printf "\nThis is a required field. You must provide a value.\n"
        else
            if [[ ! $inp =~ ^[A-Za-z0-9_\-]+$ ]]
            then
                printf "\nYou must provide a valid value.\n"
            else
                BUILDER_NAME=$inp
                break
            fi
        fi
    done
else
    BUILDER_NAME=$defaultvalue_name
fi
printf "\nAccepted parameter BUILDER_NAME=$BUILDER_NAME\n"

printf "\n\n"

unset BUILDER_NAMESPACE
if [[ -z $defaultvalue_k8s_namespace ]]
then
    printf "\n\nWhich k8s namespace would you like to create this builder in.."
    printf "\nHint:"
    echo -e "\tIf the namespace already exist the wizard will use the existing"
    echo -e "\tOtherwise it will create a new one"
    echo -e "\t\t"
    echo -e "\tDEFAULT: default (hit enter to accept default)"
fi
while true; do
    if [[ -z $defaultvalue_k8s_namespace ]]
    then
        read -p "TBS Builder Namespace: " inp
        if [[ -z $inp ]]
        then
            printf "\nThis is a required field. You must provide a value.\n"
        else
            if [[ ! $inp =~ ^[A-Za-z0-9_\-]+$ ]]
            then
                printf "\nYou must provide a valid value.\n"                
            fi
        fi
    else
        inp=$defaultvalue_k8s_namespace
    fi
    if [[ -n $inp ]]
    then
        isexist=$(kubectl get ns | grep -w $inp)
        if [[ -z $isexist ]]
        then
            printf "\nNamespace name $inp does not exist. Attempting to create...\n\n"
            kubectl create namespace $inp
            printf "\n\nDONE\n"
        else
            printf "\nNamespace name $inp exists. Using existing...\n"
        fi
        BUILDER_NAMESPACE=$inp
        break
    fi
done
printf "\nAccepted parameter BUILDER_NAMESPACE=$BUILDER_NAMESPACE\n"


printf "\n\n"

unset TBS_CLUSTERSTACK_NAME
if [[ -z $defaultvalue_cluster_stack ]]
then    
    availableclusterstacks=$(kp clusterstacks list | awk -vORS=, 'NR>1 && NF {print $1}' | sed 's/,$//')
    defaultclusterstack=$(kp clusterstacks list | awk 'NR>1 && NF {print $1}' |  grep -w base)
    printf "\n\nWhich cluster stack would you like to use for this builder.."
    printf "\nHint:"
    echo -e "\tAvailable stacks are: $availableclusterstacks"
    echo -e "\tType one value from the list above."
    echo -e "\tOR hit enter to accept default stack '$defaultclusterstack'"
    while true; do
        read -p "TBS Cluster Stack (default is '$defaultclusterstack'): " inp
        if [[ -z $inp ]]
        then
            TBS_CLUSTERSTACK_NAME=$defaultclusterstack
            break
        else
            if [[ $inp == *$availableclusterstacks* ]]
            then
                TBS_CLUSTERSTACK_NAME=$inp
                break
            else
                printf "\nYou must provide a valid value.\n"
            fi
        fi
    done
else
    TBS_CLUSTERSTACK_NAME=$defaultvalue_cluster_stack
fi
printf "\nAccepted parameter TBS_CLUSTERSTACK_NAME=$TBS_CLUSTERSTACK_NAME\n"

printf "\n\n"

unset TBS_CLUSTERSTORE_NAME
if [[ -z $defaultvalue_cluster_store ]]
then
    availableclusterstores=$(kp clusterstore list | awk -vORS=, 'NR>1 && NF {print $1}' | sed 's/,$/\n/')
    defaultclusterstore=$(kp clusterstore list | awk 'NR>1 && NF {print $1}' |  grep -w default)
    printf "\n\nWhich cluster store would you like to use for this builder.."
    printf "\nHint:"
    echo -e "\tAvailable clusterstores are: '$availableclusterstores'"
    echo -e "\tType one from the values lister above."
    echo -r "\tOR hit enter to accept default clusterstore '$defaultclusterstore'"
    while true; do
        read -p "TBS Cluster Store (default is $defaultclusterstore): " inp
        if [[ -z $inp ]]
        then
            TBS_CLUSTERSTORE_NAME=$defaultclusterstore
            break
        else
            if [[ $inp == *$availableclusterstores* ]]
            then
                TBS_CLUSTERSTORE_NAME=$inp
                break
            else
                printf "\n\nYou must provide a valid value.\n\n"
            fi
        fi
    done
else
    TBS_CLUSTERSTORE_NAME=$defaultvalue_cluster_store
fi
printf "\nAccepted parameter TBS_CLUSTERSTORE_NAME=$TBS_CLUSTERSTORE_NAME\n"

printf "\n\n"

unset TBS_BUILDER_BUILD_ORDER
if [[ -z $defaultvalue_order ]]
then
    defaultbuildorder="java,dotnet-core,nodejs,python,go,procfile,java-native-image,nginx"
    printf "\n\nWhat programming languages are you configuring this TBS builder for.."
    printf "\nHint:"
    echo -e "\tAvailable values are: $defaultbuildorder"
    echo -e "\tType the ones that your repository contains from the list above."
    echo -e "\tMultiple values needs to be provided in comma-separated format."
    echo -e "\tThe way the values are appearing are the order they will be detected."
    echo -e "\tHit enter to accept default and its order."
    echo -e "\t\t"
    printf "DEFAULT: $defaultbuildorder\n"
fi

while true; do
    if [[ -z $defaultvalue_order ]]
    then
        read -p "TBS Builder Languages: " inp
        if [[ -z $inp ]]
        then
            order=$defaultbuildorder
        else        
            order=$inp
        fi
    else
        order=$defaultvalue_order
    fi
    iserror="n"
    unset TBS_BUILDER_BUILD_ORDER
    languages=$(echo $order | tr "," "\n")
    for language in $languages
    do
        tval=$(echo $language | sed 's,^ *,,; s, *$,,')
        if [[ $language == *\/* ]] 
        then
            TBS_BUILDER_BUILD_ORDER+="\n  - group:\n    - id: $tval"
        else
            printf "Checking $tval\n"
            if grep -q "${tval}" <<< "$defaultbuildorder"
            then
                if [[ $tval == "procfile" ]]
                then
                    TBS_BUILDER_BUILD_ORDER+="\n  - group:\n    - id: paketo-buildpacks/$tval"
                else
                    TBS_BUILDER_BUILD_ORDER+="\n  - group:\n    - id: tanzu-buildpacks/$tval"
                fi 
            else
                printf "\n\nYou must provide a valid value.\n\n"
                iserror="y"
                break;
            fi
        fi
    done

    if [[ $iserror == "n" ]]
    then
        break
    else
        if [[ -n $defaultvalue_order ]]
        then
            # When it is default value supplied via parameter MUST do exist
            # otherwise will go into infinite loop.
            printf "\n\nERROR: Could parse the order provided $defaultvalue_order. Exiting...\n"
            exit;
        fi  
    fi
done
printf "\nAccepted parameter TBS_BUILDER_BUILD_ORDER=$TBS_BUILDER_BUILD_ORDER\n"

printf "\n\n"

if [[ -z $defaultvalue_image_registry_secret_name ]]
then
    printf "\nWhich image registry would you like to connect to.."
    printf "\nHint:"
    echo -e "\tLeave empty for dockerhub. Hit enter to leave empty."
    echo -e "\tOR"
    echo -e "\tProvide path to .json or .p12 (GCP Service Account File) file for GCR (Google Container Registry)."
    echo -e "\t\teg: ~/tbsfiles/projmerlin-325002-936c605cc234.json"
    echo -e "\tOR"
    echo -e "\tFor any other registry enter url of the image registry that you would use for docker push."
    echo -e "\t\teg: my-pvt-harbor.wizard.com/projectmerlin or projectmerlin.azurecr.io etc"
    dobreak="n"
    while true; do

        if [[ -z $RESITRY_TYPE ]]
        then
            read -p "Registry URL: " inp
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
            printf "\n\nAccepted GCR registry with service account path: $GCR_SERVICE_ACCOUNT_PATH\n"
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
            while true; do
                unset inp
                prompt="Dockerhub password: "
                charcount=0
                while IFS= read -p "$prompt" -r -s -n 1 char
                do
                    if [[ $char == $'\0' ]]
                    then
                        break
                    fi
                    if [[ $char == $'\177' ]]
                    then
                        if [[ $charcount > 0 ]]
                        then
                            inp=${inp%?}
                            prompt=$'\b \b'
                            ((charcount=charcount-1))
                        else
                            prompt=''
                        fi
                    else
                        prompt='*'
                        inp+="$char"
                        ((charcount=charcount+1))
                    fi        
                done
                if [[ -z $inp ]]
                then
                    printf "\nThis is a required field. You must provide a value.\n"
                else
                    export DOCKER_PASSWORD=$(echo $inp | xargs)
                    dobreak="y"
                    printf "\n\nAccepted Dockerhub registry with ID: $DOCKERHUB_ID\n"
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
            
            while true; do
                unset inp
                prompt="Registry password: "
                charcount=0
                while IFS= read -p "$prompt" -r -s -n 1 char
                do
                    if [[ $char == $'\0' ]]
                    then
                        break
                    fi
                    if [[ $char == $'\177' ]]
                    then
                        if [[ $charcount > 0 ]]
                        then
                            inp=${inp%?}
                            prompt=$'\b \b'
                            ((charcount=charcount-1))
                        else
                            prompt=''
                        fi
                    else
                        prompt='*'
                        inp+="$char"
                        ((charcount=charcount+1))
                    fi        
                done
                
                if [[ -z $inp ]]
                then
                    printf "\nThis is a required field. You must provide a value.\n"
                else
                    export REGISTRY_PASSWORD=$(echo "$inp" | xargs)
                    dobreak="y"
                    printf "\n\nAccepted private registry with: $REGISTRY_USER @ $REGISTRY_URL\n"
                    break
                fi
            done
        fi
        
        if [[ $dobreak == "y" ]]
        then
            break
        else
            printf "\nValidation failed. Please try again...\n"
            unset RESITRY_TYPE
            unset REGISTRY_URL
            unset GCR_SERVICE_ACCOUNT_PATH
        fi
    done

    unset TBS_BUILDER_IMAGE_TAG
    TBS_BUILDER_IMAGE_REGISTRY_SECRET=$BUILDER_NAME-registry-cred
    if [[ $RESITRY_TYPE == "--gcr" && -n $GCR_SERVICE_ACCOUNT_PATH ]]
    then
        $projectid=$(cat $GCR_SERVICE_ACCOUNT_PATH | jq -r ".project_id")
        TBS_BUILDER_IMAGE_TAG=gcr.io/$projectid/$BUILDER_NAME
        
        #printf "\n\nCreating k8s secret for GCR...\n\n"
        #printf "kp secret create $TBS_BUILDER_IMAGE_REGISTRY_SECRET --gcr"
        #kp secret create $TBS_BUILDER_IMAGE_REGISTRY_SECRET --gcr
    fi
    if [[ $RESITRY_TYPE == "--dockerhub" && -n $DOCKERHUB_ID && -n $DOCKER_PASSWORD ]]
    then
        TBS_BUILDER_IMAGE_TAG=$DOCKERHUB_ID/$BUILDER_NAME

        #printf "\n\nCreating k8s secret for Dockerhub...\n\n"
        #printf "kp secret create $TBS_BUILDER_IMAGE_REGISTRY_SECRET --dockerhub $DOCKERHUB_ID"
        #kp secret create $TBS_BUILDER_IMAGE_REGISTRY_SECRET --dockerhub $DOCKERHUB_ID
    fi
    if [[ $RESITRY_TYPE == "--registry" && -n $REGISTRY_URL && -n $REGISTRY_USER && -n $REGISTRY_PASSWORD ]]
    then
        TBS_BUILDER_IMAGE_TAG=$REGISTRY_URL/$BUILDER_NAME

        #printf "\n\nCreating k8s secret for Image Registry...\n\n"
        # printf "kp secret create $TBS_BUILDER_IMAGE_REGISTRY_SECRET --registry $REGISTRY_URL --registry-user $REGISTRY_USER"
        #kp secret create $TBS_BUILDER_IMAGE_REGISTRY_SECRET --registry $REGISTRY_URL --registry-user $REGISTRY_USER
    fi
else
    TBS_BUILDER_IMAGE_REGISTRY_SECRET=$defaultvalue_image_registry_secret_name
fi
printf "\nAccepted parameter TBS_BUILDER_IMAGE_REGISTRY_SECRET=$TBS_BUILDER_IMAGE_REGISTRY_SECRET\n"

if [[ -n $defaultvalue_tag ]]
then
    TBS_BUILDER_IMAGE_TAG=$defaultvalue_tag
fi
printf "\nAccepted parameter TBS_BUILDER_IMAGE_TAG=$TBS_BUILDER_IMAGE_TAG\n"


printf "\n\n"

unset TBS_BUILDER_GIT_SECRET
if [[ -z $defaultvalue_git_secret_name ]]
then
    printf "\nWhich source code repository would you like to connect to.."
    printf "\nHint:"
    echo -e "\tType 'public' if it is a public repository and does not require authentication"
    echo -e "\tOR"
    echo -e "\tProvide URL of the source code repository in the format of git@repourl.com for ssh key file based authentication."
    echo -e "\t\teg: for github: git@github.com or for bitbucket:git@bitbucket.org or etc"
    echo -e "\tOR"
    echo -e "\tProvide URL of the source code repository in the format of https://domainname.com for username password based authentication."
    echo -e "\t\teg: for github type https://github.com"
    echo -e "\t\tOR for bitbucket type https://bitbucket.org etc"
    echo -e "\t\t"
    echo -e "\tDEFAULT: https://github.com (hit enter to accept default)"
    dobreak="n"

    while true; do
        if [[ -z $GIT_URL ]]
        then
            read -p "Source code repository URL: " inp
            if [ -z "$inp" ]
            then
                GIT_URL="https://github.com"
            else 
                GIT_URL=$inp
            fi  
        fi

        if [[ $GIT_URL == *"@"* ]]
        then
            GIT_AUTH_TYPE="ssh"                
        else 
            GIT_AUTH_TYPE="basic"                
        fi
        if [[ $GIT_URL == "public" ]]
        then
            TBS_BUILDER_GIT_SECRET="public"
            break
        fi

        if [[ $GIT_AUTH_TYPE == "ssh" ]]
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
                        printf "\n\nAccepted git authentication for $GIT_URL using $GIT_SSH_FILE_PATH\n"
                        break
                    else
                        printf "\nYou must provide a valid file path (eg: ~/tbsfiles/mygithubkey.pem)...\n"
                    fi
                    
                fi
            done
        fi



        unset inp
        unset GIT_USERNAME
        unset GIT_PASSWORD
        if [[ $GIT_AUTH_TYPE == "basic" ]]
        then
            while true; do
                read -p "GIT Username: " inp
                if [[ -z $inp ]]
                then
                    printf "\nThis is a required field. You must provide a value.\n"
                else
                    GIT_USERNAME=$inp
                    break
                fi
            done
            
            while true; do
                unset inp
                prompt="GIT Password: "
                charcount=0
                while IFS= read -p "$prompt" -r -s -n 1 char
                do
                    if [[ $char == $'\0' ]]
                    then
                        break
                    fi
                    if [[ $char == $'\177' ]]
                    then
                        if [[ $charcount > 0 ]]
                        then
                            inp=${inp%?}
                            prompt=$'\b \b'
                            ((charcount=charcount-1))
                        else
                            prompt=''
                        fi
                    else
                        prompt='*'
                        inp+="$char"
                        ((charcount=charcount+1))
                    fi        
                done
                if [[ -z $inp ]]
                then
                    printf "\nThis is a required field. You must provide a value.\n"
                else
                    export GIT_PASSWORD=$(echo "$inp" | xargs)
                    dobreak="y"
                    break
                fi
            done
        fi

        if [[ $dobreak == "y" ]]
        then
            break
        else
            printf "\nValidation failed. Please try again...\n"
            unset GIT_URL
            unset GIT_AUTH_TYPE
            unset GIT_SSH_FILE_PATH
            unset GIT_USERNAME
            unset GIT_PASSWORD
        fi
    done

    TBS_BUILDER_GIT_SECRET=$BUILDER_NAME-git-cred
else
    TBS_BUILDER_GIT_SECRET=$defaultvalue_git_secret_name
fi
printf "\nAccepted parameter TBS_BUILDER_GIT_SECRET=$TBS_BUILDER_GIT_SECRET\n"


printf "\n\n"

printf "\nCreating builder config with below params\n\n"
echo -e "\tBUILDER_NAME=$BUILDER_NAME"
echo -e "\tBUILDER_NAMESPACE=$BUILDER_NAMESPACE"
echo -e "\tTBS_BUILDER_IMAGE_TAG=$TBS_BUILDER_IMAGE_TAG"
echo -e "\tTBS_CLUSTERSTACK_NAME=$TBS_CLUSTERSTACK_NAME"
echo -e "\tTBS_CLUSTERSTORE_NAME=$TBS_CLUSTERSTORE_NAME"
echo -e "\tTBS_BUILDER_IMAGE_REGISTRY_SECRET=$TBS_BUILDER_IMAGE_REGISTRY_SECRET"
echo -e "\tTBS_BUILDER_GIT_SECRET=$TBS_BUILDER_GIT_SECRET"
echo -e "\tTBS_BUILDER_BUILD_ORDER=$TBS_BUILDER_BUILD_ORDER"
printf "\n\n"


if [[ -z $BUILDER_NAME || -z $BUILDER_NAMESPACE || -z $TBS_BUILDER_IMAGE_TAG ||
    -z $TBS_CLUSTERSTACK_NAME || -z $TBS_CLUSTERSTORE_NAME || -z $TBS_BUILDER_BUILD_ORDER ||
    -z $TBS_BUILDER_IMAGE_REGISTRY_SECRET || -z $TBS_BUILDER_GIT_SECRET ]]
then
    printf "\n\nOne or more missing required value found. Validation failed. Exit..\n\n"
    exit 1;
fi


printf "\n\n******Creating cluster builder $BUILDER_NAME*******\n\n"

printf "\n\nCreating builder file /tmp/$BUILDER_NAME.yaml\n\n"
cp /usr/local/builder.template /tmp/$BUILDER_NAME.yaml

sleep 1

printf "\n\nMapping service account named $BUILDER_NAME-sa in builder file /tmp/$BUILDER_NAME.yaml\n\n"
sed -i '/BUILDER_SERVICE_ACCOUNT_NAME/s//'$BUILDER_NAME'-sa/' /tmp/$BUILDER_NAME.yaml
# sed -ri 's/^(\s*)(name\s*:\s*BUILDER_SERVICE_ACCOUNT_NAME\s*$)/\name: '$BUILDER_NAME'-sa/' /tmp/$BUILDER_NAME.yaml
# sed -ri 's/^(\s*)(serviceAccount\s*:\s*BUILDER_SERVICE_ACCOUNT_NAME\s*$)/\serviceAccount: '$BUILDER_NAME'-sa/' /tmp/$BUILDER_NAME.yaml

sleep 1


if [[ $TBS_BUILDER_GIT_SECRET != "public" ]]
then
    printf "\n\nMapping secrets $TBS_BUILDER_IMAGE_REGISTRY_SECRET and $TBS_BUILDER_GIT_SECRET in builder file /tmp/$BUILDER_NAME.yaml\n\n"
    secrets="- name: $TBS_BUILDER_IMAGE_REGISTRY_SECRET"
    secrets+="\n"
    secrets+="- name: $TBS_BUILDER_GIT_SECRET"
else
    printf "\n\nMapping secrets $TBS_BUILDER_IMAGE_REGISTRY_SECRET in builder file /tmp/$BUILDER_NAME.yaml\n\n"
    secrets="- name: $TBS_BUILDER_IMAGE_REGISTRY_SECRET"
fi
printf "\nsecrets=$secrets\n"
sed -i 's~BUILDER_IMAGE_PULL_SECRETS~- name: '$TBS_BUILDER_IMAGE_REGISTRY_SECRET'~g' /tmp/$BUILDER_NAME.yaml
awk -v repl="$secrets" '{sub(/BUILDER_SECRETS/,repl)}1' /tmp/$BUILDER_NAME.yaml > /tmp/temp.txt && mv /tmp/temp.txt /tmp/$BUILDER_NAME.yaml

sleep 1

printf "\n\nMapping TBS metadata in builder file /tmp/$BUILDER_NAME.yaml\n\n"
sed -i 's/TBS_BUILDER_NAMESPACE/'$BUILDER_NAMESPACE'/g' /tmp/$BUILDER_NAME.yaml
sed -i 's/TBS_BUILDER_NAME/'$BUILDER_NAME'/g' /tmp/$BUILDER_NAME.yaml
sed -i 's~TBS_BUILDER_IMAGE_TAG~'$TBS_BUILDER_IMAGE_TAG'~g' /tmp/$BUILDER_NAME.yaml
sed -i '/TBS_CLUSTERSTACK_NAME/s//'$TBS_CLUSTERSTACK_NAME'/' /tmp/$BUILDER_NAME.yaml
sed -i '/TBS_CLUSTERSTORE_NAME/s//'$TBS_CLUSTERSTORE_NAME'/' /tmp/$BUILDER_NAME.yaml
awk -v repl="$TBS_BUILDER_BUILD_ORDER" '{sub(/TBS_BUILDER_BUILD_ORDER/,repl)}1' /tmp/$BUILDER_NAME.yaml > /tmp/temp.txt && mv /tmp/temp.txt /tmp/$BUILDER_NAME.yaml

sleep 1

configfile="~/tmp/$BUILDER_NAME.yaml"
if [[ -d "/root/tbsfiles" && -n $wizardmode ]]
then
    printf "\n\nAttempting to create file in ~/tbsfiles/$BUILDER_NAME.yaml\n\n"
    cp /tmp/$BUILDER_NAME.yaml ~/tbsfiles/
    chmod 755 ~/tbsfiles/$BUILDER_NAME.yaml
    sleep 1

    while true; do
        read -p "Review generated file ~/tbsfiles/$BUILDER_NAME.yaml and confirm or modify to proceed further? [y/n] " yn
        case $yn in
            [Yy]* ) approved="y"; printf "\nyou confirmed yes\n"; break;;
            [Nn]* ) printf "\n\nYou said no. \n\nExiting...\n\n"; exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    configfile="~/tbsfiles/$BUILDER_NAME.yaml"
fi



printf "\n\nCreating k8s secret $TBS_BUILDER_IMAGE_REGISTRY_SECRET for container regisry in namespace $BUILDER_NAMESPACE \n\n"
if [[ $RESITRY_TYPE == "--gcr" && -n $GCR_SERVICE_ACCOUNT_PATH ]]
then
    #printf "kp secret create $TBS_BUILDER_IMAGE_REGISTRY_SECRET --gcr"
    kp secret create $TBS_BUILDER_IMAGE_REGISTRY_SECRET --gcr -n $BUILDER_NAMESPACE
fi
if [[ $RESITRY_TYPE == "--dockerhub" && -n $DOCKERHUB_ID && -n $DOCKER_PASSWORD ]]
then
    #printf "kp secret create $TBS_BUILDER_IMAGE_REGISTRY_SECRET --dockerhub $DOCKERHUB_ID"
    kp secret create $TBS_BUILDER_IMAGE_REGISTRY_SECRET --dockerhub $DOCKERHUB_ID -n $BUILDER_NAMESPACE
fi
if [[ $RESITRY_TYPE == "--registry" && -n $REGISTRY_URL && -n $REGISTRY_USER && -n $REGISTRY_PASSWORD ]]
then
    # printf "kp secret create $TBS_BUILDER_IMAGE_REGISTRY_SECRET --registry $REGISTRY_URL --registry-user $REGISTRY_USER"
    kp secret create $TBS_BUILDER_IMAGE_REGISTRY_SECRET --registry $REGISTRY_URL --registry-user $REGISTRY_USER -n $BUILDER_NAMESPACE
fi

printf "\n\nCreating k8s secret $TBS_BUILDER_GIT_SECRET for Source code repository in namespace $BUILDER_NAMESPACE...\n\n"
if [[ $GIT_AUTH_TYPE == "ssh" && -n $GIT_URL && -n $GIT_SSH_FILE_PATH ]]
then    
    # printf "kp secret create $TBS_BUILDER_GIT_SECRET --git-url $GIT_URL --git-ssh-key $GIT_SSH_FILE_PATH"
    kp secret create $TBS_BUILDER_GIT_SECRET --git-url $GIT_URL --git-ssh-key $GIT_SSH_FILE_PATH -n $BUILDER_NAMESPACE
fi
if [[ $GIT_AUTH_TYPE == "basic" && -n $GIT_URL && -n $GIT_USERNAME && -n $GIT_PASSWORD ]]
then
    # printf "kp secret create $TBS_BUILDER_GIT_SECRET --git-url $GIT_URL --git-user $GIT_USERNAME"
    kp secret create $TBS_BUILDER_GIT_SECRET --git-url $GIT_URL --git-user $GIT_USERNAME -n $BUILDER_NAMESPACE
fi

printf "\n\nCreating TBS builder $BUILDER_NAME from file $configfile\n\n"
if [[ $approved == "y" ]]
then
    kubectl apply -f ~/tbsfiles/$BUILDER_NAME.yaml
else
    kubectl apply -f /tmp/$BUILDER_NAME.yaml
fi

wait=30
printf "\n\nWaiting $wait sec\n\n"
sleep $wait

printf "\n\nChecking status:\n"
kp builder status $BUILDER_NAME -n $BUILDER_NAMESPACE

printf "\n\n"
printf "***********\n"
printf "*   END   *\n"
printf "***********\n"