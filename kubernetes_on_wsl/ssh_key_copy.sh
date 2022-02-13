#/bin/bash -x
set -x
if [ -z "$1" ]; then
 echo "usage: ./ssh_key_copy.sh node1";
 exit 1
else  
 node=$1 
fi

pk_origin="$(pwd)/.vagrant/machines/$node/virtualbox"
pk_target="$HOME/.ssh"

if test -L "${pk_origin}/private_key"; then
  echo "Original private key is a symlink. Nothing to do."
else
   if test -f "${pk_origin}/private_key"; then
     cp "${pk_origin}/private_key" "${pk_origin}/private_key-backup"
     mv "${pk_origin}/private_key" "${pk_target}/${node}_private_key"
     chmod 600 "${pk_target}/${node}_private_key"
     ln -s "${pk_target}/${node}_private_key" "${pk_origin}/private_key"
   else
     echo "${pk_origin}/private_key doesn't exist or is not a file"
   fi
fi