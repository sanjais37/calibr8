import csv
import os
import argparse

def read_csv(file_path, delimiter=','):
    with open(file_path, mode='r') as file:
        reader = csv.DictReader(file, delimiter=delimiter)
        return [{key.strip(): value for key, value in row.items()} for row in reader]

def parse_arguments():
    parser = argparse.ArgumentParser(description="Calculate mean and error based on CSV data.")
    parser.add_argument('params_data', type=str, help='Path to the params data CSV file')
    parser.add_argument('truth_data', type=str, help='Path to the truth data parameters CSV file')
    parser.add_argument('Disp_Noise_Scale_Factor', type=float, help='Disp Noise Scale Factor')
    parser.add_argument('mean_file', type=str, help='Path to save the mean values file')
    parser.add_argument('error_file', type=str, help='Path to save the error values file')
    return parser.parse_args()

def calculate_mean_and_error(params_data, truth_data):
    mean_values = []
    errors_val = []
    for param_row in truth_data:
        param = param_row['params']
        true_value = float(param_row['True Values'])
        lower_bound = float(param_row['Lower bound'])
        upper_bound = float(param_row['Upper bound'])
        tolerance = float(param_row.get('Tolerance', 0.05))

        valid_data = [
            float(data_row[param]) for data_row in params_data 
            if lower_bound + tolerance <= float(data_row[param]) <= upper_bound - tolerance
        ]
        mean_val = sum(valid_data) / len(valid_data) if valid_data else 0
        mean_values.append(f"{param}: {mean_val:.12f}")
        if mean_val == 0.0:
          error = 0.0
        else:
          error = abs(mean_val - true_value)

        normalized_error = error / true_value
        errors_val.append(normalized_error)

    return mean_values, errors_val

def write_to_file(file_path, header, data):
    if not os.path.exists(file_path) or os.stat(file_path).st_size == 0:
        with open(file_path, 'a') as f:
            f.write(header + "\n")
    with open(file_path, 'a') as f:
        f.write(data + "\n")

def main():
    args = parse_arguments()
    params_data = read_csv(args.params_data)
    truth_data = read_csv(args.truth_data)
    mean_values, errors_val = calculate_mean_and_error(params_data, truth_data)

    while len(errors_val) < 3:
        errors_val.append(0.0)
    error_data = f"{args.Disp_Noise_Scale_Factor:.4e}," + ",".join(f"{e:.4e}" for e in errors_val)

    write_to_file(args.error_file, "Disp_Noise_Scale_Factor,Y,S,D", error_data)

    with open(args.mean_file, 'w') as f:
        for mean_value in mean_values:
            f.write(mean_value + "\n")

    print(f"Mean values and errors have been written to {args.mean_file} and {args.error_file}.")

if __name__ == '__main__':
    main()

