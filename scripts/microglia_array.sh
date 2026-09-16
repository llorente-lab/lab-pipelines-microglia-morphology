#!/bin/bash
#SBATCH --job-name=microglia_array
#SBATCH --partition=illorent
#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --mem=64G
#SBATCH --array=1-672%20
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=wyvkan@stanford.edu
#SBATCH --output=/scratch/users/wyvkan/Microglia_morphology/logs/array_%A_%a.out
#SBATCH --error=/scratch/users/wyvkan/Microglia_morphology/logs/array_%A_%a.err

# ==========================================
# Path Configuration
# ==========================================
MMQT_ROOT="/home/groups/illorent/mmqt-master"
RAW_BASE="/scratch/users/wyvkan/Microglia_morphology/RawData"
ANALYZED_BASE="/scratch/users/wyvkan/Microglia_morphology/AnalyzedData"
LOG_DIR="/scratch/users/wyvkan/Microglia_morphology/logs"
SUBFOLDER_LIST="$LOG_DIR/subfolder_list.txt"

# ==========================================
# Load MATLAB Module
# ==========================================
echo "Loading MATLAB module..."

# Source the module system
source /etc/profile.d/modules.sh 2>/dev/null || \
source /usr/share/Modules/init/bash 2>/dev/null || \
source /usr/local/Modules/init/bash 2>/dev/null

# Try loading MATLAB with common version names
module load matlab 2>/dev/null || \
module load matlab/r2022b 2>/dev/null || \
module load matlab/R2022b 2>/dev/null || \
module load matlab/r2023a 2>/dev/null || \
module load matlab/R2023a 2>/dev/null || {
    echo "ERROR: Could not load MATLAB module."
    echo "Available MATLAB modules:"
    module avail matlab 2>&1
    exit 1
}

echo "MATLAB loaded: $(which matlab)"
matlab -batch "disp(version)" 2>/dev/null

# ==========================================
# Get This Job's Subfolder
# ==========================================
SUBFOLDER_NAME=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SUBFOLDER_LIST")

if [ -z "$SUBFOLDER_NAME" ]; then
    echo "ERROR: No subfolder found for task ID $SLURM_ARRAY_TASK_ID"
    exit 1
fi

SUBFOLDER_PATH="$ANALYZED_BASE/$SUBFOLDER_NAME"
MATLAB_SCRIPT="$LOG_DIR/run_mmqt_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}.m"
MATLAB_LOG="$LOG_DIR/matlab_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log"

echo "=========================================="
echo "Job Array ID:  $SLURM_ARRAY_JOB_ID"
echo "Task ID:       $SLURM_ARRAY_TASK_ID"
echo "Subfolder:     $SUBFOLDER_NAME"
echo "Path:          $SUBFOLDER_PATH"
echo "Start time:    $(date)"
echo "=========================================="

if [ ! -d "$SUBFOLDER_PATH" ]; then
    echo "ERROR: Subfolder not found: $SUBFOLDER_PATH"
    exit 1
fi

# ==========================================
# Export Variables for MATLAB
# ==========================================
export MMQT_ROOT
export SUBFOLDER_PATH
export SUBFOLDER_NAME

