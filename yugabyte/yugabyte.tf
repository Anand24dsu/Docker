terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 2.0.0"
    }
  }
}

provider "docker" {}

resource "docker_network" "yugabyte_network" {
  name   = "yugabyte_network"
  driver = "bridge"

  ipam_config {
    subnet = "192.168.100.0/24"  # Updated subnet to avoid conflicts
  }
}

resource "docker_image" "yugabyte" {
  name         = "yugabyte/yugabyte-db:latest"
  keep_locally = false
}

resource "docker_container" "yugabyte" {
  name  = "yugabyte-db"
  image = docker_image.yugabyte.name
  restart = "always"
  networks_advanced {
    name = docker_network.yugabyte_network.name
    ipv4_address = "192.168.100.10"  # Assign a fixed IP
  }

  ports {
    internal = 5433
    external = 5433
  }

  ports {
    internal = 7000
    external = 7000
  }

  ports {
    internal = 7100
    external = 7100
  }

  ports {
    internal = 9000
    external = 9000
  }

  ports {
    internal = 9042
    external = 9042
  }

  ports {
    internal = 9093
    external = 9093
  }

  ports {
    internal = 11000
    external = 11000
  }

  ports {
    internal = 12000
    external = 12000
  }

  ports {
    internal = 13000
    external = 13000
  }

  ports {
    internal = 22
    external = 2222
  }

  command = [
    "/bin/sh", "-c", 
    "apt-get update && apt-get install -y openssh-server && mkdir -p /run/sshd && echo 'root:root' | chpasswd && sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && service ssh start && tail -f /dev/null"
  ]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      password    = "root"
      host        = "192.168.100.10"
      port        = 2222
    }

    inline = [
      "echo 'SSH is working inside the container!'"
    ]
  }

  depends_on = [docker_image.yugabyte, docker_network.yugabyte_network]
}