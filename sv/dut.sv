interface dut_if #(parameter width=2) (
          input clk,
          input reset
                                       );

   logic [width:0]          a;
   logic [width:0]          b;
   logic                    c;

   task drive(logic [width:0] ia, logic [width:0] ib);
      // `uvm_info("dut_if", $sformatf("BEFORE drive regs a: %d b: %d", ia, ib), UVM_LOW)
      a = ia;
      b = ib;
      `uvm_info("dut_if", $sformatf("AFTER drive regs a: %d b: %d", ia, ib), UVM_LOW)
   endtask

   // always @(negedge clk) begin
   // DEPRECATED original way without pre_randomize call for reference
   // c_a.srandom(seed);
   // c_b.srandom(seed + 1);
   // randomize class txns using re-seed value
   // c_a.rprint();
   // c_b.rprint();
   // assign class txns to pins
   // a = c_a.get_num();
   // b = c_b.get_num();
   // end

endinterface

module dut #(parameter width=2) (
       input [width:0] a,
       input [width:0] b,
       input           clk,
       input           reset,
       output          c
                                 );

   reg [width:0]           match;

   // grab coverage automatically
   covergroup target_cg;
      coverpoint match;
   endgroup

   target_cg target;

   // EX 1. DEFAULT a == b match
   assign c = (a == b);

   // EX2. b is all 1s cross with all values of a
   // assign c  = (&b);

   // EX3. free form
   // assign c  = (a[0] && b[0]) && (a[1] && b[1]) && (a[2] && b[2]);

   // assign match to value of a
   always @(posedge clk) begin
      if (c) begin
         match <= a;
         // `uvm_info("DUT", $sformatf("!!!MATCH"), UVM_DEBUG)

         // not good but need to wait just after posedge clk to sample register
         #1;
         target.sample();
      end else begin
         match <= '0;
      end


   end

   // initialize covergroup
   initial begin
      target = new();
   end

endmodule
