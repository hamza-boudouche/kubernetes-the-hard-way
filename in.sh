#!/bin/sh

docker build . -t k8s-on-gce/tools

# if the last command (build command) returned 0, then proceed
if [ $? -eq 0 ]; then
    # container is removed automatically with   --rm flag  
    # use bind mount to copy code and reflect local changes 
    # expose port 8001 (why)
    docker run -it \
        -v "$PWD/app":/root/app \
        -p 8001:8001 \
        --rm \
        --name k8s-on-gce-tools k8s-on-gce/tools
fi
