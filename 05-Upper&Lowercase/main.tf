variable words {
  type = list(string)
  default = ["Hello", "World"]

}
locals {
  # Create a new list of lowercase words by converting each word in the input list to lowercase
  lowercase = [for word in var.words : lower(word)]
  lower = join(",", local.lowercase)
  uppercase = [for word in var.words : upper(word)]
  upper = join(",", local.uppercase)


}
resource "null_resource" "lowercase_example" {
  triggers = {
    # List of lowercase words
    result_lowercase = local.lower
    # List of uppercase words
    result_uppercase = local.upper
  }
}