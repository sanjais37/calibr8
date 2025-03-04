import numpy as np
import argparse
import csv

def generate_data(n, rng):
    # Define the bounds for each params
    bounds = {
        'Y': [250., 400.],
        'S': [800., 1150.],
        'D': [2., 12.]
    }

    data = []
    for _ in range(n):
        row = {
            'Y': rng.uniform(bounds['Y'][0], bounds['Y'][1]),
            'S': rng.uniform(bounds['S'][0], bounds['S'][1]),
            'D': rng.uniform(bounds['D'][0], bounds['D'][1])
        }
        data.append(row)

    return data

def save_to_csv(data, filename):
    header = ['Y', 'S', 'D']
    with open(filename, mode='w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=header)
        writer.writeheader()
        writer.writerows(data)
    print(f"Initial parameters guess saved to {filename}")

def main():
    parser = argparse.ArgumentParser(description="Generate synthetic data and save")
    parser.add_argument('seed', type=int, default=22, help='Random seed for reproducibility (default: 22)')
    parser.add_argument('num_data_sets', type=int, default=10, help='Number of data points to generate (default: 10)')
    parser.add_argument('filename', type=str, default="mat_data_initial.csv", help='Filename to save the data (default: "mat_data_initial.csv")')

    args = parser.parse_args()
    rng = np.random.default_rng(args.seed)
    data = generate_data(args.num_data_sets, rng)
    save_to_csv(data, args.filename)

if __name__ == "__main__":
    main()

