# Reference DNS registration
data "ibm_dns_domain_registration" "app_domain" {
  name = "${var.domain}"
}

# Set DNS name servers for CIS  
resource "ibm_dns_domain_registration_nameservers" "app_domain" {
  name_servers        = ["${ibm_cis_domain.app_domain.name_servers}"]
  dns_registration_id = "${data.ibm_dns_domain_registration.app_domain.id}"
}

# IBM Cloud Resource Group the CIS instance will be created under
data "ibm_resource_group" "app_group" {
  name = "${var.resource_group}"
}

#resource "ibm_cis" "app_domain" {
#  name              = "${var.cis_instance}"
#  resource_group_id = "${data.ibm_resource_group.app_group.id}"
#  plan              = "standard"
#  location          = "global"
#}
data "ibm_cis" "app_domain" {
  name              = "${var.cis_instance}"
  #resource_group_id = "${data.ibm_resource_group.app_group.id}"
}

resource "ibm_cis_domain" "app_domain" {
  cis_id = "${data.ibm_cis.app_domain.id}"
#  cis_id = "${ibm_cis.app_domain.id}"
  domain = "${var.domain}"
}

resource "ibm_cis_domain_settings" "app_domain" {
  cis_id            = "${data.ibm_cis.app_domain.id}"
#  cis_id = "${ibm_cis.app_domain.id}"
  domain_id         = "${ibm_cis_domain.app_domain.id}"
  "waf"             = "on"
  "ssl"             = "full"
  "min_tls_version" = "1.2"
}

resource "ibm_cis_healthcheck" "root" {
  cis_id         = "${data.ibm_cis.app_domain.id}"
#  cis_id = "${ibm_cis.app_domain.id}"
  description    = "Websiteroot"
  expected_body  = ""
  expected_codes = "200"
  path           = "/"
}

resource "ibm_cis_origin_pool" "wdc" {
  cis_id        = "${data.ibm_cis.app_domain.id}"
#  cis_id = "${ibm_cis.app_domain.id}"
  name          = "${var.datacenter_east}"
  check_regions = ["WNAM"]

  monitor = "${ibm_cis_healthcheck.root.id}"

  origins = [{
    name    = "${var.datacenter_east}"
    address = "${ibm_lbaas.lbaas_east.vip}"
    enabled = true
  }]

  description = "WDC pool"
  enabled     = true
}

resource "ibm_cis_origin_pool" "dal" {
  cis_id        = "${data.ibm_cis.app_domain.id}"
#  cis_id = "${ibm_cis.app_domain.id}"
  name          = "${var.datacenter_south}"
  check_regions = ["WNAM"]

  monitor = "${ibm_cis_healthcheck.root.id}"

  origins = [{
    name    = "${var.datacenter_south}"
    address = "${ibm_lbaas.lbaas_south.vip}"
    enabled = true
  }]

  description = "DAL pool"
  enabled     = true
}

resource "ibm_cis_global_load_balancer" "app_domain" {
  cis_id           = "${data.ibm_cis.app_domain.id}"
#  cis_id = "${ibm_cis.app_domain.id}"
  domain_id        = "${ibm_cis_domain.app_domain.id}"
  name             = "${var.dns_name}.${var.domain}"
  fallback_pool_id = "${ibm_cis_origin_pool.wdc.id}"
  default_pool_ids = ["${ibm_cis_origin_pool.dal.id}", "${ibm_cis_origin_pool.wdc.id}"]
  description      = "Load balancer"
  proxied          = true
  session_affinity = "cookie"
}