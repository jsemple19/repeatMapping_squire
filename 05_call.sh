#! /usr/bin/bash
######################################################
# Bash script call.sh to run squire Call job
# using input file arguments.sh
# Last update: 2018_02_12
# cpacyna
######################################################

#SBATCH --job-name=call
#SBATCH --time=0-5:00:00
#SBATCH --cpus-per-task=4
#SBATCH --array=2-13
#SBATCH --mem-per-cpu=2G

argument_file=./arguments.sh
. $argument_file

pthreads=$SLURM_CPUS_PER_TASK


# Print the task index.
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID

CONTRASTS=$WORK_DIR/contrasts.csv
SAMPLE_SHEET=$WORK_DIR/samplesheet.csv

# get inputs from samplesheet.csv
mapfile -t contrast_names < <(tail -n +2 "$CONTRASTS" | cut -d',' -f1)

contrast_num=$((SLURM_ARRAY_TASK_ID - 1))
contrast_name=${contrast_names[$contrast_num]}

#Load arguments
echo 'Loading arguments'

mapfile -t ctrl_group < <(grep "^${contrast_name}," "$CONTRASTS" | cut -d',' -f3)
mapfile -t treat_group < <(grep "^${contrast_name}," "$CONTRASTS" | cut -d',' -f4)

mapfile -t ctrl_samples < <(awk -F',' -v m="$ctrl_group" '$6 == m { print $1 }' "$SAMPLE_SHEET" | sort -u)
mapfile -t treat_samples < <(awk -F',' -v m="$treat_group" '$6 == m { print $1 }' "$SAMPLE_SHEET" | sort -u)


# convert sample list to comma separated string
IFS=',' group1="${treat_samples[*]}"
IFS=',' group2="${ctrl_samples[*]}"


mkdir -p $call_foler/$contrast_name

# Run SQuIRE Call
# note, need to use --cleanevn to stop the container from using the local R version
echo 'Running Call'
if singularity exec --cleanenv "$SQUIRE_SIF" squire Call --group1 "$group1" --group2 "$group2" --condition1 $treat_group --condition2 $ctrl_group --projectname $contrast_name --pthreads $pthreads --output_format $output_format  --call_folder $call_folder/$contrast_name $verbosity
then
  echo 'squire Call is complete'
fi

#call.sh
