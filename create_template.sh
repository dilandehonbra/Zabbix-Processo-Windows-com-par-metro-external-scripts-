#!/usr/bin/env bash
#Lista de CommandLine para criação do array
awk '
	function tratamento(si) {
		gsub (/"CommandLine":/, "", si)
		gsub(/^[[:space:]]+/, "", si)
		gsub(/\x27/, "\\""\x27", si)
		gsub(/^\x22+/, "", si)
		gsub(/,$/, "", si)
		gsub(/[[:space:]]+$/, "", si)
		gsub(/\x22$/, "", si)
		gsub(/[[:space:]]+$/, "", si)
		gsub(/\x22$/, "", si)
		gsub(/^\\+/, "", si)
		gsub(/^\x22+/, "", si)
		gsub(/\\$/, "%", si)
		gsub(/(\\\x22)+/, "%", si)
	return si
}
	/.*CommandLine.*/ {
	print tratamento($0)
}
' $1 | awk '{print "\"""%"$0"%""\""}' >> result.manipula

#########################################################
ARRAY=(`cat result.manipula | tr " " "#"`)
ARRAYS=(`cat result.manipula | tr " " "#" | sed 's/^\"//' | sed 's/\"$//'`)
#Ip do host para criação das chaves
IPHOST=$2

#Porta de comunicação entre host/zabbix
PORT=$3

#Nome do Template, por padrão será agrupado ao grupo "Templates"
TEMPLATE_NAME=$4



        cat << EOF > arq.txt
<?xml version="1.0" encoding="UTF-8"?>
<zabbix_export>
    <version>5.0</version>
    <date>2022-01-18T21:25:29Z</date>
    <groups>
        <group>
            <name>Templates</name>
        </group>
    </groups>
    <templates>
        <template>
            <template>$TEMPLATE_NAME</template>
            <name>$TEMPLATE_NAME</name>
            <groups>
                <group>
                    <name>Templates</name>
                </group>
            </groups>
            <applications>
                <application>
                    <name>Memory by Process</name>
                <application>
                <application>
                    <name>GetPID</name>
                </application>
                <application>
                    <name>NumberOfLogicalProcessor</name>
                </application>
                <application>
                    <name>Processos Windows</name>
                </application>
                <application>
                    <name>Proc param</name>
                </application>
            </applications>
            <items>
        <item>
                    <name>NumberOfLogicalProcessor</name>
                    <type>ZABBIX_ACTIVE</type>
                    <key>system.cpu.num</key>
                    <delay>1d</delay>
                    <applications>
                        <application>
                            <name>NumberOfLogicalProcessor</name>
                        </application>
                    </applications>
                </item>


EOF
####################CPU USAGE###############################
for i in "${ARRAY[@]}"

	do
	echo "<item> <name>Get Process (\$3)</name> <type>EXTERNAL</type> <key>win.proc.param.cpu[${IPHOST},${PORT},${i}]</key> <applications> <application> <name>GetPID</name> </application> </applications> </item>" >> arq.txt

done ;

for l in "${ARRAYS[@]}"
###TRATAMENTO PARA NOME DOS ITENS CALCULADOS###
	do
	 TRATAMENTO=$(echo $l | sed 's/[[:punct:]]/\./g' |tr " " .| sed -E 's/^[.]+//' | sed -E 's/[.]{1,}/\./g' | sed -E 's/[.]+$//')
	 TRATAMENTONAME=$(echo $l | sed 's/^\%//'| sed 's/\%$//')

	echo "<item> <name>CPU in % by Process (${TRATAMENTONAME})</name> <type>CALCULATED</type> <key>item.${TRATAMENTO}</key> <value_type>FLOAT</value_type> <units>%</units> <params>last(&quot;win.proc.param.cpu[${IPHOST},${PORT},\&quot;${l}\&quot;]&quot;)/last(&quot;system.cpu.num&quot;)</params> <applications> <application> <name>Proc param</name> </application> </applications> </item>" >> arq.txt
done;

####################MEMORY USAGE#############################

for i in "${ARRAY[@]}"

	do
	echo "<item> <name>Memory usage Process (\$3)</name> <type>EXTERNAL</type> <key>win.proc.mem[${IPHOST},${PORT},${i}]</key> <units>B</units> <applications> <application> <name>Memory by Process</name> </application> </applications> </item>" >> arq.txt

done ;

    cat << EOF >> arq.txt
</items>
            <macros>
                <macro>
                    <macro>{\$PROC_CPU_CRIT}</macro>
                    <value>90</value>
                    <description>Threshold de CPU pelo processo.</description>
                </macro>
            </macros>
        </template>
    </templates>
</zabbix_export>

EOF
XMLNAME=`echo "$TEMPLATE_NAME" | sed 's/[[:space:]]/_/g'`
cat arq.txt | tr "#" " " >> $XMLNAME.xml ; rm arq.txt
