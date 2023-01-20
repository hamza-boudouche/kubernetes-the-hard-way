# Kubernetes on Google Computing Engine

This project leverages hype tools 😉 (terraform 🏗, ansible 🛠, docker 🐳, ...)
to automate the deployment of a 6 vms (3 controllers 👩‍✈️, 3 workers 👷‍)
kubernetes cluster on GCE.

## How to use 🗺

- Put your `adc.json` in the `app` dir (See [Gcloud account](#gcloud-account) for details on this file) .
- Adapt `profile` to match your desired region, zone and project
- Launch `./in.sh`, it will build a docker image and launch a container with
  all needed tools
- In the container, launch `./create.sh` and wait for ~10mins
- And you're done ! 🚀

🚽 When you finish, launch `./cleanup.sh` to remove all gce resources.

## Versions

All versions are set as environment variables in the Dockerfile.
You can adapt it if you want to try other versions

## Gcloud account

To interact with Gcloud API we use a service account.
The `adc.json` is your service account key file.
You can find more infos on how to setup a service account
[here](https://cloud.google.com/video-intelligence/docs/common/auth#set_up_a_service_account).

## Addons

### Traefik ingress

- Go to 13-addons dir: `cd 13-addons`
- Launch `./deploy-traefik.sh`, this will create the cluster role needed for traefik, the traefik daemonset and the firewall rule to enable trafic in

### Dashboard

- Go to 13-addons dir: `cd 13-addons`
- Launch `./deploy-dashboard.sh`, this will create the service account used for the dashboard (⚠️ with tihs configuration, the service account is bound to the cluster-admin role)
- Follow the displayed instructions

### Tests

- Go to 14-example dir: `cd 14-example`
- Deploy whoami app example: `kubectl apply -f whoami.yml`

## Credits 👍

This work is an automation of [kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
