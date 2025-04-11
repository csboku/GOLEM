#!/bin/bash

# Save as 'watch-jobs' and make executable with: chmod +x watch-jobs

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
        
        # Running Jobs
        echo -e "\n${BLUE}=== RUNNING JOBS ===${NC}"
        squeue -u $USER --format="%.10i %.30j %.8T %.10M %.9P %R" | \
            awk 'NR<2{print $0;next}{print $0| "sort -k3"}'
        
        # Recent Job History
        echo -e "\n${BLUE}=== RECENT JOB HISTORY (Last 2 hours) ===${NC}"
        sacct -u $USER --starttime now-2hours \
            --format="JobID%-15,JobName%-30,State%-13,Elapsed%-12,ExitCode" | \
            grep -v '\|' | \
            sed -e "s/COMPLETED/${GREEN}COMPLETED${NC}/g" \
                -e "s/RUNNING/${YELLOW}RUNNING${NC}/g" \
                -e "s/FAILED/${RED}FAILED${NC}/g" \
                -e "s/CANCELLED/${RED}CANCELLED${NC}/g"
        
        # Summary
        echo -e "\n${BLUE}=== SUMMARY ===${NC}"
        running=$(squeue -h -u $USER | wc -l)
        completed=$(sacct -u $USER --starttime now-2hours -X -o state | grep -c "COMPLETED")
        failed=$(sacct -u $USER --starttime now-2hours -X -o state | grep -c "FAILED")
        
        echo -e "Running: ${YELLOW}$running${NC} jobs"
        echo -e "Completed (2h): ${GREEN}$completed${NC} jobs"
        echo -e "Failed (2h): ${RED}$failed${NC} jobs"
        
        # GPU usage if available
        if command -v sinfo &> /dev/null && sinfo -o "%f" | grep -q "gpu"; then
            echo -e "\n${BLUE}=== GPU USAGE ===${NC}"
            squeue -u $USER -t running -o "%.10i %.20P %.6D %.15j %G" | grep gpu
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
