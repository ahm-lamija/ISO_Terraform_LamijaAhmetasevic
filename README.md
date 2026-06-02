# AWS Infrastruktura preko Terraform-a

Ovaj repo sadrzi Terraform konfiguraciju za automatsko podizanje visoko dostupne AWS infrastrukture. 
## Resursi koje Terraform kreira:
* **VPC:** Prilagodjena mreza sa 2 javna subneta (za Load Balancer i EC2) i 2 privatna subneta (za RDS bazu).
* **Security Groups:** Striktna kontrola pristupa (Svijet -> ALB na portu 80 -> EC2 na portu 5000 -> RDS na portu 3306).
* **EC2 Instance:** 2 servera (Amazon Linux 2023) unutar javnih subneta sa automatskom instalacijom Docker-a i pokretanjem aplikacije kroz User Data skriptu.
* **RDS MySQL:** Baza podataka smjestena u izolovani privatni subnet.
* **Application Load Balancer (ALB):** Sa pripadajucom Target Grupom za distribuciju saobracaja i Health Check provjerom na rutu `/api/proizvodi`.

## Uputstvo za pokretanje i testiranje

### Preduslovi:
* Instaliran [Terraform](https://developer.hashicorp.com/terraform/downloads)
* Konfigurisane AWS akreditacije preko AWS CLI-ja (`aws configure`)

### Koraci za deployment:

1. **Inicijalizacija projekta** (Preuzimanje potrebnih AWS provajdera i modula):
   terraform init
2. **Pregled planiranih izmjena** (Provjera sta ce se tacno napraviti na AWS-u):
   terraform plan
3. **Kreiranje infrastrukture** (Automatsko pokretanje svih servisa na cloud-u):
   terraform apply --auto-approve

Nakon zavrsenog procesa Terraform ce u terminalu ispisati load_balancer_dns preko kojeg je moguc pristup aplikaciji.

## Ciscenje resursa nakon testiranja

terraform destroy --auto-approve
