variable "SUBID"  {
  type = string
}

variable "CLIENTID" {
  type = string
}

variable "CERTPATH" {
  type= string
}

variable "CERTPASS" {
  type = string
}

variable "TENANTID" {
  type = string
}

variable "location" {
  type = "string"
  default = "eastus"
  description = "Specify a location. See: az account list-locations -o table"
}

variable "tags" {
  type = "map"
  description = "A list of tags associated to all resources."
  default = {
    maintained_by = "terraform"
  }
}


