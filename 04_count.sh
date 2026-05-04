#! /usr/bin/bash
######################################################
# Bash script count.sh to run squire Count jobs
# using input file arguments.sh
# Last update: 2018_01_12
# cpacyna
######################################################

#SBATCH --job-name=count
#SBATCH --time=4-00:00:00
#SBATCH --cpus-per-task=2
#SBATCH --array=1
#SBATCH --mem-per-cpu=16G

argument_file=./arguments.sh
. $argument_file

pthreads=$SLURM_CPUS_PER_TASK
SAMPLE_SHEET=$WORK_DIR/samplesheet.csv

# Print the task index.
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID

# Set up environment and modules for SQuIRE
#echo 'Setting up environment'
#source activate $virtual_env


# Run SQuIRE Count
echo 'Running Count'
if [ -z $tempfolder ]
then
  temp_folder=$count_folder
fi

if [ -z $EM ]
then
  EM="auto"
fi

mapfile -t sample_names < <(tail -n +2 "$SAMPLE_SHEET" | cut -d',' -f1 | sort -u)

sample_num=$((SLURM_ARRAY_TASK_ID - 1))
sample_name=${sample_names[$sample_num]}
filebasename=$sample_name

singularity exec "$SQUIRE_SIF" squire Count --map_folder $map_folder --clean_folder $clean_folder --count_folder $count_folder --temp_folder $temp_folder --name $filebasename --build $build --strandedness $strandedness --EM $EM $verbosity --pthreads $pthreads -r $read_length


echo 'Count Complete on' `date`

# count.sh
