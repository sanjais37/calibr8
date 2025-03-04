#!/bin/bash
set -e

# Record start time
start_time=$(date +%s)

# Prior to executing this script:
# 1. > source env/<FLAVOR>.sh
# 2. > source capp-setup.sh
# 3. > capp load
# 4. (set up Python environment)

# run command:
# > bash run.sh 2>&1 | tee run.out
# (any 'time' output will be in run.out)

NUM_PROC=4
TIME_STEPS=8
THICKNESS="0.08"
# compute error in load and displacement using calibrated params
CALIBRATE="true"  ## true or false (Add 0 noise case for load and disp noise scale factor additionally if true)
FILTER="false"

MODEL="notch3D_Asym_finite_J2"
DMG_FILE="../../../../../../meshes/longer_notch_Asym_3D_surface_to_2D/thickness_${THICKNESS}/notch3D_Asym.dmg"
MESH_FILE="../forward/forward_notch3D_Asym_finite_J2_synthetic"
ASSOC_FILE="../../../../../../meshes/longer_notch_Asym_3D_surface_to_2D/thickness_${THICKNESS}/notch3D_Asym.txt"
SURFACE_SET_NAME="zmin"

MODEL_PLANE_STRESS="notch2D_Asym_finite_J2_plane_stress"
DMG_FILE_PLANE_STRESS="../../../../../../meshes/longer_notch_Asym_3D_surface_to_2D/thickness_${THICKNESS}/notch2D_Asym.dmg"
MESH_FILE_PLANE_STRESS="../../../../../../meshes/longer_notch_Asym_3D_surface_to_2D/thickness_${THICKNESS}/notch2D_Asym.smb"

INVERSE_3D_DMG_FILE="../../../../../../meshes/notch_Asym_3D_surface_to_2D/thickness_${THICKNESS}/notch3D_Asym.dmg"
INVERSE_3D_SMB_FILE="../../../../../../meshes/notch_Asym_3D_surface_to_2D/thickness_${THICKNESS}/notch3D_Asym.smb"
INVERSE_DMG_FILE="../../../../../../meshes/notch_Asym_3D_surface_to_2D/thickness_${THICKNESS}/notch2D_Asym.dmg"
INVERSE_SMB_FILE="../../../../../../meshes/notch_Asym_3D_surface_to_2D/thickness_${THICKNESS}/notch2D_Asym.smb"

ADD_NOISE_TO_LOAD="../../../../../scripts/add_noise_to_load.py"
PYTHON_INVERSE="../../../../../../scripts/python_inverse.py"
GENERATE_INIT_GUESS="./pb_scripts/generate_initial_data_set.py"
TXT_TO_CSV_APPEND="../../../pb_scripts/txt_to_CSV_append.py"
PARAMS_APPEND="calibrated_parameters_diff_initial_guess.csv"
TRUTH_DATA="../../../truth_data_params_bounds.csv"
COMPUTE_MEAN_ERROR="../../../pb_scripts/compute_mean_error.py"

SMB_FILTERED="filtered"
POLY_ORDER=3
POWER_KERNEL_EXPONENT=2
EPSILON_MULTIPLIER=2.6

MAT_INIT_GUESS="mat_data_initial.csv"
SEED_RAND_DATA_SETS=22
SKIP_HEADER="true"
NUM_RAND_DATA_SET=1

FORWARD="forward"
INVERSE="inverse"
PDECO="pdeco_adjoint"
VFM_FS="vfm_forward_sens"
INVERSE_TEMPLATES_DIR="../../input_file_templates"


# add noise according to integer scale factors
LOAD_NOISE_SCALE_FACTORS=("0")            #format ("0" "1" "5")
DISP_NOISE_SCALE_FACTORS=("0")            #format ("0" "0.5" "1" "2" "5")

