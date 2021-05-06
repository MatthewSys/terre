
terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "centos-test" {
  name   = "centos-test"
  pool   = "centosvm"
  source = "/home/matthew/Desktop/Terraform/CentOS-7-x86_64-GenericCloud-2009.qcow2"
  format = "qcow2"
}

resource "libvirt_network" "routed" {
  name      = "routed"
  mode      = "route"
  addresses = ["192.168.1.220/24"]
  autostart = true
}


# Use CloudInit to add our ssh-key to the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  pool           = "centosvm"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}


resource "libvirt_domain" "domain-centos" {
  name   = "centos-terraform"
  memory = "512"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_id   = libvirt_network.routed.id
    network_name = "routed"
  }


  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.centos-test.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = "true"
  }
}
