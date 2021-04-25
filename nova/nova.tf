resource "openstack_compute_keypair_v2" "test-keypair" {
  name = "my-keypair"
}

resource "openstack_compute_secgroup_v2" "secgroup_1" {
  name        = "my_secgroup"
  description = "my security group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_instance_v2" "myinstance" {
  name            = "myinstance"
  image_id        = "e4dec62b-51e8-4014-8fd5-b47f69b8d677"
  flavor_name     = "m1.small"
  key_pair        = openstack_compute_keypair_v2.test-keypair.name
  security_groups = [openstack_compute_secgroup_v2.secgroup_1.name]

  network {
    name = "public"
  }
}
