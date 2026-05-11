#! /usr/bin/bash
######################################################
# Bash script map.sh to run individual squire Map jobs
# using input file arguments.sh
# Last update: 2018_05_21
# cpacyna
######################################################

#SBATCH --job-name=map
#SBATCH --time=2-00:00:00
#SBATCH --cpus-per-task=12
#SBATCH --array=25-27%10
#SBATCH --mem-per-cpu=8G

argument_file=./arguments.sh
. $argument_file

pthreads=$SLURM_CPUS_PER_TASK
SAMPLE_SHEET=$WORK_DIR/samplesheet.csv

# Print the task index.
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID

# get inputs from samplesheet.csv
#mapfile -t sample_names < <(tail -n +2 "$SAMPLE_SHEET" | cut -d',' -f1 | sort -u)
mapfile -t sample_names < <( awk -F',' 'NR>1 && !seen[$1]++ { print $1 }' "$SAMPLE_SHEET")

sample_num=$((SLURM_ARRAY_TASK_ID - 1))
sample_name=${sample_names[$sample_num]}
echo "Sample name: " $sample_name

#Load arguments
echo 'Loading arguments'

mapfile -t r1file < <(grep "^${sample_name}," "$SAMPLE_SHEET" | cut -d',' -f2)
mapfile -t r2file < <(grep "^${sample_name}," "$SAMPLE_SHEET" | cut -d',' -f3)

# get directories of all files so they can be bound to container
bind_args=()
for b in "${r1file[@]}"; do
    dirR1=`dirname $b`
    bind_args+=( --bind "$dirR1" )
done
for b in "${r2file[@]}"; do
    dirR2=`dirname $b`
    bind_args+=( --bind "$dirR2" )
done

# convert file list to comma separated string
IFS=',' r1_args="${r1file[*]}"
IFS=',' r2_args="${r2file[*]}"


echo "Read1 files: " ${r1file[@]}
echo "Read2 files: " ${r2file[@]}

# Set up environment and modules for SQuIRE
echo 'Setting up environment'
#source activate $virtual_env

# Run SQuIRE Map
echo 'Running Map'

if [[ $r2file != 'False' ]]
then

  if [ -z $non_reference ]; then
    if singularity exec --bind "$WORK_DIR" "${bind_args[@]}" "$SQUIRE_SIF" squire Map --read1 "$r1_args" --read2 "$r2_args" --map_folder $map_folder --read_length $read_length --fetch_folder $fetch_folder --pthreads $pthreads --build $build --name $sample_name $verbosity
    then
      echo $sample_name >> success_map_$projectname.txt
    else
      echo $sample_name >> fail_map_$projectname.txt
    fi
  else
    if singularity exec --bind "$WORK_DIR" "${bind_args[@]}" "$SQUIRE_SIF" squire Map --read1 "$r1_args" --read2 "$r2_args" --map_folder $map_folder --read_length $read_length --fetch_folder $fetch_folder --extra $non_reference --pthreads $pthreads --build $build --name $sample_name $verbosity
    then
      echo $sample_name >> success_map_$projectname.txt
    else
      echo $sample_name >> fail_map_$projectname.txt
    fi
  fi

elif [[ $r2file = 'False' ]]
then
  if [ -z $non_reference ]; then
    if singularity exec --bind "$WORK_DIR" "${bind_args[@]}" "$SQUIRE_SIF"  squire Map --read1 "$r1_args" --map_folder $map_folder --read_length $read_length --fetch_folder $fetch_folder --pthreads $pthreads --build $build --name $sample_name $verbosity
    then
      echo $sample_name >> success_map_$projectname.txt
    else
      echo $sample_name >> fail_map_$projectname.txt
    fi
  else
    if singularity exec --bind "$WORK_DIR" "${bind_args[@]}" "$SQUIRE_SIF"  squire Map --read1 "$r1_args" --map_folder $map_folder --read_length $read_length --fetch_folder $fetch_folder --extra $non_reference --pthreads $pthreads --build $build --name $sample_name $verbosity
    then
      echo $sample_name >> success_map_$projectname.txt
    else
      echo $sample_name >> fail_map_$projectname.txt
    fi
  fi

fi

echo 'Map Complete on' `date`

# map.sh
