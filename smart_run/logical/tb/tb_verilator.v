/*Copyright 2019-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
/*Copyright 2019-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

`timescale 1ns/100ps

`define CLK_PERIOD          10
`define TCLK_PERIOD         40
`define MAX_RUN_TIME        32'h3000000

`define SOC_TOP             top.x_soc
`define RTL_MEM             top.x_soc.x_axi_slave128.x_f_spsram_large

`define CPU_TOP             top.x_soc.x_cpu_sub_system_axi.x_rv_integration_platform.x_cpu_top
`define tb_retire0          `CPU_TOP.core0_pad_retire0
`define retire0_pc          `CPU_TOP.core0_pad_retire0_pc[39:0]
`define tb_retire1          `CPU_TOP.core0_pad_retire1
`define retire1_pc          `CPU_TOP.core0_pad_retire1_pc[39:0]
`define tb_retire2          `CPU_TOP.core0_pad_retire2
`define retire2_pc          `CPU_TOP.core0_pad_retire2_pc[39:0]
`define CPU_CLK             `CPU_TOP.pll_cpu_clk
`define CPU_RST             `CPU_TOP.pad_cpu_rst_b
`define clk_en              `CPU_TOP.axim_clk_en
`define CP0_RSLT_VLD        `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_cp0_top.x_ct_cp0_iui.cp0_iu_ex3_rslt_vld
`define CP0_RSLT            `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_cp0_top.x_ct_cp0_iui.cp0_iu_ex3_rslt_data[63:0]

// `define APB_BASE_ADDR       40'h4000000000
`define APB_BASE_ADDR       40'hb0000000

module top(
  input wire clk
);
  reg jclk;
  reg rst_b;
  reg jrst_b;
  reg jtap_en;
  wire jtg_tms;
  wire jtg_tdi;
  wire jtg_tdo;
  wire  pad_yy_gate_clk_en_b;
  
  static integer FILE;
  
  // Writeback scoreboards: capture data when WB happens, then consume on retire
  reg [63:0] preg_scoreboard_data [0:95];
  bit        preg_scoreboard_valid [0:95];
  reg [63:0] vreg_scoreboard_data [0:63];
  bit        vreg_scoreboard_valid [0:63];
  reg [39:0] fwb_pending_pc [0:63];
  reg [4:0]  fwb_pending_frd [0:63];
  reg [1:0]  fwb_pending_slot [0:63];
  bit        fwb_pending_valid [0:63];
  
  // Statistics for X-WB logging
  integer xwb_total_count;
  integer xwb_preg0_count;
  integer xwb_no_pst_match_count;
  integer xwb_multiple_pst_match_count;
  integer xwb_no_bus_hit_count;
  
  initial begin
    integer idx;
    for (idx = 0; idx <= 95; idx = idx + 1) begin
      preg_scoreboard_valid[idx] = 1'b0;
      preg_scoreboard_data[idx]  = 64'b0;
    end
    for (idx = 0; idx <= 63; idx = idx + 1) begin
      vreg_scoreboard_valid[idx] = 1'b0;
      vreg_scoreboard_data[idx]  = 64'b0;
      fwb_pending_valid[idx]     = 1'b0;
      fwb_pending_pc[idx]        = 40'b0;
      fwb_pending_frd[idx]       = 5'b0;
      fwb_pending_slot[idx]      = 2'b0;
    end
    xwb_total_count = 0;
    xwb_preg0_count = 0;
    xwb_no_pst_match_count = 0;
    xwb_multiple_pst_match_count = 0;
    xwb_no_bus_hit_count = 0;
  end
  
  wire uart0_sin;
  wire uart0_sout;
  wire [7:0]b_pad_gpio_porta;
  
  assign pad_yy_gate_clk_en_b = 1'b1;
  
  //initial
  //begin
  //  clk =0;
  //  forever begin
  //    #(`CLK_PERIOD/2) clk = ~clk;
  //  end
  //end
  


  integer jclkCnt;
  initial 
  begin 
    jclk = 0;
    jclkCnt = 0;
    //forever begin
    //  #(`TCLK_PERIOD/2) jclk = ~jclk;
    //end
  end
  always@(posedge clk) begin
    if(jclkCnt < `TCLK_PERIOD / `CLK_PERIOD / 2 - 1) begin
      jclkCnt = jclkCnt + 1;
    end
    else begin
      jclkCnt = 0;
      jclk = !jclk;
    end
  end
  
  integer rst_bCnt;
  initial
  begin
    rst_bCnt = 0;
    rst_b = 1;
    //#100;
    //rst_b = 0;
    //#100;
    //rst_b = 1;
  end

  always@(posedge clk) begin
    rst_bCnt = rst_bCnt + 1;
    if(rst_bCnt > 10 && rst_bCnt < 20) rst_b = 0;
    else if(rst_bCnt > 20) rst_b = 1;
  end
  
  integer jrstCnt;
  initial
  begin
    jrst_b = 1;
    jrstCnt = 0;
    //#400;
    //jrst_b = 0;
    //#400;
    //jrst_b = 1;
  end
  always@(posedge clk) begin
    jrstCnt = jrstCnt + 1;
    if(jrstCnt > 40 && jrstCnt < 80) jrst_b = 0;
    else if(jrstCnt > 80) jrst_b = 1;
  end
 
  integer i;
  bit [31:0] mem_inst_temp [65536];
  bit [31:0] mem_data_temp [65536];
  string inst_pat_path;
  string data_pat_path;
  integer j;
  initial
  begin
`ifdef C910_DEBUG_BOOT
    $display("[BOOT] Enter initial loader");
`endif
    $display("\t********* Init Program *********");
    $display("\t********* Wipe memory to 0 *********");
    for(i=0; i < 32'h16384; i=i+1)
    begin
      `RTL_MEM.ram0.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram1.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram2.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram3.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram4.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram5.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram6.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram7.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram8.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram9.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram10.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram11.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram12.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram13.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram14.mem[i][7:0] = 8'h0;
      `RTL_MEM.ram15.mem[i][7:0] = 8'h0;
`ifdef C910_DEBUG_BOOT
      if ((i & 16'h0FFF) == 0)
        $display("[BOOT][wipe] i=0x%0h/0x16384", i);
`endif
    end
  
    inst_pat_path = "inst.pat";
    data_pat_path = "data.pat";
    void'($value$plusargs("INST=%s", inst_pat_path));
    void'($value$plusargs("DATA=%s", data_pat_path));

`ifdef C910_DEBUG_BOOT
    begin
      integer f_inst, f_data;
      f_inst = $fopen(inst_pat_path, "r");
      f_data = $fopen(data_pat_path, "r");
      if (f_inst == 0) $display("[BOOT][ERR] cannot open inst pat: %s", inst_pat_path);
      else begin $display("[BOOT] inst pat opened: %s", inst_pat_path); $fclose(f_inst); end
      if (f_data == 0) $display("[BOOT][ERR] cannot open data pat: %s", data_pat_path);
      else begin $display("[BOOT] data pat opened: %s", data_pat_path); $fclose(f_data); end
    end
`endif
    $display("\t********* Read program *********");
    $display("\t********* Using inst file: %s *********", inst_pat_path);
    $display("\t********* Using data file: %s *********", data_pat_path);
    $readmemh(inst_pat_path, mem_inst_temp);
    $readmemh(data_pat_path, mem_data_temp);
`ifdef C910_DEBUG_BOOT
    $display("[BOOT] readmemh done, mem_inst_temp[0]=0x%08x mem_data_temp[0]=0x%08x",
             mem_inst_temp[0], mem_data_temp[0]);
`endif
  
    $display("\t********* Load program to memory *********");
    i=0;
    for(j=0;i<32'h4000;i=j/4)
    begin
      `RTL_MEM.ram0.mem[i][7:0] = mem_inst_temp[j][31:24];
      `RTL_MEM.ram1.mem[i][7:0] = mem_inst_temp[j][23:16];
      `RTL_MEM.ram2.mem[i][7:0] = mem_inst_temp[j][15: 8];
      `RTL_MEM.ram3.mem[i][7:0] = mem_inst_temp[j][ 7: 0];
      j = j+1;
      `RTL_MEM.ram4.mem[i][7:0] = mem_inst_temp[j][31:24];
      `RTL_MEM.ram5.mem[i][7:0] = mem_inst_temp[j][23:16];
      `RTL_MEM.ram6.mem[i][7:0] = mem_inst_temp[j][15: 8];
      `RTL_MEM.ram7.mem[i][7:0] = mem_inst_temp[j][ 7: 0];
      j = j+1;
      `RTL_MEM.ram8.mem[i][7:0] = mem_inst_temp[j][31:24];
      `RTL_MEM.ram9.mem[i][7:0] = mem_inst_temp[j][23:16];
      `RTL_MEM.ram10.mem[i][7:0] = mem_inst_temp[j][15: 8];
      `RTL_MEM.ram11.mem[i][7:0] = mem_inst_temp[j][ 7: 0];
      j = j+1;
      `RTL_MEM.ram12.mem[i][7:0] = mem_inst_temp[j][31:24];
      `RTL_MEM.ram13.mem[i][7:0] = mem_inst_temp[j][23:16];
      `RTL_MEM.ram14.mem[i][7:0] = mem_inst_temp[j][15: 8];
      `RTL_MEM.ram15.mem[i][7:0] = mem_inst_temp[j][ 7: 0];
      j = j+1;
`ifdef C910_DEBUG_BOOT
      if ((j & 16'h1FFF) == 0)
        $display("[BOOT][inst copy] j=0x%0h i=0x%0h", j, i);
`endif
    end
    i=0;
    for(j=0;i<32'h4000;i=j/4)
    begin
      `RTL_MEM.ram0.mem[i+32'h4000][7:0]  = mem_data_temp[j][31:24];
      `RTL_MEM.ram1.mem[i+32'h4000][7:0]  = mem_data_temp[j][23:16];
      `RTL_MEM.ram2.mem[i+32'h4000][7:0]  = mem_data_temp[j][15: 8];
      `RTL_MEM.ram3.mem[i+32'h4000][7:0]  = mem_data_temp[j][ 7: 0];
      j = j+1;
      `RTL_MEM.ram4.mem[i+32'h4000][7:0]  = mem_data_temp[j][31:24];
      `RTL_MEM.ram5.mem[i+32'h4000][7:0]  = mem_data_temp[j][23:16];
      `RTL_MEM.ram6.mem[i+32'h4000][7:0]  = mem_data_temp[j][15: 8];
      `RTL_MEM.ram7.mem[i+32'h4000][7:0]  = mem_data_temp[j][ 7: 0];
      j = j+1;
      `RTL_MEM.ram8.mem[i+32'h4000][7:0]   = mem_data_temp[j][31:24];
      `RTL_MEM.ram9.mem[i+32'h4000][7:0]   = mem_data_temp[j][23:16];
      `RTL_MEM.ram10.mem[i+32'h4000][7:0]  = mem_data_temp[j][15: 8];
      `RTL_MEM.ram11.mem[i+32'h4000][7:0]  = mem_data_temp[j][ 7: 0];
      j = j+1;
      `RTL_MEM.ram12.mem[i+32'h4000][7:0]  = mem_data_temp[j][31:24];
      `RTL_MEM.ram13.mem[i+32'h4000][7:0]  = mem_data_temp[j][23:16];
      `RTL_MEM.ram14.mem[i+32'h4000][7:0]  = mem_data_temp[j][15: 8];
      `RTL_MEM.ram15.mem[i+32'h4000][7:0]  = mem_data_temp[j][ 7: 0];
      j = j+1;
`ifdef C910_DEBUG_BOOT
      if ((j & 16'h1FFF) == 0)
        $display("[BOOT][data copy] j=0x%0h i=0x%0h", j, i);
`endif
    end
`ifdef C910_DEBUG_BOOT
    $display("[BOOT] program load done");
`endif
  end

`ifdef C910_DEBUG_BOOT
  // --------- Run-phase debug heartbeats &关键信号边沿 ----------
  reg rst_b_d, cpu_rst_d, clk_en_d;
  integer hb_ct;
  initial begin
    rst_b_d  = 1'b1;
    cpu_rst_d= 1'b1;
    clk_en_d = 1'b0;
    hb_ct    = 0;
  end
  always @(posedge clk) begin
    hb_ct <= hb_ct + 1;
    if (rst_b_d !== rst_b) begin
      $display("[BOOT][edge] rst_b <= %0d @hb=%0d", rst_b, hb_ct);
      rst_b_d <= rst_b;
    end
    if (cpu_rst_d !== `CPU_RST) begin
      $display("[BOOT][edge] CPU_RST <= %0d @hb=%0d", `CPU_RST, hb_ct);
      cpu_rst_d <= `CPU_RST;
    end
    if (clk_en_d !== `clk_en) begin
      $display("[BOOT][edge] clk_en <= %0d @hb=%0d", `clk_en, hb_ct);
      clk_en_d <= `clk_en;
    end
    if ((hb_ct % 100000) == 0) begin
      $display("[BOOT][hb] hb_ct=%0d rst_b=%0d CPU_RST=%0d clk_en=%0d", hb_ct, rst_b, `CPU_RST, `clk_en);
    end
    if (`tb_retire0) $display("[BOOT][rt] slot0 retire pc=0x%010h", `retire0_pc);
    if (`tb_retire1) $display("[BOOT][rt] slot1 retire pc=0x%010h", `retire1_pc);
    if (`tb_retire2) $display("[BOOT][rt] slot2 retire pc=0x%010h", `retire2_pc);
  end
`endif

  integer clkCnt;
  always@(posedge clk) begin
    clkCnt = clkCnt + 1;
    if(clkCnt > `MAX_RUN_TIME) begin
      $display("**********************************************");
      $display("*   meeting max simulation time, stop!       *");
      $display("**********************************************");
      FILE = $fopen("run_case.report","w");
      $fwrite(FILE,"TEST FAIL");   
      $finish;
    end
  end
  initial
  begin
    clkCnt = 0;
  //#(`MAX_RUN_TIME * `CLK_PERIOD);
  //  $display("**********************************************");
  //  $display("*   meeting max simulation time, stop!       *");
  //  $display("**********************************************");
  //  FILE = $fopen("run_case.report","w");
  //  $fwrite(FILE,"TEST FAIL");   
  //$finish;
  end
  
  reg [31:0] retire_inst_in_period;
  reg [31:0] cycle_count;
  
  `define LAST_CYCLE 50000
  always @(posedge clk or negedge rst_b)
  begin
    if(!rst_b)
      cycle_count[31:0] <= 32'b1;
    else 
      cycle_count[31:0] <= cycle_count[31:0] + 1'b1;
  end
  
  
  always @(posedge clk or negedge rst_b)
  begin
    if(!rst_b) //reset to zero
      retire_inst_in_period[31:0] <= 32'b0;
    else if( (cycle_count[31:0] % `LAST_CYCLE) == 0)//check and reset retire_inst_in_period every 50000 cycles
    begin
      if(retire_inst_in_period[31:0] == 0)begin
        $display("*************************************************************");
        $display("* Error: There is no instructions retired in the last %d cycles! *", `LAST_CYCLE);
        $display("*              Simulation Fail and Finished!                *");
        $display("*************************************************************");
        //#10;
        FILE = $fopen("run_case.report","w");
        $fwrite(FILE,"TEST FAIL");   
  
        $finish;
      end
      retire_inst_in_period[31:0] <= 32'b0;
    end
    else if(`tb_retire0 || `tb_retire1 || `tb_retire2)
      retire_inst_in_period[31:0] <= retire_inst_in_period[31:0] + 1'b1;
  end
  
  
  
  reg [31:0] cpu_awaddr;
  reg [3:0]  cpu_awlen;
  reg [15:0] cpu_wstrb;
  reg        cpu_wvalid;
  reg [63:0] value0;
  reg [63:0] value1;
  reg [63:0] value2;
  
  
  always @(posedge clk)
  begin
    cpu_awlen[3:0]   <= `SOC_TOP.x_axi_slave128.awlen[3:0];
    cpu_awaddr[31:0] <= `SOC_TOP.x_axi_slave128.mem_addr[31:0];
    cpu_wvalid       <= `SOC_TOP.biu_pad_wvalid;
    cpu_wstrb        <= `SOC_TOP.biu_pad_wstrb;
    // value0           <= `CPU_TOP.core0_pad_wb0_data[63:0];
    // value1           <= `CPU_TOP.core0_pad_wb1_data[63:0];
    // value2           <= `CPU_TOP.core0_pad_wb2_data[63:0];
    value0              <= `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.rbus_pipe0_wb_data[63:0];
    value1              <= `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.rbus_pipe1_wb_data[63:0];
    value2              <= `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.ld_wb_preg_data_sign_extend[63:0];
  end
  
  always @(posedge clk)
  begin
      if(value0 == 64'h444333222 || value1 == 64'h444333222 || value2 == 64'h444333222)
    begin
      $display("**********************************************");
      $display("*    simulation finished successfully        *");
      $display("**********************************************");
`ifdef C910_LOGGER
      $display("*** X-WB Logging Statistics ***");
      $display("  Total X-WB logs:        %0d", xwb_total_count);
      $display("  Note: preg0 has no PST entry and cannot be tracked");
      $display("  No PST match:           %0d", xwb_no_pst_match_count);
      $display("  Multiple PST matches:   %0d", xwb_multiple_pst_match_count);
      $display("  No WB bus hit (PRF):    %0d (%.1f%%)", xwb_no_bus_hit_count,
               xwb_total_count > 0 ? (xwb_no_bus_hit_count * 100.0 / xwb_total_count) : 0.0);
`endif
     //#10;
     FILE = $fopen("run_case.report","w");
     $fwrite(FILE,"TEST PASS");   
  
     $finish;
    end
      else if (value0 == 64'h2382348720 || value1 == 64'h2382348720 || value2 == 64'h444333222)
    begin
     $display("**********************************************");
     $display("*    simulation finished with error          *");
     $display("**********************************************");
     //#10;
     FILE = $fopen("run_case.report","w");
     $fwrite(FILE,"TEST FAIL");   
  
     $finish;
    end
  
    else if((cpu_awlen[3:0] == 4'b0) &&
  //     (cpu_awaddr[31:0] == 32'h6000fff8) &&
  //     (cpu_awaddr[31:0] == 32'h0003fff8) &&
       (cpu_awaddr[31:0] == 32'h01ff_fff0) &&
        cpu_wvalid &&
       `clk_en)
    begin
     if(cpu_wstrb[15:0] == 16'hf)
     begin
        $write("%c", `SOC_TOP.biu_pad_wdata[7:0]);
     end
     else if(cpu_wstrb[15:0] == 16'hf0)
     begin
        $write("%c", `SOC_TOP.biu_pad_wdata[39:32]);
     end
     else if(cpu_wstrb[15:0] == 16'hf00)
     begin
        $write("%c", `SOC_TOP.biu_pad_wdata[71:64]);
     end
     else if(cpu_wstrb[15:0] == 16'hf000)
     begin
        $write("%c", `SOC_TOP.biu_pad_wdata[103:96]);
     end
    end
  
  end
  
  
  
  parameter cpu_cycle = 110;
  `ifndef NO_DUMP
  initial
  begin
  `ifdef NC_SIM
    $dumpfile("test.vcd");
    $dumpvars;  
  `else
    `ifdef IVERILOG_SIM
      $dumpfile("test.vcd");
      $dumpvars;  
    `else
      $dumpfile("test.vcd");
      $dumpvars;  
    `endif
  `endif
  end
  `endif
  
  assign jtg_tdi = 1'b0;
  assign uart0_sin = 1'b1;
  
  
  soc x_soc(
    .i_pad_clk           ( clk                  ),
    .b_pad_gpio_porta    ( b_pad_gpio_porta     ),
    .i_pad_jtg_trst_b    ( jrst_b               ),
    .i_pad_jtg_tclk      ( jclk                 ),
    .i_pad_jtg_tdi       ( jtg_tdi              ),
    .i_pad_jtg_tms       ( jtg_tms              ),
    .i_pad_uart0_sin     ( uart0_sin            ),
    .o_pad_jtg_tdo       ( jtg_tdo              ),
    .o_pad_uart0_sout    ( uart0_sout           ),
    .i_pad_rst_b         ( rst_b                )
  );
  
  int_mnt x_int_mnt(
  );
  
  // debug_stim x_debug_stim(
  // );

// Latest Power control
`ifdef UPF_INCLUDED
  import UPF::*;

  initial
  begin
        supply_on ("VDD", 1.00);
     	supply_on ("VDDG", 1.00);
  end

  initial 
  begin
    $deposit(top.x_soc.pmu_cpu_pwr_on,  1'b1);
    $deposit(top.x_soc.pmu_cpu_iso_in,  1'b0);
    $deposit(top.x_soc.pmu_cpu_iso_out, 1'b0);
    $deposit(top.x_soc.pmu_cpu_save,    1'b0);
    $deposit(top.x_soc.pmu_cpu_restore, 1'b0);
  end
`endif
  
  reg [31:0] virtual_counter;

  always @(posedge `CPU_CLK or negedge `CPU_RST)
  begin
    if(!`CPU_RST)
      virtual_counter[31:0] <= 32'b0;
    else if(virtual_counter[31:0]==32'hffffffff)
      virtual_counter[31:0] <= virtual_counter[31:0];
    else
      virtual_counter[31:0] <= virtual_counter[31:0] +1'b1;
  end 

  //always @(*)
  //begin
  //if(virtual_counter[31:0]> 32'h3000000) $finish;
  //end
  
  // ------------------------------------------------------------
  // Retire-time register write logging (PC -> x/f rd -> data)
  // Only for simulation; guarded by C910_LOGGER from Makefile.
  // ------------------------------------------------------------
`ifdef C910_LOGGER
  // Hierarchical short-hands
  `define PST_PREG    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.x_ct_rtu_pst_preg
  `define PST_VREG    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.x_ct_rtu_pst_freg
  `define RETIRE_MOD  `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.x_ct_rtu_retire
  `define PREGFILE    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_rf_prf_pregfile
  `define VREGFILE_FR `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_rf_prf_vregfile_fr

  function [63:0] get_preg_data;
    input [6:0] idx;
    begin
      case (idx)
        7'd0  : get_preg_data = `PREGFILE.preg0_reg_dout;
        7'd1  : get_preg_data = `PREGFILE.preg1_reg_dout;
        7'd2  : get_preg_data = `PREGFILE.preg2_reg_dout;
        7'd3  : get_preg_data = `PREGFILE.preg3_reg_dout;
        7'd4  : get_preg_data = `PREGFILE.preg4_reg_dout;
        7'd5  : get_preg_data = `PREGFILE.preg5_reg_dout;
        7'd6  : get_preg_data = `PREGFILE.preg6_reg_dout;
        7'd7  : get_preg_data = `PREGFILE.preg7_reg_dout;
        7'd8  : get_preg_data = `PREGFILE.preg8_reg_dout;
        7'd9  : get_preg_data = `PREGFILE.preg9_reg_dout;
        7'd10 : get_preg_data = `PREGFILE.preg10_reg_dout;
        7'd11 : get_preg_data = `PREGFILE.preg11_reg_dout;
        7'd12 : get_preg_data = `PREGFILE.preg12_reg_dout;
        7'd13 : get_preg_data = `PREGFILE.preg13_reg_dout;
        7'd14 : get_preg_data = `PREGFILE.preg14_reg_dout;
        7'd15 : get_preg_data = `PREGFILE.preg15_reg_dout;
        7'd16 : get_preg_data = `PREGFILE.preg16_reg_dout;
        7'd17 : get_preg_data = `PREGFILE.preg17_reg_dout;
        7'd18 : get_preg_data = `PREGFILE.preg18_reg_dout;
        7'd19 : get_preg_data = `PREGFILE.preg19_reg_dout;
        7'd20 : get_preg_data = `PREGFILE.preg20_reg_dout;
        7'd21 : get_preg_data = `PREGFILE.preg21_reg_dout;
        7'd22 : get_preg_data = `PREGFILE.preg22_reg_dout;
        7'd23 : get_preg_data = `PREGFILE.preg23_reg_dout;
        7'd24 : get_preg_data = `PREGFILE.preg24_reg_dout;
        7'd25 : get_preg_data = `PREGFILE.preg25_reg_dout;
        7'd26 : get_preg_data = `PREGFILE.preg26_reg_dout;
        7'd27 : get_preg_data = `PREGFILE.preg27_reg_dout;
        7'd28 : get_preg_data = `PREGFILE.preg28_reg_dout;
        7'd29 : get_preg_data = `PREGFILE.preg29_reg_dout;
        7'd30 : get_preg_data = `PREGFILE.preg30_reg_dout;
        7'd31 : get_preg_data = `PREGFILE.preg31_reg_dout;
        7'd32 : get_preg_data = `PREGFILE.preg32_reg_dout;
        7'd33 : get_preg_data = `PREGFILE.preg33_reg_dout;
        7'd34 : get_preg_data = `PREGFILE.preg34_reg_dout;
        7'd35 : get_preg_data = `PREGFILE.preg35_reg_dout;
        7'd36 : get_preg_data = `PREGFILE.preg36_reg_dout;
        7'd37 : get_preg_data = `PREGFILE.preg37_reg_dout;
        7'd38 : get_preg_data = `PREGFILE.preg38_reg_dout;
        7'd39 : get_preg_data = `PREGFILE.preg39_reg_dout;
        7'd40 : get_preg_data = `PREGFILE.preg40_reg_dout;
        7'd41 : get_preg_data = `PREGFILE.preg41_reg_dout;
        7'd42 : get_preg_data = `PREGFILE.preg42_reg_dout;
        7'd43 : get_preg_data = `PREGFILE.preg43_reg_dout;
        7'd44 : get_preg_data = `PREGFILE.preg44_reg_dout;
        7'd45 : get_preg_data = `PREGFILE.preg45_reg_dout;
        7'd46 : get_preg_data = `PREGFILE.preg46_reg_dout;
        7'd47 : get_preg_data = `PREGFILE.preg47_reg_dout;
        7'd48 : get_preg_data = `PREGFILE.preg48_reg_dout;
        7'd49 : get_preg_data = `PREGFILE.preg49_reg_dout;
        7'd50 : get_preg_data = `PREGFILE.preg50_reg_dout;
        7'd51 : get_preg_data = `PREGFILE.preg51_reg_dout;
        7'd52 : get_preg_data = `PREGFILE.preg52_reg_dout;
        7'd53 : get_preg_data = `PREGFILE.preg53_reg_dout;
        7'd54 : get_preg_data = `PREGFILE.preg54_reg_dout;
        7'd55 : get_preg_data = `PREGFILE.preg55_reg_dout;
        7'd56 : get_preg_data = `PREGFILE.preg56_reg_dout;
        7'd57 : get_preg_data = `PREGFILE.preg57_reg_dout;
        7'd58 : get_preg_data = `PREGFILE.preg58_reg_dout;
        7'd59 : get_preg_data = `PREGFILE.preg59_reg_dout;
        7'd60 : get_preg_data = `PREGFILE.preg60_reg_dout;
        7'd61 : get_preg_data = `PREGFILE.preg61_reg_dout;
        7'd62 : get_preg_data = `PREGFILE.preg62_reg_dout;
        7'd63 : get_preg_data = `PREGFILE.preg63_reg_dout;
        7'd64 : get_preg_data = `PREGFILE.preg64_reg_dout;
        7'd65 : get_preg_data = `PREGFILE.preg65_reg_dout;
        7'd66 : get_preg_data = `PREGFILE.preg66_reg_dout;
        7'd67 : get_preg_data = `PREGFILE.preg67_reg_dout;
        7'd68 : get_preg_data = `PREGFILE.preg68_reg_dout;
        7'd69 : get_preg_data = `PREGFILE.preg69_reg_dout;
        7'd70 : get_preg_data = `PREGFILE.preg70_reg_dout;
        7'd71 : get_preg_data = `PREGFILE.preg71_reg_dout;
        7'd72 : get_preg_data = `PREGFILE.preg72_reg_dout;
        7'd73 : get_preg_data = `PREGFILE.preg73_reg_dout;
        7'd74 : get_preg_data = `PREGFILE.preg74_reg_dout;
        7'd75 : get_preg_data = `PREGFILE.preg75_reg_dout;
        7'd76 : get_preg_data = `PREGFILE.preg76_reg_dout;
        7'd77 : get_preg_data = `PREGFILE.preg77_reg_dout;
        7'd78 : get_preg_data = `PREGFILE.preg78_reg_dout;
        7'd79 : get_preg_data = `PREGFILE.preg79_reg_dout;
        7'd80 : get_preg_data = `PREGFILE.preg80_reg_dout;
        7'd81 : get_preg_data = `PREGFILE.preg81_reg_dout;
        7'd82 : get_preg_data = `PREGFILE.preg82_reg_dout;
        7'd83 : get_preg_data = `PREGFILE.preg83_reg_dout;
        7'd84 : get_preg_data = `PREGFILE.preg84_reg_dout;
        7'd85 : get_preg_data = `PREGFILE.preg85_reg_dout;
        7'd86 : get_preg_data = `PREGFILE.preg86_reg_dout;
        7'd87 : get_preg_data = `PREGFILE.preg87_reg_dout;
        7'd88 : get_preg_data = `PREGFILE.preg88_reg_dout;
        7'd89 : get_preg_data = `PREGFILE.preg89_reg_dout;
        7'd90 : get_preg_data = `PREGFILE.preg90_reg_dout;
        7'd91 : get_preg_data = `PREGFILE.preg91_reg_dout;
        7'd92 : get_preg_data = `PREGFILE.preg92_reg_dout;
        7'd93 : get_preg_data = `PREGFILE.preg93_reg_dout;
        7'd94 : get_preg_data = `PREGFILE.preg94_reg_dout;
        7'd95 : get_preg_data = `PREGFILE.preg95_reg_dout;
        default: get_preg_data = 64'hx;
      endcase
    end
  endfunction

  function [63:0] get_vreg_fr_data;
    input [5:0] idx;
    begin
      case (idx)
        6'd0  : get_vreg_fr_data = `VREGFILE_FR.vreg0_reg_dout;
        6'd1  : get_vreg_fr_data = `VREGFILE_FR.vreg1_reg_dout;
        6'd2  : get_vreg_fr_data = `VREGFILE_FR.vreg2_reg_dout;
        6'd3  : get_vreg_fr_data = `VREGFILE_FR.vreg3_reg_dout;
        6'd4  : get_vreg_fr_data = `VREGFILE_FR.vreg4_reg_dout;
        6'd5  : get_vreg_fr_data = `VREGFILE_FR.vreg5_reg_dout;
        6'd6  : get_vreg_fr_data = `VREGFILE_FR.vreg6_reg_dout;
        6'd7  : get_vreg_fr_data = `VREGFILE_FR.vreg7_reg_dout;
        6'd8  : get_vreg_fr_data = `VREGFILE_FR.vreg8_reg_dout;
        6'd9  : get_vreg_fr_data = `VREGFILE_FR.vreg9_reg_dout;
        6'd10 : get_vreg_fr_data = `VREGFILE_FR.vreg10_reg_dout;
        6'd11 : get_vreg_fr_data = `VREGFILE_FR.vreg11_reg_dout;
        6'd12 : get_vreg_fr_data = `VREGFILE_FR.vreg12_reg_dout;
        6'd13 : get_vreg_fr_data = `VREGFILE_FR.vreg13_reg_dout;
        6'd14 : get_vreg_fr_data = `VREGFILE_FR.vreg14_reg_dout;
        6'd15 : get_vreg_fr_data = `VREGFILE_FR.vreg15_reg_dout;
        6'd16 : get_vreg_fr_data = `VREGFILE_FR.vreg16_reg_dout;
        6'd17 : get_vreg_fr_data = `VREGFILE_FR.vreg17_reg_dout;
        6'd18 : get_vreg_fr_data = `VREGFILE_FR.vreg18_reg_dout;
        6'd19 : get_vreg_fr_data = `VREGFILE_FR.vreg19_reg_dout;
        6'd20 : get_vreg_fr_data = `VREGFILE_FR.vreg20_reg_dout;
        6'd21 : get_vreg_fr_data = `VREGFILE_FR.vreg21_reg_dout;
        6'd22 : get_vreg_fr_data = `VREGFILE_FR.vreg22_reg_dout;
        6'd23 : get_vreg_fr_data = `VREGFILE_FR.vreg23_reg_dout;
        6'd24 : get_vreg_fr_data = `VREGFILE_FR.vreg24_reg_dout;
        6'd25 : get_vreg_fr_data = `VREGFILE_FR.vreg25_reg_dout;
        6'd26 : get_vreg_fr_data = `VREGFILE_FR.vreg26_reg_dout;
        6'd27 : get_vreg_fr_data = `VREGFILE_FR.vreg27_reg_dout;
        6'd28 : get_vreg_fr_data = `VREGFILE_FR.vreg28_reg_dout;
        6'd29 : get_vreg_fr_data = `VREGFILE_FR.vreg29_reg_dout;
        6'd30 : get_vreg_fr_data = `VREGFILE_FR.vreg30_reg_dout;
        6'd31 : get_vreg_fr_data = `VREGFILE_FR.vreg31_reg_dout;
        6'd32 : get_vreg_fr_data = `VREGFILE_FR.vreg32_reg_dout;
        6'd33 : get_vreg_fr_data = `VREGFILE_FR.vreg33_reg_dout;
        6'd34 : get_vreg_fr_data = `VREGFILE_FR.vreg34_reg_dout;
        6'd35 : get_vreg_fr_data = `VREGFILE_FR.vreg35_reg_dout;
        6'd36 : get_vreg_fr_data = `VREGFILE_FR.vreg36_reg_dout;
        6'd37 : get_vreg_fr_data = `VREGFILE_FR.vreg37_reg_dout;
        6'd38 : get_vreg_fr_data = `VREGFILE_FR.vreg38_reg_dout;
        6'd39 : get_vreg_fr_data = `VREGFILE_FR.vreg39_reg_dout;
        6'd40 : get_vreg_fr_data = `VREGFILE_FR.vreg40_reg_dout;
        6'd41 : get_vreg_fr_data = `VREGFILE_FR.vreg41_reg_dout;
        6'd42 : get_vreg_fr_data = `VREGFILE_FR.vreg42_reg_dout;
        6'd43 : get_vreg_fr_data = `VREGFILE_FR.vreg43_reg_dout;
        6'd44 : get_vreg_fr_data = `VREGFILE_FR.vreg44_reg_dout;
        6'd45 : get_vreg_fr_data = `VREGFILE_FR.vreg45_reg_dout;
        6'd46 : get_vreg_fr_data = `VREGFILE_FR.vreg46_reg_dout;
        6'd47 : get_vreg_fr_data = `VREGFILE_FR.vreg47_reg_dout;
        6'd48 : get_vreg_fr_data = `VREGFILE_FR.vreg48_reg_dout;
        6'd49 : get_vreg_fr_data = `VREGFILE_FR.vreg49_reg_dout;
        6'd50 : get_vreg_fr_data = `VREGFILE_FR.vreg50_reg_dout;
        6'd51 : get_vreg_fr_data = `VREGFILE_FR.vreg51_reg_dout;
        6'd52 : get_vreg_fr_data = `VREGFILE_FR.vreg52_reg_dout;
        6'd53 : get_vreg_fr_data = `VREGFILE_FR.vreg53_reg_dout;
        6'd54 : get_vreg_fr_data = `VREGFILE_FR.vreg54_reg_dout;
        6'd55 : get_vreg_fr_data = `VREGFILE_FR.vreg55_reg_dout;
        6'd56 : get_vreg_fr_data = `VREGFILE_FR.vreg56_reg_dout;
        6'd57 : get_vreg_fr_data = `VREGFILE_FR.vreg57_reg_dout;
        6'd58 : get_vreg_fr_data = `VREGFILE_FR.vreg58_reg_dout;
        6'd59 : get_vreg_fr_data = `VREGFILE_FR.vreg59_reg_dout;
        6'd60 : get_vreg_fr_data = `VREGFILE_FR.vreg60_reg_dout;
        6'd61 : get_vreg_fr_data = `VREGFILE_FR.vreg61_reg_dout;
        6'd62 : get_vreg_fr_data = `VREGFILE_FR.vreg62_reg_dout;
        6'd63 : get_vreg_fr_data = `VREGFILE_FR.vreg63_reg_dout;
        default: get_vreg_fr_data = 64'hx;
      endcase
    end
  endfunction

    task automatic capture_preg_write;
      input string src_name;
      input [6:0] preg_idx;
      input [63:0] data_in;
      begin
        if (preg_idx <= 7'd95) begin
          preg_scoreboard_data[preg_idx]  = data_in;
          preg_scoreboard_valid[preg_idx] = 1'b1;
  `ifdef C910_DBG_XWB
          $display("[DBG][X-SB] src=%s preg=%0d data=0x%016h", src_name, preg_idx, data_in);
  `endif
        end else begin
  `ifdef C910_DBG_XWB
          $display("[DBG][X-SB-WARN] src=%s preg=%0d out of range, data=0x%016h", src_name, preg_idx, data_in);
  `endif
        end
      end
    endtask

    task automatic capture_vreg_write;
      input string src_name;
      input [5:0] vreg_idx;
      input [63:0] data_in;
      begin
        if (vreg_idx <= 6'd63) begin
          vreg_scoreboard_data[vreg_idx]  = data_in;
          vreg_scoreboard_valid[vreg_idx] = 1'b1;
  `ifdef C910_DBG_XWB
          $display("[DBG][F-SB] src=%s vreg=%0d data=0x%016h", src_name, vreg_idx, data_in);
  `endif
          if (fwb_pending_valid[vreg_idx]) begin
            emit_fwb_log(fwb_pending_slot[vreg_idx], fwb_pending_pc[vreg_idx], vreg_idx, fwb_pending_frd[vreg_idx]);
            fwb_pending_valid[vreg_idx] = 1'b0;
          end
        end else begin
  `ifdef C910_DBG_XWB
          $display("[DBG][F-SB-WARN] src=%s vreg=%0d out of range, data=0x%016h", src_name, vreg_idx, data_in);
  `endif
        end
      end
    endtask

    task automatic emit_fwb_log;
      input integer slot;
      input [39:0] pc40;
      input [5:0] vreg_idx;
      input [4:0] frd;
      reg [63:0] data;
  `ifdef C910_DBG_XWB
      reg [63:0] vreg_snapshot;
  `endif
      begin
        if (vreg_idx > 6'd63) begin
          $display("[WARN][F-WB] pc=0x%010h slot=%0d vreg=%0d out of range, skipping log", {pc40[39:0]}, slot, vreg_idx);
          return;
        end
        if (vreg_scoreboard_valid[vreg_idx]) begin
          data = vreg_scoreboard_data[vreg_idx];
          vreg_scoreboard_valid[vreg_idx] = 1'b0;
  `ifdef C910_DBG_XWB
          vreg_snapshot = get_vreg_fr_data(vreg_idx);
          if (vreg_snapshot !== data)
            $display("[DBG][F-SB] pc=0x%010h slot=%0d vreg=%0d scoreboard=0x%016h VREG=0x%016h (scoreboard wins)",
                     {pc40[39:0]}, slot, vreg_idx, data, vreg_snapshot);
          else
            $display("[DBG][F-SB] pc=0x%010h slot=%0d vreg=%0d scoreboard hit data=0x%016h",
                     {pc40[39:0]}, slot, vreg_idx, data);
  `endif
        end else begin
          data = get_vreg_fr_data(vreg_idx);
          $display("[WARN][F-WB] pc=0x%010h slot=%0d vreg=%0d scoreboard entry missing, falling back to live VREG data=0x%016h",
                   {pc40[39:0]}, slot, vreg_idx, data);
        end
        $display("[C910][F-WB] pc=0x%010h rd=f%0d vreg=%0d data=0x%016h",
                 {pc40[39:0]}, frd, vreg_idx, data);
      end
    endtask

  task automatic log_slot_xwb;
    input integer slot; // 0/1/2
    input [39:0] pc40;
    reg   [6:0] preg_idx;
    reg   [4:0] rd;
    reg   found;
  reg   [63:0] data;
    reg  [95:0]  match_bitmap;
    integer      match_count;
    begin
      found = 1'b0;
      match_count = 0;
      match_bitmap = 96'b0;
      // Unrolled scan over entries 1..95
      // NOTE: preg0 does NOT have a PST entry in hardware (confirmed by RTL error)
      // This likely means preg0 is special (hardwired or not renamed)
      // Macro to reduce duplication per entry
      `define TRY_PREG_ENTRY(N) \
        begin \
          if ((slot==0 && `PST_PREG.x_ct_rtu_pst_entry_preg``N``.x_retire0_match_wb) || \
              (slot==1 && `PST_PREG.x_ct_rtu_pst_entry_preg``N``.x_retire1_match_wb) || \
              (slot==2 && `PST_PREG.x_ct_rtu_pst_entry_preg``N``.x_retire2_match_wb)) begin \
            match_count = match_count + 1; \
            match_bitmap[N] = 1'b1; \
            if (!found) begin \
              preg_idx = N; \
              rd       = `PST_PREG.x_ct_rtu_pst_entry_preg``N``.dst_reg; \
              found    = 1'b1; \
            end \
          end \
        end
      `TRY_PREG_ENTRY(1)   `TRY_PREG_ENTRY(2)   `TRY_PREG_ENTRY(3)   `TRY_PREG_ENTRY(4)
      `TRY_PREG_ENTRY(5)   `TRY_PREG_ENTRY(6)   `TRY_PREG_ENTRY(7)   `TRY_PREG_ENTRY(8)
      `TRY_PREG_ENTRY(9)   `TRY_PREG_ENTRY(10)  `TRY_PREG_ENTRY(11)  `TRY_PREG_ENTRY(12)
      `TRY_PREG_ENTRY(13)  `TRY_PREG_ENTRY(14)  `TRY_PREG_ENTRY(15)  `TRY_PREG_ENTRY(16)
      `TRY_PREG_ENTRY(17)  `TRY_PREG_ENTRY(18)  `TRY_PREG_ENTRY(19)  `TRY_PREG_ENTRY(20)
      `TRY_PREG_ENTRY(21)  `TRY_PREG_ENTRY(22)  `TRY_PREG_ENTRY(23)  `TRY_PREG_ENTRY(24)
      `TRY_PREG_ENTRY(25)  `TRY_PREG_ENTRY(26)  `TRY_PREG_ENTRY(27)  `TRY_PREG_ENTRY(28)
      `TRY_PREG_ENTRY(29)  `TRY_PREG_ENTRY(30)  `TRY_PREG_ENTRY(31)  `TRY_PREG_ENTRY(32)
      `TRY_PREG_ENTRY(33)  `TRY_PREG_ENTRY(34)  `TRY_PREG_ENTRY(35)  `TRY_PREG_ENTRY(36)
      `TRY_PREG_ENTRY(37)  `TRY_PREG_ENTRY(38)  `TRY_PREG_ENTRY(39)  `TRY_PREG_ENTRY(40)
      `TRY_PREG_ENTRY(41)  `TRY_PREG_ENTRY(42)  `TRY_PREG_ENTRY(43)  `TRY_PREG_ENTRY(44)
      `TRY_PREG_ENTRY(45)  `TRY_PREG_ENTRY(46)  `TRY_PREG_ENTRY(47)  `TRY_PREG_ENTRY(48)
      `TRY_PREG_ENTRY(49)  `TRY_PREG_ENTRY(50)  `TRY_PREG_ENTRY(51)  `TRY_PREG_ENTRY(52)
      `TRY_PREG_ENTRY(53)  `TRY_PREG_ENTRY(54)  `TRY_PREG_ENTRY(55)  `TRY_PREG_ENTRY(56)
      `TRY_PREG_ENTRY(57)  `TRY_PREG_ENTRY(58)  `TRY_PREG_ENTRY(59)  `TRY_PREG_ENTRY(60)
      `TRY_PREG_ENTRY(61)  `TRY_PREG_ENTRY(62)  `TRY_PREG_ENTRY(63)  `TRY_PREG_ENTRY(64)
      `TRY_PREG_ENTRY(65)  `TRY_PREG_ENTRY(66)  `TRY_PREG_ENTRY(67)  `TRY_PREG_ENTRY(68)
      `TRY_PREG_ENTRY(69)  `TRY_PREG_ENTRY(70)  `TRY_PREG_ENTRY(71)  `TRY_PREG_ENTRY(72)
      `TRY_PREG_ENTRY(73)  `TRY_PREG_ENTRY(74)  `TRY_PREG_ENTRY(75)  `TRY_PREG_ENTRY(76)
      `TRY_PREG_ENTRY(77)  `TRY_PREG_ENTRY(78)  `TRY_PREG_ENTRY(79)  `TRY_PREG_ENTRY(80)
      `TRY_PREG_ENTRY(81)  `TRY_PREG_ENTRY(82)  `TRY_PREG_ENTRY(83)  `TRY_PREG_ENTRY(84)
      `TRY_PREG_ENTRY(85)  `TRY_PREG_ENTRY(86)  `TRY_PREG_ENTRY(87)  `TRY_PREG_ENTRY(88)
      `TRY_PREG_ENTRY(89)  `TRY_PREG_ENTRY(90)  `TRY_PREG_ENTRY(91)  `TRY_PREG_ENTRY(92)
      `TRY_PREG_ENTRY(93)  `TRY_PREG_ENTRY(94)  `TRY_PREG_ENTRY(95)
      `undef TRY_PREG_ENTRY
      if(found) begin
        automatic bit scoreboard_hit;
        automatic bit idx_in_range;
        automatic reg [63:0] prf_snapshot;

        xwb_total_count = xwb_total_count + 1;
        if (match_count > 1)
          xwb_multiple_pst_match_count = xwb_multiple_pst_match_count + 1;

        idx_in_range   = (preg_idx <= 7'd95);
        scoreboard_hit = idx_in_range ? preg_scoreboard_valid[preg_idx] : 1'b0;

        if (scoreboard_hit) begin
          data = preg_scoreboard_data[preg_idx];
          preg_scoreboard_valid[preg_idx] = 1'b0;
`ifdef C910_DBG_XWB
          prf_snapshot = get_preg_data(preg_idx);
          if (prf_snapshot !== data)
            $display("[DBG][X-SB] pc=0x%010h slot=%0d preg=%0d scoreboard=0x%016h PRF=0x%016h (scoreboard wins)",
                     {pc40[39:0]}, slot, preg_idx, data, prf_snapshot);
          else
            $display("[DBG][X-SB] pc=0x%010h slot=%0d preg=%0d scoreboard hit data=0x%016h",
                     {pc40[39:0]}, slot, preg_idx, data);
`endif
        end else begin
          data = get_preg_data(preg_idx);
          xwb_no_bus_hit_count = xwb_no_bus_hit_count + 1;
`ifdef C910_DBG_XWB
          if (!idx_in_range)
            $display("[DBG][X-WARN] pc=0x%010h slot=%0d preg=%0d outside scoreboard range, using PRF data=0x%016h",
                     {pc40[39:0]}, slot, preg_idx, data);
          else
            $display("[DBG][X-WARN] pc=0x%010h slot=%0d preg=%0d scoreboard miss, using PRF data=0x%016h",
                     {pc40[39:0]}, slot, preg_idx, data);
`endif
        end

        if (preg_idx == 7'd0)
          xwb_preg0_count = xwb_preg0_count + 1;

        if (match_count > 1) begin
          $display("[ERROR][X-WB] pc=0x%010h slot=%0d MULTIPLE PST matches (%0d entries), bitmap=0x%024h, using first=%0d",
                   {pc40[39:0]}, slot, match_count, match_bitmap, preg_idx);
        end

        if (rd == 5'd0) begin
          if (data != 64'h0) begin
            $display("[WARN][X-WB] pc=0x%010h slot=%0d writing x0 (arch reg 0) with non-zero value 0x%016h via preg=%0d",
                     {pc40[39:0]}, slot, data, preg_idx);
          end
          // Skip emitting a normal log entry for x0 to avoid misleading traces
        end else begin
          $display("[C910][X-WB] pc=0x%010h rd=x%0d preg=%0d data=0x%016h", {pc40[39:0]}, rd, preg_idx, data);
        end
      end else begin
        xwb_no_pst_match_count = xwb_no_pst_match_count + 1;
`ifdef C910_DBG_XWB
        $display("[DBG][X-WARN] pc=0x%010h slot=%0d no PST entry matched, skipping", {pc40[39:0]}, slot);
`endif
      end
    end
  endtask

  task automatic log_slot_fwb;
    input integer slot; // 0/1/2
    input [39:0] pc40;
    reg   [5:0] vreg_idx;
    reg   [4:0] frd;
    reg   found;
    reg   [63:0] data;
    reg   [63:0] match_bitmap;
    integer      match_count;
    begin
      found = 1'b0;
      match_bitmap = 64'b0;
      match_count = 0;
      `define TRY_VREG_ENTRY(N) \
        begin \
          if ((slot==0 && `PST_VREG.x_ct_rtu_pst_entry_vreg``N``.x_retire0_match_wb) || \
              (slot==1 && `PST_VREG.x_ct_rtu_pst_entry_vreg``N``.x_retire1_match_wb) || \
              (slot==2 && `PST_VREG.x_ct_rtu_pst_entry_vreg``N``.x_retire2_match_wb)) begin \
            match_count = match_count + 1; \
            match_bitmap[N] = 1'b1; \
            if (!found) begin \
              vreg_idx = N; \
              frd      = `PST_VREG.x_ct_rtu_pst_entry_vreg``N``.dstv_reg; \
              found    = 1'b1; \
            end \
          end \
        end
      // vreg0..63
      `TRY_VREG_ENTRY(0)   `TRY_VREG_ENTRY(1)   `TRY_VREG_ENTRY(2)   `TRY_VREG_ENTRY(3)
      `TRY_VREG_ENTRY(4)   `TRY_VREG_ENTRY(5)   `TRY_VREG_ENTRY(6)   `TRY_VREG_ENTRY(7)
      `TRY_VREG_ENTRY(8)   `TRY_VREG_ENTRY(9)   `TRY_VREG_ENTRY(10)  `TRY_VREG_ENTRY(11)
      `TRY_VREG_ENTRY(12)  `TRY_VREG_ENTRY(13)  `TRY_VREG_ENTRY(14)  `TRY_VREG_ENTRY(15)
      `TRY_VREG_ENTRY(16)  `TRY_VREG_ENTRY(17)  `TRY_VREG_ENTRY(18)  `TRY_VREG_ENTRY(19)
      `TRY_VREG_ENTRY(20)  `TRY_VREG_ENTRY(21)  `TRY_VREG_ENTRY(22)  `TRY_VREG_ENTRY(23)
      `TRY_VREG_ENTRY(24)  `TRY_VREG_ENTRY(25)  `TRY_VREG_ENTRY(26)  `TRY_VREG_ENTRY(27)
      `TRY_VREG_ENTRY(28)  `TRY_VREG_ENTRY(29)  `TRY_VREG_ENTRY(30)  `TRY_VREG_ENTRY(31)
      `TRY_VREG_ENTRY(32)  `TRY_VREG_ENTRY(33)  `TRY_VREG_ENTRY(34)  `TRY_VREG_ENTRY(35)
      `TRY_VREG_ENTRY(36)  `TRY_VREG_ENTRY(37)  `TRY_VREG_ENTRY(38)  `TRY_VREG_ENTRY(39)
      `TRY_VREG_ENTRY(40)  `TRY_VREG_ENTRY(41)  `TRY_VREG_ENTRY(42)  `TRY_VREG_ENTRY(43)
      `TRY_VREG_ENTRY(44)  `TRY_VREG_ENTRY(45)  `TRY_VREG_ENTRY(46)  `TRY_VREG_ENTRY(47)
      `TRY_VREG_ENTRY(48)  `TRY_VREG_ENTRY(49)  `TRY_VREG_ENTRY(50)  `TRY_VREG_ENTRY(51)
      `TRY_VREG_ENTRY(52)  `TRY_VREG_ENTRY(53)  `TRY_VREG_ENTRY(54)  `TRY_VREG_ENTRY(55)
      `TRY_VREG_ENTRY(56)  `TRY_VREG_ENTRY(57)  `TRY_VREG_ENTRY(58)  `TRY_VREG_ENTRY(59)
      `TRY_VREG_ENTRY(60)  `TRY_VREG_ENTRY(61)  `TRY_VREG_ENTRY(62)  `TRY_VREG_ENTRY(63)
      `undef TRY_VREG_ENTRY

      if(found) begin
        automatic bit idx_in_range;
        automatic bit scoreboard_hit;
        automatic reg [63:0] prf_snapshot;

        idx_in_range   = (vreg_idx <= 6'd63);
        scoreboard_hit = idx_in_range ? vreg_scoreboard_valid[vreg_idx] : 1'b0;

        if (match_count > 1) begin
          $display("[ERROR][F-WB] pc=0x%010h slot=%0d MULTIPLE PST matches (%0d entries), bitmap=0x%016h, using first=%0d",
                   {pc40[39:0]}, slot, match_count, match_bitmap, vreg_idx);
        end

        if (scoreboard_hit) begin
          emit_fwb_log(slot, pc40, vreg_idx, frd);
        end else if (idx_in_range) begin
          if (fwb_pending_valid[vreg_idx]) begin
            $display("[ERROR][F-WB] pc=0x%010h slot=%0d vreg=%0d already pending, dropping previous retire record",
                     {pc40[39:0]}, slot, vreg_idx);
          end
          fwb_pending_valid[vreg_idx] = 1'b1;
          fwb_pending_pc[vreg_idx]    = pc40;
          fwb_pending_frd[vreg_idx]   = frd;
          fwb_pending_slot[vreg_idx]  = slot[1:0];
`ifdef C910_DBG_XWB
          $display("[DBG][F-SB] pc=0x%010h slot=%0d vreg=%0d scoreboard miss, deferring until WB data arrives",
                   {pc40[39:0]}, slot, vreg_idx);
`endif
        end else begin
          $display("[WARN][F-WB] pc=0x%010h slot=%0d vreg=%0d outside scoreboard range, skipping log",
                   {pc40[39:0]}, slot, vreg_idx);
        end
      end else begin
`ifdef C910_DBG_XWB
        $display("[DBG][F-WARN] pc=0x%010h slot=%0d no PST entry matched, skipping", {pc40[39:0]}, slot);
`endif
      end
    end
  endtask

  // Capture writeback data into scoreboards and emit retire logs
  always @(posedge clk or negedge `CPU_RST) begin
    integer idx;
    if (!`CPU_RST) begin
      for (idx = 0; idx <= 95; idx = idx + 1) begin
        preg_scoreboard_valid[idx] <= 1'b0;
        preg_scoreboard_data[idx]  <= 64'b0;
      end
      for (idx = 0; idx <= 63; idx = idx + 1) begin
        vreg_scoreboard_valid[idx] <= 1'b0;
        vreg_scoreboard_data[idx]  <= 64'b0;
        fwb_pending_valid[idx]     <= 1'b0;
        fwb_pending_pc[idx]        <= 40'b0;
        fwb_pending_frd[idx]       <= 5'b0;
        fwb_pending_slot[idx]      <= 2'b0;
      end
      xwb_total_count <= 0;
      xwb_preg0_count <= 0;
      xwb_no_pst_match_count <= 0;
      xwb_multiple_pst_match_count <= 0;
      xwb_no_bus_hit_count <= 0;
    end else begin
      integer bit_idx;
      integer hit_count;
      reg [63:0] pipe6_expand;
      reg [63:0] pipe7_expand;

      // Integer register writeback sources
      if (`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg_vld)
        capture_preg_write("iu_pipe0",
                           `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg,
                           `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg_data);

      if (`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg_vld)
        capture_preg_write("iu_pipe1",
                           `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg,
                           `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg_data);

      if (`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg_vld)
        capture_preg_write("lsu_pipe3",
                           `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg,
                           `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg_data);

      if (`CP0_RSLT_VLD)
        capture_preg_write("cp0_ex3",
                           `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_cp0_top.cp0_iu_ex3_rslt_preg,
                           `CP0_RSLT);

      if (`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.vfpu_iu_ex2_pipe6_mfvr_data_vld)
        capture_preg_write("vfpu_mfvr6",
                           `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.vfpu_iu_ex2_pipe6_mfvr_preg,
                           `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.vfpu_iu_ex2_pipe6_mfvr_data);

      if (`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.vfpu_iu_ex2_pipe7_mfvr_data_vld)
        capture_preg_write("vfpu_mfvr7",
                           `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.vfpu_iu_ex2_pipe7_mfvr_preg,
                           `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.vfpu_iu_ex2_pipe7_mfvr_data);

      // Floating-point register writeback sources
      if (`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.vfpu_idu_ex5_pipe6_wb_vreg_fr_vld) begin
        pipe6_expand = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.vfpu_idu_ex5_pipe6_wb_vreg_fr_expand;
        hit_count = 0;
        for (bit_idx = 0; bit_idx < 64; bit_idx = bit_idx + 1) begin
          if (pipe6_expand[bit_idx]) begin
            hit_count = hit_count + 1;
            capture_vreg_write("vfpu_pipe6", bit_idx[5:0],
                               `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.vfpu_idu_ex5_pipe6_wb_vreg_fr_data);
          end
        end
`ifdef C910_DBG_XWB
        if (hit_count == 0)
          $display("[DBG][F-SB-WARN] pipe6 valid but expand mask is zero");
        else if (hit_count > 1)
          $display("[DBG][F-SB-WARN] pipe6 expand has %0d bits set", hit_count);
`endif
      end

      if (`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.vfpu_idu_ex5_pipe7_wb_vreg_fr_vld) begin
        pipe7_expand = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.vfpu_idu_ex5_pipe7_wb_vreg_fr_expand;
        hit_count = 0;
        for (bit_idx = 0; bit_idx < 64; bit_idx = bit_idx + 1) begin
          if (pipe7_expand[bit_idx]) begin
            hit_count = hit_count + 1;
            capture_vreg_write("vfpu_pipe7", bit_idx[5:0],
                               `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.vfpu_idu_ex5_pipe7_wb_vreg_fr_data);
          end
        end
`ifdef C910_DBG_XWB
        if (hit_count == 0)
          $display("[DBG][F-SB-WARN] pipe7 valid but expand mask is zero");
        else if (hit_count > 1)
          $display("[DBG][F-SB-WARN] pipe7 expand has %0d bits set", hit_count);
`endif
      end

      // Emit retire logs once matching scoreboard entries exist
      if(`tb_retire0 && `RETIRE_MOD.retire_pst_wb_retire_inst0_preg_vld)
        log_slot_xwb(0, `retire0_pc);
      if(`tb_retire1 && `RETIRE_MOD.retire_pst_wb_retire_inst1_preg_vld)
        log_slot_xwb(1, `retire1_pc);
      if(`tb_retire2 && `RETIRE_MOD.retire_pst_wb_retire_inst2_preg_vld)
        log_slot_xwb(2, `retire2_pc);

      if(`tb_retire0 && `RETIRE_MOD.retire_pst_wb_retire_inst0_vreg_vld)
        log_slot_fwb(0, `retire0_pc);
      if(`tb_retire1 && `RETIRE_MOD.retire_pst_wb_retire_inst1_vreg_vld)
        log_slot_fwb(1, `retire1_pc);
      if(`tb_retire2 && `RETIRE_MOD.retire_pst_wb_retire_inst2_vreg_vld)
        log_slot_fwb(2, `retire2_pc);
    end
  end
`endif

  // ------------------------------------------------------------------
  // Minimal keep-alive: keep key gating/retire signals observed even
  // when BOOT_DEBUG_LOG is off, to avoid DCE/scheduling differences.
  // No side effects (no prints), negligible overhead.
  // ------------------------------------------------------------------
  reg _ka_ff;
  wire _ka_mix = rst_b ^ `CPU_RST ^ `clk_en ^ `tb_retire0 ^ `tb_retire1 ^ `tb_retire2;
  always @(posedge clk) begin
    _ka_ff <= _ka_mix ^ _ka_ff;
  end
  
endmodule
