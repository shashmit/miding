
import sys

def check_braces(filename):
    stack = []
    with open(filename, 'r') as f:
        lines = f.readlines()
        
    for i, line in enumerate(lines):
        line_num = i + 1
        # Ignore comments
        clean_line = line.split('//')[0]
        
        for char in clean_line:
            if char == '{':
                stack.append(line_num)
            elif char == '}':
                if not stack:
                    print(f"Extraneous }} at line {line_num}")
                    return
                stack.pop()
                
    if stack:
        print(f"Unclosed {{ at line {stack[-1]}")
    else:
        print("Braces are balanced (basic check)")

if __name__ == "__main__":
    check_braces(sys.argv[1])
