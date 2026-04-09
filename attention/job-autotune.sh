#!/bin/bash
#SBATCH --job-name=attention_autotune
#SBATCH --partition=gpubase_bygpu_b2
#SBATCH --gres=gpu:h100:1
#SBATCH --mem=16G
#SBATCH --time=0-04:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

export HELION_AUTOTUNE_COMPILE_TIMEOUT=120
export HELION_AUTOTUNE_PRECOMPILE=fork

mkdir -p logs

module load apptainer

apptainer exec --nv ~/apptainer.sandbox python3 attention_helion_autotune.py
