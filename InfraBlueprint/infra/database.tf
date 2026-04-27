resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Allow PostgreSQL traffic from web-sg only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from web-sg"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "vela-payments-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "vela-payments-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier             = "vela-payments-db"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "veladb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "vela-payments-db"
  }
}
