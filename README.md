# AWS Cloud Deployment i Terraform Automatizacija

Ovaj repo sadrži uputstva za pokretanje i testiranje aplikacije na AWS platformi kroz ručni rad i Terraform automatizaciju. 

## Softverski preduslovi
Prije početka rada, na lokalnoj mašini instalirajte sljedeće alate: Terraform, AWS CLI v2, Docker Desktop i Git.

## Koraci za pokretanje ručnog deployment-a

# Kreiranje VPC mreže: 
Otvorite VPC Dashboard, kliknite na Create VPC (opcija VPC and more), definišite 2 javna i 2 privatna subneta kroz dvije zone (us-east-1a i us-east-1b) i kliknite Create.

# Kreiranje S3 Bucketa: 
Otvorite S3 Dashboard, kliknite na Create bucket, unesite unikatno ime za bucket, a ostale opcije ostavite na defaultu i kreirajte bucket.

# Kreiranje RDS MySQL Baze: 
Otvorite RDS Dashboard, kliknite na Create database. Izaberite MySQL i Free Tier šablon. Postavite korisničko ime na admin, unesite lozinku, a pod Additional configuration upišite naziv početne baze: projekat2_db. Smjestite bazu u privatne subnete i kreirajte je. U sigurnosnoj grupi baze nakon kreiranja dozvolite port 3306 za sve adrese.

# Lansiranje EC2 Servera: 
Otvorite EC2 Dashboard, kliknite na Launch instances i postavite broj instanci na 2. Izaberite Amazon Linux 2023 i t2.micro veličinu. Rasporedite instance u javne subnete i omogućite javne IP adrese. Na dnu stranice, pod Advanced Details i User Data, zalijepite skriptu za instalaciju Dockera:
#!/bin/bash
dnf update -y
dnf install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Pokretanje Docker kontejnera: 
Povežite se na prvu instancu preko EC2 Instance Connect-a. U terminalu pokrenite svoj backend kontejner i proslijedite mu adresu baze:
docker run -d -p 5000:5000 -e DB_HOST=projekt2-baza.cfjj96d2xi2r.us-east-1.rds.amazonaws.com -e DB_USER=admin -e DB_PASSWORD=Lozinka123 -e DB_NAME=projekat2_db --name moj-backend lamijaahm/projekat2-backend:latest
Ponovite isti postupak i na drugoj EC2 instanci.

# Podešavanje Load Balancera: 
Kreirajte Target Grupu za instance na portu 5000 sa health check rute /api/proizvodi i u nju dodajte obje instance. Zatim kreirajte Application Load Balancer na portu 80 kroz javne subnete i usmjerite ga na tu Target Grupu.



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
Kako bi se izbjegli nezeljeni troskovi, kompletna infrastruktura se moze obrisati komandom
terraform destroy --auto-approve
