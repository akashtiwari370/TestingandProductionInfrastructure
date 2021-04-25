
resource "aws_vpc" "main" {

  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = "true"
  tags = {
    Name = "project-vpc"
  }
}

#########################

resource "aws_subnet" "subnet1" {

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "terra-subnet-1"
  }
}

########################

resource "aws_subnet" "subnet2" {

  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "terra-subnet-2"
  }
}

#####################

resource "aws_internet_gateway" "gw" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terra-gw"
  }
}

#########################

resource "aws_route_table" "r" {

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "main"
  }
}

#############################

resource "aws_route_table_association" "a" {

  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r.id
}

########################################

resource "aws_route_table_association" "b" {

  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.r.id
}


###################################

resource "aws_security_group" "allowssh" {

  name        = "allowssh"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terra-sg"
  }
}

########################################

resource "aws_db_instance" "mysqldb" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  storage_type         = "gp2"
  name                 = "mydb"
  username             = "aki"
  password             = "redhat123"
  port                 = "3306"
  publicly_accessible  = true
  skip_final_snapshot  = true
  parameter_group_name = "default.mysql5.7"

  tags = {
    Name = "database-1"
  }
}

#############################################################



resource "aws_iam_role" "cluster_role" {
  name = "frontend_cluster_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eksClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}
resource "aws_iam_role_policy_attachment" "eksServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster_role.name
}



resource "aws_eks_cluster" "aws_eks" {
  name     = "frontend_cluster"
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  }

  tags = {
    Name = "cluster-1"
  }
}

resource "aws_iam_role" "eks_nodes_policy" {
  name = "eks-node-group"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }  
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes_policy.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes_policy.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes_policy.name
}


resource "aws_eks_node_group" "eks-nodes" {
  cluster_name    = aws_eks_cluster.aws_eks.name
  node_group_name = "eks-group"
  node_role_arn   = aws_iam_role.eks_nodes_policy.arn
  subnet_ids      = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
  ]

}


#########################################################################################3


