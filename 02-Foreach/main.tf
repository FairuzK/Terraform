locals {
  instances ={
    dev1= {
        instance_type= "t3.micro"
        ami_id="ami_dev1"
    }
    dev2= {
        instance_type= "t2.micro"
        ami_id="ami_dev2"
    }
    dev3= {
        instance_type= "t3.micro"
        ami_id="ami_dev3"
    }
  }
}
resource "aws_instance" "this" {
    for_each = local.instances

    ami           = each.value.ami_id
    instance_type = each.value.instance_type

    tags = {
        Name = each.key
    }

  
}