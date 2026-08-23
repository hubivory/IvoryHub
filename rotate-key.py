"""
rotate-key.py - Rotate the LootLabs embedded key across all scripts.

Usage:
    python rotate-key.py              # generates a random key
    python rotate-key.py IVORY-XXXX-XXXX-XXXX-XXXX   # uses your key

Clones the repo from GitHub, updates the XOR-encoded _b table in all
game scripts, commits, and pushes. Works from any machine.
"""

import random
import string
import sys
import re
import os
import subprocess
import shutil
import tempfile

REPO_URL = "https://github.com/hubivory/IvoryHub.git"
XOR_SALT = 0x5A

FILES = [
    "games/FinalSwarm.luau",
    "games/Towerofhell.luau",
    "games/MeltTheIce.luau",
    "games/Karinderya.luau",
    "IvoryKeySystem_Real.luau",
    "INSTRUCTIONS.md",
]


def generate_key():
    chars = string.ascii_uppercase + string.digits
    parts = ["IVORY"]
    for _ in range(4):
        parts.append("".join(random.choices(chars, k=4)))
    return "-".join(parts)


def encode_key(key):
    return [ord(c) ^ XOR_SALT for c in key]


def run(cmd, cwd=None):
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
    if r.returncode != 0:
        print(f"FAILED: {' '.join(cmd)}")
        print(f"  {r.stderr.strip()}")
        sys.exit(1)
    return r.stdout.strip()


def main():
    if len(sys.argv) > 1:
        key = sys.argv[1].upper()
    else:
        key = generate_key()

    if len(key) != 25 or not key.startswith("IVORY-") or key.count("-") != 4:
        print(f"Error: Key must be IVORY-XXXX-XXXX-XXXX-XXXX (25 chars), got '{key}'")
        sys.exit(1)

    bytes_list = encode_key(key)
    bytes_str = ",".join(str(b) for b in bytes_list)

    print(f"Key:    {key}")
    print(f"Salt:   0x{XOR_SALT:X}")
    print(f"Bytes:  {bytes_str}")
    print()

    # Clone repo to temp directory
    tmpdir = tempfile.mkdtemp(prefix="ivorykey_")
    print(f"Cloning {REPO_URL}...")
    run(["git", "clone", "--depth=1", REPO_URL, tmpdir])
    print("Cloned.\n")

    # Set git identity for temp repo
    run(["git", "config", "user.email", "ivoryhub@bot.local"], cwd=tmpdir)
    run(["git", "config", "user.name", "IvoryHub Bot"], cwd=tmpdir)

    # Update files
    pattern = re.compile(r"local _b = \{[\d,]+\}")
    replacement = f"local _b = {{{bytes_str}}}"

    updated = 0
    for path in FILES:
        full = os.path.join(tmpdir, path)
        try:
            with open(full, "r", encoding="utf-8") as f:
                content = f.read()
        except FileNotFoundError:
            print(f"SKIP (not found): {path}")
            continue

        new_content, count = pattern.subn(replacement, content, count=1)

        if count == 0:
            print(f"SKIP (pattern not found): {path}")
            continue

        with open(full, "w", encoding="utf-8") as f:
            f.write(new_content)

        print(f"OK: {path}")
        updated += 1

    print(f"\nUpdated {updated}/{len(FILES)} files")

    if updated == 0:
        print("Nothing to commit.")
        shutil.rmtree(tmpdir, ignore_errors=True)
        return

    # Commit and push
    print(f"\nCommitting and pushing...")
    msg = "feat: rotate API key"

    run(["git", "add", "-A"], cwd=tmpdir)
    run(["git", "commit", "-m", msg], cwd=tmpdir)
    print(f"Committed: {msg}")

    run(["git", "push"], cwd=tmpdir)
    print("Pushed to GitHub!")

    # Cleanup
    shutil.rmtree(tmpdir, ignore_errors=True)


if __name__ == "__main__":
    main()
