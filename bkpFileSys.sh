#!/bin/bash
#
# Script: fs_backup_full.sh
# Author: Joao Bernardes
# Function: Daily backup

# Setting vars
TIMESTAMP=$(date "+%Y%m%d%H%M")
ORIG="/var/www/html /usr/local/nagios/share /usr/local/pnp4nagios/share /etc/httpd /backup/mysql"
DEST="/backup/filesystem"				# Destination dir
REMOTEDIR="/opt/backup/fs_dpl1/"
REMOTEADDR="root@177.70.99.225"
REMOTEDEST="$REMOTEADDR:$REMOTEDIR"
REMOTESSHPORT=22001
TRGTDESC="digitalocean-htdocs-bak"
COMP="$DEST/$TRGTDESC-$TIMESTAMP.tgz"
EXC="*.log" 						# Extentions to exclude
NOB=5							# Number of backups to keep
LOG="/var/log/bkp-fs-bak-$TIMESTAMP.log"
GPGKEY="@joao-lb"

# Static Vars
_ECHO="`which echo` -e"
_TAR=`which tar`
_GPG=`which gpg`
_M5S=`which md5sum`
_SCP=`which scp`

# Iniciando criacao do arquivo tgz:
$_ECHO | tee -a $LOG
$_ECHO "Iniciando criacao do arquivo tgz..." | tee -a $LOG
$_ECHO | tee -a $LOG
$_TAR -cvzf $COMP --exclude='$EXC' $ORIG 2>&1 >> $LOG && $_ECHO "Arquivo $COMP criado com êxito!" | tee -a $LOG



# Estatisticas do job
$_ECHO | tee -a $LOG
$_ECHO "Computando estatisticas..." | tee -a $LOG

STATS_SIZE=$(du -lhs $COMP |  awk '{print $1}')
STATS_NOFILE=$($_TAR -tf $COMP | wc -l)
STATS_CHKSUM=$($_M5S $COMP | awk '{print $1}')

$_ECHO "  " | tee -a $LOG
$_ECHO "Tamanho do backup: $STATS_SIZE" | tee -a $LOG
$_ECHO "Quantidade de arquivos incluídos: $STATS_NOFILE" | tee -a $LOG
$_ECHO "Checksum do arquivo tgz: $STATS_CHKSUM" | tee -a $LOG

$_ECHO | tee -a $LOG



# rotina para limpeza de arquivos antigos
$_ECHO | tee -a $LOG
$_ECHO "Executando rotina de limpeza de arquivos antigos na unidade remota..." | tee -a $LOG
$_ECHO | tee -a $LOG

if [ $(ls -1 $DEST/$TRGTDESC-*|wc -l) -gt $NOB ];then
    oldfile=$(ls -1 $DEST/$TRGTDESC-* -r --sort=time|head -1)
    $_ECHO "o arquivo antigo [ $oldfile ] esta sendo apagado..." | tee -a $LOG
    rm -rf $oldfile
else
    $_ECHO nao existem arquivos antigos a serem limpos... | tee -a $LOG
fi



# Criptografando
$_ECHO | tee -a $LOG
$_ECHO | tee -a $LOG
$_ECHO "Criptografando arquivo tgz... (keyring utilizado: $GPGKEY)" | tee -a $LOG
$_ECHO | tee -a $LOG
#$_GPG -r $GPGKEY -e $COMP && rm -rf $COMP | tee -a $LOG && $_ECHO "Arquivo criptografado criado com êxito:" | tee -a $LOG
$_GPG -r $GPGKEY -e $COMP && rm -rf $COMP  

STATS_FNAME_GPG=$(ls $DEST | grep $TIMESTAMP)
STATS_CHKSUM_GPG=$($_M5S $COMP.gpg | awk '{print $1}')

$_ECHO "Arquivo criptografado criado com êxito: $STATS_FNAME_GPG" | tee -a $LOG
$_ECHO "Checksum: $STATS_CHKSUM_GPG" | tee -a $LOG


# Enviando arquivos para unidade remota 
$_ECHO | tee -a $LOG
$_ECHO | tee -a $LOG
$_ECHO "Enviando arquivos para unidade remota..." | tee -a $LOG
$_ECHO | tee -a $LOG
$_SCP -P $REMOTESSHPORT $COMP.gpg $REMOTEDEST | tee -a $LOG

# rotina para limpeza de arquivos antigos na unidade remota
$_ECHO | tee -a $LOG
$_ECHO "Executando rotina de limpeza de arquivos antigos..." | tee -a $LOG
$_ECHO | tee -a $LOG

if [ $(ssh -p $REMOTESSHPORT $REMOTEADDR ls -l $REMOTEDIR | wc -l) -gt $NOB ];then
    oldremfile=$(ssh -p $REMOTESSHPORT $REMOTEADDR ls $REMOTEDIR -r --sort=time|head -1)
    $_ECHO "o arquivo antigo [ $oldremfile ] na unidade remota esta sendo apagado..." | tee -a $LOG
    ssh -p $REMOTESSHPORT $REMOTEADDR rm -rf $REMOTEDIR/$oldremfile
else
    $_ECHO "nao existem arquivos antigos a serem limpos na unidade remota..." | tee -a $LOG
fi


$_ECHO | tee -a $LOG
$_ECHO | tee -a $LOG
$_ECHO "Backup concluido!" | tee -a $LOG



