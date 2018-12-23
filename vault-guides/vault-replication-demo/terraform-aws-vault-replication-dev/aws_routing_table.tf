# Update west routing table
data "aws_route_table" "west" {
  provider = "aws.us-w2"
  subnet_id = "${module.west.subnet_public_ids[0]}"
}

resource "aws_route" "west" {
  provider = "aws.us-w2"
  route_table_id            = "${data.aws_route_table.west.id}"
  destination_cidr_block    = "${module.east.vpc_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}

# Update east routing table
data "aws_route_table" "east" {
  subnet_id = "${module.east.subnet_public_ids[0]}"
}

resource "aws_route" "east" {
  route_table_id            = "${data.aws_route_table.east.id}"
  destination_cidr_block    = "${module.west.vpc_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}
