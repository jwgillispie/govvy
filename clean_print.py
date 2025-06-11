#!/usr/bin/env python3
import re

def clean_print_statements(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Replace all print statements that are inside kDebugMode blocks
    # This pattern matches the complete if (kDebugMode) blocks containing print statements
    
    # Pattern 1: Simple if (kDebugMode) { print(...); } blocks
    pattern1 = r'\s*if \(kDebugMode\) \{\s*print\([^}]*?\);\s*\}'
    content = re.sub(pattern1, '', content, flags=re.MULTILINE | re.DOTALL)
    
    # Pattern 2: if (kDebugMode && ...) { print(...); } blocks
    pattern2 = r'\s*if \(kDebugMode &&[^{]*\) \{\s*print\([^}]*?\);\s*\}'
    content = re.sub(pattern2, '', content, flags=re.MULTILINE | re.DOTALL)
    
    # Pattern 3: Multi-line kDebugMode blocks
    # This is more complex - we need to handle nested braces carefully
    lines = content.split('\n')
    cleaned_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i].strip()
        
        # Check if this line starts a kDebugMode block
        if 'if (kDebugMode' in line and '{' in line:
            # Find the matching closing brace
            brace_count = line.count('{') - line.count('}')
            j = i + 1
            
            # Collect all lines in this block
            block_lines = [lines[i]]
            
            while j < len(lines) and brace_count > 0:
                block_line = lines[j]
                block_lines.append(block_line)
                brace_count += block_line.count('{') - block_line.count('}')
                j += 1
            
            # Check if the block contains print statements
            block_text = '\n'.join(block_lines)
            if 'print(' in block_text:
                # Skip this entire block
                i = j
                continue
        
        # Check for standalone } else if (kDebugMode) blocks
        elif '} else if (kDebugMode' in line:
            # Similar logic for else if blocks
            brace_count = line.count('{') - line.count('}')
            j = i + 1
            
            block_lines = [lines[i]]
            
            while j < len(lines) and brace_count > 0:
                block_line = lines[j]
                block_lines.append(block_line)
                brace_count += block_line.count('{') - block_line.count('}')
                j += 1
            
            block_text = '\n'.join(block_lines)
            if 'print(' in block_text:
                i = j
                continue
        
        cleaned_lines.append(lines[i])
        i += 1
    
    content = '\n'.join(cleaned_lines)
    
    # Clean up any remaining lone print statements that might have kDebugMode checks
    content = re.sub(r'\s*print\([^)]*kDebugMode[^)]*\);\s*', '', content, flags=re.MULTILINE)
    
    # Clean up any remaining print statements with fileName.endsWith checks
    content = re.sub(r'\s*if \(kDebugMode && [^{]*\) \{\s*print\([^}]*\);\s*\}', '', content, flags=re.MULTILINE | re.DOTALL)
    
    with open(file_path, 'w') as f:
        f.write(content)

if __name__ == '__main__':
    clean_print_statements('lib/services/legiscan_service.dart')
    print("Print statements cleaned successfully")