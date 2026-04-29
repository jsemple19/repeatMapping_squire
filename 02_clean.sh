#!/usr/bin/bash -l
######################################################
# Bash script 02_clean.sh to run the Clean step of SQuIRE with input arguments
# Filters Repeatmasker file for Repeats of interest, collapses overlapping repeats, and returns as BED file.
# Input file: arguments.sh
# Last update: 2018_01_12
# Tested on version 0.9.9.92
# cpacyna
# ---
# Run with:
# sbatch -D . --export=argument_file='arguments.sh' clean.sh
######################################################


#SBATCH --job-name=clean
#SBATCH --time=0-02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1




#Load arguments
echo 'Loading arguments'
argument_file=./arguments.sh
. $argument_file

# Set up environment and modules for SQuIRE
#echo 'Setting up environment'
#source activate $virtual_env

# Run SQuIRE Build
echo 'Running Clean'

if [ -z $repeatmasker_file ]
then
  if [ -z $non_reference ]; then
    singularity exec --bind $WORK_DIR $SQUIRE_SIF squire Clean --build $build --fetch_folder $fetch_folder --clean_folder $clean_folder $class $family $subfamily $verbosity
  else
    singularity exec --bind $WORK_DIR $SQUIRE_SIF squire Clean --build $build --fetch_folder $fetch_folder --clean_folder $clean_folder $class $family $subfamily --extra $non_reference $verbosity
  fi
else
  if [ -z $non_reference ]; then
    singularity exec --bind $WORK_DIR $SQUIRE_SIF squire Clean --rmsk $repeatmasker_file --fetch_folder $fetch_folder --clean_folder $clean_folder $class $family $subfamily $verbosity
  else
    singularity exec --bind $WORK_DIR $SQUIRE_SIF squire Clean --rmsk $repeatmasker_file --fetch_folder $fetch_folder --clean_folder $clean_folder $class $family $subfamily --extra $non_reference $verbosity
  fi
fi

echo 'Clean Complete on' `date`

# clean.sh