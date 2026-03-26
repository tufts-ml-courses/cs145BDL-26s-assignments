#!/usr/bin/env bash
#SBATCH -n 1                # Number of nodes
#SBATCH -c 4                # Number of cores
#SBATCH -t 0-03:00          # Runtime in D-HH:MM
#SBATCH -p batch            # Partition to submit to
#SBATCH --mem-per-cpu 3000  # Memory (in MB) per cpu
#SBATCH -o log_ae_%j.out
#SBATCH -e log_ae_%j.err
#SBATCH --export=ALL

export MKL_NUM_THREADS=4
export OMP_NUM_THREADS=4

python hw4_training_on_mnist.py \
    --method 'AE' \
    --lr $lr \
    --hidden_layer_sizes $hidden_layer_sizes
