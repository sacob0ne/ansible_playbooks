## Requirements
```
Python
Ansible
```
## USAGE

### Options

- inventory: e.g. dev.team
- **m25**: default - false
  - true: It includes rules for HDD SMART monitoring which is enabled only on *bare metal machines* (stg / prod)
  - false: for VDC and AWS environments (mainly dev ones)
- **update**: default - false
  - true: for updates and code changes
  - false: for fresh environment install
- **aws**: default - false
  - true: only for aws
  - false: for Sky DCs or VDCs

```
cd dap-core/devops/ansible-prometheus-stack
ansible-playbook -i ../_env/{{INVENTORY}} dap-prov-prometheus-stack.yml -e "update=true" -e "m25=true" -v
```


### Note: Prometheus's version is 2.1.0 which means the default configuration has changed.


#### Run history
