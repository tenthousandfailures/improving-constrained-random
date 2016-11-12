package irand;

`include "uvm_macros.svh"
import uvm_pkg::*;

class master_seed extends uvm_object;

   local static master_seed unique_instance;
   local static semaphore synchronized         = new(1);
   static string server                        = "localhost";
   static int port                             = 999;
   static int max_objective                    = 100;

   local static real coverage_value            = 0;

   local static rand int unsigned seed         = 0;
   local static int unsigned sim_initial_seed  = 0;

   local function new();
      // randomize();
   endfunction

   // thread safe singleton pattern
   static function master_seed get_instance();
      if (unique_instance == null) begin
         while (!synchronized.try_get()) begin;
            // `uvm_info("MS", "SOMEONE GOT THE SEMAPHORE", UVM_DEBUG)
            if (unique_instance == null) begin
               unique_instance  = new();

               $value$plusargs("server=%s", server);
               $value$plusargs("port=%d", port);
               $value$plusargs("max_objective=%d", max_objective);

               // $value$plusargs("ntb_random_seed=%d", sim_initial_seed);
               // replaced by the following
               unique_instance.sim_initial_seed  = $get_initial_random_seed;

               // give the given initial seed to our seed
               unique_instance.seed              = sim_initial_seed;

               `uvm_info("MS", $sformatf("DEBUG SINGLETON START - ntb_random_seed: %d, server: %s, port: %d, max_objective: %d", seed, server, port, max_objective), UVM_LOW)

               // `uvm_info("MS", "making new!", UVM_HIGH)
               synchronized.put();
               // `uvm_info("MS", "SOMEONE RETURNED THE SEMAPHORE", UVM_DEBUG)
               break;
            end
         end
      end
      return unique_instance;
   endfunction

   static function void set_coverage_value(real c);
      coverage_value  = c;
   endfunction

   static function real get_coverage_value();
      print();
      return coverage_value;
   endfunction

   // set the seed of the singleton
   static function void set_seed(int unsigned s);
      // `uvm_info("MS", $sformatf("SEED IS %d", s), UVM_DEBUG)
      unique_instance.srandom(s);
      uvm_pkg::uvm_global_random_seed  = s;
      seed                             = s;

   endfunction

   // everytime get_seed is called a new seed is generated
   // we can return seed because it is a static member
   static function int unsigned get_seed();
      unique_instance.randomize();
      // print();

      // TODO using the UVM method don't call randomize just return seed

      // original bad non-singleton solution
      // seed  = seed + 1;

      return seed;
   endfunction

   static function int unsigned return_seed();
      return seed;
   endfunction

   static function void print();
      // DEBUG
      // `uvm_info("MS", $sformatf("master seed is %d", seed), UVM_DEBUG)
      `uvm_info("MS", $sformatf("master coverage values is %d", coverage_value), UVM_HIGH)
   endfunction

endclass

endpackage
