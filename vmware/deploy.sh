#!/bin/bash

################################################################
# Objetivo: Realizar deploy automatizado via Ansible no vcenter
# Modo de uso: ./deploy
# By: Bruno Miquelini
# Data de criação: 07/07/2021
# Data de modificação: 15/07/2021
# Alterações: Listagem de datastores, Listagem de vlans, interação para solicitação de informações das maquinas, adição de escolha de ambiente
################################################################

#OBS
#Necessario criar o arquivo .vlans, com a listagem das vlans disponiveis no vcenter (exportar aba portgroups)
#Esse ajuste sera realizado posteriormente para automatizar a coleta
#Crie um arquivo .vlans e adicione o nome das VLANs disponiveis em todo o seu ambiente para facilitar. 

#Collors
RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"

#Permite a utilização do Backspace
stty erase ^h


###############################################################
#INICIO - VARS
vcenter_hostname="vcenter.local"

#FIM - VARS
#################################################################
clear
echo -e "$RED"
echo -e "############################################################"
echo -e "$GREEN"
echo -e "                   INICIANDO SCRIPT DE DEPLOY....               "
echo -e "$RED"
echo -e "############################################################"
echo -e "$NOCOLOR"
sleep 2

vars() {
 echo "Ambiente de deploy:"
 echo
 echo -e "$GREEN"
 echo -e "DC: $dc_name"
 echo -e "Cluster: $cl_name"
 echo -e "$NOCOLOR"
 sleep 3
}

if [ -z $1 ] ; then
 clear
 echo "########################E R R O R###########################"
 echo "Digite o ambiente para deploy"
 echo "$0 <hml|dev|prd-dc|prd-sc>"
 echo "############################################################"
 exit 1
 
#AJUSTAR dc_name e cl_name conforme datacenters e clusters do seu ambiente
elif [ "$1" == "dev" ] ; then
 dc_name="DC_DEV"
 dc_dir="\/"
 cl_name="DC_CLUSTER_DEV"
 vars
elif [ $1 == "hml" ] ; then
 dc_name="DC_HML"
 dc_dir="\/"
 cl_name="DC_CLUSTER_HML"
 vars

elif [ $1 == "prd" ] ; then
 dc_name="DC_PRD"
 dc_dir="\/"
 cl_name="DC_CLUSTER_PRD"
 vars

else
 clear
 echo -e "$RED"
 echo "[-] $1 - Valor invalido"
 echo -e "$NOCOLOR"
 exit 1
fi
echo -e "$NOCOLOR"

getHostname () {
read -p "- Digite o nome da VM: " vm_name
if [ -z $vm_name ] ;then
  echo -e "$RED"
  echo -e "[-] Valor nulo invalido"
  echo -e "$NOCOLOR"
  getHostname
elif [ `echo $vm_name| grep _ | wc -l` -ne 0 ] ;then
  echo -e "$RED"
  echo "[-] Não use \"_\" (Underscore) no hostname"
  echo -e "$NOCOLOR"
  getHostname
else
  echo -e "$GREEN"
  #VM Name em letras maiusculas
  vm_name=`echo $vm_name | tr [a-z] [A-Z]`
  h_name=`echo $vm_name | tr [A-Z] [a-z]`
  echo -e "[+] VM: $vm_name - Hostname: $h_name"
  echo -e "$NOCOLOR"
fi
}

