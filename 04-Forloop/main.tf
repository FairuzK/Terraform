variable "regions"{
    type = list(string)
    default = ["us-east-1", "us-west-2"]
}

locals {
   dev_regions = [for region in var.regions : "${region}-dev"]
}

resource "null_resource" "forloop_example" {
    triggers = {
        # List of development regions
        dev_regions = join(",", local.dev_regions)
    }
}