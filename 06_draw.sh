#! /usr/bin/bash
######################################################
# Bash script count.sh to run individual squire Draw jobs
# using input file arguments.sh
# Last update: 2018_01_12
# cpacyna
######################################################

#SBATCH --job-name=draw
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --array=2-10,12-28%5
#SBATCH --mem-per-cpu=2G

#Load arguments
argument_file=./arguments.sh
. $argument_file

pthreads=$SLURM_CPUS_PER_TASK


# Print the task index.
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID

# get sample names
SAMPLE_SHEET=$WORK_DIR/samplesheet.csv
mapfile -t sample_names < <( awk -F',' 'NR>1 && !seen[$1]++ { print $1 }' "$SAMPLE_SHEET")

sample_num=$((SLURM_ARRAY_TASK_ID - 1))
sample_name=${sample_names[$sample_num]}

echo "Sample name: " $sample_name


# Run SQuIRE Draw
echo 'Running Draw'
if singularity exec "$SQUIRE_SIF" squire Draw --map_folder $map_folder --draw_folder $draw_folder --name $sample_name --normlib $normlib --pthreads $pthreads --strandedness $strandedness $verbosity -b $build
then
  echo 'Draw is complete'
fi

# draw.sh
