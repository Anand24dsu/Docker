packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

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
  type = string
  default = "ubuntu"
}

variable "ssh_password" {
  type = string
  default = "ubuntu"
}


build {
  name    = "qemu"  // Consistent name
  sources = ["source.qemu.yugabyte"] // Corrected source reference

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
    scripts           = ["install_yugabyte.sh"]
    execute_command = "sudo -E -S sh '{{ .Path }}'"
  }
}

source "qemu" "yugabyte" { // Corrected name: "yugabyte"
  accelerator      = "kvm"
  disk_size        = var.disk_size
  format           = "qcow2"
  headless         = true
  http_directory   = "http"
 iso_checksum     = "sha256:d7fe3d6a0419667d2f8eff12796996328daa2d4f90cd9f87aa9371b362f987bf"
  iso_urls = [
    "https://releases.ubuntu.com/24.04/ubuntu-24.04.2-desktop-amd64.iso"
  ]
  output_directory = "output-ubuntu"  // Changed output directory
  memory           = var.memory
  net_device       = "virtio-net"
  qemuargs = [
    ["-m", var.memory],
    ["-smp", var.cpus]
  ]
   shutdown_command   = "echo ubuntu | sudo -S shutdown -P now"
  ssh_password       = var.ssh_password # Use variable for password
  ssh_port           = 22
  ssh_timeout        = "20m"
  ssh_username       = var.ssh_username   # Use variable for username
  vm_name            = "ubuntu-vm"  // Changed VM name
}