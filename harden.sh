#!/bin/bash

# Function to check and regenerate SSH keys
check_and_regenerate_keys() {
    if sudo sha256sum /etc/ssh/ssh_host* 2>/dev/null; then
        echo "Existing SSH keys found. Regenerating new keys..."
        sudo rm /etc/ssh/ssh_host*
        sudo dpkg-reconfigure openssh-server
        echo "New SSH keys generated successfully."
    else
        echo "No existing SSH keys found."
    fi
}

# Function to disable terminal history
disable_terminal_history() {
    echo "Disabling terminal history..."
    unset HISTFILE
    history -c
    echo "Terminal history disabled."
}

# Function to prompt user to change password
prompt_user_password_change() {
    echo "Prompting user to change password..."
    sudo chage -d 0 "$SUDO_USER"
    echo "User prompted to change password."
}

# Function to update SSH configuration including port change
update_ssh_configuration() {
    echo "Updating SSH configuration..."
    config_file="/etc/ssh/sshd_config"
    # Backup the original sshd_config file
    cp "$config_file" "$config_file.bak"
    # Update parameters
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$config_file"
    sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' "$config_file"
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$config_file"
    sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$config_file"
    sed -i 's/^UsePAM.*/UsePAM yes/' "$config_file"
    # Change SSH service port
    sed -i 's/^#Port 22/Port 666/' "$config_file"
    echo "SSH configuration updated successfully. SSH service port changed to 666."
}

# Function to enable SSH service at boot
enable_ssh_at_boot() {
    echo "Enabling SSH service at boot..."
    sudo systemctl enable ssh
    echo "SSH service enabled at boot."
}

# Function to apply OPSEC rules
apply_opsec_rules() {
    echo "Applying OPSEC rules..."
    sudo iptables -I INPUT 1 -p tcp -s 0.0.0.0/0 --dport 50050 -j DROP
    sudo iptables -I INPUT 1 -p tcp -s 127.0.0.1 --dport 50050 -j ACCEPT
    sudo iptables -I INPUT 2 -p tcp -s 0.0.0.0/0 --dport 60000 -j DROP
    sudo iptables -I INPUT 2 -p tcp -s 127.0.0.1 --dport 60000 -j ACCEPT
    sudo service iptables start
    sudo iptables-save > /etc/iptables/rules.v4
    echo "OPSEC rules applied successfully."
}

# Display hardening message
echo "Hardening System... Preparing for a more secure environment."

# Update SSH configuration
update_ssh_configuration

# Enable SSH service at boot
enable_ssh_at_boot

# Apply OPSEC rules
apply_opsec_rules

# Check and regenerate SSH keys
check_and_regenerate_keys

# Disable terminal history
disable_terminal_history

# Prompt user to change password
prompt_user_password_change

# Restart SSH service
service ssh restart

# Display completion message
echo "Hardening Complete! Your system is now more secure."
