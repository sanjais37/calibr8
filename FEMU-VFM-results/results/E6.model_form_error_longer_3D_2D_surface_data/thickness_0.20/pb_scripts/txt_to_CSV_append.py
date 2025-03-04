import os
import csv
import argparse

def read_temp_file(temp_file):
    temp_data = {}
    with open(temp_file, 'r') as file:
        for line in file:
            key, value = line.strip().split(':')
            temp_data[key.strip()] = float(value.strip())
    return temp_data

def append_to_csv(main_file, data):
    file_exists = os.path.isfile(main_file)
    with open(main_file, mode='a', newline='') as file:
        writer = csv.writer(file)
        if not file_exists:
            writer.writerow(['Y', 'S', 'D'])
        # Write the data
        writer.writerow([data['Y'], data['S'], data['D']])

def main(main_csv_file, temp_txt_file):
    temp_data = read_temp_file(temp_txt_file)
    append_to_csv(main_csv_file, temp_data)

# Setup argument parser
def setup_parser():
    parser = argparse.ArgumentParser(description="Append data from temp.txt to main.csv")
    parser.add_argument('main_csv_file', type=str, help="The main CSV file to append data to")
    parser.add_argument('temp_txt_file', type=str, help="The temporary text file containing the data")
    return parser

if __name__ == "__main__":
    # Setup argument parser and parse arguments
    parser = setup_parser()
    args = parser.parse_args()

    main(args.main_csv_file, args.temp_txt_file)

