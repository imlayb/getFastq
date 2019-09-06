# Requires parallel-fastq-dump on PATH, edirect, typical aspera connect installation, and curl.
# All or nothing behavior.

function getSRA {
	if [[ $# == 1 ]]; then
		FASP_CMD="/home/${USER}/.aspera/cli/bin/ascp -T -k 1 -l  900m  -i /home/${USER}/.aspera/cli/etc/asperaweb_id_dsa.openssh anonftp@ftp.ncbi.nlm.nih.gov:/sra/sra-instant/reads/ByRun/sra/SRR/${1::6}/${1}/${1}.sra ${1}.sra"
		echo $FASP_CMD
	  eval $FASP_CMD
		if [[ $? == 0 ]]; then
		  return 0
		elif [[ $? != 0 ]]; then
		  echo "Failed to download using fasp. Resorting to https with curl."
		  result=$(esearch -db sra -query ${SRR} | efetch -format xml | xtract -pattern RUN -element "@url,SRAFiles/SRAFile" | awk -v SRR="$SRR" -F'[ ]' '$1 ~ SRR {print $1}')
		  HTTPS_CMD="curl ${result} --output ./${1}.sra"
		  echo $HTTPS_CMD
		  eval $HTTPS_CMD
		  if [[ $? == 0 ]]; then
		    return 0
		  elif [[$? != 0 ]]; then
		    return 1
		  fi
	  fi
	fi
}
THREADS=1
TMPDIR=./
while getopts ":d:t:" opt; do
  case $opt in
    t)
      re='^[0-9]+$'
      if ! [[ $OPTARG =~ $re ]]; then
        echo "error: Not a number" >&2; exit 1
      else
        THREADS=$OPTARG
      fi
      ;;
    d)
        if ! [[ -d $OPTARG ]]; then
          echo "Invalid temporary directory" >&2; exit 1
        else
          TMPDIR=$OPTARG
        fi
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

input=$(cat <&0) # Reads from stdin
for SRR in $input
do
	SRR=${SRR%\"}
	SRR=${SRR#\"}
	if  [[ ${SRR::3} == "SRR" ]]; then
		echo "Attempting to get ${SRR}"
		getSRA $SRR
		if [[ $? != 0 ]]; then
		  getSRA $SRR # Try again
		fi
		if [[ $? != 0 ]]; then
		  echo "Failed to download ${SRR}"
		  exit 1
		fi
		parallel-fastq-dump -s ${SRR}.sra -t $THREADS --readids --split-files --tmpdir $TMPDIR
    if [[ $? == 0 ]]; then
      rm ${SRR}.sra
    fi
	fi
done