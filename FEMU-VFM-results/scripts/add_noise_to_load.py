import numpy as np
import matplotlib.pyplot as plt

import argparse


def plot_noisy_load(noiseless_load, noise, scale_factors):
    steps = np.arange(len(noiseless_load))

    fig, ax = plt.subplots(figsize=(11, 8))
    ax.scatter(steps, noiseless_load, zorder=0, label="Noiseless",
        color="black")

    for idx, scale_factor in enumerate(scale_factors):
        ax.scatter(steps, noiseless_load + scale_factor * noise, zorder=idx,
            label=f"{scale_factor}x")

    ax.set_xlabel("Load Step #", fontsize=22)
    ax.set_ylabel("Load (N)", fontsize=22)
    ax.set_title("Net Load y-component on Top Surface", fontsize=22)
    ax.legend(loc="best", fontsize=20)
    fig.savefig("noisy_load.pdf")


def main():
    parser = argparse.ArgumentParser(description="add noise to the load data")
    parser.add_argument("noiseless_load_file", type=str,
        help="file that contains the noiseless load data")
    parser.add_argument("base_noise_level", type=float,
        help="base level of load noise")
    parser.add_argument("scale_factors_file", type=str,
        help="file that contains noise scale factors")
    parser.add_argument("random_seed", type=int,
        help="seed for the random number generator")
    parser.add_argument("output_dir_prefix", type=str,
        help="prefix for the output directories")

    args = parser.parse_args()

    noiseless_load_file = args.noiseless_load_file
    base_noise_level = args.base_noise_level
    scale_factors_file = args.scale_factors_file
    random_seed = args.random_seed
    output_dir_prefix = args.output_dir_prefix

    noiseless_load = np.loadtxt(noiseless_load_file)
    scale_factors = np.loadtxt(scale_factors_file).astype(int)

    rng = np.random.default_rng(random_seed)
    noise = base_noise_level * rng.normal(0., 1., noiseless_load.shape)
    
    if np.ndim(scale_factors) == 0:  #it's not an iterable
        scale_factors = [scale_factors]

    for scale_factor in scale_factors:
        # additive white Gaussian noise (AWGN)
        noisy_load = noiseless_load + scale_factor * noise
        np.savetxt(output_dir_prefix + f"_{scale_factor}x_load.dat", noisy_load)

    plot_noisy_load(noiseless_load, noise, scale_factors)


if __name__ == "__main__":
    main()
