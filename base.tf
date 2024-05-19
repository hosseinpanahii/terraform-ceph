terraform {
  required_version = ">= 0.14.7"
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"

      version = "2.7.0"
    }
  }
}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server
  allow_unverified_ssl = true
}



locals {
  disks = [
    { "id":1, "dev":"sdb", "sizeGB":10 },
    { "id":2, "dev":"sdc", "sizeGB":10  },
    { "id":3, "dev":"sdd", "sizeGB":10  }
  ]
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

# resource_pool_id can either come from cluster or from esxi host

data "vsphere_compute_cluster" "cluster" {
  count         = var.vsphere_cluster=="" ? 0:1
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_host" "esxihost" {
  count         = var.vsphere_cluster=="" ? 1:0
  # name not needed if there is only 1 esxi host
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

#data "vsphere_network" "network2" {
#  name          = var.vsphere_network
#  datacenter_id = data.vsphere_datacenter.dc.id
data "vsphere_virtual_machine" "template" {
  name          = var.vsphere_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "mons-ansible" {
  name     = var.mons_ansible["name"]
  resource_pool_id = var.vsphere_cluster=="" ? data.vsphere_host.esxihost[0].resource_pool_id:data.vsphere_compute_cluster.cluster[0].resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.host_vm_folder
  num_cpus = var.host_cpu
  memory   = var.host_ram_mb
  guest_id = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  disk {
     label            = "disk0"
     unit_number      = 0
     #size             = var.host_disk_gb # can expand template disk, but will need parted
     size             = data.vsphere_virtual_machine.template.disks.0.size
     eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
     thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }
  cdrom {
    client_device = true
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
  extra_config = {
      "guestinfo.userdata"         = base64encode(templatefile("${path.module}/template/userdata.yaml", {
        flag = "False"
       }))
      "guestinfo.userdata.encoding" = "base64"
      "guestinfo.metadata"         = base64encode(templatefile("${path.module}/template/metadata.yaml", {
        ip_address  = var.mons_ansible["ip"]
        hostname = var.mons_ansible["name"]
      }))
      "guestinfo.metadata.encoding" = "base64"
  }
  provisioner "file" {
    source      = "./scripts/install-req-ansible.sh"
    destination = "/tmp/install-req-ansible.sh"
  }  
  provisioner "file" {
    source      = "./scripts/install-ceph-on-nodes.sh"
    destination = "/tmp/install-ceph-on-nodes.sh"
  }
  provisioner "file" {
    source      = "ansible/prepare-ceph-nodes.yml"
    destination = "/home/${var.host_user}/prepare-ceph-nodes.yml"
  }
  provisioner "file" {
    source      = "ansible/install-cephadm.yml"
    destination = "/home/${var.host_user}/install-cephadm.yml"
  }
  provisioner "file" {
    source      = "ansible/ansible.cfg"
    destination = "/home/${var.host_user}/ansible.cfg"
  }
  provisioner "file" {
    source      = "ansible/inventory"
    destination = "/home/${var.host_user}/inventory"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-req-ansible.sh",
      "/tmp/install-req-ansible.sh",
    ]
  }
  provisioner "local-exec" {
    command = "scp ubuntu@te-moh-ceph-mon-0:/home/ubuntu/.ssh/id_rsa.pub /root/terraform-ceph/ceph/id_rsa.pub"
  }
  connection {
    type = "ssh"
    agent = "false"
    host = var.mons_ansible["ip"]
    user = var.host_user_root
    password = var.host_password_root
  }
}

resource "vsphere_virtual_machine" "mons" {
  for_each = { for inst in var.mons_object : inst.name => inst }
  name     = each.key
  resource_pool_id = var.vsphere_cluster=="" ? data.vsphere_host.esxihost[0].resource_pool_id:data.vsphere_compute_cluster.cluster[0].resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.host_vm_folder
  num_cpus = var.host_cpu
  memory   = var.host_ram_mb
  guest_id = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  disk {
     label            = "disk0"
     unit_number      = 0
     #size             = var.host_disk_gb # can expand template disk, but will need parted
     size             = data.vsphere_virtual_machine.template.disks.0.size
     eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
     thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }
  cdrom { 
    client_device = true
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
  extra_config = {
      "guestinfo.userdata"         = base64encode(templatefile("${path.module}/template/userdata.yaml", {
        flag = "False"
       }))
      "guestinfo.userdata.encoding" = "base64"
      "guestinfo.metadata"         = base64encode(templatefile("${path.module}/template/metadata.yaml", {
        ip_address  = each.value.ip
        hostname = each.key
      }))
      "guestinfo.metadata.encoding" = "base64"
  }
  provisioner "file" {
    source      = "./scripts/general-install-req.sh"
    destination = "/tmp/general-install-req.sh"
  }  
 
  provisioner "file" {
    source      = "./id_rsa.pub"
    destination = "/tmp/id_rsa.pub"
  }  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/general-install-req.sh",
      "/tmp/general-install-req.sh",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/id_rsa.pub /home/${var.host_user}/.ssh/authorized_keys",
      "sudo cp /tmp/id_rsa.pub /root/.ssh/authorized_keys"
    ]
  }
  connection { 
    type = "ssh"
    agent = "false"
    host = each.value.ip
    user = var.host_user_root
    password = var.host_password_root
  }
  depends_on = [vsphere_virtual_machine.mons-ansible]
}
resource "vsphere_virtual_machine" "osds" {
  for_each = { for inst in var.osds_object : inst.name => inst }
  name     = each.key
  resource_pool_id = var.vsphere_cluster=="" ? data.vsphere_host.esxihost[0].resource_pool_id:data.vsphere_compute_cluster.cluster[0].resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.host_vm_folder
  num_cpus = var.host_cpu
  memory   = var.host_ram_mb
  guest_id = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  disk {
     label            = "disk0"
     unit_number      = 0
     #size             = var.host_disk_gb # can expand template disk, but will need parted
     size             = data.vsphere_virtual_machine.template.disks.0.size
     eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
     thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }
# creates variable number of data disks for VM
  dynamic "disk" {
    for_each = [ for disk in local.disks: disk ]
    content {
    label       = "disk${disk.value.id}"
    unit_number = disk.value.id
    size        = disk.value.sizeGB
    } 
  } 
  cdrom {
    client_device = true
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
  extra_config = {
      "guestinfo.userdata"         = base64encode(templatefile("${path.module}/template/userdata.yaml", {
        flag = "False"
       }))
      "guestinfo.userdata.encoding" = "base64"
      "guestinfo.metadata"         = base64encode(templatefile("${path.module}/template/metadata.yaml", {
        ip_address  = each.value.ip
        hostname = each.key
      }))
      "guestinfo.metadata.encoding" = "base64"
  }
  provisioner "file" {
    source      = "./scripts/general-install-req.sh"
    destination = "/tmp/general-install-req.sh"
  }

  provisioner "file" {
    source      = "./id_rsa.pub"
    destination = "/tmp/id_rsa.pub"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/general-install-req.sh",
      "/tmp/general-install-req.sh",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/id_rsa.pub /home/${var.host_user}/.ssh/authorized_keys",
      "sudo cp /tmp/id_rsa.pub /root/.ssh/authorized_keys"
    ]
  }
  connection {
    type = "ssh"
    agent = "false"
    host = each.value.ip
    user = var.host_user_root
    password = var.host_password_root
  }

  depends_on = [vsphere_virtual_machine.mons-ansible]
}

resource "null_resource" "playbook-pre-ceph" {

  connection {
    type = "ssh"
    agent = "false"
    host = var.mons_ansible["ip"]
    user = var.host_user
    password = var.host_password
  }
  provisioner "remote-exec" {
   inline = [
      "cd ~",
      "ansible-playbook  prepare-ceph-nodes.yml --user ${var.host_user}",
      "ansible-playbook  install-cephadm.yml --user ${var.host_user} -e  node_ip=${var.mons_ansible["ip"]}",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install-ceph-on-nodes.sh",
      "/tmp/install-ceph-on-nodes.sh",
    ]
  }

  depends_on = [vsphere_virtual_machine.osds]
}

