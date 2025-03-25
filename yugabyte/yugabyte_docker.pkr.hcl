packer {
  required_plugins {
    docker = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/docker"
    }
  }
}

variable "image_name" {
  type    = string
  default = "yugabyte-db"
}
 
variable "tags" {
  type    = list(string)
  default = ["latest"]
}

source "docker" "yugabyte" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  name    = "yugabyte-docker"
  sources = ["source.docker.yugabyte"]

  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      "apt-get install -y sudo",  # ✅ Install sudo first
      "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y wget gnupg2 lsb-release python-is-python3",
       "sudo apt install python3",
       "python3 --version",
      "wget https://downloads.yugabyte.com/releases/2024.2.1.0/yugabyte-2024.2.1.0-b185-linux-x86_64.tar.gz",
      "tar xvfz yugabyte-2024.2.1.0-b185-linux-x86_64.tar.gz",
      "cd yugabyte-2024.2.1.0",
      "sudo ./bin/post_install.sh",  # ✅ Run as sudo
      "echo 'Provisioning complete'"
    ]
  }

  post-processor "docker-tag" {
    repository = var.image_name
    tags       = var.tags
  }
}
