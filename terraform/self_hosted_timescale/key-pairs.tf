resource "aws_key_pair" "deployer" {
  key_name   = "deploy-tsdb-${var.instance}-${data.aws_caller_identity.current.account_id}"
  public_key = var.public_key
}
