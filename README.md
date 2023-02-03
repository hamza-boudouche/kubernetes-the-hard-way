# How to use

- Put your `adc.json` in the `app` dir (See [Gcloud account](#gcloud-account) for details on this file) .
- Adapt `profile` to match your desired region, zone and project
- Launch `./in.sh`, it will build a docker image and launch a container with
  all needed tools
- In the container, launch `./create.sh` and wait until it finishes executing
- When you finish, launch `./cleanup.sh` to remove all gce resources.

# Gcloud account

To interact with Gcloud API we use a service account.
The `adc.json` is your service account key file.
You can find more infos on how to setup a service account
[here](https://cloud.google.com/video-intelligence/docs/common/auth#set_up_a_service_account).
