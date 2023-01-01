resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true



  tags = {
    "Name" = "dev"
  }

}

//creating public subnet 

resource "aws_subnet" "my_vpc_publicsubnet" {
  vpc_id                  = aws_vpc.my_vpc.id //appending id of VPC 
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  //labeling of vpc
  tags = {
    "name" = "dev-public"
  }

}

//creating internet gateway 

resource "aws_internet_gateway" "my_vpc_ig" {

  vpc_id = aws_vpc.my_vpc.id
  tags = {
    "Name" = "igw"
  }
}

//creating route table for vpv

resource "aws_route_table" "my_vpc_rt" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    "name" = "my_vpc_rt"
  }

}

//specifing route 

resource "aws_route" "name" {
  route_table_id         = aws_route_table.my_vpc_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_vpc_ig.id

}


// connecting vpc withh route table with route table association 

resource "aws_route_table_association" "my_vpc_rta" {
  subnet_id      = aws_subnet.my_vpc_publicsubnet.id
  route_table_id = aws_route_table.my_vpc_rt.id
}



//creating security group for vpc
resource "aws_security_group" "my_vpc_sg" {
  name        = "dev_sg"
  description = "dev security grp"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

//creating a key pair through ssh-keygen ; then assigning a key pair 
resource "aws_key_pair" "my_vpc_key" {
    key_name = "my_vpc_key"
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM5+B6p87j5CtmHrAsUBo+oJ+uNEv6+IAN6VSj3pFrXW"
  
}


//ec2 instance configuration 

resource "aws_instance" "dev_node" {
    instance_type = "t2.micro"
    ami = data.aws_ami.server_ami.id
    key_name = aws_key_pair.my_vpc_key.id
    vpc_security_group_ids = [ aws_security_group.my_vpc_sg.id ]
    subnet_id = aws_subnet.my_vpc_publicsubnet.id
    user_data = file("userdata.tpl")



    tags = {
      "Name" = "dev-node"  //instance name 

    }

    
    root_block_device {
      volume_size = 10 //specifing root volume to 10 
    }
}