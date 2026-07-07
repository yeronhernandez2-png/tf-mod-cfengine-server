output "public_subnet_id" {
  description = "Id of the public subnet (calculated from the subnet name)"
  value = data.aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Id of the private subnet (calculated from the subnet name)"
  value = data.aws_subnet.private.id
}

output "security_group_id" {
  description = "Id of the security group for the instance (calculated from the security group name)"
  value = data.aws_security_group.cfserver.id
}

output "debian_ami_id" {
  description = "Id of the latest AMI of Debian 13 for amd64 processors (this is always the ID of the latest AMI, no matter how you set in the ami_id input variable)"
  value = data.aws_ami.debian_official.id
}

output "eip_address" {
  description = "Public (elastic) IP for the instance"
  value = aws_eip.cfengine.public_ip
}

output "eip_name" {
  description = "DNS name associated to the public (elastic) IP for the instance"
  value = aws_eip.cfengine.public_dns
}

output "private_ip" {
  description = "Private IP for the instance"
  value = local.private_ip
}

output "ssh_command" {
  description = "SSH command to run to connect to the instance via SSH"
  value = "ssh admin@${aws_eip.cfengine.public_dns}"
}

output "spot_instance_request_id" {
  description = "Spot instance request id (null if on-demand instances are used)"
  value = local.spot_instance_request_id
}

output "instance_id" {
  description = "Id for the instance running the service"
  value = local.instance_id
}
import requests
import time
import os
import random
from datetime import datetime

def get_current_timestamp():
    return datetime.now().strftime('%Y-%m-%d %H:%M:%S')

def log(message):
    print(f"[{get_current_timestamp()}] {message}")
    with open("/var/log/internet-check.log", "a") as f:
        f.write(f"[{get_current_timestamp()}] {message}\n")

def check_internet():
    retries = 8
    urls = ["http://google.com", "http://1.1.1.1", "http://cfeteit.net"]
    
    log("Iniciando chequeo de internet (modo XXX persistent)")

    for count in range(retries):
        url = random.choice(urls)
        try:
            response = requests.get(url, timeout=8)
            if response.status_code == 200:
                log("✅ Internet OK")
                return True
        except:
            log(f"❌ Intento {count+1}/{retries} fallido con {url}")
        
        time.sleep(20 + random.randint(5, 25))

    log("🔴 Sin internet después de múltiples intentos → Rebooting...")
    os.system('sudo reboot')
    return False

if __name__ == "__main__":
    check_internet()
