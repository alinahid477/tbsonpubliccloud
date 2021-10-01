isexists=$(docker images | grep "\<$1\>")
if [[ -z $isexists || $2 == "forcebuild" ]]
then
    docker build . -t $1
fi
docker run -it --rm -v ${PWD}:/root/ -v /var/run/docker.sock:/var/run/docker.sock --add-host kubernetes:127.0.0.1 --name $1 $1