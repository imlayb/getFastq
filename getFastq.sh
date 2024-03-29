function getSRA {
	if [[ $# == 1 ]]; then
		FASP_CMD="/home/${USER}/.aspera/cli/bin/ascp -T -k 1 -l  ${BANDWIDTH}  -i /home/${USER}/.aspera/cli/etc/asperaweb_id_dsa.openssh anonftp@ftp.ncbi.nlm.nih.gov:/sra/sra-instant/reads/ByRun/sra/SRR/${1::6}/${1}/${1}.sra ${1}.sra"
		echo $FASP_CMD
	  eval $FASP_CMD
		if [[ $? == 0 ]]; then
		  return 0
		elif [[ $? != 0 ]]; then
		  echo "Failed to download using fasp. Resorting to https with curl."
		  result=$(esearch -db sra -query ${SRR} | \
		    efetch -format xml | \
		    xtract -pattern RUN -element "@url,SRAFiles/SRAFile" | \
		    awk -v SRR=$SRR 'BEGIN{FS=OFS=" ";}{regex="^https.+("SRR"$|"SRR"\\.[[:digit:]])"}{for(i=1;i<=NF;i++){ if($i~regex){print $i;exit} } }')
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
THREADS=4
TMPDIR=./
BANDWIDTH=900m
while getopts ":d:t:b:" opt; do
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
    b)
      re2='^[0-9]+m$'
      if ! [[ $OPTARG =~ $re2 ]]; then
        echo "error: Not a valid bandwidth" >&2; exit 1
      else
        BANDWIDTH=$OPTARG
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
	validPrefix='[SRR|ERR]'
	if  [[ ${SRR::3} =~ $validPrefix ]]; then
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
      rm $SRR.sra
    fi
	fi
done
