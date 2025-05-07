import os
import subprocess
import re

projects_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/projects/"
examples_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/examples/"
environment_script = "/Users/user/Documents/Coding/Computer Architecture/oss-cad-suite/environment"
oss_cad_suite_bin = "/Users/user/Documents/Coding/Computer Architecture/oss-cad-suite/bin"

def run_simulation(folder_path, testbench_name, sv_name, remake, parameters):
    gtkwave_dir = os.path.join(folder_path, "gtkwave")
    os.makedirs(gtkwave_dir, exist_ok=True)

    # Extract parameters
    cache_size = parameters["CACHE_SIZE"]
    block_size = parameters["BLOCK_SIZE"]
    assoc = parameters["ASSOC"]

    sv_base_name = os.path.splitext(os.path.basename(sv_name))[0]
    vcd_path = os.path.join(gtkwave_dir, f"{sv_base_name}.vcd")
    vvp_path = os.path.join(gtkwave_dir, f"{sv_base_name}.vvp")
    
    tb_base_name = os.path.splitext(os.path.basename(testbench_name))[0]
    parameter_overrides = [
        f"-P{tb_base_name}.CACHE_SIZE={cache_size}",
        f"-P{tb_base_name}.BLOCK_SIZE={block_size}",
        f"-P{tb_base_name}.ASSOC={assoc}"
    ]

    param_override_str = " ".join(parameter_overrides)

    if (remake != None and remake != "") or not os.path.exists(vvp_path):
        print("Running iverilog compilation with parameters:")
        print(f"  CACHE_SIZE={cache_size}, BLOCK_SIZE={block_size}, ASSOC={assoc}")
        iverilog_command = (
            f'source ~/.bash_profile && '
            f'iverilog -g2012 '
            f'{param_override_str} '
            f'-o "{vvp_path}" '
            f'"{sv_name}" "{testbench_name}"'
        )

        result = subprocess.run(
            iverilog_command,
            shell=True,
            executable="/bin/bash",
            cwd=folder_path,
            capture_output=True,
            text=True
        )
        print("--- iverilog stdout ---")
        print(result.stdout)
        if result.returncode != 0:
            print("--- iverilog stderr ---")
            print(result.stderr)
            print("Error in iverilog step, stopping.")
            exit(1)
        print("iverilog compilation successful.")

        print("Running vvp simulation...")
        vvp_command = (
            f'source ~/.bash_profile && '
            f'vvp "{vvp_path}"'
        )
        result = subprocess.run(
            vvp_command,
            shell=True,
            executable="/bin/bash",
            cwd=folder_path,
            capture_output=True,
            text=True
        )
        print("--- vvp stdout ---")
        print(result.stdout)
        if result.returncode != 0:
            print("--- vvp stderr ---")
            print(result.stderr)
            print("Error in vvp step, stopping.")
            exit(1)
        print("vvp simulation successful.")
    else:
        print("Skipping iverilog and vvp steps (remake not requested).")

    print(f"Launching GTKWave for {vcd_path}...")
    gtkwave_cmd = [f"{oss_cad_suite_bin}/gtkwave", vcd_path]

    try:
        subprocess.Popen(
            gtkwave_cmd,
            cwd=gtkwave_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        print("GTKWave launched.")
    except FileNotFoundError:
        print(f"Error: GTKWave executable not found. Looked for '{gtkwave_cmd[0]}'.")
        exit(1)
    except Exception as e:
        print(f"An unexpected error occurred during GTKWave launch: {e}")
        exit(1)

    # Run the simulation and save output
    output_file = os.path.join(folder_path + '/simulations/simulation_results', f"{sv_base_name}_results.txt")
    with open(output_file, 'w') as outfile:
        result = subprocess.run(
            f'source ~/.bash_profile && vvp "{vvp_path}"',
            shell=True, executable="/bin/bash", cwd=folder_path,
            stdout=outfile, stderr=outfile
        )
        if result.returncode != 0:
            print(f"Error in vvp step for {sv_base_name}, check {output_file} for details.")
            exit(1)

    return output_file

def extract_metrics(output_file):
    with open(output_file, 'r') as file:
        output = file.read()

    # Use regex to find metrics
    total_accesses = re.search(r'Total Accesses:\s*(\d+)', output)
    total_read_hits = re.search(r'Total Read Hits:\s*(\d+)', output)
    total_read_misses = re.search(r'Total Read Misses:\s*(\d+)', output)
    total_write_hits = re.search(r'Total Write Hits:\s*(\d+)', output)
    total_write_misses = re.search(r'Total Write Misses:\s*(\d+)', output)

    metrics = {
        "total_accesses": int(total_accesses.group(1)) if total_accesses else 0,
        "total_read_hits": int(total_read_hits.group(1)) if total_read_hits else 0,
        "total_read_misses": int(total_read_misses.group(1)) if total_read_misses else 0,
        "total_write_hits": int(total_write_hits.group(1)) if total_write_hits else 0,
        "total_write_misses": int(total_write_misses.group(1)) if total_write_misses else 0,
    }

    # Calculate overall hits and misses
    metrics["total_hits"] = metrics["total_read_hits"] + metrics["total_write_hits"]
    metrics["total_misses"] = metrics["total_read_misses"] + metrics["total_write_misses"]

    return metrics

def main():
    remake_input = input("Remake (y/n) [y]: ").strip().lower()
    remake = remake_input in ["t", "y", "yes", ""]

    folder_name = input("Folder Name [cachef]: ") or "cachef"

    # Ensure results directory is created
    summary_results_path = os.path.join(projects_dir, folder_name, 'results', 'simulation_results.txt')
    os.makedirs(os.path.dirname(summary_results_path), exist_ok=True)

    cache_files = [
        ("caches/direct_mapped_cache.sv", "testbenches/direct_mapped_cache_tb.sv", {
            "CACHE_SIZE": 512,
            "BLOCK_SIZE": 32,
            "ASSOC": 1,
        }),
        # Add more cache/testbench pairs here as needed
    ]

    base_dirs = [projects_dir, examples_dir]
    folder_path_found = None 

    for base_dir in base_dirs:
        potential_folder_path = os.path.join(base_dir, folder_name)
        if os.path.exists(potential_folder_path):
            folder_path_found = potential_folder_path
            print(f"Found project folder: {folder_path_found}")

            summary_results = []  # To hold comparison results

            for sv_name_relative, testbench_name_relative, parameters in cache_files:
                full_sv_path = os.path.join(folder_path_found, sv_name_relative)
                full_testbench_path = os.path.join(folder_path_found, testbench_name_relative)

                if not os.path.exists(full_sv_path):
                    print(f"Error: SV file not found at '{full_sv_path}'")
                    continue 
                if not os.path.exists(full_testbench_path):
                    print(f"Error: Testbench file not found at '{full_testbench_path}'")
                    continue 

                print(f"Using SV file: {sv_name_relative}")
                print(f"Using Testbench file: {testbench_name_relative}")

                output_file = run_simulation(
                    folder_path_found,
                    testbench_name_relative,
                    sv_name_relative,
                    remake,
                    parameters
                )
                
                metrics = extract_metrics(output_file)
                summary_results.append((sv_name_relative, metrics))

            # Write summary results
            with open(summary_results_path, 'w') as summary_file:
                for sv_name, metrics in summary_results:
                    summary_file.write(f"{os.path.basename(sv_name)} - Total Accesses: {metrics['total_accesses']}, "
                                       f"Hits: {metrics['total_hits']}, Misses: {metrics['total_misses']}\n")
                
                # Determine the best configuration based on hits
                best_cache = max(summary_results, key=lambda x: x[1]['total_hits'])
                summary_file.write(f"\nBest Configuration: {os.path.basename(best_cache[0])}\n")

            break 

    if folder_path_found is None:
        print(f"Error: Folder '{folder_name}' not found in directories: {base_dirs}")
        exit(1)

    print("Completed simulation and GTKWave launch process.")

if __name__ == "__main__":
    main()