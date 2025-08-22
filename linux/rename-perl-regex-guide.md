# Perl Regex Guide for Linux `rename` Command

## Basic Syntax

The `rename` command uses Perl's substitution and translation operators:

```bash
rename 's/PATTERN/REPLACEMENT/FLAGS' files
rename 'y/SEARCHLIST/REPLACELIST/' files
```

## Substitution Operator: s///

### Basic Structure
```bash
rename 's/old/new/' *.txt          # Replace first occurrence
rename 's/old/new/g' *.txt         # Replace all occurrences (global)
```

### Common Flags

| Flag | Description | Example |
|------|-------------|---------|
| `g` | Global - replace all occurrences | `s/a/b/g` |
| `i` | Case-insensitive matching | `s/hello/hi/i` |
| `x` | Extended - allows whitespace and comments | `s/ foo / bar /x` |
| `e` | Evaluate replacement as Perl expression | `s/(\d+)/sprintf("%03d",$1)/e` |
| `r` | Return modified string (don't modify original) | Used in Perl scripts |

## Translation Operator: y/// (or tr///)

Replaces characters one-to-one:

```bash
# Convert to lowercase
rename 'y/A-Z/a-z/' *

# Convert to uppercase  
rename 'y/a-z/A-Z/' *

# Replace specific characters
rename 'y/ /_/' *             # Spaces to underscores
rename 'y/ABC/123/' *         # A→1, B→2, C→3
```

## Perl Regex Special Features

### Capture Groups and Backreferences

```bash
# Swap parts around a delimiter
rename 's/(.*)_(.*)/$2_$1/' *     # file_name.txt → name_file.txt

# Rearrange date format
rename 's/(\d{2})-(\d{2})-(\d{4})/$3-$2-$1/' *  # DD-MM-YYYY → YYYY-MM-DD

# Keep only certain parts
rename 's/IMG_(.*)\.JPG/photo_$1.jpg/' *
```

### Non-Capturing Groups
```bash
# Group without capturing
rename 's/(?:IMG|PIC)_(.*)/$1/' *    # Remove IMG_ or PIC_ prefix
```

### Perl-Specific Escape Sequences

| Sequence | Description | Example |
|----------|-------------|---------|
| `\l` | Lowercase next character | `s/(.)(.*)/$1\l$2/` |
| `\u` | Uppercase next character | `s/(.)(.*)/$1\u$2/` |
| `\L` | Lowercase until \E | `s/(.*)$/\L$1/` |
| `\U` | Uppercase until \E | `s/(.*)$/\U$1/` |
| `\E` | End case modification | `s/(.*)_(.*)/$1_\U$2\E/` |
| `\Q` | Quote metacharacters until \E | `s/\Q$special\E/replaced/` |

### Examples:
```bash
# Capitalize first letter of each word
rename 's/\b(\w)/\u$1/g' *

# Lowercase entire filename except extension
rename 's/(.*)\.([^.]*)$/\L$1\E.$2/' *

# Uppercase first letter, lowercase rest
rename 's/(.)(.*)/\u$1\L$2/' *
```

## Using Perl Code with /e Flag

The `/e` flag evaluates the replacement as Perl code:

```bash
# Pad numbers with zeros
rename 's/(\d+)/sprintf("%03d", $1)/e' *

# Add file size to name
rename 's/(.*)\./$1_/; s/$/.txt/' *

# Increment numbers
rename 's/(\d+)/$1+1/e' *

# Use current date
rename 's/^/`date +%Y%m%d`_/e' *

# Calculate and replace
rename 's/file(\d+)/sprintf("file%02d", $1*2)/e' *
```

## Advanced Patterns

### Lookarounds in Perl Regex

```bash
# Add extension only if missing
rename 's/(?<!\.txt)$/.txt/' *

# Remove numbers only before extension
rename 's/\d+(?=\.[^.]+$)//' *

# Insert text before pattern
rename 's/(?=\.jpg$)/_backup/' *    # file.jpg → file_backup.jpg
```

### Conditional Replacements

```bash
# Different replacements based on pattern
rename 's/(photo|image)/$1 eq "photo" ? "pic" : "img"/e' *

# Complex conditions
rename 's/(\d{4})/$1 > 2020 ? "new_$1" : "old_$1"/e' *
```

## Common Use Cases

### File Extension Management
```bash
# Change extension
rename 's/\.jpeg$/\.jpg/i' *

# Add extension if missing
rename 's/^([^.]+)$/$1.txt/' *

# Remove extension
rename 's/\.[^.]*$//' *

# Change multiple extensions
rename 's/\.(jpeg|jpg|JPG|JPEG)$/.jpg/i' *
```

### Cleaning Filenames
```bash
# Remove special characters (keep alphanumeric, dash, underscore, dot)
rename 's/[^a-zA-Z0-9._-]//g' *

# Replace multiple spaces/underscores with single
rename 's/[_\s]+/_/g' *

# Remove trailing/leading whitespace
rename 's/^\s+|\s+$//g' *

# Windows to Unix friendly
rename 's/[\<\>:"|?*]/_/g' *
```

### Numbering and Sequences
```bash
# Extract and pad numbers
rename 's/.*?(\d+).*/$1/; s/^/file_/; s/(\d+)/sprintf("%04d",$1)/e' *

# Resequence with increment
rename 's/\d+/sprintf("%03d", ++$n)/e' *.jpg

# Add counter (requires -n for preview first)
rename 's/^/sprintf("%02d_", ++$c)/e' *
```

### Date and Time Stamps
```bash
# Add current date
rename 's/^/`date +%Y%m%d`_/e' *

# Reformat dates
rename 's/(\d{2})(\d{2})(\d{4})/$3-$2-$1/' *

# Extract date from filename
rename 's/.*(\d{4}-\d{2}-\d{2}).*/$1/' *
```

## Practical Examples

### Photo Organization
```bash
# Camera files: IMG_1234.JPG → 2024-01-15_001.jpg
rename 's/IMG_(\d+)\.JPG/sprintf("photo_%03d.jpg", $1)/ei' *

# Add location prefix
rename 's/^/vacation_paris_/' *.jpg

# Organize by date taken (from EXIF would need external tool)
rename 's/^/`date -r "$_" +%Y%m%d`_/' *
```

### Document Management
```bash
# Version control: doc.txt → doc_v1.txt
rename 's/(\.[^.]*)$/_v1$1/' *

# Archive old files
rename 's/^/archive_/' `find . -mtime +30`

# Standardize report names
rename 's/report[_-]?(\d{4})[_-]?(\d{2})/report_$1_$2/' *
```

### Batch Processing
```bash
# Process in steps
rename 's/ /_/g' *                    # Step 1: spaces to underscores
rename 's/__+/_/g' *                  # Step 2: multiple to single
rename 's/^_|_$//g' *                 # Step 3: trim underscores
rename 'y/A-Z/a-z/' *                 # Step 4: lowercase

# Or as one complex command
rename 's/ /_/g; s/__+/_/g; s/^_|_$//g; y/A-Z/a-z/' *
```

## Safety and Testing

### Dry Run (-n flag)
Always test first:
```bash
rename -n 's/old/new/' *    # Shows what would happen
```

### Verbose Mode (-v flag)
See actual changes:
```bash
rename -v 's/old/new/' *    # Shows each rename operation
```

### Interactive Mode
Some versions support:
```bash
rename -i 's/old/new/' *    # Asks for confirmation
```

## Tips and Tricks

1. **Quote your expressions**: Use single quotes to prevent shell expansion
   ```bash
   rename 's/\$/@/g' *     # Replaces literal $
   ```

2. **Handle spaces in filenames**: Use proper quoting
   ```bash
   rename 's/ /_/g' *      # Works with spaces
   ```

3. **Chain operations**: Separate with semicolons
   ```bash
   rename 's/OLD/new/; s/ /_/g; y/A-Z/a-z/' *
   ```

4. **Use word boundaries**: For precise matching
   ```bash
   rename 's/\btest\b/exam/g' *    # Only whole word "test"
   ```

5. **Preserve parts**: Capture what you want to keep
   ```bash
   rename 's/.*_(\d{4})\.txt$/report_$1.txt/' *
   ```

## Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "Bareword found" | Unquoted Perl code | Use quotes around expression |
| "Substitution replacement not terminated" | Missing delimiter | Check for unmatched / |
| "Quantifier follows nothing" | Invalid regex | Check special characters |
| No changes made | Pattern doesn't match | Test with -n flag first |

## Perl Regex vs Standard Regex

Key differences in rename/Perl:
- `$1`, `$2` instead of `\1`, `\2` in replacement
- More escape sequences (`\u`, `\l`, `\U`, `\L`)
- `/e` flag for code evaluation
- Translation operator `y///`
- Perl-specific functions available with `/e`