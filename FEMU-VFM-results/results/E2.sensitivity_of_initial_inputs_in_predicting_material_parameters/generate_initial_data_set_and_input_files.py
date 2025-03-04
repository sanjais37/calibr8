import numpy as np
import pandas as pd

import argparse
import yaml


class IndentDumper(yaml.Dumper):
    def increase_indent(self, flow=False, indentless=False):
        return super(IndentDumper, self).increase_indent(flow, False)


def get_materials_block(entire_yaml_input_file):
    top_key = list(entire_yaml_input_file.keys())[0]
    yaml_input_file = entire_yaml_input_file[top_key]
    local_residual_materials_block = \
        yaml_input_file["residuals"]["local residual"]["materials"]

    # only single block calibration problems are supported
    local_residual_elem_set_names = list(local_residual_materials_block.keys())
    inverse_materials_elem_set_names = list(local_residual_materials_block.keys())
    assert local_residual_elem_set_names == inverse_materials_elem_set_names
    assert len(local_residual_elem_set_names) == 1
    elem_set_name = local_residual_elem_set_names[0]

    local_residual_params_block = local_residual_materials_block[elem_set_name]

    return local_residual_params_block


def update_yaml_input_file_parameters(input_yaml, param_names, param_values):

    local_residual_params_block = \
        get_materials_block(input_yaml)

    for param_name, param_value in zip(param_names, param_values):
        local_residual_params_block[param_name] = float(param_value)


def generate_data(n, rng):
    # Define the bounds for each quantity
    bounds = {
        'E': [100.e3, 300.e3],
        'nu': [0.23, 0.35],
        'Y': [250., 400.],
        'S': [800., 1150.],
        'D': [2., 12.]
    }

    # Generate random data within the bounds
    data = {
        'E': rng.uniform(bounds['E'][0], bounds['E'][1], n),
        'nu': rng.uniform(bounds['nu'][0], bounds['nu'][1], n),
        'Y': rng.uniform(bounds['Y'][0], bounds['Y'][1], n),
        'S': rng.uniform(bounds['S'][0], bounds['S'][1], n),
        'D': rng.uniform(bounds['D'][0], bounds['D'][1], n)
    }

    # Create a DataFrame
    df = pd.DataFrame(data)

    return df

def main():
    parser = \
        argparse.ArgumentParser(
            description="generate random initial guesses and input files"
        )
    parser.add_argument("-n", "--num_data_sets", type=int,
        help="number of data sets")
    parser.add_argument("-s", "--seed", type=int, default=22,
        help="random seed")

    args = parser.parse_args()

    num_data_sets = args.num_data_sets
    seed = args.seed

    # numpy's latest guidance on random number generation
    # suggests using "generators" instead of np.random.uniform

    # setting a random seed is necessary for reproducibility
    seed = 22
    rng = np.random.default_rng(seed)

    # Generate data and save to CSV
    df = generate_data(num_data_sets, rng)
    filename = "mat_data_initial.csv"
    df.to_csv(filename, index=False)
    print(f"Data saved to {filename}")


    param_names = list(df.columns)
    problem_str = "notch2D_Asym_finite_J2_plane_stress"

    inverse_methods = ("vfm", "pdeco")

    for inverse_method in inverse_methods:
        inverse_dir = f"{inverse_method}/"
        inverse_input_file = f"{inverse_dir}{inverse_method}_{problem_str}.yaml"

        with open(inverse_input_file, "r") as file:
            input_yaml = yaml.safe_load(file)

        for idx in range(num_data_sets):
            update_yaml_input_file_parameters(input_yaml, param_names,
                df.iloc[idx].values)
            output_file = f"{inverse_dir}{inverse_method}_run_{idx}.yaml"
            with open(output_file, "w") as file:
                yaml.dump(input_yaml, file, default_flow_style=False,
                    sort_keys=False, Dumper=IndentDumper)


if __name__ == "__main__":
    main()