RANDOM_NOISE_SEED=37
NOISY_DIR_PREFIX="noisy"
NOISY_SMB_NAME="${NOISY_DIR_PREFIX}_synthetic"
NOISY_DISP_DIR="${NOISY_DIR_PREFIX}_displacement_data"
NOISY_LOAD_DIR="${NOISY_DIR_PREFIX}_load_data"
CALIBRATION_DIR="compute_load_disp_error"

# undeformed sample length
L_Y=1.0
# computed using the formula from the paper
# (this is likely a conservative estimate for the noise)
DISP_EPS_STAR_NOISE=$(echo "scale=10; 0.01 * ${L_Y} / (0.8 * 2048)" | bc)
printf "DISP_EPS_STAR_NOISE = %.4e\n" $DISP_EPS_STAR_NOISE

# rough guess of typical load measurement noise standard deviation in Newtons
# see forward/noisy_load.pdf
LOAD_EPS_STAR_NOISE="0.25"

# run the forward problem to generate noiseless displacement and load data
PROBLEM=${FORWARD}_${MODEL}
PROBLEM_PLANE_STRESS=${FORWARD}_${MODEL_PLANE_STRESS}
cd ${FORWARD}
sed -e "s/THICKNESS/${THICKNESS}/" \
    "${PROBLEM}.yaml" > "temp_${PROBLEM}.yaml"
sed -e "s/THICKNESS/${THICKNESS}/" \
    "${PROBLEM_PLANE_STRESS}.yaml" > "temp_${PROBLEM_PLANE_STRESS}.yaml"    
echo "RUNNING ${PROBLEM}"
mpirun -n ${NUM_PROC} primal temp_${PROBLEM}.yaml 2>&1 | tee "${PROBLEM}.txt"
echo -e "COMPLETED ${PROBLEM}\n"
echo "RUNNING ${PROBLEM_PLANE_STRESS}"
mpirun -n ${NUM_PROC} primal temp_${PROBLEM_PLANE_STRESS}.yaml 2>&1 | tee "${PROBLEM_PLANE_STRESS}.txt"
rm -rf temp*
echo -e "COMPLETED ${PROBLEM_PLANE_STRESS}\n"

# write to a file for add_noise_to_load.py
printf "%d\n" "${LOAD_NOISE_SCALE_FACTORS[@]}" > load_noise_scale_factors.txt

# remove any previously generated noisy datasets
rm -rf ${NOISY_DIR_PREFIX}*

