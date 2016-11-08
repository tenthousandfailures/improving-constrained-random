interface rseed_interface (
                     input clk,
                     input reset
                     );

   bit                     trigger         = 0;
   time                    start_time      = 7;
   time                    loop_time       = 10;
   bit                     final_report    = 0;
   real                    coverage_value  = 0;
   int                     max_target      = 100;
   int                     unsigned seed;

   irand::master_seed      ms;

   string                  server  = "top_default_server";
   int                     port    = 9999;

   function void get_instance();
      ms.get_instance();
      `uvm_info("MS", $sformatf("get_instance called"), UVM_DEBUG)
   endfunction

   // set the seed of the singleton
   function void set_seed(int unsigned s);

      // this is the atomic option of forcing the seed index to start over - replaced with pre_randomize version
      // `uvm_info("MS", $sformatf("removing the uvm_random_seed_table and setting uvm_global_random_seed"), UVM_HIGH)
      // uvm_pkg::uvm_random_seed_table_lookup.delete();

      seed  = s;
      ms.set_seed(s);
   endfunction

   function void print();
      // `uvm_info("TOP", $sformatf("master seed is %d", seed), UVM_DEBUG)
      `uvm_info("TOP", $sformatf("master coverage value is %d", coverage_value), UVM_MEDIUM)
   endfunction

   function real get_coverage_value();
      return ms.get_coverage_value();
   endfunction

   initial begin
      #0;

      ms       = irand::master_seed::get_instance();
      server      = ms.server;
      port        = ms.port;
      max_target  = ms.max_target;
      seed        = ms.return_seed();
      `uvm_info("RS", $sformatf("DEBUG ntb_random_seed: %d, server: %s, port: %d, max_target: %d", seed, server, port, max_target), UVM_LOW)

      `uvm_info("TOP", $sformatf("master coverage value is %d", coverage_value), UVM_MEDIUM)

   end

   initial begin
      $value$plusargs("start_time=%d", start_time);
      $value$plusargs("loop_time=%d", loop_time);

      #(start_time);
      forever begin
         #(loop_time);

         // use variable instead of file to pass over coverage value
         coverage_value                 = dut.target.match.get_coverage();
         ms.set_coverage_value(coverage_value);

         `uvm_info("TOP", $sformatf("INFO STATUS :  SV : %0t : a = %d, b = %d, c = %d, match = %d, seed = %d, cg = %f",
                                    $time,
                                    dut.a,
                                    dut.b,
                                    dut.c,
                                    dut.match,
                                    ms.return_seed(),
                                    ms.get_coverage_value()), UVM_HIGH)

         // set off the trigger for the simulator TCL shell to process
         trigger                        = ~trigger;
         if (ms.get_coverage_value() >= ms.max_target) begin
            `uvm_info("TOP", $sformatf("COVERAGE GOAL MET coverage: %d max_target: %d", ms.get_coverage_value(), ms.max_target), UVM_LOW)
            // $finish();
            final_report  = 1;
         end
      end
   end

endinterface
