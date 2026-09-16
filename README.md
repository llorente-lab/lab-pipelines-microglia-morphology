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
| Resource | Path |
|---|---|
| MMQT toolbox | `/home/groups/illorent/mmqt-master` |
| Bio-Formats toolbox | `/home/groups/illorent/bfmatlab` |
| MMQT private fixes | `/home/groups/illorent/mmqt_private` |

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/llorente-lab/lab-pipelines-microglia-morphology.git
cd lab-pipelines-microglia-morphology

# 2. Follow the setup guide
cat docs/sherlock_setup.md

# 3. Transfer your ND2 files to Sherlock
scp *.nd2 YOUR_SUNETID@login.sherlock.stanford.edu:/scratch/users/$USER/Microglia_morphology/RawData/

# 4. Run the pipeline
sbatch scripts/microglia_array.sh