# create dir for noisy displacement data
mkdir -p ${NOISY_DISP_DIR}
cd ${NOISY_DISP_DIR}
# generate the noisy displacement datasets
for DISP_NOISE_SCALE_FACTOR in "${DISP_NOISE_SCALE_FACTORS[@]}"; do
  NOISY_DIR="${NOISY_DIR_PREFIX}_${DISP_NOISE_SCALE_FACTOR}x"
  mkdir ${NOISY_DIR}
  cd ${NOISY_DIR}
  DISP_NOISE_FACTOR=$(echo "scale=10; ${DISP_NOISE_SCALE_FACTOR} * ${DISP_EPS_STAR_NOISE}" | bc)
  mpirun -n ${NUM_PROC} perturber ${DMG_FILE} "../../${PROBLEM}_synthetic/" \
          ${TIME_STEPS} ${RANDOM_NOISE_SEED} ${DISP_NOISE_FACTOR} "$NOISY_SMB_NAME/"
  mpirun -n ${NUM_PROC} render ${DMG_FILE} "${NOISY_SMB_NAME}/" "${NOISY_SMB_NAME}_viz"
  # Apply filter to noisy data
  if [ "$FILTER" = true ]; then
    echo -e "Applying filtering\n"
    mv "${NOISY_SMB_NAME}/" "unfiltered_${NOISY_SMB_NAME}/"
    mv "${NOISY_SMB_NAME}_viz/" "unfiltered_${NOISY_SMB_NAME}_viz/"
    mpirun -n ${NUM_PROC} collapse ${DMG_FILE} "unfiltered_${NOISY_SMB_NAME}/" \
           "serial_${NOISY_SMB_NAME}/" ${NUM_PROC}
    moving_least_squares ${DMG_FILE} "serial_${NOISY_SMB_NAME}/" ${TIME_STEPS} \
            ${POLY_ORDER} ${POWER_KERNEL_EXPONENT} ${EPSILON_MULTIPLIER} "filtered_${NOISY_SMB_NAME}/"
    render ${DMG_FILE} "filtered_${NOISY_SMB_NAME}/" "filtered_${NOISY_SMB_NAME}_VIZ"
    mpirun -n ${NUM_PROC} split ${DMG_FILE} "filtered_${NOISY_SMB_NAME}/" "${NOISY_SMB_NAME}/" ${NUM_PROC}
    mpirun -n ${NUM_PROC} render ${DMG_FILE} "${NOISY_SMB_NAME}/" "${NOISY_SMB_NAME}_viz"
    rm -rf serial*
    echo -e "MLS filtering applied successfully to the displacement noisy data: '${DISP_NOISE_SCALE_FACTOR}x'\n"
  fi
  #writing 3D data to 3D smaller geometry
  mpirun -n ${NUM_PROC} collapse ${DMG_FILE} "${NOISY_SMB_NAME}/" \
           "serial_${NOISY_SMB_NAME}/" ${NUM_PROC}
  moving_least_squares_two_meshes ${DMG_FILE} "serial_${NOISY_SMB_NAME}/" \
   ${TIME_STEPS} ${INVERSE_3D_DMG_FILE} ${INVERSE_3D_SMB_FILE} ${POLY_ORDER} ${POWER_KERNEL_EXPONENT} \
   ${EPSILON_MULTIPLIER} "serial_synthetic/"
  mpirun -n ${NUM_PROC} split ${INVERSE_3D_DMG_FILE} "serial_synthetic/" \
          "${NOISY_SMB_NAME}/" ${NUM_PROC}
  mpirun -n ${NUM_PROC} render ${INVERSE_3D_DMG_FILE} "${NOISY_SMB_NAME}/" \
          "${NOISY_SMB_NAME}_viz"
  rm -rf  serial_synthetic
  #write 3D data to 2D surface of same geometry then to 2D smaller geometry for inverse problem
  transfer_surface_data ${DMG_FILE} "serial_${NOISY_SMB_NAME}/" ${ASSOC_FILE} ${TIME_STEPS} \
           ${SURFACE_SET_NAME} ${DMG_FILE_PLANE_STRESS} ${MESH_FILE_PLANE_STRESS} \
           "serial_longer_synthetic_plane_stress/"
  render ${DMG_FILE_PLANE_STRESS} "serial_longer_synthetic_plane_stress/" \
   "serial_longer_synthetic_plane_stress_viz"
  moving_least_squares_two_meshes ${DMG_FILE_PLANE_STRESS} "serial_longer_synthetic_plane_stress/" \
   ${TIME_STEPS} ${INVERSE_DMG_FILE} ${INVERSE_SMB_FILE} ${POLY_ORDER} ${POWER_KERNEL_EXPONENT} \
   ${EPSILON_MULTIPLIER} "serial_synthetic_plane_stress/"
  mpirun -n ${NUM_PROC} split ${DMG_FILE} "serial_synthetic_plane_stress/" \
          "${NOISY_SMB_NAME}_plane_stress/" ${NUM_PROC}
  mpirun -n ${NUM_PROC} render ${DMG_FILE} "${NOISY_SMB_NAME}_plane_stress/" \
          "${NOISY_SMB_NAME}_plane_stress_viz"
 rm -rf serial_longer_synthetic_plane_stress serial_${NOISY_SMB_NAME} serial_synthetic_plane_stress
  cd ..
done
cd ..

# create dir for noisy load data
mkdir -p ${NOISY_LOAD_DIR}
cd ${NOISY_LOAD_DIR}
# generate the noisy load datasets
python3 $ADD_NOISE_TO_LOAD "../load_3D.dat" ${LOAD_EPS_STAR_NOISE} "../load_noise_scale_factors.txt" \
        ${RANDOM_NOISE_SEED} ${NOISY_DIR_PREFIX}
