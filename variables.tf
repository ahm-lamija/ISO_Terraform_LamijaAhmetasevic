variable "aws_region" {
  description = "AWS regija u kojoj se kreiraju resursi"
  type        = string
  default     = "us-east-1"
}

variable "db_username" {
  description = "Korisnicko ime za RDS MySQL bazu"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Lozinka za RDS MySQL bazu"
  type        = string
  default     = "Lozinka123"
}

variable "db_name" {
  description = "Naziv pocetne baze podataka"
  type        = string
  default     = "projekat2_db"
}
