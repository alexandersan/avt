provider "google" {
  region      = "${var.region}"
  project     = "${var.project_name}"
  credentials = "${file("${var.credentials_file_path}")}"
}

resource "google_compute_instance" "node" {
  count = "${var.number_of_vms}"

  name         = "node-0${count.index}"
  machine_type = "f1-micro"
  zone         = "${var.region_zone}"
  tags         = ["terraform"]

  disk {
    image = "ubuntu-os-cloud/ubuntu-1404-trusty-v20160602"
  }

  network_interface {
    network = "default"

    access_config {
      # Ephemeral
    }
  }

  metadata {
    ssh-keys = "root:${file("${var.public_key_path}")}"
  }

  provisioner "remote-exec" {
    connection {
    user = "ubuntu"
    # The connection will use the local SSH agent for authentication.
    }
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y upgrade",
      "sudo touch /provisioned"
    ]
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }
}

resource "google_compute_firewall" "default" {
  name    = "tf-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["node"]
}

