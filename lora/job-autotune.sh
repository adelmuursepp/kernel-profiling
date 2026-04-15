#!/bin/bash
#SBATCH --job-name=lora_autotune
#SBATCH --partition=gpubase_bygpu_b2
#SBATCH --gres=gpu:h100:1
#SBATCH --mem=16G
#SBATCH --time=0-04:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

export HELION_AUTOTUNE_PRECOMPILE=spawn
mkdir -p logs

source ../../../add_path.sh

module load apptainer

apptainer exec --nv --env PYTHONPATH="$PYTHONPATH" ~/apptainer.sandbox python3.12 lora_helion_autotune.py
