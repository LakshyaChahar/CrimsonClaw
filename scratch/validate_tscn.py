import os, re

base_dir = r"f:\Coding\projects\CrimsonClaw"
tscn_file = os.path.join(base_dir, "level3.tscn")

print(f"Validating {tscn_file}...")

with open(tscn_file, "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Collect all ext_resource IDs
ext_resources = {}
for match in re.finditer(r'\[ext_resource\s+type="([^"]+)"(?:\s+uid="([^"]+)")?\s+path="([^"]+)"\s+id="([^"]+)"\]', content):
    res_type, uid, path, res_id = match.groups()
    ext_resources[res_id] = (res_type, path, uid)

print(f"Total ext_resources defined: {len(ext_resources)}")

# Collect all ExtResource("...") references in scene
used_ext_ids = set(re.findall(r'ExtResource\("([^"]+)"\)', content))
print(f"Total ExtResource IDs referenced: {len(used_ext_ids)}")

for eid in used_ext_ids:
    if eid not in ext_resources:
        print(f"ERROR: ExtResource('{eid}') is referenced but NOT defined in header!")

for eid, (rtype, rpath, ruid) in ext_resources.items():
    if eid not in used_ext_ids and rtype != "Script":
        print(f"WARNING: ExtResource '{eid}' ({rpath}) is defined but never used.")
