#!/bin/bash
#SBATCH --job-name=attention_autotune
#SBATCH --partition=gpubase_bygpu_b2
#SBATCH --gres=gpu:h100:1
#SBATCH --mem=32G
#SBATCH --time=1-00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

export HELION_AUTOTUNE_COMPILE_TIMEOUT=600
export HELION_AUTOTUNE_PRECOMPILE=spawn

mkdir -p logs

module load apptainer

apptainer exec --nv ~/apptainer.sandbox python3 attention_helion_autotune.py
