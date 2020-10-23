# terraform-jenkins
Deploys a Jenkins Master and Workers across two AWS regions with full automation from VPC upwards, using Terraform and Ansible. Jenkins is publicly accessible via ALB with ACM provided certificates, and Route53 DNS.

All the code here is from testing and does NOT represent best practice for deployment or security.

Note: Jenkins is setup with a default login of admin/password so change it quickly and don't leave it running.

Quickstart:

yum -y install python3-pip graphviz

pip3 install awscli

pip3 install ansible

pip3 install boto3

wget https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip

unzip terraform_0.12.29_linux_amd64.zip

mv terraform /usr/bin

chmod 0750 /usr/bin/terraform


Create an IAM user (Or role if running from existing instance)

aws configure - set region us-east-1 and json format (Writes .aws/config and .aws/credentials)

Create S3 bucket for terraform state, update in backend.tf

Create Route53 record set for your domain and update dns-name in variables.tf

Create SSH keypair with no passphrase, ssh-keygen -t rsa


terraform init

terraform plan

terraform apply

terraform destroy

terraform graph | dot -Tpng -o ~/tf.png

ansible-playbook install_jenkins_master.yml -e "passed_in_hosts=localhost" --syntax-check

...etc
