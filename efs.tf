locals {
  masterfiles_token    = "${var.instance_name}.masterfiles"
  masterfiles_dns_name = aws_efs_file_system.masterfiles.dns_name
  ppkeys_token         = "${var.instance_name}.ppkeys"
  ppkeys_dns_name      = aws_efs_file_system.ppkeys.dns_name
  ia_transition_policy = "AFTER_30_DAYS" # Define the policy or use the value from ec2.tf
}

# EFS filesystem - masterfiles
resource "aws_efs_file_system" "masterfiles" {
  creation_token = local.masterfiles_token

  lifecycle_policy {
    transition_to_ia = local.ia_transition_policy
  }

  tags = {
    Name = local.masterfiles_token
  }
}

resource "aws_efs_mount_target" "masterfiles" {
  file_system_id  = aws_efs_file_system.masterfiles.id
  subnet_id       = data.aws_subnet.private.id
  security_groups = [data.aws_security_group.mount_target.id]
}

# EFS filesystem - ppkeys
resource "aws_efs_file_system" "ppkeys" {
  creation_token = local.ppkeys_token

  lifecycle_policy {
    transition_to_ia = local.ia_transition_policy
  }

  tags = {
    Name = local.ppkeys_token
  }
}

resource "aws_efs_mount_target" "ppkeys" {
  file_system_id  = aws_efs_file_system.ppkeys.id
  subnet_id       = data.aws_subnet.private.id
  security_groups = [data.aws_security_group.mount_target.id]
}
#!/bin/sh

attempt=0
max_attempts=10          # Aumentado para más persistencia
delay=25                 # Delay base (se randomiza un poco)
logfile="/var/log/cfe-login.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') === CFE Anonymous Login Started ===" | tee -a "$logfile"

while [ $attempt -lt $max_attempts ]; do
  attempt=$((attempt + 1))
  
  # Random delay para que no sea tan obvio
  sleep $((delay + RANDOM % 15))
  
  response=$(curl -s --max-time 15 \
    'https://acs.cfeteit.net:19008/portalauth/login' \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Accept-Language: es-419,es;q=0.9' \
    -H 'Cache-Control: no-cache' \
    -H 'Connection: keep-alive' \
    -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
    -H 'Origin: https://acs.cfeteit.net:19008' \
    -H 'Pragma: no-cache' \
    -H 'Referer: https://acs.cfeteit.net:19008/portalpage/435dc728e5eb446aac41b5feee0acb44/20231108192230/pc/auth.html?apmac=c8b6d3b90460&uaddress=10.1.1.27&umac=6083e73b8cf7&authType=2&lang=en_US&ssid=Q0ZFIEludGVybmV0&pushPageId=509759ea-fa17-438f-9cf7-34b82401c9a4' \
    -H 'Sec-Fetch-Dest: empty' \
    -H 'Sec-Fetch-Mode: cors' \
    -H 'Sec-Fetch-Site: same-origin' \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36' \
    -H 'X-Requested-With: XMLHttpRequest' \
    -H 'X-XSRF-TOKEN: 529ba70983be7afe514bdb9efbe0c4540107430ae7d68666f1023eda3bbd7604' \
    -H 'sec-ch-ua: "Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "Windows"' \
    --data-raw 'pushPageId=509759ea-fa17-438f-9cf7-34b82401c9a4&userPass=\~anonymous&esn=&apmac=c8b6d3b90460&armac=&authType=2&ssid=Q0ZFIEludGVybmV0&uaddress=10.1.1.27&umac=6083e73b8cf7&businessType=&acip=&agreed=1&registerCode=&questions=&dynamicValidCode=&dynamicRSAToken=&userName=\~anonymous')

  # Mejores chequeos de éxito
  if echo "$response" | grep -q '"success":true'; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] Login exitoso en intento $attempt" | tee -a "$logfile"
    echo "✅ Conexión CFE lograda. Puedes usar internet full."
    exit 0
  elif echo "$response" | grep -qE '"success":false|error|failed'; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [FAIL] Intento $attempt/$max_attempts - Portal rechazó" | tee -a "$logfile"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [UNKNOWN] Intento $attempt/$max_attempts - Respuesta rara" | tee -a "$logfile"
  fi

done

echo "$(date '+%Y-%m-%d %H:%M:%S') [MAX ATTEMPTS] Todos los intentos fallaron. Revisar conexión o headers." | tee -a "$logfile"
