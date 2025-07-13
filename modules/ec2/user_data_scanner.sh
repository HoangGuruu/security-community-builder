#!/bin/bash
yum update -y
yum install -y nmap netcat-openbsd hping3 curl wget

# Create port scanning script
cat > /home/ec2-user/port_scanner.sh << 'EOF'
#!/bin/bash
echo "Starting port scanning activities..."

# Get current instance IP for reference
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Scanner instance IP: $INSTANCE_IP"

# 1. Port scan common services (will trigger GuardDuty)
echo "Scanning common ports..."
nmap -sS -O -p 22,23,25,53,80,110,143,443,993,995,3389 8.8.8.8 || true
nmap -sS -p 1-1000 1.1.1.1 || true

# 2. Aggressive scan patterns
echo "Performing aggressive scans..."
nmap -sS -sV -A -p- --script vuln 8.8.4.4 || true

# 3. UDP scans
echo "Performing UDP scans..."
nmap -sU -p 53,67,68,123,161 8.8.8.8 || true

# 4. Stealth scans
echo "Performing stealth scans..."
nmap -sF -p 80,443 google.com || true
nmap -sX -p 22,80 amazon.com || true

# 5. Network reconnaissance
echo "Performing network reconnaissance..."
nmap -sn 10.0.1.0/24 || true

# 6. Banner grabbing
echo "Banner grabbing..."
nc -v -w 3 google.com 80 << 'BANNER'
GET / HTTP/1.1
Host: google.com

BANNER

# 7. Suspicious connection attempts
echo "Making suspicious connections..."
for port in 22 23 25 53 80 110 143 443 993 995 3389; do
    nc -z -v -w 1 198.51.100.1 $port 2>/dev/null || true
    nc -z -v -w 1 203.0.113.1 $port 2>/dev/null || true
done

sleep 60
EOF

chmod +x /home/ec2-user/port_scanner.sh
chown ec2-user:ec2-user /home/ec2-user/port_scanner.sh

# Create systemd service for scanning activities
cat > /etc/systemd/system/port-scanner.service << EOF
[Unit]
Description=Port Scanner Security Simulation
After=network.target

[Service]
Type=simple
User=ec2-user
ExecStart=/home/ec2-user/port_scanner.sh
Restart=always
RestartSec=600

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable port-scanner.service
systemctl start port-scanner.service

# Run initial scan
su - ec2-user -c "/home/ec2-user/port_scanner.sh" &