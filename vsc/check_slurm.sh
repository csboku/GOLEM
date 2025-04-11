#!/bin/bash

# Save as 'myjobs' and make executable with: chmod +x myjobs

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "\n${BLUE}=== RUNNING JOBS ===${NC}"
squeue -u $USER --format="%.10i %.30j %.8T %.10M %.9P %R" | \
    awk 'NR<2{print $0;next}{print $0| "sort -k3"}'

echo -e "\n${BLUE}=== TODAY'S JOB HISTORY ===${NC}"
sacct -u $USER --starttime today \
    --format="JobID%-15,JobName%-30,State%-13,Elapsed%-12,ExitCode" | \
    grep -v '\|' | \
    sed -e "s/COMPLETED/${GREEN}COMPLETED${NC}/g" \
        -e "s/RUNNING/${YELLOW}RUNNING${NC}/g" \
        -e "s/FAILED/${RED}FAILED${NC}/g" \
        -e "s/CANCELLED/${RED}CANCELLED${NC}/g"

# Show total counts
echo -e "\n${BLUE}=== SUMMARY ===${NC}"
echo "Running: $(squeue -h -u $USER | wc -l) jobs"
echo "Completed today: $(sacct -u $USER --starttime today -X -o state | grep -c "COMPLETED")"
echo "Failed today: $(sacct -u $USER --starttime today -X -o state | grep -c "FAILED")"

# Optional: Show GPU usage if you're using GPUs
if command -v sinfo &> /dev/null && sinfo -o "%f" | grep -q "gpu"; then
    echo -e "\n${BLUE}=== GPU USAGE ===${NC}"
    squeue -u $USER -t running -o "%.10i %.20P %.6D %.15j %G" | grep gpu
fi
