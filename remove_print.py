#!/usr/bin/env python3
import re
import sys

def remove_print_statements(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Pattern to match kDebugMode blocks with print statements
    # This handles multi-line blocks properly
    pattern = r'\s*if \(kDebugMode\) \{\s*print\([^;]+\);\s*\}'
    content = re.sub(pattern, '', content, flags=re.MULTILINE | re.DOTALL)
    
    # Pattern to match kDebugMode blocks with multiple print statements
    pattern = r'\s*if \(kDebugMode\) \{[^}]*print\([^}]*\}'
    content = re.sub(pattern, '', content, flags=re.MULTILINE | re.DOTALL)
    
    # Pattern to match standalone kDebugMode conditions
    pattern = r'\s*} else if \(kDebugMode\) \{\s*print\([^;]+\);\s*\}'
    content = re.sub(pattern, '', content, flags=re.MULTILINE | re.DOTALL)
    
    # Pattern to match individual lines that contain print in kDebugMode context
    # Remove the print line but keep the structure
    lines = content.split('\n')
    new_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if 'if (kDebugMode)' in line and '{' in line:
            # Check if this is a simple one-line print block
            if i + 2 < len(lines) and 'print(' in lines[i + 1] and '}' in lines[i + 2]:
                # Skip the whole block
                i += 3
                continue
            elif i + 3 < len(lines) and 'print(' in lines[i + 1] and 'print(' in lines[i + 2] and '}' in lines[i + 3]:
                # Skip block with 2 print statements
                i += 4
                continue
            # Add more patterns as needed
        new_lines.append(line)
        i += 1
    
    content = '\n'.join(new_lines)
    
    # Final cleanup for any remaining isolated print statements with kDebugMode
    content = re.sub(r'\s*if \(kDebugMode &&[^}]*\}\s*', '', content, flags=re.MULTILINE | re.DOTALL)
    
    with open(file_path, 'w') as f:
        f.write(content)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python remove_print.py <file_path>")
        sys.exit(1)
    
    remove_print_statements(sys.argv[1])
    print("Print statements removed successfully")