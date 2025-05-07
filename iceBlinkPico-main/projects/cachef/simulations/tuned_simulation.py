import os
import subprocess
import re

projects_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/projects/"
examples_dir = "/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/examples/"

def run_simulation(folder_path, testbench_name, sv_name, remake, parameters):
    sv_base_name = os.path.splitext(os.path.basename(sv_name))[0]
    tb_base_name = os.path.splitext(os.path.basename(testbench_name))[0]
    vvp_path = os.path.join(folder_path, f"{sv_base_name}.vvp")

    os.makedirs(os.path.join(folder_path, 'simulations', 'tuned_results'), exist_ok=True)

    cache_size = parameters["CACHE_SIZE"]
    block_size = parameters["BLOCK_SIZE"]
    assoc = parameters.get("ASSOC", cache_size // block_size)

    # Generate parameters string for the testbench using tb_base_name
    param_override_str = " ".join([
        f"-P{tb_base_name}.CACHE_SIZE={cache_size}",
        f"-P{tb_base_name}.BLOCK_SIZE={block_size}",
        f"-P{tb_base_name}.ASSOC={assoc}"
    ])

    # Check if the VVP file needs to be created or updated
    if (remake != None and remake != "") or not os.path.exists(vvp_path):
        result = subprocess.run(
            f'source ~/.bash_profile && iverilog -g2012 -o "{vvp_path}" {param_override_str} "{sv_name}" "{testbench_name}"',
            shell=True, executable="/bin/bash", cwd=folder_path
        )
        if result.returncode != 0:
            print(f"Error in iverilog step for {sv_base_name}, stopping.")
            exit(1)

    # Run the simulation and save output
    output_file = os.path.join(folder_path, 'simulations', 'tuned_results', f"{sv_base_name}_results.txt")

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

    print(output)

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

def generate_cache_configs():
    cache_configs = []
    # [1, 2, 4, 8, 16]
    for cache_size in [128, 256, 512]:
        for block_size in [8, 16, 32]:
            for assoc in [1, 2]:
                cache_configs.append({
                    "CACHE_SIZE": cache_size,
                    "BLOCK_SIZE": block_size,
                    "ASSOC": assoc,
                })
    return cache_configs

def main():
    remake = input("Remake (y/n): ").strip().lower() == "y"
    folder_name = input("Folder Name: ") or "cachef"
    cache_type =  input("Cache Type: ") or "set_associative_cache"

    # Ensure results directory is created
    summary_results_path = os.path.join(projects_dir, folder_name, 'results', cache_type+'_tuned_results.txt')
    full_summary_results_path = os.path.join(projects_dir, folder_name, 'results', cache_type+'_tuned_results_summary.txt')

    base_dirs = [projects_dir, examples_dir]
    folder_found = False

    # Locate the specified folder
    for base_dir in base_dirs:
        folder_path = os.path.join(base_dir, folder_name)
        if os.path.exists(folder_path):
            folder_found = True

            summary_results = []  # To hold comparison results

            # Generate cache configurations
            for parameters in generate_cache_configs():
                output_file = run_simulation(folder_path,
                                              "testbenches/"+cache_type+"_tb.sv",
                                              "caches/"+cache_type+".sv",
                                              remake, parameters)
                metrics = extract_metrics(output_file)
                summary_results.append((parameters, metrics))

            # Write summary results
            with open(summary_results_path, 'w') as summary_file:
                for params, metrics in summary_results:
                    summary_file.write(f"Parameters: {params} - Total Accesses: {metrics['total_accesses']}, "
                                       f"Hits: {metrics['total_hits']}, Misses: {metrics['total_misses']}\n")

                # Determine the best configuration based on hit rate
                best_cache = max(summary_results, 
                                 key=lambda x: (x[1]['total_accesses'] > 0,
                                                x[1]['total_hits'] / x[1]['total_accesses'] * 100 if x[1]['total_accesses'] > 0 else 0))

                best_hit_rate = (best_cache[1]['total_hits'] / best_cache[1]['total_accesses'] * 100) if best_cache[1]['total_accesses'] > 0 else 0
                summary_file.write(f"\nBest Configuration: {best_cache[0]} with Hit Rate: {best_hit_rate:.2f}%\n")

            with open(full_summary_results_path, 'w') as summary_file:
                summary_file.write("Cache Simulation Summary\n")
                summary_file.write("========================\n\n")

                for params, metrics in summary_results:
                    summary_file.write(f"Configuration: Direct Mapped Test Config\n")
                    summary_file.write("  Parameters: {}\n".format(params))
                    summary_file.write("  Metrics:\n")
                    summary_file.write(f"    Total Accesses: {metrics['total_accesses']}\n")
                    summary_file.write(f"    Total Hits: {metrics['total_hits']}\n")
                    summary_file.write(f"    Total Misses: {metrics['total_misses']}\n")
                    summary_file.write(f"    Read Hits: {metrics['total_read_hits']}\n")
                    summary_file.write(f"    Read Misses: {metrics['total_read_misses']}\n")
                    summary_file.write(f"    Write Hits: {metrics['total_write_hits']}\n")
                    summary_file.write(f"    Write Misses: {metrics['total_write_misses']}\n")
                    
                    overall_hit_rate = (metrics['total_hits'] / metrics['total_accesses'] * 100) if metrics['total_accesses'] > 0 else 0
                    summary_file.write(f"    Overall Hit Rate: {overall_hit_rate:.2f}%\n\n")

                # Finding best cache configuration based on hit rate
                best_cache = max(summary_results, 
                                 key=lambda x: (x[1]['total_accesses'] > 0, 
                                                x[1]['total_hits'] / x[1]['total_accesses'] * 100 if x[1]['total_accesses'] > 0 else 0))

                best_hit_rate = (best_cache[1]['total_hits'] / best_cache[1]['total_accesses'] * 100) if best_cache[1]['total_accesses'] > 0 else 0
                summary_file.write("--- Best Configuration (by Hit Rate %) ---\n")
                summary_file.write(f"Configuration: Direct Mapped Test Config\n")
                summary_file.write(f"Parameters: {best_cache[0]}\n")
                summary_file.write(f"Total Hits: {best_cache[1]['total_hits']}\n")
                summary_file.write(f"Overall Hit Rate: {best_hit_rate:.2f}%\n")

            break

    if not folder_found:
        raise FileNotFoundError(f"- '{folder_name}' not found in directories.")

    print("Completed all simulations.")

if __name__ == "__main__":
    main()