getIp () {
read -p "- Digite o ipv4 da vm: " vm_ip
if [[ $vm_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo -e "$GREEN"
  echo -e "[+] IP: $vm_ip"
  echo -e "$NOCOLOR"
else
  clear
  echo -e "$RED"
  echo -e "[-] Digite um IP valido"
  echo -e "$NOCOLOR"

  getIp
fi
}

getGw () {
read -p "- Digite o ipv4 do Gateway: " vm_gw
if [[ $vm_gw =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo -e "$GREEN"
  echo -e "[+] GW: $vm_gw"
  echo -e "$NOCOLOR"
else
  clear
  echo -e "$RED"
  echo "[-] Digite um IP valido para o Gateway"
  echo -e "$NOCOLOR"

  getGw
fi
}

echo "Digite os dados da VM para deploy"
echo
getHostname
getIp
getGw

clear
echo "- Informações digitadas"
echo -e "$GREEN"
echo -e "VM: $vm_name"
echo -e "IP: $vm_ip"
echo -e "GW: $vm_gw"
echo -e "$NOCOLOR"

#Entra no diretorio:
cd /root/ansible_vmware

echo "[vm_name]" > hosts
echo "$vm_ip" >> hosts


#Collors
RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"

clear
#Checa vlans
getVlan() {

echo -e "$RED"
echo -e "VLANS DISPONIVEIS: "
echo -e "$NOCOLOR"
vlans=`echo $dc_name | sed 's/_NEW//g'`
grep $vlans  .vlans

echo -e "$RED"
read -p "Digite o port group va VM: " net_name
echo -e "$NOCOLOR"

if [ -z $net_name ] ; then
  echo
  echo -e "$RED"
  clear
  echo "[-] Digite uma vlan valida!"
  sleep 2
  getVlan

  echo "[-] Digite uma vlan valida!"
  echo -e "$NOCOLOR"
elif [ `grep -w $net_name .vlans| wc -l` -eq '0' ] ; then
  echo -e "$RED"
  clear
  echo "[-] Vlan não existente"
  sleep 2
  getVlan
  echo -e "$NOCOLOR"
else
  echo -e "$GREEN"
  echo "[+] VLAN: $net_name"
  echo -e "$NOCOLOR"

fi
}
getVlan

#Solicita login vcenter
echo -e "$RED"
echo -e "DIGITE USUARIO E SENHA DO VCENTER: $vcenter_hostname..."
echo -e "$NOCOLOR"

#Solicita usuario e senha do vcenter
getUser() {
read -p "Digite o usuario do vcenter: " vcenter_username
if [ -z $vcenter_username ] ; then
  echo
  echo "Digite um nome de usuario valido!"
  getUser
fi
stty -echo
read -p "Digite a senha: " vcenter_password
if [ -z $vcenter_password ] ; then
  echo "Necessario digitar a senha... Digite novamente o usuario e senha!"
  getUser
fi
stty sane
echo


}

#Chama função para pegar usuario e senha
getUser

#Cria template de variaveis
sed -e "s/vcenter_hostname.*/vcenter_hostname: \"$vcenter_hostname\"/g" \
-e "s/vcenter_username.*/vcenter_username: \"$vcenter_username\"/g" \
-e "s/vcenter_password.*/vcenter_password: \"$vcenter_password\"/g" \
-e "s/vm_name.*/vm_name: \"$vm_name\"/g" \
-e "s/vm_ip.*/vm_ip: $vm_ip/g" \
-e "s/vm_gw.*/vm_gw: $vm_gw/g" \
-e "s/dc_name.*/dc_name: \"$dc_name\"/g" \
-e "s/dc_dir.*/dc_dir: \"$dc_dir\"/g" \
-e "s/cl_name.*/cl_name: \"$cl_name\"/g" \
-e "s/ds_name.*/ds_name: \"$ds_name\"/g" \
-e "s/h_name.*/h_name: \"$h_name\"/g" \
-e "s/net_name.*/net_name: \"$net_name\"/g" \
VARS.model > roles/deploy/vars/main.yaml

cp -f roles/deploy/vars/main.yaml roles/ds_list/vars/main.yaml

#Inicia role de listagem de datastore
echo -e "$GREEN"
echo -e "[+] Iniciando coleta de datastores..."
echo -e "$NOCOLOR"

sed -i 's/#    - ds_list/    - ds_list/g' playbook.yaml
sed -i 's/    - deploy/#    - deploy/g' playbook.yaml
ansible-playbook playbook.yaml -vvv >.ds 2> /dev/null
sed -i 's/#    - deploy/    - deploy/g' playbook.yaml
sed -i 's/    - ds_list/#    - ds_list/g' playbook.yaml
cat .ds | grep -B1 provisioned| grep name| cut -d ":" -f2| tr -d ' ",' > .ds_names


for i in `cat .ds | grep "free"| cut -d ":" -f2 | tr -d ' ,[a-z][A-Z]"'`; do expr "$i" / 1073741824; done > .ds_free


echo
#Função para coleta da variavel do datastore
getDs() {
echo -e "$RED"
echo -e "DATASTORE                        FREE SPACE"
echo -e "$NOCOLOR"
paste .ds_names .ds_free | grep -v local | sed 's/$/ TB/g'

echo -e "$RED"
read -p "Digite o Datastore: " ds_name
echo -e "$NOCOLOR"

#Verifica se variavel foi digitada
if [ -z $ds_name ] ; then
  echo
  echo -e "$RED"
  clear
  echo "[-] Digite um DS valido!"
  getDs
  echo -e "$NOCOLOR"
#Verifica se datastore existe
elif [ `grep -w $ds_name .ds_names | grep -v local| wc -l` -eq '0' ] ; then
  echo -e "$RED"
  clear
  echo "[-] DS não existente"
  getDs
  echo -e "$NOCOLOR"
#Informa que variavel foi setada com sucesso
else
  echo -e "$GREEN"
  echo "[+] DS: $ds_name"
  echo -e "$NOCOLOR"

fi
}

#Chama função para coleta do datastore
getDs
sed -i "s/ds_name.*/ds_name: \"$ds_name\"/g" roles/deploy/vars/main.yaml

clear
echo -e "Valide as informações: "

echo "Cluster: $cl_name"
echo "VM: $vm_name"
echo "PortGroup: $net_name"
echo "IP: $vm_ip"
echo "GW: $vm_gw"
echo "DataStore: $ds_name"

echo
echo -e "$GREEN"
echo "[+] - Iniciando Deploy"
echo -e "$NOCOLOR"

#Executa role de deploy
ansible-playbook  playbook.yaml 2> /dev/null

#Testa falha na execução
if [ $? -eq 0 ] ; then
  echo -e "$GREEN"
  echo "[+] `date` - Deploy realizado com sucesso: ENV: $cl_name,  USER: $vcenter_username, VM: $vm_name" | tee -a log-deploy.log
  echo -e "$NOCOLOR"
elif [ $? -eq 1 ] ; then
  echo -e "$RED"
  echo "[-] `date` - Falha ao realizar o Deploy:  ENV: $cl_name, USER: $vcenter_username, VM: $vm_name", IP: $vm_ip | tee -a log-deploy.log
  echo -e "$NOCOLOR"
fi


#Resetando arquivo de variaveis
cat VARS.model > roles/deploy/vars/main.yaml
cat VARS.model > roles/ds_list/vars/main.yaml