# ==========================================
# Write MATLAB Script
# ==========================================
cat > "$MATLAB_SCRIPT" << 'MATLAB_EOF'
try
    % -------------------------------------------------------
    % Paths
    % -------------------------------------------------------
    mmqt_root      = getenv('MMQT_ROOT');
    subfolder_path = getenv('SUBFOLDER_PATH');
    subfolder_name = getenv('SUBFOLDER_NAME');
    figureScaling  = 2.5;
    figureHide     = true;

    fprintf('Processing subfolder: %s\n', subfolder_name);
    fprintf('Path: %s\n', subfolder_path);

    % -------------------------------------------------------
    % Add MMQT toolbox to path
    % -------------------------------------------------------
    addpath(genpath(mmqt_root));
    mmqt_contents = dir(mmqt_root);
    for k = 1:length(mmqt_contents)
        if mmqt_contents(k).isdir && ~ismember(mmqt_contents(k).name, {'.', '..'})
            addpath(genpath(fullfile(mmqt_root, mmqt_contents(k).name)));
        end
    end

    % Add private functions from group home directory
    private_path = '/home/groups/illorent/mmqt_private';
    if exist(private_path, 'dir')
        addpath(private_path);
        fprintf('Private functions added from: %s\n', private_path);
    else
        error('Private functions folder not found: %s', private_path);
    end
    fprintf('MMQT toolbox loaded.\n');

    % -------------------------------------------------------
    % Add Bio-Formats toolbox
    % -------------------------------------------------------
    bfmatlab_path = '/home/groups/illorent/bfmatlab';
    addpath(bfmatlab_path);
    javaaddpath(fullfile(bfmatlab_path, 'bioformats_package.jar'));
    fprintf('Bio-Formats toolbox loaded.\n');
    
    % -------------------------------------------------------
    % Initialize tee function state
    % This fixes 'openedFiles' variable issue when private
    % functions are called outside their original private scope
    % -------------------------------------------------------
    % Call tee with no arguments to initialize openedFiles
    try
        tee([]);
    catch
        % Expected to fail but initializes the persistent variable
    end
    fprintf('tee function initialized.\n');

    % -------------------------------------------------------
    % Verify key functions are available
    % -------------------------------------------------------
    fprintf('\nVerifying required functions:\n');
    required_functions = {
        'read_3D_image_matrix', ...
        'write_3d_image_matrix', ...
        'mmqt_segment_image', ...
        'mmqt_skeletonize_microglia', ...
        'mmqt_extract_features', ...
        'mmqt_select_cells_and_features', ...
        'check_processing_status'
    };
    allFound = true;
    for f = 1:length(required_functions)
        func_path = which(required_functions{f});
        if ~isempty(func_path)
            fprintf('  [OK]      %s\n        -> %s\n', required_functions{f}, func_path);
        else
            fprintf('  [MISSING] %s\n', required_functions{f});
            allFound = false;
        end
    end
    if ~allFound
        error('Some required functions are missing. Check toolbox paths above.');
    end
    fprintf('All required functions found.\n\n');

    % -------------------------------------------------------
    % Find MAT files in subfolder
    % -------------------------------------------------------
    mat_files = dir(fullfile(subfolder_path, '*.mat'));

    if isempty(mat_files)
        fprintf('No MAT files found in subfolder - SKIPPING\n');
        return;
    end

    fprintf('Found %d MAT file(s)\n', length(mat_files));

    % -------------------------------------------------------
    % Process each MAT file
    % -------------------------------------------------------
    for j = 1:length(mat_files)
        mat_file_path = fullfile(subfolder_path, mat_files(j).name);

        fprintf('\nProcessing: %s\n', mat_files(j).name);

        ht = tic;

        % Step 1/4: Segmentation
        % Refresh status from disk before each step
        status = check_processing_status(subfolder_path);
        if ~status.hasSegmentation
            fprintf('  Step 1/4: Segmenting image...\n');
            mmqt_segment_image(char(mat_file_path), figureScaling, figureHide);
            fprintf('  Step 1/4: Segmentation complete\n');
        else
            fprintf('  Step 1/4: Segmentation exists - SKIPPING\n');
        end

        % Step 2/4: Skeletonization
        % Refresh status after segmentation
        status = check_processing_status(subfolder_path);
        if ~status.hasSkeleton
            fprintf('  Step 2/4: Skeletonizing microglia...\n');
            mmqt_skeletonize_microglia(char(mat_file_path));
            fprintf('  Step 2/4: Skeletonization complete\n');
        else
            fprintf('  Step 2/4: Skeleton exists - SKIPPING\n');
        end

        % Step 3/4: Feature extraction
        % Refresh status after skeletonization
        status = check_processing_status(subfolder_path);
        if ~status.hasFeatures
            fprintf('  Step 3/4: Extracting features...\n');
            mmqt_extract_features(char(mat_file_path), figureScaling, figureHide);
            fprintf('  Step 3/4: Feature extraction complete\n');
        else
            fprintf('  Step 3/4: Features exist - SKIPPING\n');
        end

        % Step 4/4: Cell and feature selection
        % Refresh status after feature extraction
        status = check_processing_status(subfolder_path);
        if ~status.hasSelection
            fprintf('  Step 4/4: Selecting cells and features...\n');
            mmqt_select_cells_and_features(char(mat_file_path), figureHide);
            fprintf('  Step 4/4: Cell selection complete\n');
        else
            fprintf('  Step 4/4: Selection exists - SKIPPING\n');
        end

        % Final status check
        status = check_processing_status(subfolder_path);
        elapsed_time = toc(ht);

        if status.isComplete
            fprintf('SUCCESS - Time: %.1f seconds\n', elapsed_time);
        else
            fprintf('WARNING: Not fully complete - Time: %.1f seconds\n', elapsed_time);
        end
    end

catch ME
    fprintf('FATAL ERROR: %s\n', ME.message);
    for k = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
    exit(1);
end
MATLAB_EOF

# ==========================================
# Start Virtual Display for MATLAB figure rendering
# ==========================================
echo "Starting virtual display..."

# Find a free display number based on task ID to avoid conflicts
DISPLAY_NUM=$((89 + SLURM_ARRAY_TASK_ID))
export DISPLAY=":${DISPLAY_NUM}"

# Start Xvfb virtual display
Xvfb "${DISPLAY}" -screen 0 1920x1080x24 -ac &
XVFB_PID=$!
echo "Xvfb started on display ${DISPLAY} with PID ${XVFB_PID}"

# Give Xvfb time to start
sleep 3

# Verify Xvfb is running
if ! kill -0 $XVFB_PID 2>/dev/null; then
    echo "ERROR: Xvfb failed to start"
    exit 1
fi

# ==========================================
# Run MATLAB Script
# ==========================================
matlab -nosplash -batch "run('$MATLAB_SCRIPT')" 2>&1 | tee "$MATLAB_LOG"
EXIT_CODE=${PIPESTATUS[0]}

# ==========================================
# Stop Virtual Display
# ==========================================
echo "Stopping virtual display..."
kill $XVFB_PID 2>/dev/null
wait $XVFB_PID 2>/dev/null

# Clean up temp script
rm -f "$MATLAB_SCRIPT"

echo ""
echo "=========================================="
echo "Task $SLURM_ARRAY_TASK_ID complete: $(date)"
echo "Subfolder: $SUBFOLDER_NAME"
echo "Exit code: $EXIT_CODE"
echo "=========================================="

exit $EXIT_CODE
