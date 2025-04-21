# Instructions for mem_init
instructions = [
    '00000033',  # ADD R1, R0, R0
    '00500113',  # ADDI R2, R0, 5
    '00202023',  # SW R2, 0(R0)
    '00002183',  # LW R3, 0(R0)
    '00310233',  # ADD R4, R2, R3
    '00005037',  # LUI R5, 0x00001
]

total_memory_words = 2048

# Create and write to mem_init.memh
with open('mem_init.memh', 'w') as mem_file:
    for instruction in instructions:
        mem_file.write(f'{instruction}\n')  # Write each instruction
  
    # Pad the rest of the memory with zeros
    for _ in range(len(instructions), total_memory_words):
        mem_file.write('00000000\n')  # Add zeros for unused addresses

print("mem_init.memh created successfully.")