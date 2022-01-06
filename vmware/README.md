Modo de uso:

-Interativo:
#./deploy.sh <env>

  Ou
  
  -Edita manualmente as variaveis:
   #vi roles/ds_list/vars/main.yaml
   #vi roles/deploy/vars/main.yaml
  
    IMPORTANTE: *Não esquecer de apagar os dados sensiveis das variaveis ou usar o VAULT
    
 #ansible-playbook playbook.yaml
