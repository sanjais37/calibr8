import numpy as np
import matplotlib.pyplot as plt

from functools import partial
from scipy.optimize import fmin_l_bfgs_b


def voce(alpha, params):
    Y, K, S, D = params
    return Y + K * alpha + S * (1. - np.exp(-D * alpha))

def power_law(alpha, params):
    Y, A, n = params
    return Y_power_law + A * alpha**n

def objective(params, alpha, data):
    J = 0.5 * np.sum((voce(alpha, params) - data)**2)
    return J


Y_voce = 330.
K = 0.
S = 1000.
D = 10.

voce_params = np.r_[Y_voce, K, S, D]

Y_power_law = 330.
A = 1000.
n = 2. / 3.
power_law_params = np.r_[Y_power_law, A, n]

alpha = np.linspace(0, 0.29, 100)
H_voce = voce(alpha, voce_params)
H_power_law = power_law(alpha, power_law_params)

#cutoff_alpha = 6e-2
#cutoff_idx = np.where(alpha > cutoff_alpha)[0][0]
cutoff_idx = len(alpha)

objfun = partial(objective, alpha=alpha[:cutoff_idx],
    data=H_power_law[:cutoff_idx])
initial_guess = np.r_[Y_voce, K, S, D]

opt_params, fun_vals, cvg_dict = fmin_l_bfgs_b(objfun, initial_guess,
    approx_grad=True, factr=10)
cY_voce, cK, cS, cD = opt_params
H_calibrated_voce = voce(alpha, opt_params)

plt.close("all")
fig, ax = plt.subplots(figsize=(11, 8))
ax.scatter(alpha, H_power_law,
    label=f"Power Law -- $H = Y + A \\alpha^n$: $Y$={Y_power_law:.1f}, $A$={A:.1f}, $n$={n:.3f}",
    zorder=0, color="black", marker="x")
ax.scatter(alpha, H_voce,
    label=f"Linear + Voce -- $H = K \\alpha + Y + S (1 - \exp(-D \\alpha))$: $Y$={Y_voce:.1f}, $K$ = {K:.1f}, $S$={S:.1f}, $D$={D:.1f}",
    zorder=1, color="red", marker="o")
ax.scatter(alpha, H_calibrated_voce,
    label=f"Linear + Voce -- $H = K \\alpha + Y + S (1 - \exp(-D \\alpha))$: $Y$={cY_voce:.1f}, $K$ = {cK:.1f}, $S$={cS:.1f}, $D$={cD:.1f}",
    zorder=2, color="blue", marker="d")
ax.set_xlabel(r"$\alpha$", fontsize=22)
ax.set_ylabel(r"$H(\alpha)$", fontsize=22)
ax.set_title("Hardening Curve", fontsize=22)
ax.legend(loc="best", fontsize=10)
