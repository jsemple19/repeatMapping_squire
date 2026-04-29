#!/usr/bin/bash
######################################################
# Bash script fetch.sh to run the Fetch step of SQuIRE with input arguments
# Input file: arguments.sh
# Last update: 2018_01_12
# Tested on version 0.9.9.92
# cpacyna
# ---
# Run with:
# sbatch -D . --export=argument_file='arguments.sh' fetch.sh
######################################################

#SBATCH --job-name=fetch
#SBATCH --time=0-02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2



#Load arguments
echo 'Loading arguments'
pwd
argument_file=./arguments.sh
. $argument_file

# Set up environment and modules for SQuIRE
echo 'Setting up environment'
source $CONDA_ACTIVATE squire
#source activate $virtual_env
echo 'Loading modules'
pthreads=$SLURM_CPUS_PER_TASK

# Run SQuIRE Fetch
echo 'Running Fetch'
#squire Fetch --build $build --fetch_folder $fetch_folder --fasta --rmsk  --chrom_info  --index  --gene --pthreads $pthreads $verbosity

singularity exec --bind $WORK_DIR $SQUIRE_SIF squire Fetch --build $build --fetch_folder $fetch_folder --fasta --rmsk  --chrom_info  --index  --gene --pthreads $pthreads $verbosity

echo 'Fetch Complete on' `date`

# fetch.sh
