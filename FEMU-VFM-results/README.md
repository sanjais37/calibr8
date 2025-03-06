The numerical results reported in the article titled "A comparative study of calibration techniques for finite strain elastoplasticity: Numerically-exact sensitivities for FEMU and VFM" are organized in the `results` folder, which contains problem-specific subdirectories. Each subdirectory holds a complete set of problem data (inputs and outputs), with the exception of the `mesh` files.

## Problems:

1. inverse_solution_accuracy_and_computation_time
2. sensitivity_of_initial_inputs_in_predicting_material_parameters
3. noisy-data
   - unfiltered_inverse_solution_accuracy_with_noisy_data
   - filtered_inverse_solution_accuracy_with_noisy_data
4. hardening-misspecification
   - model_form_error_hardening_misspecification_K_0
   - model_form_error_hardening_misspecification_with_Kparam
5. model_form_error_mesh_density
6. model_form_error_plane_stress_assumption
   - model_form_error_longer_3D_2D_surface_data

## How to run:

1. For each of the above problems separate bash file `run.sh` is provided in the respective problem subdirectory inside `results` directory which generates the complete output for that problem. Execute the following run command:
 - run command:
 `bash run.sh 2>&1 | tee run.out`

2. Prior to executing this `run.sh` script, execute the following inside the `calibr8 root` directory to enable the `Calibr8` environment:
 - `source env/<FLAVOR>.sh`  (e.g., source env/linux-shared.sh)
 - `source capp-setup.sh`
 - `capp load`
 -  set up Python environment

3. Choose the `FLAVOR` depending on your operating system (OS). Presently, `Calibr8` supports the following flavors:
   - cee-shared
   - cee-static 
   - linux-shared
   - osx-shared
   - osx-shared
   - toss3-static
   
## Additional Information

 - Make sure to have the required environment set up before running the problems.
 - The example files in the `examples` directory (located in the root) illustrate various inverse use cases, including FEMU (PDECO) and VFM, using different gradient computation methods such as finite differences (FD), Adjoint, and Forward Sensitivity (FS)
 
 -  For `Calibr8` installation details, visit: [Calibr8 GitHub Repository](https://github.com/sandialabs/calibr8)
 
 - The `SHA` key is provided for each problem to enable version control, if required.
 
## Troubleshooting

 If you encounter issues, make sure that:

 - The environment is correctly sourced.
 - All dependencies are properly installed.
 - You are using the correct `FLAVOR` for your operating system.

## Citation (bib)
 
 
 
 
 
