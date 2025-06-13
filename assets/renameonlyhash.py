import os

# Folder path where your files are
folder_path = r"C:\Users\364ds\AppData\Roaming\XXMI Launcher\WWMI\Extract"

for root, dirs, files in os.walk(folder_path):
    for filename in files:
        try:
            if "t=" not in filename:
                print(f"Skipping (no 't='): {filename}")
                continue

            # Get extension
            _, ext = os.path.splitext(filename)

            # Extract the 8 characters after "t="
            t_index = filename.find("t=")
            new_name_part = filename[t_index + 2 : t_index + 10]

            if len(new_name_part) < 8:
                print(f"Skipping (too short after 't='): {filename}")
                continue

            new_filename = new_name_part + ext

            # Full paths
            old_file = os.path.join(root, filename)
            new_file = os.path.join(root, new_filename)

            # Check for name conflict
            if os.path.exists(new_file):
                print(f"Skipping (target exists): {new_filename}")
                continue

            os.rename(old_file, new_file)
            print(f"Renamed: {old_file} → {new_file}")

        except Exception as e:
            print(f"Error processing {filename}: {e}")
