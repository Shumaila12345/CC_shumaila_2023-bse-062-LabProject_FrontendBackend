# Lab Project: Terraform + Ansible - Frontend Backend Nginx HA

**Student Name:** Shumaila  
**Roll Number:** 2023-BSE-062  
**Course:** Cloud Computing  

## 🏗️ Architecture Overview

- **1 Nginx Frontend**: Load balancer and reverse proxy
- **3 Apache HTTPD Backends**: 2 active + 1 backup
- **AWS Infrastructure**: VPC, Subnet, Security Groups, EC2
- **Automation**: Terraform + Ansible

## 🚀 Quick Start
```bash
# 1. Configure AWS
aws configure

# 2. Generate SSH Key
ssh-keygen -t ed25519 -f ~/.ssh/terraform_key -N ""

# 3. Deploy
terraform init
terraform apply -auto-approve

# 4. Test
terraform output test_url
```

## 📁 Project Structure
```
LabProject_FrontendBackend/
├── main.tf
├── variables.tf
├── locals.tf
├── outputs.tf
├── inventory_template.tpl
├── ansible/
│   ├── ansible.cfg
│   ├── playbooks/site.yaml
│   └── roles/
│       ├── backend/
│       └── frontend/
└── README.md
```

## 🧹 Cleanup
```bash
terraform destroy -auto-approve
```

---
**Last Updated**: January 2026
