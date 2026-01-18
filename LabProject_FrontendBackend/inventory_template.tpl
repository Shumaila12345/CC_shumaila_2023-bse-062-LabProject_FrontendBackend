[frontend]
${frontend_ip} ansible_user=ec2-user

[backends]
${backend_0_ip} ansible_user=ec2-user backend_name=backend-0 backend_private_ip=${backend_0_private_ip}
${backend_1_ip} ansible_user=ec2-user backend_name=backend-1 backend_private_ip=${backend_1_private_ip}
${backend_2_ip} ansible_user=ec2-user backend_name=backend-2 backend_private_ip=${backend_2_private_ip}

[all:vars]
ansible_ssh_private_key_file=${private_key_path}
ansible_python_interpreter=/usr/bin/python3
