import os
import re

def convert_opacity_to_alpha(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    # Pattern that supports:
    # - .withOpacity(0.3)
    # - .withOpacity(
    #       0.3,
    #   )
    pattern = re.compile(
        r'\.withOpacity\(\s*([\d.]+)\s*,?\s*\)',
        re.MULTILINE
    )

    changed = False

    def replacer(match):
        nonlocal changed
        opacity_value = float(match.group(1))
        alpha_value = round(opacity_value * 255)
        changed = True
        return f'.withAlpha({alpha_value})'

    new_content = pattern.sub(replacer, content)

    if changed:
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(new_content)
        print(f'Updated: {file_path}')

def scan_project_for_dart_files(root_dir='lib'):
    for root, _, files in os.walk(root_dir):
        for name in files:
            if name.endswith('.dart'):
                convert_opacity_to_alpha(os.path.join(root, name))

if __name__ == "__main__":
    scan_project_for_dart_files()
