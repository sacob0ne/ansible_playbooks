##Requirements
```
Python
Ansible
```

##USAGE

###Options

- inventory: e.g. dev.team
- **update**: default - false
  - true: for updates and code changes, avoids preflight phase
  - false: for fresh environment install
- **standalone**: default - false 
  - true: For a single-machine, standalone environment : __please set all hosts in the hosts file to the same IP address__ 
  - false: it deploys each component on a different machine where feasible
- **extendlvprivate**: default - false | depends on _update_ value (update=false)	

 *It's used only in the installation process so it doesn't really matter if you're doing an update*

  - true: it will extend root volume to the whole disk 
  - false: it will create a separate volume for elk

```
cd dap-core/devops/ansible-elk-stack
ansible-playbook -i ../_env/{{INVENTORY}} dap-prov-elk-stack.yml -e "update=true" -e "standalone=false" -v
```

####Run history