cd ../..

# generate parameters initial guess
python3 "${GENERATE_INIT_GUESS}" ${SEED_RAND_DATA_SETS} ${NUM_RAND_DATA_SET} ${MAT_INIT_GUESS}

# read the parameters initial data
mat_data=()
while IFS=, read -r Y S D; do
  # Skip the header
  if [ "$SKIP_HEADER" = true ]; then
    SKIP_HEADER=false
    continue
  fi
  # Store the parameters as tuples in an array
  mat_data+=("$Y,$S,$D")
done < "${MAT_INIT_GUESS}"

cd ${CALIBRATION_DIR}
rm -rf *.txt *.out *.dat *.pdf temp_*
cd ..

# copy input file templates and run PDECO and VFM inversions
cd ${INVERSE}
rm -rf ${NOISY_DIR_PREFIX}* *.txt *.pdf
PROBLEM_TYPES=(${VFM_FS} ${PDECO} 3D_${PDECO})
#MODELS=(${MODEL} ${MODEL_PLANE_STRESS} ${MODEL_PLANE_STRESS})
#PROBLEM_TYPES=(${PDECO} ${VFM_FS} 3D_${PDECO})
MODELS=(${MODEL_PLANE_STRESS} ${MODEL_PLANE_STRESS} ${MODEL})
for LOAD_NOISE_SCALE_FACTOR in "${LOAD_NOISE_SCALE_FACTORS[@]}"; do
  HEADER_CAL=true
  LOAD_NOISE_DIR="${NOISY_DIR_PREFIX}_load_${LOAD_NOISE_SCALE_FACTOR}x"
  mkdir ${LOAD_NOISE_DIR}
  cd ${LOAD_NOISE_DIR}
  for DISP_NOISE_SCALE_FACTOR in "${DISP_NOISE_SCALE_FACTORS[@]}"; do
    NOISY_DISP_DIR="${NOISY_DIR_PREFIX}_disp_${DISP_NOISE_SCALE_FACTOR}x"
    mkdir ${NOISY_DISP_DIR}
    cd ${NOISY_DISP_DIR}
    model_idx=-1
    for PROBLEM_TYPE in "${PROBLEM_TYPES[@]}"; do
      model_idx=$((model_idx + 1))
      PROBLEM="${PROBLEM_TYPE}_${MODELS[model_idx]}"
      TEMPLATE_INPUT_FILE="${INVERSE_TEMPLATES_DIR}/template_${PROBLEM}.yaml"
      INPUT_FILE="${PROBLEM}.yaml"
      num_guess=0
      for row in "${mat_data[@]}"; do
        IFS=',' read -r Y S D <<< "$row"
        # Remove commas from Y, S, and D
        Y=$(echo "$Y" | tr -d ',')
        S=$(echo "$S" | tr -d ',')
        D=$(echo "$D" | tr -d ',')
        # Print the processed values
        num_guess=$((num_guess + 1))
        echo "Initial guess::${num_guess} => Y: $Y, S: $S, D: $D"

        sed -e "s/NOISE_SCALE_FACTOR/${LOAD_NOISE_SCALE_FACTOR}/" \
            -e "s/DISP_NOISE_FACTOR/${DISP_NOISE_SCALE_FACTOR}/" \
            -e "s/THICKNESS/${THICKNESS}/" \
            -e "s/Y_VAL/${Y}/" \
            -e "s/S_VAL/${S}/" \
            -e "s/D_VAL/${D}/" \
            "${TEMPLATE_INPUT_FILE}" > "${INPUT_FILE}"

        # Print and run the python script
        echo "RUNNING ${LOAD_NOISE_DIR} ${NOISY_DISP_DIR} ${PROBLEM}"
        time python3 ${PYTHON_INVERSE} ${INPUT_FILE} -n ${NUM_PROC} 2>&1 | tee "${PROBLEM}.out"

        # Print calibrated parameters
        echo -e "CALIBRATED PARAMS:\n"
        cat "calibrated_params.txt"

        python3 "${TXT_TO_CSV_APPEND}" "${PROBLEM_TYPE}_${PARAMS_APPEND}" calibrated_params.txt

        # Print completion message
        echo -e "COMPLETED ${LOAD_NOISE_DIR} ${NOISY_DISP_DIR} ${PROBLEM}\n"
      done

      OUTPUT_FILE="${PROBLEM_TYPE}_${NOISY_DIR_PREFIX}_load_${LOAD_NOISE_SCALE_FACTOR}x.txt"

      python3 "${COMPUTE_MEAN_ERROR}" "${PROBLEM_TYPE}_${PARAMS_APPEND}" "${TRUTH_DATA}" \
        ${DISP_NOISE_SCALE_FACTOR} "mean_${PROBLEM_TYPE}_calibrated_params.txt" \
        "../../params_error_${OUTPUT_FILE}"

      if [ "$CALIBRATE" = true ]; then
        # calibration for load and displacement error
        CALIBRATION_OBJ_FILE="objective_${PROBLEM_TYPE}_calibration.dat"
        PROBLEM="calibration_${PROBLEM_TYPE}_${MODELS[model_idx]}"

        mean_file="mean_${PROBLEM_TYPE}_calibrated_params.txt"

        while IFS=':' read -r key value; do
          key=$(echo $key | xargs)
          value=$(echo $value | xargs)

          # Assign values to the respective variables
          case "$key" in
            "Y") mean_Y="$value" ;;
            "S") mean_S="$value" ;;
            "D") mean_D="$value" ;;
          esac
        done < "${mean_file}"

        CURRENT_DIR=$(pwd)
        cd "../../../${CALIBRATION_DIR}"
        if [ "$HEADER_CAL" = true ]; then
          echo "disp_noise_scale_factor,error_displacement, error_load" > "load_disp_error_${OUTPUT_FILE}"
        fi

        # Check if any of the values is zero
        if (( $(echo "$mean_Y == 0" | bc -l) || $(echo "$mean_S == 0" | bc -l) || $(echo "$mean_D == 0" | bc -l) )); then
          echo "One or more parameters hit the bounds. Y=$mean_Y, S=$mean_S, D=$mean_D"
        else
          sed -e "s/SMB_DATA_PATH/${FORWARD}_${MODELS[model_idx]}/" \
              -e "s/THICKNESS/${THICKNESS}/" \
              -e "s/Y_VAL/${mean_Y}/" \
              -e "s/S_VAL/${mean_S}/" \
              -e "s/D_VAL/${mean_D}/" \
              "${PROBLEM}.yaml" > "temp_${PROBLEM}.yaml"

          echo "RUNNING calibration ${LOAD_NOISE_DIR} ${NOISY_DISP_DIR} ${PROBLEM}"
          mpirun -n ${NUM_PROC} primal "temp_${PROBLEM}.yaml"

          err_disp=$(awk '{sum+=$1} END {print sum}' "${CALIBRATION_OBJ_FILE}")
          err_load=$(awk '{sum+=$2} END {print sum}' "${CALIBRATION_OBJ_FILE}")

          echo "${DISP_NOISE_SCALE_FACTOR},$err_disp,$err_load" >> "load_disp_error_${OUTPUT_FILE}"

          rm -rf "temp_${PROBLEM}.yaml"
          echo -e "COMPLETED calibration ${LOAD_NOISE_DIR} ${NOISY_DISP_DIR} ${PROBLEM}\n"
        fi
        cd "${CURRENT_DIR}"
      fi
    done
    HEADER_CAL=false #TODO update
    cd ..
  done
  cd ..
done
cd ..

# tree package is needed
echo "===After successfully running the bash file directory tree with outputs=====" > directory_tree.txt
tree >> directory_tree.txt

# Record end time
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
elapsed_minutes=$(echo "scale=2; $elapsed_time / 60" | bc)
echo "Total elapsed time: $elapsed_minutes minutes"

