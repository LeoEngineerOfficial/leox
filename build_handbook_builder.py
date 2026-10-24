import os
import subprocess
import sys

BASE_DIR = r"d:\Shinnovation\leox"
OUT_DIR = os.path.join(BASE_DIR, "LEO_OPUS_INTERVIEW_PREPARATION")
os.makedirs(OUT_DIR, exist_ok=True)

print("Starting automated handbook generation...")
