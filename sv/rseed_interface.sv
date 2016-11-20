interface rseed_interface (
                     input clk,
                     input reset
                     );

   bit                     trigger                = 0;
   bit                     code_coverage_trigger  = 0;
   time                    start_time             = 7;
   time                    interval_time          = 10;
   bit                     final_report           = 0;
   real                    coverage_value         = 0;
   int                     client_index           = 0;
   int                     max_objective          = 100;
   bit                     coverage_dump          = 0;
   real                    code_coverage_value    = -1;

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

   function void set_code_coverage(real c);
      code_coverage_value  = c;
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
      max_objective  = ms.max_objective;
      seed        = ms.return_seed();
      `uvm_info("RS", $sformatf("DEBUG ntb_random_seed: %d, server: %s, port: %d, max_objective: %d", seed, server, port, max_objective), UVM_LOW)
      `uvm_info("RS", $sformatf("master coverage value is %d", coverage_value), UVM_MEDIUM)

   end

   initial begin
      $value$plusargs("start_time=%d", start_time);
      $value$plusargs("interval_time=%d", interval_time);
      $value$plusargs("client_index=%d", client_index);
      $value$plusargs("coverage_dump=%d", coverage_dump);

      // if we want to dump coverage dump it here
      if (coverage_dump) begin
         $coverage_dump();
         `uvm_info("RS", $sformatf("coverage_dump for previous"), UVM_LOW)
      end

      #(start_time);
      forever begin

         #(interval_time);

         // coverage_dump is only valid is the postpone region which is problematic
         if (coverage_dump) begin
            $coverage_dump($sformatf("client_index_%0d", client_index));
            `uvm_info("RS", $sformatf("coverage_dump for previous"), UVM_LOW)
         end

         // use variable instead of file to pass over coverage value
         coverage_value                 = dut.objective.match.get_coverage();
         ms.set_coverage_value(coverage_value);

         `uvm_info("TOP", $sformatf("INFO STATUS :  SV : %0t : a = %d, b = %d, c = %d, match = %d, seed = %d, cg = %f, cc = %f",
                                    $time,
                                    dut.a,
                                    dut.b,
                                    dut.c,
                                    dut.match,
                                    ms.return_seed(),
                                    ms.get_coverage_value(),
                                    code_coverage_value
                                    ), UVM_HIGH)

         if (coverage_dump) begin
            `uvm_info("RS", $sformatf("coverage_dump"), UVM_LOW)
            code_coverage_trigger  = ~code_coverage_trigger;
         end


         // set off the trigger for the simulator TCL shell to process
         trigger  = ~trigger;
         if (ms.get_coverage_value() >= ms.max_objective) begin
            `uvm_info("RS", $sformatf("COVERAGE GOAL MET coverage: %d max_objective: %d", ms.get_coverage_value(), ms.max_objective), UVM_LOW)
            // $finish();
            final_report  = 1;
         end
      end
   end

endinterface
