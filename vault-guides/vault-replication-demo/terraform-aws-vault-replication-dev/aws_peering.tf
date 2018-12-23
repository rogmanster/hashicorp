# Create vpc peering connection
data "aws_caller_identity" "peer" {
  provider = "aws.us-w2"
}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = "${module.east.vpc_id}"
  peer_vpc_id   = "${module.west.vpc_id}"
  peer_owner_id = "${data.aws_caller_identity.peer.account_id}"
  peer_region   = "us-west-2"
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = "aws.us-w2"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}
