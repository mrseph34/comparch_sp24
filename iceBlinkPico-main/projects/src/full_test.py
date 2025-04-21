import os
import subprocess

projects_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/projects/"
examples_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/examples/"
oss_cad_suite_bin = "/Users/user/Documents/Coding/Computer Architecture/oss-cad-suite/bin"

def run_simulation(folder_path, remake):
    gtkwave_dir = os.path.join(folder_path, "gtkwave")
    os.makedirs(gtkwave_dir, exist_ok=True)

    sv_name = "top.sv"
    testbench_name = "tests/top_tb.sv"

    sv_base_name = os.path.splitext(sv_name)[0]
    vcd_path = os.path.join(gtkwave_dir, f"{sv_base_name}.vcd")

    modules_to_compile = [
        os.path.join(folder_path, sv_name),
        os.path.join(folder_path, testbench_name),
        os.path.join(folder_path, "core/control_unit.sv"),
        os.path.join(folder_path, "core/datapath.sv"),
        os.path.join(folder_path, "memory/memory.sv"),
        os.path.join(folder_path, "instructions/instruction_decoder.sv"),
        os.path.join(folder_path, "instructions/immediate_generator.sv"),
        os.path.join(folder_path, "instructions/alu.sv"),
        os.path.join(folder_path, "instructions/register_file.sv")
    ]

    iverilog_command = f'source ~/.bash_profile && iverilog -g2012 -o "{gtkwave_dir}/{sv_base_name}.vvp" ' + ' '.join(modules_to_compile)

    print("Running iverilog command:")
    print(iverilog_command)

    if remake:
        result = subprocess.run(
            iverilog_command,
            shell=True, executable="/bin/bash", cwd=folder_path,
            stderr=subprocess.PIPE, stdout=subprocess.PIPE
        )
        if result.returncode != 0:
            print("Error in iverilog step:")
            print(result.stderr.decode())
            exit(1)

        run_vvp(folder_path, gtkwave_dir, sv_base_name)

    run_vvp(folder_path, gtkwave_dir, sv_base_name)

def run_vvp(folder_path, gtkwave_dir, sv_base_name):
    vvp_command = f'source ~/.bash_profile && vvp "{gtkwave_dir}/{sv_base_name}.vvp"'
    print("Running vvp command:")
    print(vvp_command)

    result = subprocess.run(
        vvp_command,
        shell=True, executable="/bin/bash", cwd=folder_path,
        stderr=subprocess.PIPE, stdout=subprocess.PIPE
    )
    if result.returncode != 0:
        print("Error in vvp step:")
        print(result.stderr.decode())
        exit(1)

    if not os.path.exists(os.path.join(gtkwave_dir, f"{sv_base_name}.vcd")):
        print(f"VCD file '{sv_base_name}.vcd' not found. Check the vvp run for errors.")
        exit(1)

    gtkwave_command = [f"{oss_cad_suite_bin}/gtkwave", os.path.join(gtkwave_dir, f"{sv_base_name}.vcd")]
    result = subprocess.run(gtkwave_command, cwd=gtkwave_dir)
    if result.returncode != 0:
        print("Error in GTKWave step, stopping.")
        exit(1)

if __name__ == "__main__":
    remake = input("Remake (y/n): ").strip().lower() == "y"
    folder_name = input("Folder Name (press Enter for 'src'): ") or "src"

    base_dirs = [projects_dir, examples_dir]
    folder_found = False

    for base_dir in base_dirs:
        folder_path = os.path.join(base_dir, folder_name)
        if os.path.exists(folder_path):
            folder_found = True
            run_simulation(folder_path, remake)
            break

    if not folder_found:
        raise FileNotFoundError(f"- '{folder_name}' not found in directories.")

    print("Completed simulation and GTKWave launch.")