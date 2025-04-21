import os
import subprocess

projects_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/projects/"
examples_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/examples/"

def run_make(folder_name):

    # Set up the environment
    environment_script = "/Users/user/Documents/Coding/Computer Architecture/oss-cad-suite/environment"
    
    # Escape spaces by quoting the environment script path
    environment_script_escaped = f"\"{environment_script}\""
    
    # Source the environment script and run make
    subprocess.run(f"source {environment_script_escaped} && make", shell=True, executable="/bin/bash", cwd=folder_name)
    subprocess.run(f"source {environment_script_escaped} && make prog", shell=True, executable="/bin/bash", cwd=folder_name)
    subprocess.run(f"source {environment_script_escaped} && make clean", shell=True, executable="/bin/bash", cwd=folder_name)

if __name__ == "__main__":

    # Define name of folder that will have makefile to run
    folder_name = input("Makefile: ") or 'src'

    # Define the two base directories to search
    base_dirs = [
        projects_dir,
        examples_dir
    ]
    
    # Check if the folder exists in either of the directories
    folder_found = False
    for base_dir in base_dirs:
        folder_path = os.path.join(base_dir, folder_name)
        if os.path.exists(folder_path):
            folder_found = True
            run_make(folder_path)
            break
    
    if not folder_found:
        raise FileNotFoundError(f"- '{folder_name}' not found in directories.")
    
    print("ran make: ", folder_name)