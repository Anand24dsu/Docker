packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

# Variables for configuration
variable "cpus" {
  type    = string
  default = "2"
}

variable "memory" {
  type    = string
  default = "4096"
}

variable "disk_size" {
  type    = string
  default = "20480"
}

variable "yb_version" {
  type    = string
  default = "2.19.2.0-b115"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "ssh_password" {
  type    = string
  default = "ubuntu"
}

# QEMU Build
build {
  name    = "qemu"  
  sources = ["source.qemu.yugabyte"]  

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y wget curl git python3 python3-pip sudo",
      "sudo useradd -m -s /bin/bash yugabyte",
      "echo 'yugabyte ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/yugabyte",
      "sudo chmod 0440 /etc/sudoers.d/yugabyte"
    ]
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /home/yugabyte/yb_build",
      "sudo chown -R yugabyte:yugabyte /home/yugabyte/yb_build",
      "mkdir -p /home/yugabyte/yb_data",
      "sudo chown -R yugabyte:yugabyte /home/yugabyte/yb_data"
    ]
  }

  provisioner "shell" {
    scripts          = ["install_yugabyte.sh"]
    execute_command  = "sudo -E -S sh '{{ .Path }}'"
  }
}

# QEMU Source Configuration
source "qemu" "yugabyte" {
  accelerator      = "kvm"
  disk_size        = var.disk_size
  format           = "qcow2"
  headless         = true
  output_directory = "output-ubuntu"

  # Ubuntu Mini ISO for Bionic (18.04)
  iso_checksum = "sha1:cce936c1f9d1448c7d8f74b76b66f42eb4f93d4a"
  iso_urls = [
    "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/netboot/mini.iso"
  ]

  memory     = var.memory
  net_device = "virtio-net"
  qemuargs   = [
    ["-m", var.memory],
    ["-smp", var.cpus]
  ]

  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  ssh_password     = var.ssh_password
  ssh_port         = 22
  ssh_timeout      = "20m"
  ssh_username     = var.ssh_username
  vm_name          = "ubuntu-mini"
}
