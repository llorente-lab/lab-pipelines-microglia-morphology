# Llorente Lab - Microglia Morphology Pipeline

Automated pipeline for processing microglia morphology data from ND2 files
using the MMQT toolbox on Stanford Sherlock HPC.

## Overview

This pipeline processes confocal microscopy ND2 files through four steps:

| Step | Function | Output |
|---|---|---|
| 1 | Segmentation | `*_stack3_segmented.mat` |
| 2 | Skeletonization | `*_stack4_watershed_areas.mat` |
| 3 | Feature Extraction | `*_features_of_cells.txt` |
| 4 | Cell Selection | `*_features_summarized.txt` |

## Requirements

### Sherlock Access
- Stanford Sherlock HPC account
- Access to `illorent` partition
- MATLAB (R2022b or later)

### Group Resources (Pre-installed)
All pipeline scripts and toolboxes are pre-installed in the group 
shared space and ready to use.

| Resource | Path |
|---|---|
| **Pipeline script** | `/home/groups/illorent/microglia_morphology/microglia_array.sh` |
| MMQT toolbox | `/home/groups/illorent/mmqt-master` |
| Bio-Formats toolbox | `/home/groups/illorent/bfmatlab` |
| MMQT private fixes | `/home/groups/illorent/mmqt_private` |

### Quick Start

1. Transfer your ND2 files to Sherlock: *Read globus_transfer.md for more information.*

2. Since the script is pre-installed in the group space, you can 
submit it directly without cloning the repository:

```bash
sbatch /home/groups/illorent/microglia_morphology/microglia_array.sh


