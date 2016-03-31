provision: project-id.txt
	PROJECT_ID=`cat project-id.txt`
	TF_VAR_project=$(PROJECT_ID) terraform apply

configure:
	ansible-playbook -i /usr/local/bin/terraform-inventory site.yml


destroy: project-id.txt
	TF_VAR_project=$(PROJECT_ID) terraform destroy
	rm project-id.txt

project-id.txt:
	echo $$RANDOM | md5 | cut -c-1-8 > project-id.txt


