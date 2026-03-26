# README : Guide to batch mode on HPC: running many jobs in parallel

### Step 1: Understand the basic experiment: Train an autoencoder

We'd like to train an autoencoder (AE), just like in BDL class HW4:

* [HW4 Instructions](https://www.cs.tufts.edu/cs/145/2026s/assignments/hw4.html)
* [HW4 Starter Code](https://github.com/tufts-ml-courses/cs145BDL-26s-assignments)

Recall that we had a script, `hw4_training_on_mnist.py`, we could use like this:

```
$ python hw4_training_on_mnist.py --help
  --method {AE,VAE}     Which method to use, AE or VAE
  --n_epochs N_EPOCHS   Number of epochs (default: 10)
  --batch_size BATCH_SIZE
                        Batch size (default: 1000)
  --lr LR               Learning rate for grad. descent (default: 0.01)
  --data_folder DATA_FOLDER
                        Folder where you want MNIST data stored
  --hidden_layer_sizes HIDDEN_LAYER_SIZES
                        Comma-separated list of size values (default: "32")
  --filename_prefix FILENAME_PREFIX
  --q_sigma Q_SIGMA     Fixed variance of approximate posterior (default: 0.1)
  --n_mc_samples N_MC_SAMPLES
                        Number of Monte Carlo samples (default: 1)
  --seed SEED           Random seed (default: 8675309)
```

Learning is sensitive to several algorithmic hyperparameters we can specify as options to this script.

Here, we're interested in exploring several settings:

* learning rate (lr) of 0.001, 0.010, and 0.100
* number of hidden units of 032 and 512

So we could simply just manually call this script at different settings, like
```
python hw4_training_on_mnist.py \
    --method 'AE' \
    --lr 0.001 \
    --hidden_layer_sizes 32 \
    --filename_prefix myresult
```

But this is boring! Let's use the cluster to run all 6 jobs (2 lr settings, 3 arch size settings) simultaneously!

### Step 2: Create a "do_experiment.slurm" script to perform our work

Take a look at [do_experiment_hw4_ae.slurm](https://github.com/tufts-ml-courses/cs145BDL-26s-assignments/blob/main/hpc_guide/do_experiment_hw4_ae.slurm)

You'll see it's like a standard shell script, but with an unusual header (lines that start with '#'). The main body should look familiar: we just call `hw4_training_on_mnist.py` with some passed in arguments.

We can ignore the header for now. Try it out! It's just like any shell script:

```
$ lr=0.001 hidden_layer_sizes=032 bash do_experiment_hw4_ae.slurm
```

**NB: For bash scripts, provide all environment variables BEFORE the call, not after.**

EXPECTED OUT:

```
train data: 20000 images. Total pixels on: 2018998. Frac pixels on: 0.129
  epoch   0  on train per-pixel VI-loss 0.711  bce 0.702  l1 0.501
test data: 10000 images. Total pixels on: 1018438. Frac pixels on: 0.130
  epoch   0  on test  per-pixel VI-loss 0.712  bce 0.703  l1 0.501
====  done with eval at epoch 0
  epoch   1 | frac_seen 0.20 | avg loss  0.5068 | batch loss  0.4693 | batch l1  0.318
  epoch   1 | frac_seen 0.40 | avg loss  0.4946 | batch loss  0.4617 | batch l1  0.316
...
```

Great! But what's the big deal? This is a wrapper that *can be understood* by the SLURM job scheduling system.

Look at the header:
```
#!/usr/bin/env bash
#SBATCH -n 1                # Number of nodes
#SBATCH -c 4                # Number of cores
#SBATCH -t 0-03:00          # Runtime in D-HH:MM
#SBATCH -p batch            # Partition to submit to
#SBATCH --mem-per-cpu 3000  # Memory (in MB) per cpu
#SBATCH -o log_ae_%j.out
#SBATCH -e log_ae_%j.err
#SBATCH --export=ALL
```

These settings say that when we request a job, we want 4 cores and to run for at most 3 hours, and use at most 3GB (3000 MB) of RAM.

The `--export=ALL` makes sure all environment variables are passed along. This includes the PATH and MAMBA_EXE from our [HPC First Time Setup instructions](https://www.cs.tufts.edu/comp/145/2026s/tufts_hpc_setup.html#first-time-setup) which are critical to our python env.


### Step 3: Try out a single job submission via 'sbatch'

Once we have our 'do_experiment' script, we can **submit** it to the job scheduler via this command:

```
$ lr=0.01 hidden_layer_sizes=32 sbatch < do_experiment_hw4_ae.slurm
```
Notes:

* sbatch reads in from a text file, so the `<` is important. [More info on '<'](https://unix.stackexchange.com/questions/283374/what-does-the-left-chevron-triangle-bracket-do)
* env var arguments need to go FIRST when calling sbatch.

EXPECTED OUTPUT:
```
Submitted batch job 34740124
```
Remember that number (in this case 34740124). This is the JOBID. 

OK, the job has been submitted. You can check on it with the command:
```
$ squeue -u TUFTS_USERNAME
```
EXPECTED OUTPUT:
```
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
          34740124     batch   sbatch mhughe02  R       1:24      1 m3n46
          34740078     batch     bash mhughe02  R    1:10:58      1 alpha001
```
If you see status of 'R' then congrats! Your job is running!

You might alternatively see a status like 'PENDING' if the queue is very busy. Be patient!

#### How can I monitor my job while it runs?

You can use the `squeue -u TUFTS_USERNAME` call to check on all your jobs. When they are done, they will no longer appear in that list.

You can also look at the log_JOBID.out and log_JOBID.err log files, which are capturing the stdout and stderr of your jobs!

```
$ cat log_34740124.out
...
MNIST train data : 60000 binary images with raw shape (28,28).
Requested batch_size 100, so each epoch consists of 600 updates
==== evaluation after epoch 0
train data: 20000 images. Total pixels on: 2018998. Frac pixels on: 0.129
  epoch   0  on train per-pixel VI-loss 0.708  bce 0.696  l1 0.500
test data: 10000 images. Total pixels on: 1018438. Frac pixels on: 0.130
  epoch   0  on test  per-pixel VI-loss 0.708  bce 0.695  l1 0.500
====  done with eval at epoch 0
  epoch   1 | frac_seen 0.20 | avg loss  0.4286 | batch loss  0.3793 | batch l1  0.253
  epoch   1 | frac_seen 0.40 | avg loss  0.4052 | batch loss  0.3822 | batch l1  0.254
  epoch   1 | frac_seen 0.60 | avg loss  0.3951 | batch loss  0.3608 | batch l1  0.243
  epoch   1 | frac_seen 0.80 | avg loss  0.3881 | batch loss  0.3738 | batch l1  0.246
  epoch   1 | frac_seen 1.00 | avg loss  0.3833 | batch loss  0.3661 | batch l1  0.240
==== evaluation after epoch 1
  epoch   1  on train per-pixel VI-loss 0.397  bce 0.363  l1 0.240

...
```

### Step 3: How to launch many jobs at once

We'll need two scripts:
* one to loop over all settings [loop_many_experiments.sh](https://github.com/tufts-ml-courses/cs145BDL-26s-assignments/blob/main/hpc_guide/loop_many_experiments_hw4_ae.sh)
* one to do the work at each setting [do_experiment.slurm](https://github.com/tufts-ml-courses/cs145BDL-26s-assignments/blob/main/hpc_guide/do_experiment_hw4_ae.slurm)

Our desired end behavior is to just call the "loop_many_experiments_hw4_ae.sh" script with a desired action:
```
$ bash loop_many_experiments_hw4_ae.sh list      ## Just list out settings we'll explore
$ bash loop_many_experiments_hw4_ae.sh run_here  ## Run only first job here in this terminal (useful for debugging)
$ bash loop_many_experiments_hw4_ae.sh submit    ## Send the work to the HPC cluster to be scheduled, via 'sbatch'
```

As a test, please try the first command at your terminal. Don't try the others just yet.

```
$ bash launch_experiments.sh
/cluster/tufts/c26sp1cs0145/$USER//hw4-2026-AE-lr=0.001-arch=512
/cluster/tufts/c26sp1cs0145/$USER//hw4-2026-AE-lr=0.010-arch=512
/cluster/tufts/c26sp1cs0145/$USER//hw4-2026-AE-lr=0.100-arch=512
/cluster/tufts/c26sp1cs0145/$USER//hw4-2026-AE-lr=0.001-arch=032
/cluster/tufts/c26sp1cs0145/$USER//hw4-2026-AE-lr=0.010-arch=032
/cluster/tufts/c26sp1cs0145/$USER//hw4-2026-AE-lr=0.100-arch=032
```

Great! It's listing out all the settings we want to experiment with, and where it will save the results!

If you peek at loop_many_experiments.sh, you'll see that we:

* loop over all settings of the variables
* at each one call `do_experiment.slurm`

This loop uses [Unix Environment Variables](https://www.digitalocean.com/community/tutorials/how-to-read-and-set-environmental-and-shell-variables-on-a-linux-vps) to store and pass information between the two scripts.

There's a simple IF statement that controls whether we call bash and run locally (action='run_here') or call sbatch and let the grid do the work (action='submit').

OK, so let's try it! 

```
$ bash loop_many_experiments_hw4_ae.sh submit
/cluster/tufts/c26sp1cs0145/$USER//hw4-2026-AE-lr=0.001-arch=512
Submitted batch job 34740131
/cluster/tufts/c26sp1cs0145/$USER//hw4-2026-AE-lr=0.010-arch=512
Submitted batch job 34740132
/cluster/tufts/c26sp1cs0145/$USER//hw4-2026-AE-lr=0.100-arch=512
Submitted batch job 34740133
/cluster/tufts/c26sp1cs0145/$USER//hw4-2026-AE-lr=0.001-arch=032
Submitted batch job 34740134
/cluster/tufts/c26sp1cs0145/$USER//hw4-2026-AE-lr=0.010-arch=032
Submitted batch job 34740135
/cluster/tufts/c26sp1cs0145/$USER//hw4-2026-AE-lr=0.100-arch=032
Submitted batch job 34740136
```

Tada! You've submitted your first set of batch jobs! Now go get a coffee and let the machines work for you.
