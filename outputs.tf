output "load_balancer_dns" {
  description = "Javni URL preko kojeg se pristupa aplikaciji"
  value       = aws_lb.moj_alb.dns_name
}

output "rds_endpoint" {
  description = "Endpoint (link) za povezivanje na RDS bazu"
  value       = aws_db_instance.mysql.endpoint
}
