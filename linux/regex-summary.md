# Extensive Regular Expression (Regex) Summary

## Basic Metacharacters

| Character | Description | Example | Matches |
|-----------|-------------|---------|---------|
| `.` | Any single character (except newline) | `a.c` | abc, a9c, a@c |
| `^` | Start of string/line | `^Hello` | Hello at beginning |
| `$` | End of string/line | `world$` | world at end |
| `\` | Escape special characters | `\.` | Literal period |
| `\|` | Alternation (OR) | `cat\|dog` | cat or dog |

## Character Classes

| Pattern | Description | Example | Matches |
|---------|-------------|---------|---------|
| `[abc]` | Any single character in set | `[aeiou]` | Any vowel |
| `[^abc]` | Any single character NOT in set | `[^0-9]` | Any non-digit |
| `[a-z]` | Character range | `[a-zA-Z]` | Any letter |
| `[a-z0-9]` | Multiple ranges | `[a-zA-Z0-9_]` | Alphanumeric + underscore |

### Predefined Character Classes

| Pattern | Description | Equivalent |
|---------|-------------|------------|
| `\d` | Any digit | `[0-9]` |
| `\D` | Any non-digit | `[^0-9]` |
| `\w` | Any word character | `[a-zA-Z0-9_]` |
| `\W` | Any non-word character | `[^a-zA-Z0-9_]` |
| `\s` | Any whitespace | `[ \t\n\r\f\v]` |
| `\S` | Any non-whitespace | `[^ \t\n\r\f\v]` |
| `\b` | Word boundary | - |
| `\B` | Non-word boundary | - |

## Quantifiers

| Quantifier | Description | Example | Matches |
|------------|-------------|---------|---------|
| `*` | 0 or more | `ab*c` | ac, abc, abbc, abbbc |
| `+` | 1 or more | `ab+c` | abc, abbc, abbbc |
| `?` | 0 or 1 | `colou?r` | color, colour |
| `{n}` | Exactly n times | `\d{3}` | 123, 456 |
| `{n,}` | n or more times | `\d{2,}` | 12, 123, 1234 |
| `{n,m}` | Between n and m times | `\d{2,4}` | 12, 123, 1234 |

### Greedy vs Lazy Quantifiers

| Greedy | Lazy | Description |
|--------|------|-------------|
| `*` | `*?` | Match as few as possible |
| `+` | `+?` | Match as few as possible (min 1) |
| `?` | `??` | Match 0 if possible |
| `{n,}` | `{n,}?` | Match exactly n if possible |

## Groups and Capturing

| Pattern | Description | Example |
|---------|-------------|---------|
| `()` | Capturing group | `(ab)+` matches and captures ab |
| `(?:)` | Non-capturing group | `(?:ab)+` matches but doesn't capture |
| `\1`, `\2` | Backreference | `(a)\1` matches aa |
| `(?<name>)` | Named group | `(?<year>\d{4})` |

## Assertions (Lookarounds)

| Pattern | Description | Example | Explanation |
|---------|-------------|---------|-------------|
| `(?=)` | Positive lookahead | `\d(?=px)` | Digit followed by px |
| `(?!)` | Negative lookahead | `\d(?!px)` | Digit NOT followed by px |
| `(?<=)` | Positive lookbehind | `(?<=\$)\d+` | Digits preceded by $ |
| `(?<!)` | Negative lookbehind | `(?<!\$)\d+` | Digits NOT preceded by $ |

## Special Sequences

| Pattern | Description |
|---------|-------------|
| `\n` | Newline |
| `\r` | Carriage return |
| `\t` | Tab |
| `\f` | Form feed |
| `\v` | Vertical tab |
| `\0` | Null character |
| `\xHH` | Hex character (e.g., `\x41` = A) |
| `\uHHHH` | Unicode character |

## Flags/Modifiers

| Flag | Description | Example Usage |
|------|-------------|---------------|
| `i` | Case-insensitive | `/hello/i` matches Hello, HELLO |
| `g` | Global match | `/a/g` finds all a's |
| `m` | Multiline mode | `^` and `$` match line breaks |
| `s` | Dotall mode | `.` matches newlines |
| `x` | Extended mode | Allows comments and whitespace |
| `u` | Unicode mode | Full Unicode support |

## Common Patterns

### Email Address
```regex
^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
```

### URL
```regex
https?://(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&/=]*)
```

### IP Address (IPv4)
```regex
^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$
```

### Phone Number (US)
```regex
^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$
```

### Date (YYYY-MM-DD)
```regex
^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$
```

### Time (24-hour)
```regex
^([01]?[0-9]|2[0-3]):[0-5][0-9]$
```

### Password (Complex)
```regex
^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$
```
Requires: lowercase, uppercase, digit, special char, min 8 chars

### Credit Card
```regex
^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13})$
```

### Hex Color
```regex
^#?([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$
```

## Practical Examples

### Extract/Replace Operations

**Extract all numbers from text:**
```regex
\d+
```

**Find duplicate words:**
```regex
\b(\w+)\s+\1\b
```

**Remove extra whitespace:**
```regex
\s{2,}
# Replace with single space
```

**Extract text between quotes:**
```regex
"([^"]*)"
# or for single quotes
'([^']*)'
```

**Match HTML tags:**
```regex
<([^>]+)>
```

**Extract filename from path:**
```regex
[^/\\]+$
```

### Validation Patterns

**Username (alphanumeric + underscore, 3-16 chars):**
```regex
^[a-zA-Z0-9_]{3,16}$
```

**Decimal number:**
```regex
^-?\d+\.?\d*$
```

**HTML/XML tag pair:**
```regex
<([a-z]+)([^>]*)>.*?</\1>
```

## Language-Specific Notes

### Python
```python
import re
# Compile for reuse
pattern = re.compile(r'\d+')
# Methods: match(), search(), findall(), sub()
```

### JavaScript
```javascript
// Literal notation
const pattern = /\d+/g;
// Constructor
const pattern = new RegExp('\\d+', 'g');
```

### grep/sed (Linux)
```bash
# Basic regex (BRE)
grep 'pattern' file
# Extended regex (ERE)
grep -E 'pattern' file
# Perl regex (PCRE)
grep -P 'pattern' file
```

## Tips and Best Practices

1. **Start simple**: Build complex patterns incrementally
2. **Use raw strings**: In Python use `r''` to avoid double escaping
3. **Test thoroughly**: Use regex testers (regex101.com, regexr.com)
4. **Consider performance**: More specific patterns are usually faster
5. **Document complex patterns**: Add comments explaining what they match
6. **Avoid catastrophic backtracking**: Be careful with nested quantifiers
7. **Use non-capturing groups**: When you don't need the capture
8. **Be specific**: `[0-9]` is clearer than `\d` in some contexts

## Common Pitfalls

1. **Forgetting to escape special characters**: `.` matches any char, `\.` matches period
2. **Greedy vs lazy**: `.*` will match as much as possible
3. **Multiline differences**: `^` and `$` behavior changes with `m` flag
4. **Word boundaries**: `\b` doesn't work with non-word characters
5. **Unicode issues**: Some shortcuts like `\w` may not include accented characters