#!/bin/bash

# Ask the user for the destination directory
read -p "Enter the destination directory for the Redmine setup: " dest_dir

# Create the directory if it doesn't exist
mkdir -p "$dest_dir"

# Ask for the port number
read -p "Enter the port number you want to run Redmine on (e.g., 3000, 3001, etc.): " port_number

# Ask for the Redmine container name
read -p "Enter a name for the Redmine container: " redmine_container_name

# Ask for the MySQL container name
read -p "Enter a name for the MySQL container: " mysql_container_name

# Extract the .tar.gz file to the destination directory
# Extract to a temporary directory first
temp_dir=$(mktemp -d)
tar -xzf redmine_test_instance.tar.gz -C "$temp_dir"

# Move the contents of the extracted directory to the destination directory
mv "$temp_dir/redmine_test_instance/"* "$dest_dir"

# Remove the temporary directory
rm -rf "$temp_dir"

# Move into the destination directory
cd "$dest_dir"

# Create the docker-compose.yml file
cat <<EOL > docker-compose.yml
version: '3'
services:
$redmine_container_name:
image: redmine:latest
container_name: $redmine_container_name
ports:
- "$port_number:3000"
environment:
REDMINE_DB_MYSQL: $mysql_container_name
REDMINE_DB_DATABASE: redmine_test
REDMINE_DB_USERNAME: redmine
REDMINE_DB_PASSWORD: redmine_password
volumes:
- ./redmine_test_files:/usr/src/redmine/files
depends_on:
- $mysql_container_name

$mysql_container_name:
image: mysql:5.7
container_name: $mysql_container_name
environment:
MYSQL_ROOT_PASSWORD: my-secret-pw
MYSQL_DATABASE: redmine_test
MYSQL_USER: redmine
MYSQL_PASSWORD: redmine_password
volumes:
- ./mysql_test_data:/var/lib/mysql
EOL

# Inform the user that the docker-compose.yml has been created
echo "docker-compose.yml has been created in $dest_dir"

# Start the containers
docker-compose up -d

# Inform the user that the setup is complete
echo "Redmine has been set up at http://localhost:$port_number"
