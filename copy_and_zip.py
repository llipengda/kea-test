import os
from pathlib import Path
import zipfile
import sys

def should_ignore(path_parts):
    return any(part.startswith("coverage_report#") for part in path_parts)

def zip_filtered_files(src_root, zip_path):
    src_root = Path(src_root)

    with zipfile.ZipFile(zip_path, 'w', compression=zipfile.ZIP_DEFLATED) as zipf:
        for dirpath, _, filenames in os.walk(src_root):
            current_path = Path(dirpath)
            rel_parts = current_path.relative_to(src_root).parts

            if should_ignore(rel_parts):
                continue

            for filename in filenames:
                if (
                    filename in ["index.html", "utg.js"] or
                    (filename.startswith("kea") and filename.endswith(".log")) or
                    filename.startswith("coverage.")
                ):
                    src_file = current_path / filename
                    rel_path = src_file.relative_to(src_root)
                    zipf.write(src_file, arcname=rel_path)
                    print(f"Zipped: {src_file} -> {rel_path}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python copy_and_zip.py <source_dir> <output_zip_file>")
        sys.exit(-1)

    src = sys.argv[1]
    zip_file = sys.argv[2]
    zip_filtered_files(src, zip_file)
