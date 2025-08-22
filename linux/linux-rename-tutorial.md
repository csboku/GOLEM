# Linux Rename Tutorial

## Basic Methods for Renaming Files

### 1. Using `mv` (Move) Command
The simplest way to rename a file or directory:

```bash
# Rename a single file
mv oldname.txt newname.txt

# Rename a directory
mv old_directory new_directory

# Move and rename simultaneously
mv /path/to/oldfile.txt /different/path/newfile.txt
```

### 2. Using `rename` Command
The `rename` command uses Perl regular expressions for batch renaming:

```bash
# Install if not available
sudo apt install rename    # Debian/Ubuntu
sudo dnf install prename   # Fedora

# Basic syntax
rename 's/old_pattern/new_pattern/' files

# Examples:
# Change extension from .txt to .bak
rename 's/\.txt$/\.bak/' *.txt

# Replace spaces with underscores
rename 's/ /_/g' *

# Convert to lowercase
rename 'y/A-Z/a-z/' *

# Add prefix to all files
rename 's/^/prefix_/' *

# Remove a string from filenames
rename 's/unwanted_string//' *
```

### 3. Batch Renaming with Loops

```bash
# Using a for loop to add timestamps
for file in *.jpg; do
    mv "$file" "$(date +%Y%m%d)_$file"
done

# Sequential numbering
counter=1
for file in *.pdf; do
    mv "$file" "document_${counter}.pdf"
    ((counter++))
done

# Replace substring in multiple files
for file in *old_string*; do
    mv "$file" "${file//old_string/new_string}"
done
```

### 4. Using `mmv` (Mass Move)
For pattern-based batch renaming:

```bash
# Install
sudo apt install mmv

# Rename with patterns
mmv "*.jpeg" "#1.jpg"              # Change extension
mmv "file_*.txt" "document_#1.txt" # Change prefix
mmv "*_old.*" "#1_new.#2"          # Change middle part
```

## Safety Tips

1. **Test first with `-n` (dry run)**:
   ```bash
   rename -n 's/old/new/' *.txt  # Shows what would happen
   ```

2. **Use `-i` for interactive mode**:
   ```bash
   mv -i oldfile newfile  # Prompts before overwriting
   ```

3. **Create backups**:
   ```bash
   cp file.txt file.txt.bak && mv file.txt newname.txt
   ```

## Common Use Cases

### Remove spaces from filenames
```bash
rename 's/ /_/g' *
# or
for f in *\ *; do mv "$f" "${f// /_}"; done
```

### Add date to filenames
```bash
for file in *.log; do
    mv "$file" "$(date +%Y-%m-%d)_$file"
done
```

### Change case
```bash
# To lowercase
rename 'y/A-Z/a-z/' *

# To uppercase
rename 'y/a-z/A-Z/' *
```

### Remove special characters
```bash
rename 's/[^a-zA-Z0-9._-]//g' *
```

### Pad numbers with zeros
```bash
rename 's/(\d+)/sprintf("%03d", $1)/e' *.txt
# Converts file1.txt → file001.txt
```

## Quick Reference

| Task | Command |
|------|---------|
| Simple rename | `mv old.txt new.txt` |
| Batch extension change | `rename 's/\.old$/\.new/' *` |
| Remove spaces | `rename 's/ /_/g' *` |
| Add prefix | `rename 's/^/prefix_/' *` |
| Add suffix | `rename 's/$/suffix/' *` |
| Sequential numbering | Use for loop with counter |

Remember: Always test your rename commands on a few files first or use the `-n` flag to preview changes!