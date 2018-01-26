resource "google_compute_route" "nat-route" {
  name        = "${var.env_id}-nat-route"
  dest_range  = "0.0.0.0/0"
  network       = "${google_compute_network.bbl-network.name}"
  next_hop_instance = "${google_compute_instance.nat-instance.name}"
  next_hop_instance_zone = "${var.zone}"
  priority    = 800
  tags = ["no-ip"]
}

resource "google_compute_instance" "nat-instance" {
  name         = "${var.env_id}-nat-instance-primary"
  machine_type = "n1-standard-1"
  zone         = "${var.zone}"

  tags = ["${var.env_id}-nat", "${var.env_id}-internal"]

  boot_disk {
    initialize_params {
      image = "ubuntu-1604-xenial-v20180109"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.bbl-subnet.name}"
    access_config {
    }
  }

  can_ip_forward = true

  metadata_startup_script = <<EOT
#!/bin/bash
sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
EOT
}
