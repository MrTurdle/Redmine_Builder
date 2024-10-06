#!/bin/bash

# Update the package lists
echo "Updating package lists..."
sudo apt update -y

# Upgrade existing packages
echo "Upgrading installed packages..."
sudo apt upgrade -y

# Install Docker
echo "Installing Docker..."
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io -y

# Ensure Docker is started and enabled
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose installation
docker-compose --version

# Install tar utility (if not installed)
echo "Installing tar utility..."
sudo apt install tar -y

# Optional: Add the current user to the docker group to avoid needing sudo for Docker commands
echo "Adding current user to Docker group..."
sudo usermod -aG docker $USER

# Inform the user to restart the shell for group changes to take effect
echo "You need to restart your shell or log out and back in for the Docker group changes to take effect."

# Provide information to the user
echo "All dependencies installed. You can now run the Redmine builder script."
