import os
import subprocess

projects_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/projects/"
examples_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/examples/"
environment_script = "/Users/user/Documents/Coding/Computer Architecture/oss-cad-suite/environment"
oss_cad_suite_bin = "/Users/user/Documents/Coding/Computer Architecture/oss-cad-suite/bin"

def run_simulation(folder_path, folder_name, testbench_name, sv_name, remake):
    gtkwave_dir = os.path.join(folder_path, "gtkwave")
    os.makedirs(gtkwave_dir, exist_ok=True)

    # Run Icarus Verilog, VVP, and GTKWave using the sourced environment
    if remake != None and remake != "":
        result = subprocess.run(
            f'source ~/.bash_profile && iverilog -g2012 -o {folder_name}.vvp {sv_name} {testbench_name}',
            shell=True, executable="/bin/bash", cwd=gtkwave_dir
        )
        if result.returncode != 0:
            print("Error in iverilog step, stopping.")
            exit(1)

        result = subprocess.run(
            f'source ~/.bash_profile && vvp {folder_name}.vvp',
            shell=True, executable="/bin/bash", cwd=gtkwave_dir
        )
        if result.returncode != 0:
            print("Error in vvp step, stopping.")
            exit(1)

    result = subprocess.run(
        [f"{oss_cad_suite_bin}/gtkwave", f"{gtkwave_dir}/{folder_name}.vcd"],
        cwd=gtkwave_dir
    )
    if result.returncode != 0:
        print("Error in GTKWave step, stopping.")
        exit(1)

if __name__ == "__main__":
    remake = input("Remake: ") or None
    folder_name = input("Folder Name: ") or "sine2"
    sv_name = input("SV File (top.sv): ") or "sine2.sv"
    testbench_name = input("Testbench File (testbench.sv): ") or "sine2_tb.sv"

    base_dirs = [projects_dir, examples_dir]
    folder_found = False

    for base_dir in base_dirs:
        folder_path = os.path.join(base_dir, folder_name)
        if os.path.exists(folder_path):
            folder_found = True
            run_simulation(folder_path, folder_name, testbench_name, sv_name, remake)
            break

    if not folder_found:
        raise FileNotFoundError(f"- '{folder_name}' not found in directories.")

    print("Completed simulation and GTKWave launch.")