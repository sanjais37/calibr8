#!/bin/bash

longer_geo_3d="../../../meshes/longer_notch_Asym_3D_surface_to_2D/longer_notch3D_Asym.dmg"
longer_mesh_3d="../forward/forward_notch3D_Asym_finite_J2_synthetic"
assoc_3d="../../../meshes/longer_notch_Asym_3D_surface_to_2D/longer_notch3D_Asym.txt"
num_steps=8
surface_set_name="zmin"

longer_geo_2d="../../../meshes/longer_notch_Asym_3D_surface_to_2D/longer_notch2D_Asym.dmg"
longer_mesh_2d="../../../meshes/longer_notch_Asym_3D_surface_to_2D/longer_notch2D_Asym.smb"

longer_outmesh="longer_notch2D"

transfer_surface_data ${longer_geo_3d} "${longer_mesh_3d}/" ${assoc_3d} ${num_steps} ${surface_set_name} ${longer_geo_2d} ${longer_mesh_2d} "${longer_outmesh}/"

render ${longer_geo_3d} "${longer_mesh_3d}/" "${longer_mesh_3d}_viz"
render ${longer_geo_2d} "${longer_outmesh}/" "${longer_mesh_2d}_viz"

source_geo=${longer_geo_2d}
source_mesh=${longer_outmesh}

target_geo="../../../meshes/notch_Asym_3D_surface_to_2D/notch2D_Asym.dmg"
target_mesh="../../../meshes/notch_Asym_3D_surface_to_2D/notch2D_Asym.smb"
outmesh="outmesh"

poly_order=3
power_kernel_exponent=2
epsilon_multiplier=2.6

moving_least_squares_two_meshes ${source_geo} "${source_mesh}/" ${num_steps} \
  ${target_geo} ${target_mesh} \
  ${poly_order} ${power_kernel_exponent} ${epsilon_multiplier} \
  "${outmesh}/"

render ${target_geo} "${outmesh}/" "${outmesh}_viz"

mpiexec -n 4 split ${target_geo} "${outmesh}/" "${outmesh}_4p/" 4
