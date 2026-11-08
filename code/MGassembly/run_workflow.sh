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

# Navigate to the workflow directory. SLURM_SUBMIT_DIR is the directory from
# which `sbatch` was invoked, so this script must be submitted from the
# workflow directory (the one containing the Snakefile and config.yaml).
cd "$SLURM_SUBMIT_DIR" || exit 1
if [[ ! -f Snakefile || ! -f config.yaml ]]; then
    echo "Error: Snakefile and/or config.yaml not found in $(pwd)." >&2
    echo "Submit this script from the MGassembly workflow directory." >&2
    exit 1
fi

# Make sure Apptainer is added to plat
export PATH=/usr/bin/apptainer:$PATH

echo "Starting Snakemake workflow on batch node..."
echo "Current directory: $(pwd)"
echo "Snakemake version: $(snakemake --version)"

# Bind mounts for Apptainer. The PLBS is mounted at /opt/plbs inside the
# container, and the processed-data directory (processed_data_root in
# config.yaml) is bound at its absolute host path so containerized rules can
# write to it. A relative processed_data_root is resolved against the workflow
# directory, matching how Snakemake interprets it.
PLBS_DIR="/home/uwm/petersob/Data/Peterson_Lab_Bioinformatics_Scaffold"
PROCESSED_DATA_ROOT=$(sed -nE 's/^processed_data_root:[[:space:]]*"?([^"#]*[^"#[:space:]])"?.*$/\1/p' config.yaml)
if [[ -z "$PROCESSED_DATA_ROOT" ]]; then
    echo "Error: could not read processed_data_root from config.yaml." >&2
    exit 1
fi
mkdir -p "$PROCESSED_DATA_ROOT"
WORKSHOP_DIR=$(cd "$PROCESSED_DATA_ROOT" && pwd -P)
echo "Processed data directory: $WORKSHOP_DIR"

# Run Snakemake with your profile
# The --profile slurm ensures that individual rules are submitted to Slurm
# by the Snakemake master process running on this batch node.
# --apptainer-args on the command line overrides the value in the profile.
snakemake --workflow-profile profiles/slurm --keep-going --rerun-incomplete \
    --apptainer-args "--bind ${PLBS_DIR}:/opt/plbs --bind ${WORKSHOP_DIR}:${WORKSHOP_DIR}:rw"

echo "Snakemake workflow finished."