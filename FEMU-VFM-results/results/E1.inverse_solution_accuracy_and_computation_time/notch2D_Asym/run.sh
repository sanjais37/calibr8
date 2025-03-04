#!/bin/bash

# Prior to executing this script:
# 1. > source env/<FLAVOR>.sh
# 2. > source capp-setup.sh
# 3. > capp load

# run command:
# > bash run.sh 2>&1 | tee run.out
# (time output will be in run.out)

# "all_params" runs perform finite difference checks before optimization

MODEL="notch2D_Asym_finite_J2_plane_stress"

FORWARD="forward"
VFM_FS="vfm_forward_sens"
VFM_ADJOINT="vfm_adjoint"
VFM_FD="vfm_finite_difference"
PDECO_ADJOINT="pdeco_adjoint"
PDECO_FD="pdeco_finite_difference"

PARAM_TYPES=("plastic_params_only" "all_params")

export PROBLEM="${FORWARD}_${MODEL}"
cd ${FORWARD}
echo "RUNNING ${PROBLEM}"
time mpirun -n 1 primal ${PROBLEM}.yaml 2>&1 | tee "${PROBLEM}.txt"
echo -e "COMPLETED ${PROBLEM}\n"
cd ..

for PARAM_TYPE in "${PARAM_TYPES[@]}"; do
  cd ${PARAM_TYPE}

  export PROBLEM="${VFM_FS}_${MODEL}"
  cd ${VFM_FS}
  echo "RUNNING ${PARAM_TYPE}: ${PROBLEM}"
  time mpirun -n 1 inverse ${PROBLEM}.yaml 2>&1 | tee "${PROBLEM}.txt"
  echo -e "COMPLETED ${PROBLEM}\n"
  cd ..

  export PROBLEM="${VFM_ADJOINT}_${MODEL}"
  cd ${VFM_ADJOINT}
  echo "RUNNING ${PARAM_TYPE}: ${PROBLEM}"
  time mpirun -n 1 inverse ${PROBLEM}.yaml 2>&1 | tee "${PROBLEM}.txt"
  echo -e "COMPLETED ${PROBLEM}\n"
  cd ..

  export PROBLEM="${VFM_FD}_${MODEL}"
  cd ${VFM_FD}
  echo "RUNNING ${PARAM_TYPE}: ${PROBLEM}"
  time mpirun -n 1 inverse ${PROBLEM}.yaml 2>&1 | tee "${PROBLEM}.txt"
  echo -e "COMPLETED ${PROBLEM}\n"
  cd ..

  export PROBLEM="${PDECO_ADJOINT}_${MODEL}"
  cd ${PDECO_ADJOINT}
  echo "RUNNING ${PARAM_TYPE}: ${PROBLEM}"
  time mpirun -n 1 inverse ${PROBLEM}.yaml 2>&1 | tee "${PROBLEM}.txt"
  echo -e "COMPLETED ${PROBLEM}\n"
  cd ..

  export PROBLEM="${PDECO_FD}_${MODEL}"
  cd ${PDECO_FD}
  echo "RUNNING ${PARAM_TYPE}: ${PROBLEM}"
  time mpirun -n 1 inverse ${PROBLEM}.yaml 2>&1 | tee "${PROBLEM}.txt"
  echo -e "COMPLETED ${PROBLEM}\n"
  cd ..

  cd ..
done
