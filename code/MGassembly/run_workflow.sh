#!/bin/bash
#SBATCH --job-name=snakemake_workflow_MGassembly
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=240:00:00
#SBATCH --output=snakemake_master_%j.out
#SBATCH --error=snakemake_master_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=petersob@uwm.edu

# Activate the conda environment where Snakemake is installed
source /tank/data/LS/petersob/petersob/conda/bin/activate
conda activate snakemake_env

# Navigate to your workflow directory
cd /home/uwm/petersob/Data/petersob/dataProcessing_GLWCHg_LE_PRE_MG/code/MGassembly

# Make sure Apptainer is added to plat
export PATH=/usr/bin/apptainer:$PATH

echo "Starting Snakemake workflow on batch node..."
echo "Current directory: $(pwd)"
echo "Snakemake version: $(snakemake --version)"

# Run Snakemake with your profile
# The --profile slurm ensures that individual rules are submitted to Slurm
# by the Snakemake master process running on this batch node.
snakemake --workflow-profile profiles/slurm --keep-going --rerun-incomplete

echo "Snakemake workflow finished."