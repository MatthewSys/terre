provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "centosvm" {
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


# Create the machine
resource "libvirt_domain" "domain-ubuntu" {
  name   = "ubuntu-terraform"
  memory = "512"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_id   = libvirt_network.vm_network.id
    network_name = "vm_network"
  }

  # IMPORTANT
  # Ubuntu can hang is a isa-serial is not present at boot time.
  # If you find your CPU 100% and never is available this is why
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
    volume_id = libvirt_volume.ubuntu-qcow2.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = "true"
  }
}