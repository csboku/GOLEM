# Rsync Tutorial & Cheat Sheet

## What is Rsync?

Rsync (remote sync) is a powerful command-line tool for efficiently synchronizing files and directories between locations. It only transfers the differences between source and destination, making it ideal for backups, mirroring, and keeping datasets in sync.

## Basic Syntax

```bash
rsync [options] source destination
```

## Essential Options

| Option | Description |
|--------|-------------|
| `-a` | Archive mode (preserves permissions, timestamps, symbolic links) |
| `-v` | Verbose (show files being transferred) |
| `-r` | Recursive (copy directories recursively) |
| `-u` | Update (skip files that are newer on destination) |
| `-z` | Compress data during transfer |
| `-h` | Human-readable output |
| `-n` | Dry run (show what would be transferred without doing it) |
| `-P` | Show progress and keep partial files |
| `--delete` | Delete files in destination that don't exist in source |
| `--exclude` | Exclude files/patterns |
| `--include` | Include files/patterns |

## Common Command Patterns

### Basic Local Sync
```bash
# Sync directory contents (note the trailing slash on source)
rsync -av /path/to/source/ /path/to/destination/

# Sync directory itself (no trailing slash on source)
rsync -av /path/to/source /path/to/destination/
```

### Remote Sync (SSH)
```bash
# Local to remote
rsync -avz /local/path/ user@remote-host:/remote/path/

# Remote to local
rsync -avz user@remote-host:/remote/path/ /local/path/

# Remote to remote
rsync -avz user1@host1:/path/ user2@host2:/path/
```

### Safe Sync with Dry Run
```bash
# Always test first with dry run
rsync -avn --delete /source/ /destination/

# Then run for real
rsync -av --delete /source/ /destination/
```

## Research-Specific Examples

### Syncing Model Data
```bash
# Sync WRF output files to backup location
rsync -avP --include="wrfout_*" --exclude="*" \
  /model/runs/current/ /backup/wrf_outputs/

# Sync with compression for large datasets
rsync -avzP /data/atmospheric_data/ \
  user@hpc-cluster:/scratch/username/data/
```

### Code Synchronization
```bash
# Sync code excluding temporary files
rsync -av --exclude=".git" --exclude="*.pyc" --exclude="__pycache__" \
  /local/project/ user@server:/home/username/project/

# Include only specific file types
rsync -av --include="*.jl" --include="*.R" --include="*.py" \
  --exclude="*" /code/ /backup/code/
```

### Incremental Backups
```bash
# Create incremental backup with deletion of removed files
rsync -av --delete --backup --backup-dir=/backup/$(date +%Y%m%d) \
  /important/data/ /backup/current/
```

## Advanced Patterns

### Exclude Multiple Patterns
```bash
# Using exclude-from file
echo "*.tmp" > exclude.txt
echo "*.log" >> exclude.txt
echo "cache/" >> exclude.txt

rsync -av --exclude-from=exclude.txt /source/ /destination/

# Or inline multiple excludes
rsync -av --exclude="*.tmp" --exclude="*.log" --exclude="cache/" \
  /source/ /destination/
```

### Bandwidth Limiting
```bash
# Limit bandwidth to 1000 KB/s
rsync -av --bwlimit=1000 /large/dataset/ user@server:/data/
```

### Resume Interrupted Transfers
```bash
# Use -P flag to keep partial files and show progress
rsync -avP /large/files/ user@server:/destination/
```

## Useful Rsync Aliases

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
# Safe sync with dry run first
alias rsync-check='rsync -avn'
alias rsync-sync='rsync -av'
alias rsync-move='rsync -av --remove-source-files'

# Research data specific
alias rsync-data='rsync -avzP --exclude="*.tmp" --exclude="*.log"'
alias rsync-code='rsync -av --exclude=".git" --exclude="*.pyc" --exclude="__pycache__"'
```

## Best Practices

1. **Always use trailing slashes consistently**
   - `/source/` copies contents of source
   - `/source` copies the source directory itself

2. **Test with dry run first**
   ```bash
   rsync -avn [options] source destination
   ```

3. **Use compression for slow connections**
   ```bash
   rsync -avz [other options] source destination
   ```

4. **Monitor progress for large transfers**
   ```bash
   rsync -avP [other options] source destination
   ```

5. **Be careful with --delete**
   - Always test with dry run when using `--delete`
   - Consider using `--backup` for safety

## Troubleshooting

### Common Issues
- **Permission denied**: Use `sudo` or fix ownership/permissions
- **Host key verification failed**: Check SSH keys and known_hosts
- **Connection timeout**: Check network connectivity and SSH config
- **Disk space**: Ensure sufficient space at destination

### Debugging
```bash
# Verbose output with statistics
rsync -avv --stats /source/ /destination/

# Debug SSH connection issues
rsync -av -e "ssh -v" /source/ user@host:/destination/
```

## Performance Tips

- Use `-z` for compression on slow connections
- Use `--whole-file` for fast local networks
- Use `--inplace` for very large files to avoid temporary copies
- Consider `--partial-dir` for resumable transfers

---

**Quick Reference**: For most use cases, `rsync -avP` is your go-to command pattern!