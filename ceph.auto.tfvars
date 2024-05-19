# vcenter credentials
vsphere_user          = "Administrator@vsphere.local"
vsphere_password      = "*****"
vsphere_server        = "1.1.1.1"
vsphere_datacenter    = "SHM Datacenter"
vsphere_datastore     = "FUJITSU DX80"
vsphere_cluster       = "SHM Cluster"
vsphere_network       = "LAB-DVS"

# name of template
vsphere_template      = "ubuntu2204"

# OS template credentials
host_user             = "ubuntu"
host_password         = "ubuntu"
host_user_root        = "root"
host_password_root    = "P@ssw0rd"
host_name             = "lhr"
host_vm_folder        = "LAB/Mohammad VMs"
host_domain           = "demo.lab"
host_cpu              = "4"
host_ram_mb           = "16384"
host_subnet           = "24"
host_gateway          = "10.10.69.1"
dns_server_list       = [ "8.8.8.8" ]
dns_suffix_list       = [ "demo.lab" ]
