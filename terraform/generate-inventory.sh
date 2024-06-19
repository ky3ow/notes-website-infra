#!/usr/bin/env bash

echo "Generating inventory.ini for Ansible.."

vm_ip=$(terraform output vm_ips 2>/dev/null | tr -d '"')

if [ $? -ne 0 ]; then
		echo "Error: Failed to retrieve VM IPs from Terraform"
		exit 1
fi

echo "[azure]" > inventory.ini
echo "$vm_ip ansible_user=blog" >> inventory.ini

echo "Success!"
