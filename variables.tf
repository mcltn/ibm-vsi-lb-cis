variable "ssh_public_key" {
}

variable "ssh_label" {
  default = "ssh_key_scale_group"
}

variable "app_server_count" {
  default = 2
}

variable "vm_post_install_script_uri" {
  default = "https://raw.githubusercontent.com/mcltn/post-provision/master/nginx-log-mon.sh"
}

variable "datacenter_east" {
  default = "wdc07"
}

variable "datacenter_south" {
  default = "dal13"
}

variable "datacenter_west" {
  default = "sjc04"
}

variable "vlan_name_east" {
  default = "demo_vlan_east"
}

variable "vlan_name_south" {
  default = "demo_vlan_south"
}

variable "cis_instance" {
  default = "cis-mcltn-1"
}
variable "domain" {
  default = "mcltn-demo.com"
}

variable "dns_name" {
  default = "cisdemo"
}

variable "resource_group" {
  default = "default"
}