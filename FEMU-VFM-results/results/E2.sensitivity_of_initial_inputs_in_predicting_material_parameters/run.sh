#!/bin/bash

# Prior to executing this script:
# 1. > source env/<FLAVOR>.sh
# 2. > source capp-setup.sh
# 3. > capp load
# 4. load your Python environment

# run command:
# > bash run.sh 2>&1 | tee run.out
# (time output will be in run.out)

MODEL="notch2D_Asym_finite_J2_plane_stress"

# use multiple processors to save time
NUM_PROC=4

# create the initial guesses and input files
NUM_DATA_SETS=10
RANDOM_SEED=22
python generate_initial_data_set_and_input_files.py -n ${NUM_DATA_SETS} -s ${RANDOM_SEED}

FORWARD="forward"
# only doing forward sensitivities vfm because adjoint vfm has
# the same gradient and is slower on small parameter problems
VFM="vfm"
# adjoint method for gradient (forward sensitivities not implemented)
PDECO="pdeco"

export PROBLEM="${FORWARD}_${MODEL}"
cd ${FORWARD}
echo "RUNNING ${PROBLEM}"
time mpirun -n ${NUM_PROC} primal ${PROBLEM}.yaml 2>&1 | tee "${PROBLEM}.out"
echo -e "COMPLETED ${PROBLEM}\n"
cd ..

INVERSE_TYPES=(${VFM} ${PDECO})

for INVERSE_TYPE in "${INVERSE_TYPES[@]}"; do
  cd ${INVERSE_TYPE}

  for idx in $(seq 0 $((${NUM_DATA_SETS} - 1))); do
    RUN_NAME="${INVERSE_TYPE}_run_${idx}"
    time mpirun -n ${NUM_PROC} inverse "${RUN_NAME}.yaml" 2>&1 | tee "${RUN_NAME}.out"
    echo -e "COMPLETED ${RUN_NAME}\n"
  done

  cd ..
done
