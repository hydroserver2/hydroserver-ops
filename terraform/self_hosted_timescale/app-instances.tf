resource "aws_instance" "primary_1" {
  ami             = var.aws_ami
  instance_type   = var.aws_type
  security_groups = ["${aws_security_group.swarm.name}"]
  key_name        = aws_key_pair.deployer.key_name
  connection {
    host        = self.public_ip
    user        = "ec2-user"
    private_key = var.private_key
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install git -y",
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose;",
      "docker network create tsdb",
      "docker run --restart=unless-stopped --name=tsdb_db -d -p 5432:5432 --network tsdb -e POSTGRES_DB=tsdb -e POSTGRES_USER=${var.db_user} -e POSTGRES_PASSWORD=${var.db_password} -v $(pwd)/data:/var/lib/postgresql/data timescale/timescaledb:latest-pg13",
      "docker run -d --restart=unless-stopped --name=postgres_backup --network tsdb -e SCHEDULE='@daily' -e S3_REGION=${var.region}  -e S3_ACCESS_KEY_ID=${var.access_key} -e S3_SECRET_ACCESS_KEY=${var.secret_key} -e S3_BUCKET=timescale-backup-${var.instance}-${data.aws_caller_identity.current.account_id} -e POSTGRES_DATABASE=tsdb -e TSDB_USER=${var.db_user}  -e POSTGRES_HOST=tsdb_db -e POSTGRES_PASSWORD=${var.db_password} -e S3_PREFIX=backup -e POSTGRES_EXTRA_OPTS='--format=plain --quote-all-identifiers --no-tablespaces --no-owner --no-privileges' schickling/postgres-backup-s3"
    ]
  }
  tags = {
    Name = "tsdb-primary-${var.instance}-${data.aws_caller_identity.current.account_id}"
  }
  depends_on = [
    aws_s3_bucket.timescale_backup_bucket
  ]
}
resource "aws_instance" "replica_1" {
  ami             = "ami-00798d7180f25aac2"
  instance_type   = var.aws_type
  security_groups = ["${aws_security_group.swarm.name}"]
  key_name        = aws_key_pair.deployer.key_name
  connection {
    host        = self.public_ip
    user        = "ec2-user"
    private_key = var.private_key
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install git -y",
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose;",
      "docker network create tsdb",
      "docker run --restart=unless-stopped --name=tsdb_db -d -p 5432:5432 --network tsdb -e POSTGRES_DB=tsdb -e POSTGRES_USER=${var.db_user} -e POSTGRES_PASSWORD=${var.db_password} -v $(pwd)/data:/var/lib/postgresql/data timescale/timescaledb:latest-pg13",
      "docker run -d --restart=unless-stopped --name=postgres_backup --network tsdb -e SCHEDULE='@daily' -e S3_REGION=${var.region}  -e S3_ACCESS_KEY_ID=${var.access_key} -e S3_SECRET_ACCESS_KEY=${var.secret_key} -e S3_BUCKET=timescale-backup-${var.instance}-${data.aws_caller_identity.current.account_id} -e POSTGRES_DATABASE=tsdb -e TSDB_USER=${var.db_user}  -e POSTGRES_HOST=tsdb_db -e POSTGRES_PASSWORD=${var.db_password} -e S3_PREFIX=backup -e POSTGRES_EXTRA_OPTS='--format=plain --quote-all-identifiers --no-tablespaces --no-owner --no-privileges' schickling/postgres-backup-s3"
    ]
  }
  tags = {
    Name = "tsdb-replica-${var.instance}-${data.aws_caller_identity.current.account_id}"
  }
  depends_on = [
    aws_s3_bucket.timescale_backup_bucket
  ]
}
