variable "regions"{
    type = list(string)
    default = ["us-east-1", "us-west-2"]
}

locals {
    # Create a new list of development regions by appending "-dev" to each region in the input list
   dev_regions = [for region in var.regions : "${region}-dev"]
}

    # Line below is used to demonstrate the for loop in Terraform. It creates a new list of development regions by appending "-dev" to each region in the input list. The resulting list is stored in the local variable "dev_regions".
resource "null_resource" "forloop_example" {
    triggers = {
        # List of development regions
        dev_regions = join(",", local.dev_regions)
    }
}