#!/bin/bash

echo "---------- Setting Up Andrew Arcade ----------"

USER="arcade"

if id "$USER" &>/dev/null; then
    echo "User '$USER' already exists."
else
    echo "User '$USER' does not exist. Creating..."
    
    sudo useradd -m "$USER"
    
    if [ $? -eq 0 ]; then
        echo "User '$USER' created successfully."
    else
        echo "Failed to create user '$USER'."
        exit 1
    fi
fi