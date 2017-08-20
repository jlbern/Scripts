#!/bin/bash
#
# Script: jboss-bak.sh
# Author: Joao Bernardes
# Function: Daily compress the jboss directory for backup porpouses.

# Setting vars
TIMESTAMP=$(date "+%Y%m%d%H%M")
ORIG="/opt/jboss-eap-4.3/"
DEST="/opt/backup/jboss"				# Destination dir
TRGTDESC="jboss-bak"
COMP="$DEST/$TRGTDESC-$TIMESTAMP.tar.gz"
EXC="*.log" 						# Extentions to exclude
LOG="/var/log/bkp/jboss-bak-$TIMESTAMP.log"
NOB=5							# Number of backups to keep


# Incluir estrutura de validacao com 'if' na proxima release
/bin/tar -cvzf $COMP --exclude='$EXC' $ORIG 2>&1 >> $LOG

# rotina para limpeza de arquivos antigos
echo | tee -a $LOG
echo "Executando rotina de limpeza de arquivos antigos..." | tee -a $LOG

if [ $(ls -1 $DEST/$TRGTDESC-*|wc -l) -gt $NOB ];then
    oldfile=$(ls -1 $DEST/$TRGTDESC-* -r --sort=time|head -1)
    echo "o arquivo antigo [ $oldfile ] esta sendo apagado..." | tee -a $LOG
    rm -rf $oldfile
else
    echo nao existem arquivos antigos a serem limpos... | tee -a $LOG
fi

# Estatisticas do job
echo | tee -a $LOG
echo "Computando estatisticas..." | tee -a $LOG

STATS_SIZE=$(du -lhs $COMP |  awk '{print $1}')
STATS_NOFILE=$(/bin/tar -tf $COMP | wc -l)

echo "  " | tee -a $LOG
echo "Arquivo de backup $COMP gerado com êxito..." | tee -a $LOG
echo "Tamanho do backup: $STATS_SIZE" | tee -a $LOG
echo "Quantidade de arquivos incluídos: $STATS_NOFILE" | tee -a $LOG

echo | tee -a $LOG
echo "Backup concluido!" | tee -a $LOG
