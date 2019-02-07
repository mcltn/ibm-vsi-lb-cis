
resource "ibm_compute_ssh_key" "ssh_key_gip" {
    label = "${var.ssh_label}"
    public_key = "${var.ssh_public_key}"
}

# Create a private vlan
resource "ibm_network_vlan" "lb_vlan_private_east" {
  name        = "${var.vlan_name_east}"
  datacenter  = "${var.datacenter_east}"
  type        = "PRIVATE"
}

# Create a private vlan
resource "ibm_network_vlan" "lb_vlan_private_south" {
  name        = "${var.vlan_name_south}"
  datacenter  = "${var.datacenter_south}"
  type        = "PRIVATE"
}

resource "ibm_compute_vm_instance" "vm_instances_east" {
  count = "${var.app_server_count}"
  hostname = "app-${count.index+1}"
  domain = "${var.domain}"
  os_reference_code = "UBUNTU_14_64"
  datacenter = "${var.datacenter_east}"
  network_speed = 100
  hourly_billing = true
  private_network_only = false
  cores = 1
  memory = 1024
  disks = [25]
  local_disk = false
  private_vlan_id = "${ibm_network_vlan.lb_vlan_private_east.id}"
  ssh_key_ids = [
    "${ibm_compute_ssh_key.ssh_key_gip.id}"
  ],
  post_install_script_uri = "${var.vm_post_install_script_uri}"
}

resource "ibm_compute_vm_instance" "vm_instances_south" {
  count = "${var.app_server_count}"
  hostname = "app-${count.index+1}"
  domain = "${var.domain}"
  os_reference_code = "UBUNTU_14_64"
  datacenter = "${var.datacenter_south}"
  network_speed = 100
  hourly_billing = true
  private_network_only = false
  cores = 1
  memory = 1024
  disks = [25]
  local_disk = false
  private_vlan_id = "${ibm_network_vlan.lb_vlan_private_south.id}"
  ssh_key_ids = [
    "${ibm_compute_ssh_key.ssh_key_gip.id}"
  ],
  post_install_script_uri = "${var.vm_post_install_script_uri}"
}

resource "ibm_lbaas" "lbaas_east" {
  name        = "lbaas2-east"
  description = ""
  subnets     = ["${ibm_compute_vm_instance.vm_instances_east.0.private_subnet_id}"]
  protocols = [
    {
      frontend_protocol     = "HTTP"
      frontend_port         = 80
      backend_protocol      = "HTTP"
      backend_port          = 80
      load_balancing_method = "round_robin"
    },
  ]
}

resource "ibm_lbaas" "lbaas_south" {
  name        = "lbaas2-south"
  description = ""
  subnets     = ["${ibm_compute_vm_instance.vm_instances_south.0.private_subnet_id}"]
  protocols = [
    {
      frontend_protocol     = "HTTP"
      frontend_port         = 80
      backend_protocol      = "HTTP"
      backend_port          = 80
      load_balancing_method = "round_robin"
    },
  ]
}

resource "ibm_lbaas_server_instance_attachment" "server_attach_east" {
    count = "${var.app_server_count}"
    private_ip_address = "${element(ibm_compute_vm_instance.vm_instances_east.*.ipv4_address_private,count.index)}"
    lbaas_id = "${ibm_lbaas.lbaas_east.id}"
    depends_on = ["ibm_lbaas.lbaas_east"]
}

resource "ibm_lbaas_server_instance_attachment" "server_attach_south" {
    count = "${var.app_server_count}"
    private_ip_address = "${element(ibm_compute_vm_instance.vm_instances_south.*.ipv4_address_private,count.index)}"
    lbaas_id = "${ibm_lbaas.lbaas_south.id}"
    depends_on = ["ibm_lbaas.lbaas_south"]
}
