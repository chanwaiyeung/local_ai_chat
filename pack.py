import os
import zipfile

# Determine desktop path
desktop = os.path.join(os.path.expanduser('~'), 'Desktop')
zip_filename = os.path.join(desktop, '【高標準重構與評分報告】local_ai_chat_AI_Reviewed.zip')

print(f"Creating zip file at: {zip_filename}")

exclude_dirs = {'.dart_tool', 'build', '.git', '.idea', 'windows', 'android', 'web', 'run_logs', 'release_v2.2.0', 'release_v2.3.0'}

with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for root, dirs, files in os.walk('.'):
        # Exclude directories
        dirs[:] = [d for d in dirs if d not in exclude_dirs and not d.startswith('.')]
        
        for file in files:
            file_path = os.path.join(root, file)
            # Add file to zip archive with relative path
            arcname = os.path.relpath(file_path, '.')
            try:
                zipf.write(file_path, arcname)
            except Exception as e:
                print(f"Failed to add {arcname}: {e}")

print("Packaging complete!")
