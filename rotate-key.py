"""
rotate-key.py - Rotate the LootLabs embedded key across all scripts.

Usage:
    python rotate-key.py              # generates a random key
    python rotate-key.py IVORY-XXXX-XXXX-XXXX-XXXX   # uses your key

Updates the XOR-encoded _b table in all game scripts, the standalone UI,
and INSTRUCTIONS.md. Then shows the git commands to commit.
"""

import random
import string
import sys
import re
import os
import subprocess

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


def main():
    # Find project root (where rotate-key.py lives, or fall back to cwd)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    if os.path.isfile(os.path.join(script_dir, "IvoryHub.luau")):
        os.chdir(script_dir)
    # else: assume cwd is already the project root

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

    pattern = re.compile(r"local _b = \{[\d,]+\}")
    replacement = f"local _b = {{{bytes_str}}}"

    updated = 0
    for path in FILES:
        try:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
        except FileNotFoundError:
            print(f"SKIP (not found): {path}")
            continue

        new_content, count = pattern.subn(replacement, content, count=1)

        if count == 0:
            print(f"SKIP (pattern not found): {path}")
            continue

        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)

        print(f"OK: {path}")
        updated += 1

    print(f"\nUpdated {updated}/{len(FILES)} files")

    if updated == 0:
        print("Nothing to commit.")
        return

    print(f"\nCommitting and pushing...")
    msg = f"rotate key to {key}"

    r = subprocess.run(["git", "add", "-A"], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"git add failed: {r.stderr}")
        return

    r = subprocess.run(["git", "commit", "-m", msg], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"git commit failed: {r.stderr}")
        return
    print(f"Committed: {msg}")

    r = subprocess.run(["git", "push"], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"git push failed: {r.stderr}")
        return
    print("Pushed to GitHub!")


if __name__ == "__main__":
    main()
