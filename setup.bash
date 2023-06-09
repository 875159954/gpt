#!/bin/bash


# Prompt the user before modifying the Nginx configuration file
read -p "!!!!!WARNING!!!!! This script will modify the Nginx configuration file. Are you sure you want to continue? (yes/n): " answer

if [[ $answer != "yes" ]]; then
  echo "Exiting script."
  exit 1
fi



# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    # Install Docker
    
    read -p "you need to REBOOT after Docker installation. (yes/n): " answer

    if [[ $answer != "yes" ]]; then
      echo "Exiting script."
      exit 1
    fi
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    # Add current user to docker group
    sudo usermod -aG docker $USER
    newgrp docker

    # Set the reboot flag
    echo "Docker have been installed. Please reboot the system and run the script again."
    echo "Docker have been installed. Please reboot the system and run the script again."
    echo "Docker have been installed. Please reboot the system and run the script again."
    
    exit 1
fi

# allow traffic to pass http port 80 on ubuntu.
sudo ufw allow http

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    # 1. Install nginx
    sudo apt install -y nginx

    # 2. Configure nginx to relay port 80 to localhost:3000
    sudo bash -c "cat > /etc/nginx/sites-available/default <<- 'EOF'
server {
    listen 80;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF"

    # 3. Restart nginx
    sudo systemctl restart nginx


fi




# 4. create .env.local file and ask user for GPT_API_KEY

if [ ! -f ".env.local" ]; then
    touch .env.local
    echo -n "Please enter your GPT_API_KEY: "
    read GPT_API_KEY
    echo "GPT_API_KEY=$GPT_API_KEY" >> .env.local
fi

check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker compose"
    else
        echo "Neither docker-compose nor docker compose found. Please install one of them."
        exit 1
    fi
}

# Check if Docker is installed
# ... (rest of the script remains unchanged) ...

# 5. Run docker-compose with build and detached options
check_docker_compose
$DOCKER_COMPOSE_CMD up --build -d
