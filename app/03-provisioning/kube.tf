terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.43.0"
    }
  }
    backend "remote" {
    hostname     = "app.terraform.io"
    organization = "hamza-inc"

    workspaces {
      name = "sdtd"
    }
  }
}


resource "google_compute_router" "router" {
  name    = "router"
  region  = "us-central1"
  network = "${google_compute_network.default.name}"

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


variable "gce_ssh_user" {
  default = "root"
}
variable "gce_ssh_pub_key_file" {
  default = "google_compute_engine.pub"
}

variable "gce_zone" {
  type = string
  default = "us-central1-a"
}

// Configure the Google Cloud provider
provider "google" {
  credentials = "${file("adc.json")}"
}

resource "google_compute_network" "default" {
  name                    = "kubernetes-the-easy-way"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "default" {
  name            = "kubernetes"
  network         = "${google_compute_network.default.name}"
  ip_cidr_range   = "10.240.0.0/24"
}

resource "google_compute_firewall" "internal" {
  name    = "kubernetes-the-easy-way-allow-internal"
  network = "${google_compute_network.default.name}"

  allow {
    protocol = "icmp" // why ? k8s only ueses TCP internally 
  }

  allow {
    protocol = "udp" // why ? k8s only ueses TCP internally 
  }

  allow {
    protocol = "tcp"
  }

  source_ranges = [ "10.240.0.0/24","10.200.0.0/16" ] // why the second one
}

resource "google_compute_firewall" "external" {
  name    = "kubernetes-the-easy-way-allow-external"
  network = "${google_compute_network.default.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }

  source_ranges = [ "0.0.0.0/0" ]
}

resource "google_compute_address" "default" {
  name = "kubernetes-the-easy-way"
  region = "us-central1"
}

resource "google_compute_instance" "controller" {
  count = 3
  name            = "controller-${count.index}"
  machine_type    = "n1-standard-1"
  zone            = "${var.gce_zone}"
  can_ip_forward  = true

  tags = ["kubernetes-the-easy-way","controller"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.default.name}"
    network_ip = "10.240.0.1${count.index}"

    # access_config {
    #   // Ephemeral IP
    # }
  }
  
  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = "apt-get install -y python"
}

resource "google_compute_instance" "worker" {
  count = 3
  name            = "worker-${count.index}"
  machine_type    = "n1-standard-1"
  zone            = "${var.gce_zone}"
  can_ip_forward  = true

  tags = ["kubernetes-the-easy-way","worker"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.default.name}"
    network_ip = "10.240.0.2${count.index}"

    # access_config {
    #   // Ephemeral IP
    # }
  }
  
  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  metadata = {
    pod-cidr = "10.200.${count.index}.0/24"
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = "apt-get install -y python"
}

resource "google_compute_instance" "loadbalancer" {
  name            = "loadbalancer"
  machine_type    = "n1-standard-1"
  zone            = "${var.gce_zone}"
  can_ip_forward  = true

  tags = ["kubernetes-the-easy-way","loadbalancer"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.default.name}"
    network_ip = "10.240.0.3"

    access_config {
      // Ephemeral IP
    }
  }
  
  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = "apt-get install -y python"
}

resource "google_compute_instance" "nfs" {
  name            = "nfs"
  machine_type    = "n1-standard-1"
  zone            = "${var.gce_zone}"
  can_ip_forward  = true

  tags = ["kubernetes-the-easy-way","nfs"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
      size = 500
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.default.name}"
    network_ip = "10.240.0.4"

    # access_config {
    #   // Ephemeral IP
    # }
  }
  
  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = "apt-get install -y python"
}

resource "google_compute_instance" "bastion" {
  name            = "bastion"
  machine_type    = "n1-standard-1"
  zone            = "${var.gce_zone}"
  can_ip_forward  = true

  tags = ["kubernetes-the-easy-way","bastion"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.default.name}"
    network_ip = "10.240.0.5"

    access_config {
      // Ephemeral IP
    }
  }
  
  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = "apt-get install -y python"
}

output bastion_private_key {  
  value = file("./google_compute_engine")
}