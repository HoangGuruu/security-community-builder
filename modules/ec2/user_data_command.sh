#!/bin/bash
yum update -y
yum install -y aws-cli nmap netcat-openbsd curl wget

# Configure AWS CLI with attacker credentials
mkdir -p /home/ec2-user/.aws
cat > /home/ec2-user/.aws/credentials << EOF
[default]
aws_access_key_id = ${attacker_access_key}
aws_secret_access_key = ${attacker_secret_key}
EOF

cat > /home/ec2-user/.aws/config << EOF
[default]
region = us-east-1
output = json
EOF

chown -R ec2-user:ec2-user /home/ec2-user/.aws

# Create malicious activity script
cat > /home/ec2-user/malicious_activities.sh << 'EOF'
#!/bin/bash
echo "Starting security simulation activities..."

# 1. Connect to known malicious IPs (will trigger GuardDuty)
echo "Connecting to suspicious IPs..."
curl -m 5 http://198.51.100.1 || true
curl -m 5 http://203.0.113.1 || true
wget -T 5 http://192.0.2.1 || true

# 2. Attempt unauthorized S3 access
echo "Attempting S3 access..."
aws s3 ls s3://${s3_bucket_name} || true
aws s3 cp s3://${s3_bucket_name}/confidential.txt /tmp/ || true

# 3. Attempt unauthorized DynamoDB access
echo "Attempting DynamoDB access..."
aws dynamodb scan --table-name ${dynamodb_table_name} || true

# 4. Generate suspicious DNS queries
echo "Generating suspicious DNS queries..."
nslookup malware.example.com || true
nslookup botnet.example.com || true

# 5. Attempt to access metadata service (IMDS)
echo "Accessing metadata service..."
curl -m 5 http://169.254.169.254/latest/meta-data/iam/security-credentials/ || true

# 6. Create suspicious network connections
echo "Creating suspicious network connections..."
nc -z 8.8.8.8 53 || true
nc -z 1.1.1.1 80 || true

sleep 60
EOF

chmod +x /home/ec2-user/malicious_activities.sh
chown ec2-user:ec2-user /home/ec2-user/malicious_activities.sh

# Create systemd service to run activities periodically
cat > /etc/systemd/system/security-sim.service << EOF
[Unit]
Description=Security Simulation Activities
After=network.target

[Service]
Type=simple
User=ec2-user
ExecStart=/home/ec2-user/malicious_activities.sh
Restart=always
RestartSec=300

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable security-sim.service
systemctl start security-sim.service

# Run initial activities
su - ec2-user -c "/home/ec2-user/malicious_activities.sh" &