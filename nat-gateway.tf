resource "google_compute_address" "nat-gateway" {
  name = "${var.prefix}-nat-gateway"
  count = "${var.zones}"
}

resource "google_compute_instance" "nat-gateway" {
  count = "${var.zones}"
  name = "${var.prefix}-nat-gateway-"
  machine_type = "${var.nat-gateway-machine_type}"
  zone = "${element(var.region_params["${var.region}"], count.index)}"
  tags = ["${var.tags}"]
  boot_disk {
    initialize_params {
      image = "${var.nat-gateway-image}"
    }
  }
  network_interface {
    subnetwork = "${var.subnetwork}"
    access_config {
      nat_ip = "${element(google_compute_address.nat-gateway.address, count.index)}"
    }
  }
  can_ip_forward = true
  metadata_startup_script = "${data.template_file.nat-gateway_startup-script.rendered}"
}

resource "google_compute_route" "nat-gateway-zone1" {
  count = "${var.zones}"
  name = "${var.prefix}-nat-gateway-${lookup(var.region_params["${var.region}"],"zone"${element(var.zones, count.index)})}"
  dest_range = "0.0.0.0/0"
  network = "${var.network}"
  next_hop_instance = "${google_compute_instance.nat-gateway-zone1.name}"
  next_hop_instance_zone = "${element(google_compute_instance.nat-gateway.name, count.index)}"
  priority = "${var.priority}"
  tags = ["${var.route-tag}"]
}
