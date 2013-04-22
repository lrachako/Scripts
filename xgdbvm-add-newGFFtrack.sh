#!/usr/bin/env bash
 
# Usage statement
print_usage()
{
  cat << EOF
Usage: xgdbvm-add-tsa.sh [options] GFF3_file
  Options:
    -d    MySQL database corresponding to the GDB; default is 'GDB001'
    -h    print this help message and exit
    -t    table name for naming the MySQL table; default is 'gseg_UserGene_annotation' 
    -o    output directory to which intermediate .sql files will be written;
          default is current directory
    -p    MySQL password, if different from system default
    -s    directory containing xGDBvm scripts; default is '/xGDBvm/scripts'
    -u    MySQL username; default is 'gdbuser'
EOF
}
# Parse options
DB="GDB001"
LABEL="UserGene"
OUTPATH="."
PASSWORD="xgdb"
SCRIPTDIR="/xGDBvm/scripts"
USERNAME="gdbuser"
gff=$1
geneSQL="$OUTPATH/${LABEL}.sql"
TABLE="gseg_${LABEL}_annotation"
while getopts "d:hl:o:p:s:u:" OPTION
do
  case $OPTION in
    d)
      DB=$OPTARG
      ;;
    h)
      print_usage
      exit 0
      ;;
    l)
      LABEL=$OPTARG
      ;;
    o)
      OUTPATH=$OPTARG
      ;;
    p)
      PASSWORD=$OPTARG
      ;;
    s)
      SCRIPTDIR=$OPTARG
      ;;
    u)
      USERNAME=$OPTARG
      ;;
  esac
done

# Parse GFF3 gene models

#$SCRIPTDIR/GFF_to_XGDB_Standard.pl -t $TABLE $gff > $geneSQL
perl GFF_to_XGDB_Standard.pl -t $TABLE $gff > $geneSQL

if [ ! -s $geneSQL ]; then
  echo -e "error: error creating file '$geneSQL'"
  exit 1
fi

read -d '' TABLESQL <<EOF

CREATE TABLE $TABLE (
  uid int(10) unsigned NOT NULL auto_increment,
  gseg_gi varchar(128) NOT NULL default '',
  geneId varchar(128) NOT NULL default '',
  strand enum('f','r') NOT NULL default 'f',
  l_pos int(10) unsigned NOT NULL default '0',
  r_pos int(10) unsigned NOT NULL default '0',
  gene_structure text NOT NULL,
  description text,
  note text,
  CDSstart int(20) unsigned NOT NULL default '0',
  CDSstop int(20) unsigned NOT NULL default '0',
  transcript_id varchar(128) NOT NULL default '',
  locus_id varchar(128) NOT NULL default '',
  PRIMARY KEY  (uid),
  KEY ind1 (geneId),
  KEY glftIND (l_pos),
  KEY grgtIND (r_pos),
  KEY ggaINDggi (gseg_gi),
  FULLTEXT KEY ggaFT_DescNote (description,note)
)ENGINE=MyISAM AUTO_INCREMENT=9639 DEFAULT CHARSET=latin1;
EOF

# Create table
echo "$TABLESQL" | mysql -u $USERNAME -p$PASSWORD $DB

# Populate TSA table
mysql -u $USERNAME -p$PASSWORD $DB < $geneSQL
geneCOUNT=$(echo "SELECT COUNT(*) AS 'Gene models uploaded:' from $TABLE" | mysql -u $USERNAME -p$PASSWORD $DB)
echo $geneCOUNT
