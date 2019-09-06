# getFastq
A BASH script for downloading and extracting Fastq files from SRA files from SRA without needing the SRA-toolkit. Avoiding prefetch may be convenient for your workflow as it was for mine.

## Features
  * Use of parallel-fastq-dump, vastly speeding up SRA-Fastq extraction times.
  * Attempts to download SRA files with `ascp` first before getting the `https://` url for the SRR using Edirect.
  * Attempts to download accessions twice in case of error.
  * Pass-through options for parallel-fastq-dump
    * -t : threads
    * -d : temporary directory for parallel-fastq-dump
  * Pass-through options for ascp
    * -b : bandwidth in the format of <X>m. E.g. 900m
## Dependencies
1. Ability to execute BASH scripts.
2. Aspera CLI installed in /home/${USER}/.aspera (The default).
3. Curl
4. [Edirect](https://www.ncbi.nlm.nih.gov/books/NBK179288/) on $PATH.
5. [parallel-fastq-dump](https://github.com/rvalieris/parallel-fastq-dump) on $PATH.

## Instructions
* The script reads accessions from `stdin`, removing quotations and ignoring strings that do not start with SRR.
  * Pipe inputs using `$./getFastq.sh -t 30 < accessions.txt`
  * Pipe inputs using `$cat accessions.txt | ./getFastq.sh -t 30`
