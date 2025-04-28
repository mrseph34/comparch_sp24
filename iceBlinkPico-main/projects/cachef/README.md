# Cache Architecture Project

## Overview
This project focuses on designing and simulating various cache architectures to explore how different configurations affect performance.

## Directory Structure
- caches/: Contains the SystemVerilog cache implementations.
- testbenches/: Contains the Verilog testbenches for each cache type.
- simulations/: Contains Python scripts for running simulations and results.

cachef/
│
├── caches/
│   ├── direct_mapped_cache.sv
│   ├── fully_associative_cache.sv
│   └── set_associative_cache.sv
│
├── testbenches/
│   ├── tb_direct_mapped.sv
│   ├── tb_fully_associative.sv
│   └── tb_set_associative.sv
│
├── simulations/
│   ├── run_simulation.py
│   └── simulation_results.txt
│
└── README.md

## Cache Module Parameters
- The cache modules are designed to be parameterized for flexibility and ease of comparison. Below is a list of parameters used across all cache implementations:

| Parameter               | Description                              | Example Values          |
|-------------------------|------------------------------------------|-------------------------|
| CACHE_SIZE              | Total size of the cache in bytes         | 256, 512, 1024          |
| BLOCK_SIZE              | Size of each cache line/block in bytes   | 16, 32, 64              |
| ASSOC                   | Level of associativity                   | 1 (direct-mapped), 2, 4 |
| ADDR_WIDTH              | Bit-width of the address space           | 32, 64                  |
| DATA_WIDTH              | Bit-width of data in each cache line     | 32, 64, 128             |
| REPLACEMENT_POLICY      | Cache replacement policy                 | "LRU", "FIFO"           |