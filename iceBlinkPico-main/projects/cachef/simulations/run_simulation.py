import os
import subprocess
import re

projects_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/projects/"
examples_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/examples/"

def run_simulation(folder_path, testbench_name, sv_name, remake, parameters):
    sv_base_name = os.path.splitext(os.path.basename(sv_name))[0]
    vvp_path = os.path.join(folder_path, f"{sv_base_name}.vvp")

    os.makedirs(folder_path + '/simulations/simulation_results', exist_ok=True)

    # Generate parameters string for the testbench
    param_str = " ".join([f"-D{key}={value}" for key, value in parameters.items()])
    
    # Check if the VVP file needs to be created or updated
    if remake or not os.path.exists(vvp_path):
        result = subprocess.run(
            f'source ~/.bash_profile && iverilog -g2012 -o "{vvp_path}" {param_str} {sv_name} {testbench_name}',
            shell=True, executable="/bin/bash", cwd=folder_path
        )
        if result.returncode != 0:
            print(f"Error in iverilog step for {sv_base_name}, stopping.")
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
    total_hits = re.search(r'Total Hits:\s*(\d+)', output)
    total_misses = re.search(r'Total Misses:\s*(\d+)', output)

    metrics = {
        "total_accesses": int(total_accesses.group(1)) if total_accesses else 0,
        "total_hits": int(total_hits.group(1)) if total_hits else 0,
        "total_misses": int(total_misses.group(1)) if total_misses else 0,
    }
    return metrics

def main():
    remake = input("Remake (y/n): ").strip().lower() == "y"
    folder_name = input("Folder Name: ") or "cachef"
    
    # Ensure results directory is created
    summary_results_path = os.path.join(projects_dir, folder_name, 'simulations', 'simulation_results.txt')
    
    # Define cache/testbench pairs with hyperparameters
    cache_files = [
        ("caches/direct_mapped_cache.sv", "testbenches/direct_mapped_cache_tb.sv", {
            "CACHE_SIZE": 256,
            "BLOCK_SIZE": 16,
            "ASSOC": 1,
        }),
        # Add more cache/testbench pairs here as needed
    ]

    base_dirs = [projects_dir, examples_dir]
    folder_found = False

    # Locate the specified folder
    for base_dir in base_dirs:
        folder_path = os.path.join(base_dir, folder_name)
        if os.path.exists(folder_path):
            folder_found = True
            
            summary_results = []  # To hold comparison results
            
            # Run simulation for each cache/testbench pair with hyperparameters
            for sv_name, testbench_name, parameters in cache_files:
                output_file = run_simulation(folder_path, testbench_name, sv_name, remake, parameters)
                metrics = extract_metrics(output_file)
                summary_results.append((sv_name, metrics))

            # Write summary results
            with open(summary_results_path, 'w') as summary_file:
                for sv_name, metrics in summary_results:
                    summary_file.write(f"{os.path.basename(sv_name)} - Total Accesses: {metrics['total_accesses']}, "
                                       f"Hits: {metrics['total_hits']}, Misses: {metrics['total_misses']}\n")
                
                # Comparison logic here (can be tailored betteer eh)
                best_cache = max(summary_results, key=lambda x: x[1]['total_hits'])
                summary_file.write(f"\nBest Configuration: {os.path.basename(best_cache[0])}\n")
                
            break

    if not folder_found:
        raise FileNotFoundError(f"- '{folder_name}' not found in directories.")

    print("Completed all simulations.")

if __name__ == "__main__":
    main()