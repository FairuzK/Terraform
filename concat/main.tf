locals {
    list_one=["dev", "prod"]
    list_two=[ "test", "env"]

    mergerd_list=concat(local.list_one, local.list_two)
}

resource "null_resource" "concat_example" {
    triggers = {
        merged_list = join(",", local.mergerd_list)
    }
}