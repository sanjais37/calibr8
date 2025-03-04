#!/bin/bash

source_geo="../../../meshes/notch2D_Asym/notch2D_Asym.dmg"
source_mesh="../forward/forward_notch2D_Asym_finite_J2_plane_stress_synthetic"
num_steps=2

target_geo="../../../meshes/notch_Asym_3D_surface_to_2D/notch2D_Asym.dmg"
target_mesh="../../../meshes/notch_Asym_3D_surface_to_2D/notch2D_Asym.smb"

poly_order=3
power_kernel_exponent=2
epsilon_multiplier=2.6

outmesh="outmesh"

moving_least_squares_two_meshes ${source_geo} "${source_mesh}/" ${num_steps} \
  ${target_geo} ${target_mesh} \
  ${poly_order} ${power_kernel_exponent} ${epsilon_multiplier} \
  "${outmesh}/"

render ${source_geo} "${source_mesh}/" "${source_mesh}_viz"
render ${target_geo} "${outmesh}/" "${outmesh}_viz"
