# Generate switch configs

Requirements:
- up to date SHCD that adheres to the SHCD rules.
    - [SHCD rules](./shcd_connection_rules.md)
- `sls_input_file.json`


```
canu generate network config --csm 1.2 -a TDS --shcd ./shcd_file.xlsx --tabs 25G_10G,NMN,HMN --corners I14,S47,I18,S22,J21,U38 --sls-file ./sls_input_file.json --foler ../switch_configs
```
