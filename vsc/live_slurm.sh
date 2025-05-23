#!/bin/bash

# Save as 'watch-jobs' and make executable with: chmod +x watch-jobs

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Clear screen function
clear_screen() {
    printf "\033c"
}

# Monitor function
monitor_jobs() {
    while true; do
        clear_screen

        # Print current time
        echo -e "${BLUE}=== SLURM JOB MONITOR === $(date '+%Y-%m-%d %H:%M:%S') ===${NC}"

        # Running Jobs (Overview)
        echo -e "\n${BLUE}=== RUNNING JOBS (Overview) ===${NC}"
        squeue -u $USER --format="%.10i %.30j %.8T %.10M %.9P %R" | \
            awk 'NR<2{print $0;next}{print $0| "sort -k3"}'

        # Running Jobs (Resource Usage) - Corrected Section
        echo -e "\n${BLUE}=== RESOURCE USAGE (Running Jobs) ===${NC}"
        # Get list of running job IDs for the current user
        local running_job_ids=$(squeue -h -u $USER -t RUNNING -o %i)

        if [ -n "$running_job_ids" ]; then
            # Use sstat to get resource usage for the running jobs
            # Removed 'JobName' as it caused an error on this system
            # Correlate JobID with the 'Overview' section above for the name
            sstat --jobs=$(echo "$running_job_ids" | paste -sd,) --format="JobID%-12,NTasks,AveCPU,MaxRSS" -P -n
        else
            echo "No running jobs to show resource usage for."
        fi


        # Summary
        echo -e "\n${BLUE}=== SUMMARY ===${NC}"
        local running=$(squeue -h -u $USER -t RUNNING | wc -l)
        local completed=$(sacct -u $USER --starttime now-2hours -X -n -o state | grep -c "COMPLETED")
        local failed=$(sacct -u $USER --starttime now-2hours -X -n -o state | grep -c "FAILED")

        echo -e "Running: ${YELLOW}$running${NC} jobs"
        echo -e "Completed (2h): ${GREEN}$completed${NC} jobs"
        echo -e "Failed (2h): ${RED}$failed${NC} jobs"

        # GPU usage if available
        if command -v sinfo &> /dev/null && sinfo -o "%f" | grep -q "gpu"; then
            echo -e "\n${BLUE}=== GPU USAGE (Running Jobs) ===${NC}"
            squeue -u $USER -t RUNNING -o "%.10i %.20P %.6D %.15j %G" | grep 'gpu:'
        fi

        # Check for critical conditions
        if [ $failed -gt 0 ]; then
            echo -e "\n${RED}⚠️  WARNING: Failed jobs detected in the last 2 hours!${NC}"
        fi

        echo -e "\n${BLUE}Updating every 10 seconds... (Ctrl+C to exit)${NC}"
        sleep 10
    done
}

# Trap Ctrl+C to clean up
trap 'echo -e "\n${BLUE}Exiting monitor...${NC}"; exit' INT

# Start monitoring
monitor_jobs
