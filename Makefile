
name := kubernetes-the-hard-way
_key_pair_file := ./secrets/${name}.ed25519
_terraform_dir := ./terraform

plan:
	cd "${_terraform_dir}" && terraform plan

apply:
	cd "${_terraform_dir}" && terraform apply -auto-approve

destroy:
	cd "${_terraform_dir}" && terraform destroy -auto-approve

key-pair:
	mkdir -p "$$(dirname "${_key_pair_file}")" && \
	[ -f "${_key_pair_file}" ] || \
	aws ec2 create-key-pair \
	  --key-name "${name}" \
	  --key-type 'ed25519' \
	  --output text --query 'KeyMaterial' \
	  > "${_key_pair_file}" && \
	chmod 600 "${_key_pair_file}"

delete-key-pair:
	aws ec2 delete-key-pair --key-name "${name}" && \
	rm "${_key_pair_file}"

.PHONY: plan apply destroy key-pair delete-key-pair
