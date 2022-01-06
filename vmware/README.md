Modo de uso:Ha duas roles no arquivo playbook.yaml
  - ds_list = Lista Datastores do vcenter
  - deploy = Realiza o deploy de uma maquina virtual baseado em TEMPLATE de sistema no vCenter


-Interativo:
#./deploy.sh <env>

  Ou
  
  -Edita manualmente as variaveis:
   #vi roles/ds_list/vars/main.yaml
   #vi roles/deploy/vars/main.yaml
  
    IMPORTANTE: *Não esquecer de apagar os dados sensiveis das variaveis ou usar o VAULT
    
 #ansible-playbook playbook.yaml
