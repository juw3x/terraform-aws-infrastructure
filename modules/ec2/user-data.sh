#!/bin/bash
# User data script for EC2 instances

# Update system
yum update -y

# Install necessary packages
yum install -y python3 python3-pip nginx

# Create a simple Python web application
cat > /home/ec2-user/app.py << 'EOF'
import http.server
import socketserver
import os

PORT = 80
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'production')
PROJECT = os.environ.get('PROJECT', 'devops-infrastructure')

class MyHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>{PROJECT} - {ENVIRONMENT}</title>
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                }}
                .container {{
                    background: white;
                    padding: 40px;
                    border-radius: 10px;
                    box-shadow: 0 10px 30px rgba(0,0,0,0.3);
                    text-align: center;
                }}
                h1 {{
                    color: #667eea;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>{PROJECT}</h1>
                <p>Environment: {ENVIRONMENT}</p>
                <p>Status: Running on EC2</p>
            </div>
        </body>
        </html>
        """
        self.wfile.write(html.encode())

with socketserver.TCPServer(("", PORT), MyHandler) as httpd:
    print(f"Server running on port {PORT}")
    httpd.serve_forever()
EOF

# Create systemd service for the application
cat > /etc/systemd/system/webapp.service << 'EOF'
[Unit]
Description=Python Web Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user
ExecStart=/usr/bin/python3 /home/ec2-user/app.py
Restart=always
Environment=ENVIRONMENT=${environment}
Environment=PROJECT=${project}

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the service
systemctl daemon-reload
systemctl start webapp
systemctl enable webapp

# Configure Nginx as reverse proxy
cat > /etc/nginx/conf.d/webapp.conf << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Restart Nginx
systemctl restart nginx
systemctl enable nginx
