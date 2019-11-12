resource "google_compute_global_address" "static" {
  count = local.node_count != 1 ? 0 : 1
  
  name = "ipv4-address"
}

resource "google_dns_record_set" "a-record" {
  count = local.node_count != 1 ? 0 : 1
  
  name = "${var.dns-subdomain}.${var.dns-zone}."
  type = "A"
  ttl  = 60

  managed_zone = "${var.dns-zone-name}"

  rrdatas = ["${google_compute_global_address.static[0].address}"]
}
