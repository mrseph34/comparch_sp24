module and_gate_tb;

  reg a, b;         // Inputs
  wire c;           // Output

  // Instantiate the AND gate (you can replace this with your module)
  and_gate uut (
    .a(a),
    .b(b),
    .c(c)
  );

  // Test pattern
  initial begin
    // Set up VCD dump file for GTkwave
    $dumpfile("and_gate_tb.vcd");  // Specify output file
    $dumpvars(0, and_gate_tb);     // Dump all signals at top level

    // Apply test vectors
    a = 0; b = 0; #10; // Wait for 10 time units
    a = 0; b = 1; #10;
    a = 1; b = 0; #10;
    a = 1; b = 1; #10;

    // End simulation
    $finish;
  end

endmodule

module and_gate (
  input a, b,
  output c
);
  assign c = a & b; // AND gate logic
endmodule