# Transferring Files to Sherlock Using Globus

Globus is the recommended method for transferring large ND2 files to 
Sherlock due to its reliability, speed and ability to resume interrupted 
transfers.

## Prerequisites
1. Create a free Globus account at [globus.org](https://www.globus.org)
2. Log in using your **Stanford credentials** (SUNet ID)
3. Install **Globus Connect Personal** on your local machine:
   - Download from [globus.org/globus-connect-personal](https://www.globus.org/globus-connect-personal)
   - Follow the installation instructions for your OS
   - Launch and log in with your Globus account

---

## Step 1: Set Up Your Local Endpoint
1. Open **Globus Connect Personal** on your local machine
2. Click **Preferences** → **Access**
3. Add the folder containing your ND2 files to the allowed paths
4. Note your **local endpoint name** (set during installation)

---

## Step 2: Find the Sherlock Endpoint
1. Go to [app.globus.org](https://app.globus.org)
2. Click **File Manager** in the left sidebar
3. In the left panel search box, type: 
4. Select **SRCC Sherlock** from the results
5. Authenticate with your **Stanford SUNet ID** when prompted

---

## Step 3: Navigate to Your Destination
In the **right panel** (Sherlock), navigate to:
You can type the path directly in the **Path** box at the top.

---

## Step 4: Navigate to Your Source Files
In the **left panel** (your local machine):
1. Type **Stanford Google Drive**
2. Navigate to the folder containing your ND2 files

---

## Step 5: Transfer Files
1. Select the ND2 files you want to transfer
   - Click a file to select it
   - Hold `Shift` to select multiple files
   - Click **Select All** to select everything in the folder
2. Click the **Start** button (▶) pointing toward Sherlock
3. Globus will begin the transfer and notify you by email when complete

---

## Step 6: Verify Transfer on Sherlock
```bash
# Log into Sherlock
ssh YOUR_SUNETID@login.sherlock.stanford.edu

# Check files arrived
ls /scratch/users/$USER/Microglia_morphology/RawData/

# Count ND2 files
find /scratch/users/$USER/Microglia_morphology/RawData \
    -name "*.nd2" | wc -l
