

variable "project_name" {
  description = "The name of the project"
  type        = string
}

# Generate a random integer to create a globally unique name
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

locals {
  random_number       = random_integer.ri.result
  resource_group_name = "${var.project_name}-rg-${local.random_number}"
}
