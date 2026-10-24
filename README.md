# Throats

Code accompanying the paper **Beyond cross-sections: machine-learned 3D pore elements for truly three-dimensional pore-network models**, submitted to *Computers & Geosciences*.

The code splits the pore space of a segmented 3D micro-CT image into **throats**,
computes the hydraulic conductance and shape descriptors of every throat from a
pore-scale Stokes flow solution, and trains an XGBoost model to predict throat
conductance from its shape (leave-one-sample-out validation).

> **Naming note.** Inside the code (variable names, generated file names and the `halfthroat_id`
> column) the object is still called *halfthroat*, a legacy name from an earlier version of the method.
> In the paper and in this documentation it is called a *throat*.

## Repository structure

```
notebooks/
  1_extract_pores_edges.ipynb             boundaries between neighbouring pores
  2_generate_throats.ipynb                growth of throats from the pore boundaries
  3_exctract_throat_boundaries.ipynb      inlet/outlet boundaries of every throat
  3.5_calculate_flow_pressure.ipynb       flow between pores and mean pressure on the throat boundaries
  4_calc_throats_parameters.ipynb         conductance g and shape features -> datasets/<filename>.csv
  ML_loso.ipynb                           XGBoost, leave-one-sample-out, selection of the Δp criterion
scripts/
  ShapeParameter.jl                       Julia shape parameter G_vp (called from notebook 4)
raw_data/                                 3D images (.raw)
saved_dicts_and_lists/                    intermediate dictionaries (.npy)
datasets/                                 feature tables (.csv)
```

Run the notebooks in the order 1 → 2 → 3 → 3.5 → 4 for every sample, then `ML_loso.ipynb`.
Notebook 3.5 is run three times per sample, once for each flow direction (`flow_direction = 'x'`, `'y'`, `'z'`).
All paths are relative, so the notebooks must be run from the `notebooks/` folder.


## Settings

Every notebook starts with a settings cell:

```python
filename = 'Leopard'     # sample prefix: all files are named <filename>_*.raw / <filename>_*.npy
raw_dimension = 1000     # image size in voxels (the image is a cube raw_dimension^3)
```

Label images are read and written as raw binary arrays with `np.fromfile(..., dtype=np.int32)`,
i.e. 32 bits per voxel, C order.
`3.5_calculate_flow_pressure.ipynb` has two additional settings:

```python
flow_direction = 'z'     # direction of the applied flow: 'x', 'y' or 'z'
dtype = np.float32       # voxel type of the pressure and velocity fields (32 bits per voxel)
```

In `ML_loso.ipynb` the settings cell defines the list of samples (`SAMPLES`), the tune/eval split,
the grid of the Δp criterion and the optuna/XGBoost search parameters.

## Input data

The sample images can be downloaded from the open public dataset referenced in the paper.

The following steps are **not** part of this code and must be done by the user with any suitable tool:

1. **Pore segmentation.** Split the pore space into individual pores and save the label image as
   `raw_data/<filename>_pores.raw` (int32, one positive label per pore, `-1` for the solid phase).
   This can be done, for example, with the watershed-based network extraction in
   [OpenPNM / PoreSpy](https://porespy.org/) (SNOW algorithm).
2. **Stokes flow simulation.** Compute the pressure and velocity fields for a flow applied along each of the
   three axes (x, y, z), for example with FDMSS (Gerke et al., 2018, *Computers & Geosciences* 114, 41–58)
   or any other pore-scale Stokes solver.
   Save the fields as raw `dtype` arrays of the same size as the image, for every flow direction `<d>` = `x`, `y`, `z`:

   | File | Content |
   |---|---|
   | `raw_data/<filename>_<d>_p.raw` | pressure |
   | `raw_data/<filename>_<d>_ux.raw`, `..._uy.raw`, `..._uz.raw` | velocity components |

   `3.5_calculate_flow_pressure.ipynb` uses `uz` along the first array axis, `uy` along the second and `ux` along the third.
   From these fields it computes the flow between pores (`saved_dicts_and_lists/<filename>_pores_flow_<d>.npy`)
   and the mean pressure on every throat boundary (`saved_dicts_and_lists/<filename>_halfthroat_boundaries_pressure_<d>.npy`),
   which are used in `4_calc_throats_parameters.ipynb`.

## Requirements

- Python ≥ 3.10 with Jupyter, `numpy`, `scipy`, `scikit-image`, `matplotlib`, `pandas`,
  `scikit-learn`, `xgboost`, `optuna`
- Julia with the `Images` package, and the Python–Julia bridge [`julia` (PyJulia)](https://github.com/JuliaPy/pyjulia)
  (used in notebook 4 for `G_vp`)

- Memory: the 3D arrays are held in RAM; so we highy recomend using setups with more than 40GB RAM

## Outputs

- `raw_data/`: `<filename>_pore_boundaries.raw`, `<filename>_halfthroats.raw`, `<filename>_halfthroats_boundaries.raw`
- `saved_dicts_and_lists/`: `<filename>_pores_boundaries_numbers.npy`, `<filename>_halfthroat_boundaries_numbers.npy`,
  `<filename>_pores_flow_<d>.npy`, `<filename>_halfthroat_boundaries_pressure_<d>.npy`, `<filename>_G_vp.npy`
- `datasets/<filename>.csv`: one row per throat (`halfthroat_id`, conductance `g`, pressure drops, shape features)
- `notebooks/`: `ML_loso.ipynb` writes the results dump (`.pkl`) and the figures `R2_loso.pdf`, `final_loso.pdf`

## License

This code is released under the MIT License, see [LICENSE](LICENSE).

## Citation

If you use this code, please cite the paper: *[reference]*.
