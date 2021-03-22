# mgs_inventory
## _Collects systeminfo to your zabbix monitoring system._
This is a bunch of commands for collect hardware or software information both for Windows and Linux Operating System.
# Installation
1. Copy files to your zabbix agent installation directory (usually C:\Zabbix for Windows or /etc/zabbix for Linux).
2. Remove zabbix_agentd.conf.d/zabbix_agentd.mgs-inventory-windows.conf if your're using Linux or zabbix_agetnd.conf.d/zabbix_agentd.mgs-inventory-linux.conf if you're using Windows.
3. Add folowing lines to your zabbix_agentd.conf:
```
Include=c:\zabbix\zabbix_agentd.conf.d\*.conf
```
4. Import template_mgs-inventory.xml template to your zabbix.

