
name := kubernetes-the-hard-way
_key_pair_file := ./secrets/${name}.ed25519

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

.PHONY: key-pair
