import os, re

base_dir = r"f:\Coding\projects\CrimsonClaw"
tscn_file = os.path.join(base_dir, "level3.tscn")

visited = set()

def check_file(rel_path):
    if rel_path in visited:
        return
    visited.add(rel_path)

    full_path = os.path.join(base_dir, rel_path.replace("res://", "").replace("/", os.sep))
    if not os.path.exists(full_path):
        return

    if full_path.endswith(".tscn") or full_path.endswith(".tres"):
        try:
            with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                lines = f.readlines()
            for i, line in enumerate(lines):
                # Check ext_resource UIDs and paths
                if line.startswith("[ext_resource"):
                    uid_match = re.search(r'uid="([^"]+)"', line)
                    path_match = re.search(r'path="([^"]+)"', line)
                    type_match = re.search(r'type="([^"]+)"', line)
                    
                    if path_match:
                        target_path = path_match.group(1)
                        if uid_match:
                            uid = uid_match.group(1)
                            # Check if uid is valid format or dummy
                            if "dteleporter" in uid or len(uid) < 10:
                                print(f"Invalid UID in {rel_path}:{i+1} -> {uid} for {target_path}")
                        check_file(target_path)
        except Exception as e:
            print(f"Error in {rel_path}: {e}")

print("Checking UIDs recursively for level3.tscn...")
check_file("res://level3.tscn")
print("Finished checking UIDs.")
