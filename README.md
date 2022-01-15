# Zabbix-Processo-Windows-com-par-metro-external-scripts-

O resultado do script é o PercentUserTime, esse valor pode ser dividido pelo número de cpus resultando na utilização de cpu do processo com paramâmetro.

O external Script segue a seguinte sintaxe no frontend Zabbix

win.proc.param[IP,PORTA,PROCESSO,PARÂMETRO]

No meu caso foi criado o item a nivel de host, com outro item calculado baseado na chave system.cpu.num


Exemplo :

Type = Calculated

Fórmula = last("win.proc.param[IP,PORTA,PROCESSO,PARAMETRO]") / last("system.cpu.num")

Type of information = Numeric (float)

Units = %

.
