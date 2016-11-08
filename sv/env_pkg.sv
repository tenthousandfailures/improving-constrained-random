package env_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

class ms_sequence_item extends uvm_sequence_item;

   irand::master_seed ms;
   bit ms_enable = 1;

   function new();
      ms = irand::master_seed::get_instance();
   endfunction

   function void pre_randomize();

      if (ms_enable) begin
         `uvm_info("pre_randomize", $sformatf("pre_randomize started"), UVM_DEBUG)
         ms_run();
      end

   endfunction

   function void ms_run();
      // TODO using the UVM seeding mechanism
      // string s;
      // string b;

      string inst_id;
      string type_id;
      string type_id2;

      // use generic method to reseed - needed for non-uvm things
      // this.srandom(ms.get_seed());

      if (get_full_name() == "") begin
         inst_id  = "__global__";
      end else begin
         inst_id           = get_full_name();
      end

      type_id           = get_type_name();
      type_id2          = {uvm_instance_scope(), type_id};

      if(uvm_pkg::uvm_random_seed_table_lookup.exists(inst_id)) begin
         // `uvm_info("pre_randomize", $sformatf("found inst_id: %s", inst_id), UVM_LOW)
         if(uvm_pkg::uvm_random_seed_table_lookup[inst_id].seed_table.exists(type_id2)) begin
            // remove the seed_table - debug below shows that count keeps it unique
            // `uvm_info("pre_randomize",
            //           $sformatf("removing the uvm_random_seed_table for inst_id: %s and type_id2: %s count: %d",
            //                     inst_id,
            //                     type_id2,
            //                     uvm_pkg::uvm_random_seed_table_lookup[inst_id].count[type_id2]
            //                     ),
            //           UVM_LOW)
            uvm_pkg::uvm_random_seed_table_lookup[inst_id].seed_table.delete(type_id2);
         end
      end else begin
         // `uvm_info("pre_randomize", $sformatf("did not find inst_id: %s and type_id2: %s", inst_id, type_id2), UVM_LOW)
      end

      // TODO using the UVM seeding mechanism it is possible to be better with random stability
      // reseed using the uvm built-in
      reseed();

      // DEBUG TO PRINT seed table tree
      // if ( uvm_pkg::uvm_random_seed_table_lookup.first(s) ) begin
      //    do
      //      begin
      //         `uvm_info("MS_ITEM", $sformatf("%s get_type_name: %s get_full_name: %s", s, get_type_name(), get_full_name()), UVM_LOW)
      //         if ( uvm_pkg::uvm_random_seed_table_lookup[s].seed_table.first(b) ) begin
      //            do
      //              begin
      //                 `uvm_info("MS_ITEM", $sformatf("%s", b), UVM_LOW)
      //              end
      //                   while (uvm_pkg::uvm_random_seed_table_lookup[s].seed_table.next(b));
      //         end
      //      end
      //    while (uvm_pkg::uvm_random_seed_table_lookup.next(s));
      // end

      // `uvm_info("CB", $sformatf("class base for %i running pre_randomize"), UVM_DEBUG)
   endfunction

endclass

// the txn
class num_sequence_item #(parameter width=2) extends ms_sequence_item;
   // `uvm_object_param_utils(num_sequence_item#(width));

   rand logic [width:0] num;

   function new();
      super.new();
   endfunction

   // not needed handled by parent class
   // function void pre_randomize();
   //    super.pre_randomize();
   // endfunction

   // randomize and print
   function void rprint();
      this.randomize();
      // `uvm_info("CR", $sformatf("num is: %d", num), UVM_DEBUG)
   endfunction

   function logic [width:0] get_num();
      return num;
   endfunction

endclass

class test0 extends uvm_test;
   `uvm_component_utils(test0)

   parameter width  = 1;

   time loop_time;

   num_sequence_item#(width) c_a, c_b;

   virtual rseed_interface rseed_interface;
   virtual dut_if#(width) dif;

   function new(string name = "test0", uvm_component parent = null);
      super.new(name, parent);

      if (!uvm_config_db#(virtual rseed_interface)::get(this, "", "rseed_interface", rseed_interface)) begin
         `uvm_fatal("test0", "Failed to get rseed_interface")
      end
      if (!uvm_config_db#(virtual dut_if#(width))::get(this, "", "dif", dif)) begin
         `uvm_fatal("test0", "Failed to get dut_if")
      end

      // get loop time to loop one last time through
      $value$plusargs("loop_time=%d", loop_time);

      // c_a  = num_sequence_item#(width)::type_id::create();
      // c_b  = num_sequence_item#(width)::type_id::create();

      c_a  = new();
      c_b  = new();

   endfunction

   virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      `uvm_info("STATUS", "starting test", UVM_MEDIUM)

      fork
         begin
            // this is the forever loop that represents the uvm driver
            forever begin
               @(negedge dif.clk);
               // randomize class txns using re-seed value
               c_a.rprint();
               c_b.rprint();
               // `uvm_info("test0", $sformatf("drive with a: %d b: %d", ia, ib), UVM_LOW)

               // TODO making this work would be closer to a driver
               dif.drive(c_a.get_num(), c_b.get_num());
            end
         end
         // this exits the fork if the test reaches its goal
         wait (rseed_interface.final_report == 1);
      join_any

      // wait just a little to run any other cleanup things
      #(loop_time);
      #(loop_time);
      phase.drop_objection(this);
   endtask

endclass
endpackage
