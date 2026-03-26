#!/bin/bash
# Usage
# -----
# $ bash launch_experiments.sh ACTION_NAME
#
# where ACTION_NAME is either 'list' or 'submit' or 'run_here'

if [[ -z $1 ]]; then
    ACTION_NAME='list'
else
    ACTION_NAME=$1
fi

# Verify environment set up properly
hastorch=`which python && python -c 'import torch'`
if [[ $? -ne 0 ]]; then
    echo "ERROR: Python environment not setup. Review this guide:"
    echo "https://www.cs.tufts.edu/comp/145/2026s/tufts_hpc_setup.html#first-time-setup"
    exit
fi

export SAVEDIR=/cluster/tufts/c26sp1cs0145/$USER/
export n_epochs=400
export q_sigma=0.05
export n_mc_samples=10
export batch_size=100

for arch in 512 032
do

for lr in 0.001 0.010 0.100
do
    export hidden_layer_sizes=$arch
    export batch_size=$batch_size
    export lr=$lr

    export filename_prefix="$SAVEDIR/hw4-2026-AE-lr=$lr-arch=$hidden_layer_sizes"
    ## Use this line to see where you are in the loop
    echo "$filename_prefix"

    ## NOTE all env vars that have been 'export'-ed will be passed along
    if [[ $ACTION_NAME == 'submit' ]]; then
        ## Use this line to submit the experiment to the batch scheduler
	    sbatch < do_experiment_hw4_ae.slurm
    
    elif [[ $ACTION_NAME == 'run_here' ]]; then
        ## Use this line to just run interactively
        bash do_experiment_hw4_ae.slurm
        exit
    fi


done
done


