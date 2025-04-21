import os
import subprocess

projects_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/projects/"
examples_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/examples/"
environment_script = "/Users/user/Documents/Coding/Computer Architecture/oss-cad-suite/environment"
oss_cad_suite_bin = "/Users/user/Documents/Coding/Computer Architecture/oss-cad-suite/bin"

def run_simulation(folder_path, testbench_name, sv_name, remake):
    gtkwave_dir = os.path.join(folder_path, "gtkwave")
    os.makedirs(gtkwave_dir, exist_ok=True)

    # Extract the base name of the SV file (e.g., alu.sv → alu)
    sv_base_name = os.path.splitext(os.path.basename(sv_name))[0]
    vcd_path = os.path.join(gtkwave_dir, f"{sv_base_name}.vcd")

    # Run Icarus Verilog, VVP, and GTKWave using the sourced environment
    if remake != None and remake != "":
        result = subprocess.run(
            f'source ~/.bash_profile && iverilog -g2012 -o "{gtkwave_dir}/{sv_base_name}.vvp" {sv_name} {testbench_name}',
            shell=True, executable="/bin/bash", cwd=folder_path
        )
        if result.returncode != 0:
            print("Error in iverilog step, stopping.")
            exit(1)

        result = subprocess.run(
            f'source ~/.bash_profile && vvp "{gtkwave_dir}/{sv_base_name}.vvp"',
            shell=True, executable="/bin/bash", cwd=folder_path
        )
        if result.returncode != 0:
            print("Error in vvp step, stopping.")
            exit(1)

    result = subprocess.run(
        [f"{oss_cad_suite_bin}/gtkwave", vcd_path],
        cwd=gtkwave_dir
    )
    if result.returncode != 0:
        print("Error in GTKWave step, stopping.")
        exit(1)

    

if __name__ == "__main__":
    remake = input("Remake (y/n): ").strip().lower() == "y"
    folder_name = input("Folder Name: ") or "src"
    sv_name = input("SV File (top.sv): ") or "cpu.sv"
    testbench_name = input("Testbench File (testbench.sv): ") or "tests/cpu_tb.sv"

    base_dirs = [projects_dir, examples_dir]
    folder_found = False

    for base_dir in base_dirs:
        folder_path = os.path.join(base_dir, folder_name)
        if os.path.exists(folder_path):
            folder_found = True
            run_simulation(folder_path, testbench_name, sv_name, remake)
            break

    if not folder_found:
        raise FileNotFoundError(f"- '{folder_name}' not found in directories.")

    print("Completed simulation and GTKWave launch.")