#! /usr/bin/bash
######################################################
# Bash script map.sh to run individual squire Map jobs
# using input file arguments.sh
# Last update: 2018_05_21
# cpacyna
######################################################

#SBATCH --job-name=map
#SBATCH --time=2-00:00:00
#SBATCH --cpus-per-task=2
#SBATCH --array=1-28%10
#SBATCH --mem=8G

argument_file=./arguments.sh
. $argument_file

pthreads=$SLURM_CPUS_PER_TASK
SAMPLE_SHEET=$WORK_DIR/samplesheet.csv

# Print the task index.
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID

# get inputs from samplesheet.csv
line_num=$((SLURM_ARRAY_TASK_ID + 1))
line=$(sed -n "${line_num}p" $SAMPLE_SHEET)
IFS=',' read -r -a sample_data <<< "$line"

#Load arguments
echo 'Loading arguments'
# r1file=$1
# basename=${r1file//}
# basename=$2
# argument_file=$3
# r2file=$4

r1file=${sample_data[1]}
r2file=${sample_data[2]}
filebasename=${sample_data[0]}

# Set up environment and modules for SQuIRE
echo 'Setting up environment'
#source activate $virtual_env

# Run SQuIRE Map
echo 'Running Map'

if [[ $r2file != 'False' ]]
then

  if [ -z $non_reference ]; then
    if singularity exec --bind $WORK_DIR $SQUIRE_SIF squire Map --read1 $r1file --read2 $r2file --map_folder $map_folder --read_length $read_length --fetch_folder $fetch_folder --pthreads $pthreads --build $build --name $filebasename $verbosity
    then
      echo $filebasename >> success_map_$projectname.txt
    else
      echo $filebasename >> fail_map_$projectname.txt
    fi
  else
    if singularity exec --bind $WORK_DIR $SQUIRE_SIF squire Map --read1 $r1file --read2 $r2file --map_folder $map_folder --read_length $read_length --fetch_folder $fetch_folder --extra $non_reference --pthreads $pthreads --build $build --name $filebasename $verbosity
    then
      echo $filebasename >> success_map_$projectname.txt
    else
      echo $filebasename >> fail_map_$projectname.txt
    fi
  fi

elif [[ $r2file = 'False' ]]
then
  if [ -z $non_reference ]; then
    if singularity exec --bind $WORK_DIR $SQUIRE_SIF squire Map --read1 $r1file --map_folder $map_folder --read_length $read_length --fetch_folder $fetch_folder --pthreads $pthreads --build $build --name $filebasename $verbosity
    then
      echo $filebasename >> success_map_$projectname.txt
    else
      echo $filebasename >> fail_map_$projectname.txt
    fi
  else
    if singularity exec --bind $WORK_DIR $SQUIRE_SIF squire Map --read1 $r1file --map_folder $map_folder --read_length $read_length --fetch_folder $fetch_folder --extra $non_reference --pthreads $pthreads --build $build --name $filebasename $verbosity
    then
      echo $filebasename >> success_map_$projectname.txt
    else
      echo $filebasename >> fail_map_$projectname.txt
    fi
  fi

fi

echo 'Map Complete on' `date`

# map.sh
