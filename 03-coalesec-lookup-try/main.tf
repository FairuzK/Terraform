
# Setting a default value for a variable and using the coalesce function to provide a fallback value in case the variable is not set.
#======Setting missing values with coalesce()========

# variable "user_defined_name" {
#   type = string
#   default = "" # 0r null, if you like, but null is not a string, so it will cause an error if you try to use it in a string context
# }

# resource "aws_instance" "example" {
#   ami           = "ami-test"
#   instance_type = "t2.micro"

#   tags = {
#     Name = coalesce(var.user_defined_name, "default-name")
#   }
# }

# ==== Providing a default value for a variable and using the lookup function to retrieve a value from a map, with a fallback value in case the key is not found.
# data external "my_data" {
#   program = ["python3", "${path.module}/example.sh"]
#   query = {
#     name= "some api"
#   }
# }

# resource "aws_instance" "example" {
#   ami           = "ami-test"
#   instance_type = "t2.micro"

#   tags = {
#     Name        = coalesce(lookup(data.external.my_data.result, "name", null), "default-name")
#     Description = coalesce(lookup(data.external.my_data.result, "description", null), "No description available")
#   }
# }

# Enviroment variable example
variable "enviroment_settings" {
  type = map(string)
  default = {  
  }
}

# Local values to store the results of the coalesce and lookup functions
locals {
    config_file_value = try(
      jsondecode(file("${path.module}/config.json")).my_setting,
      null
    )
    enviroment_value = lookup(var.enviroment_settings, "my_setting", null)  
}
# Line 1: The coalesce function is used to return the first non-null value from a list of values. In this case, it checks the local.config_file_value and local.enviroment_value, and if both are null, it returns "default-value".
resource "null_resource" "example_config" {
    triggers = {
        seeting_in_use = coalesce(
            local.config_file_value, local.enviroment_value, "default-value")
    } 
}
  