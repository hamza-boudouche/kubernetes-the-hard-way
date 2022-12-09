FROM python:3.6-alpine

# hardcoded versions to avoid incompatibility issues in the future
ENV TERRAFORM_VERSION=1.3.4 \
    GCLOUD_SDK_VERSION=409.0.0 \
    CFSSL_VERSION=R1.2 \
    KUBE_VERSION=v1.12.2

# prepare to download necessary files to install gcloud cli and terraform
ENV GCLOUD_SDK_FILE=google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    TERRAFORM_FILE=terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# download necessary files
RUN apk update && \
    apk add bash curl git openssh-client gcc make musl-dev libffi-dev openssl-dev && \
    curl -o /root/$GCLOUD_SDK_FILE https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/$GCLOUD_SDK_FILE && \
    curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/$CFSSL_VERSION/cfssl_linux-amd64 && \
    curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/$CFSSL_VERSION/cfssljson_linux-amd64 && \
    curl -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/amd64/kubectl && \
    curl -o /root/$TERRAFORM_FILE https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/$TERRAFORM_FILE

WORKDIR /root

# unzip files and install gcloud, kubectl and ansible
RUN unzip $TERRAFORM_FILE && \
    mv terraform /usr/local/bin && \
    rm $TERRAFORM_FILE && \
    tar xzf $GCLOUD_SDK_FILE && \
    /root/google-cloud-sdk/install.sh -q && \
    /root/google-cloud-sdk/bin/gcloud config set disable_usage_reporting true && \
    rm /root/${GCLOUD_SDK_FILE} && \
    chmod +x /usr/local/bin/cfssl* /usr/local/bin/kubectl && \
    pip3 install ansible

# contains setup commands and env vars for ansible, gcloud and 
ADD profile /root/.bashrc
ADD ansible.cfg /root/.ansible.cfg

RUN source ~/google-cloud-sdk/path.bash.inc

RUN wget -q https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson

RUN chmod +x cfssl cfssljson

RUN mv cfssl cfssljson /usr/local/bin/

WORKDIR /root/app

ENTRYPOINT [ "/bin/bash" ]

