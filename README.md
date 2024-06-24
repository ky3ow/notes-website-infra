```bash
terraform login # login to hcp terraform, where remote state is stored

terraform apply -auto-approve
```

```bash
./generate-inventory.sh

ansible-playbook -i inventory.ini playbook.yml
```
