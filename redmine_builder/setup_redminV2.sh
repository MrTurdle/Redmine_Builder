#!/bin/bash

# Define the template folder path
template_folder="./templates"

# Check if the template folder exists
if [ ! -d "$template_folder" ]; then
    echo "Template folder not found. Please ensure the templates folder is in the correct location."
    exit 1
fi

# Find all .tar.gz files in the template folder
templates=($(ls "$template_folder"/*.tar.gz 2>/dev/null))

# Check if any templates were found
if [ ${#templates[@]} -eq 0 ]; then
    echo "No templates found in the template folder."
    exit 1
fi

# Display a menu for template selection
echo "Select a template to use:"
for i in "${!templates[@]}"; do
    echo "$((i+1)). ${templates[$i]##*/}"  # Show only the filename, not the full path
done

# Ask the user to choose a template
read -p "Enter the number of the template to use: " template_choice

# Validate the user's choice
if ! [[ "$template_choice" =~ ^[0-9]+$ ]] || [ "$template_choice" -lt 1 ] || [ "$template_choice" -gt ${#templates[@]} ]; then
    echo "Invalid selection. Exiting."
    exit 1
fi

# Get the selected template file
selected_template="${templates[$((template_choice-1))]}"
template_name=$(basename "$selected_template" .tar.gz)  # Remove .tar.gz from filename

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

# Ask for the database username (default is redmine)
read -p "Enter the username to be used for Redmine and MySQL (default is redmine): " db_username
db_username=${db_username:-redmine}  # If user doesn't enter a value, use "redmine"

# Ask for the database password (default is redmine_password)
read -p "Enter the password to be used for Redmine and MySQL (default is redmine_password): " db_password
db_password=${db_password:-redmine_password}  # If user doesn't enter a value, use "redmine_password"

# Extract the selected template to the destination directory
# Extract to a temporary directory first
temp_dir=$(mktemp -d)
tar -xzf "$selected_template" -C "$temp_dir"

# Move the contents of the extracted directory to the destination directory
mv "$temp_dir"/* "$dest_dir"

# Remove the temporary directory
rm -rf "$temp_dir"

# Move into the destination directory
cd "$dest_dir"

# Create the docker-compose.yml file dynamically, adjusting the volume paths based on the template name
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
      REDMINE_DB_DATABASE: $template_name
      REDMINE_DB_USERNAME: $db_username
      REDMINE_DB_PASSWORD: $db_password
    volumes:
      - ./${template_name}_files:/usr/src/redmine/files
    depends_on:
      - $mysql_container_name

  $mysql_container_name:
    image: mysql:5.7
    container_name: $mysql_container_name
    environment:
      MYSQL_ROOT_PASSWORD: my-secret-pw
      MYSQL_DATABASE: $template_name
      MYSQL_USER: $db_username
      MYSQL_PASSWORD: $db_password
    volumes:
      - ./${template_name}_mysql_data:/var/lib/mysql
EOL

# Inform the user that the docker-compose.yml has been created
echo "docker-compose.yml has been created in $dest_dir"

# Start the containers
docker-compose up -d

# Inform the user that the setup is complete
echo "Redmine has been set up at http://localhost:$port_number"
