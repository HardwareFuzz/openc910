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

`define SOC_TOP             tb.x_soc
`define RTL_MEM             tb.x_soc.x_axi_slave128.x_f_spsram_large

`define CPU_TOP             tb.x_soc.x_cpu_sub_system_axi.x_rv_integration_platform.x_cpu_top
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

module tb();
  reg clk;
  reg jclk;
  reg rst_b;
  reg jrst_b;
  reg jtap_en;
  wire jtg_tms;
  wire jtg_tdi;
  wire jtg_tdo;
  wire  pad_yy_gate_clk_en_b;
  
  static integer FILE;
  
  wire uart0_sin;
  wire uart0_sout;
  wire [7:0]b_pad_gpio_porta;
  
  assign pad_yy_gate_clk_en_b = 1'b1;
  
  initial
  begin
    clk =0;
    forever begin
      #(`CLK_PERIOD/2) clk = ~clk;
    end
  end
  
  initial 
  begin 
    jclk = 0;
    forever begin
      #(`TCLK_PERIOD/2) jclk = ~jclk;
    end
  end
  
  initial
  begin
    rst_b = 1;
    #100;
    rst_b = 0;
    #100;
    rst_b = 1;
  end
  
  initial
  begin
    jrst_b = 1;
    #400;
    jrst_b = 0;
    #400;
    jrst_b = 1;
  end
 
  integer i;
  bit [31:0] mem_inst_temp [65536];
  bit [31:0] mem_data_temp [65536];
  string inst_pat_path;
  string data_pat_path;
  integer j;
  initial
  begin
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
    end
  
    inst_pat_path = "inst.pat";
    data_pat_path = "data.pat";
    void'($value$plusargs("INST=%s", inst_pat_path));
    void'($value$plusargs("DATA=%s", data_pat_path));

    $display("\t********* Read program *********");
    $display("\t********* Using inst file: %s *********", inst_pat_path);
    $display("\t********* Using data file: %s *********", data_pat_path);
    $readmemh(inst_pat_path, mem_inst_temp);
    $readmemh(data_pat_path, mem_data_temp);
  
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
    end
  end

  initial
  begin
  #(`MAX_RUN_TIME * `CLK_PERIOD);
    $display("**********************************************");
    $display("*   meeting max simulation time, stop!       *");
    $display("**********************************************");
    FILE = $fopen("run_case.report","w");
    $fwrite(FILE,"TEST FAIL");   
  $finish;
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
        #10;
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
     #10;
     FILE = $fopen("run_case.report","w");
     $fwrite(FILE,"TEST PASS");   
  
     $finish;
    end
      else if (value0 == 64'h2382348720 || value1 == 64'h2382348720 || value2 == 64'h444333222)
    begin
     $display("**********************************************");
     $display("*    simulation finished with error          *");
     $display("**********************************************");
     #10;
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
      $fsdbDumpvars();
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
    $deposit(tb.x_soc.pmu_cpu_pwr_on,  1'b1);
    $deposit(tb.x_soc.pmu_cpu_iso_in,  1'b0);
    $deposit(tb.x_soc.pmu_cpu_iso_out, 1'b0);
    $deposit(tb.x_soc.pmu_cpu_save,    1'b0);
    $deposit(tb.x_soc.pmu_cpu_restore, 1'b0);
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
  `define RTU_TOP     `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top
  `define PST_PREG    `RTU_TOP.x_ct_rtu_pst_preg
  `define PST_VREG    `RTU_TOP.x_ct_rtu_pst_freg
  `define RETIRE_MOD  `RTU_TOP.x_ct_rtu_retire
  `define ROB_MOD     `RTU_TOP.x_ct_rtu_rob
  `define ROB_RT      `ROB_MOD.x_ct_rtu_rob_rt
  `define PREGFILE    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_rf_prf_pregfile
  `define VREGFILE_FR `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_rf_prf_vregfile_fr

  // Track IID -> (preg, rd) mappings so we can recover writeback info even if PST has no entry
  reg [6:0] logger_iid2preg   [0:127];
  reg [4:0] logger_iid2rd     [0:127];
  reg       logger_iid_has_rd [0:127];
  reg [5:0] logger_iid2vreg   [0:127];
  reg [4:0] logger_iid2frd    [0:127];
  reg       logger_iid_has_vrd[0:127];
  integer   logger_i;

  initial begin
    for (logger_i = 0; logger_i < 128; logger_i = logger_i + 1) begin
      logger_iid2preg[logger_i]   = 7'd0;
      logger_iid2rd[logger_i]     = 5'd0;
      logger_iid_has_rd[logger_i] = 1'b0;
      logger_iid2vreg[logger_i]   = 6'd0;
      logger_iid2frd[logger_i]    = 5'd0;
      logger_iid_has_vrd[logger_i]= 1'b0;
    end
  end

  // Capture dispatch updates and retire clears to keep IID map accurate
  always @(posedge clk or negedge `CPU_RST) begin
    if(!`CPU_RST) begin
      for (logger_i = 0; logger_i < 128; logger_i = logger_i + 1) begin
        logger_iid2preg[logger_i]   <= 7'd0;
        logger_iid2rd[logger_i]     <= 5'd0;
        logger_iid_has_rd[logger_i] <= 1'b0;
        logger_iid2vreg[logger_i]   <= 6'd0;
        logger_iid2frd[logger_i]    <= 5'd0;
        logger_iid_has_vrd[logger_i]<= 1'b0;
      end
    end else begin
      if(`RTU_TOP.idu_rtu_pst_dis_inst0_preg_vld) begin
        logger_iid2preg[`RTU_TOP.idu_rtu_pst_dis_inst0_preg_iid]   <= `RTU_TOP.idu_rtu_pst_dis_inst0_preg;
        logger_iid2rd[`RTU_TOP.idu_rtu_pst_dis_inst0_preg_iid]     <= `RTU_TOP.idu_rtu_pst_dis_inst0_dst_reg;
        logger_iid_has_rd[`RTU_TOP.idu_rtu_pst_dis_inst0_preg_iid] <= 1'b1;
      end
      if(`RTU_TOP.idu_rtu_pst_dis_inst1_preg_vld) begin
        logger_iid2preg[`RTU_TOP.idu_rtu_pst_dis_inst1_preg_iid]   <= `RTU_TOP.idu_rtu_pst_dis_inst1_preg;
        logger_iid2rd[`RTU_TOP.idu_rtu_pst_dis_inst1_preg_iid]     <= `RTU_TOP.idu_rtu_pst_dis_inst1_dst_reg;
        logger_iid_has_rd[`RTU_TOP.idu_rtu_pst_dis_inst1_preg_iid] <= 1'b1;
      end
      if(`RTU_TOP.idu_rtu_pst_dis_inst2_preg_vld) begin
        logger_iid2preg[`RTU_TOP.idu_rtu_pst_dis_inst2_preg_iid]   <= `RTU_TOP.idu_rtu_pst_dis_inst2_preg;
        logger_iid2rd[`RTU_TOP.idu_rtu_pst_dis_inst2_preg_iid]     <= `RTU_TOP.idu_rtu_pst_dis_inst2_dst_reg;
        logger_iid_has_rd[`RTU_TOP.idu_rtu_pst_dis_inst2_preg_iid] <= 1'b1;
      end
      if(`RTU_TOP.idu_rtu_pst_dis_inst3_preg_vld) begin
        logger_iid2preg[`RTU_TOP.idu_rtu_pst_dis_inst3_preg_iid]   <= `RTU_TOP.idu_rtu_pst_dis_inst3_preg;
        logger_iid2rd[`RTU_TOP.idu_rtu_pst_dis_inst3_preg_iid]     <= `RTU_TOP.idu_rtu_pst_dis_inst3_dst_reg;
        logger_iid_has_rd[`RTU_TOP.idu_rtu_pst_dis_inst3_preg_iid] <= 1'b1;
      end

      if(`RTU_TOP.idu_rtu_pst_dis_inst0_vreg_vld) begin
        logger_iid2vreg[`RTU_TOP.idu_rtu_pst_dis_inst0_vreg_iid]   <= `RTU_TOP.idu_rtu_pst_dis_inst0_vreg;
        logger_iid2frd[`RTU_TOP.idu_rtu_pst_dis_inst0_vreg_iid]    <= `RTU_TOP.idu_rtu_pst_dis_inst0_dstv_reg;
        logger_iid_has_vrd[`RTU_TOP.idu_rtu_pst_dis_inst0_vreg_iid]<= 1'b1;
      end
      if(`RTU_TOP.idu_rtu_pst_dis_inst1_vreg_vld) begin
        logger_iid2vreg[`RTU_TOP.idu_rtu_pst_dis_inst1_vreg_iid]   <= `RTU_TOP.idu_rtu_pst_dis_inst1_vreg;
        logger_iid2frd[`RTU_TOP.idu_rtu_pst_dis_inst1_vreg_iid]    <= `RTU_TOP.idu_rtu_pst_dis_inst1_dstv_reg;
        logger_iid_has_vrd[`RTU_TOP.idu_rtu_pst_dis_inst1_vreg_iid]<= 1'b1;
      end
      if(`RTU_TOP.idu_rtu_pst_dis_inst2_vreg_vld) begin
        logger_iid2vreg[`RTU_TOP.idu_rtu_pst_dis_inst2_vreg_iid]   <= `RTU_TOP.idu_rtu_pst_dis_inst2_vreg;
        logger_iid2frd[`RTU_TOP.idu_rtu_pst_dis_inst2_vreg_iid]    <= `RTU_TOP.idu_rtu_pst_dis_inst2_dstv_reg;
        logger_iid_has_vrd[`RTU_TOP.idu_rtu_pst_dis_inst2_vreg_iid]<= 1'b1;
      end
      if(`RTU_TOP.idu_rtu_pst_dis_inst3_vreg_vld) begin
        logger_iid2vreg[`RTU_TOP.idu_rtu_pst_dis_inst3_vreg_iid]   <= `RTU_TOP.idu_rtu_pst_dis_inst3_vreg;
        logger_iid2frd[`RTU_TOP.idu_rtu_pst_dis_inst3_vreg_iid]    <= `RTU_TOP.idu_rtu_pst_dis_inst3_dstv_reg;
        logger_iid_has_vrd[`RTU_TOP.idu_rtu_pst_dis_inst3_vreg_iid]<= 1'b1;
      end

      if(`ROB_RT.rob_retire_inst0_vld) begin
        logger_iid_has_rd[`ROB_RT.rob_retire_inst0_iid] <= 1'b0;
        logger_iid_has_vrd[`ROB_RT.rob_retire_inst0_iid] <= 1'b0;
      end
      if(`ROB_RT.rob_retire_inst1_vld) begin
        logger_iid_has_rd[`ROB_RT.rob_retire_inst1_iid] <= 1'b0;
        logger_iid_has_vrd[`ROB_RT.rob_retire_inst1_iid] <= 1'b0;
      end
      if(`ROB_RT.rob_retire_inst2_vld) begin
        logger_iid_has_rd[`ROB_RT.rob_retire_inst2_iid] <= 1'b0;
        logger_iid_has_vrd[`ROB_RT.rob_retire_inst2_iid] <= 1'b0;
      end
    end
  end

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

  task automatic log_slot_xwb;
    input integer slot; // 0/1/2
    input [39:0] pc40;
    reg   [6:0] preg_idx;
    reg   [4:0] rd;
    reg         found;
    reg   [63:0] data;
    reg   [63:0] bus_data;
    reg   [63:0] prf_snapshot;
    reg          bus_valid;
    reg          duplicate;
    reg   [6:0]  duplicate_idx;
    reg  [95:0]  match_bitmap;
    reg          fallback_used;
    reg   [6:0]  retire_iid;
    reg          iid_has_rd;
    reg   [6:0]  iid_preg;
    reg   [4:0]  iid_rd;
    integer      match_count;
    begin
      found = 1'b0;
      match_count = 0;
      duplicate = 1'b0;
      duplicate_idx = 7'd0;
      match_bitmap = 96'b0;
      bus_valid = 1'b0;
      bus_data  = 64'b0;
      prf_snapshot = 64'b0;
      data = 64'b0;
      fallback_used = 1'b0;
      retire_iid = 7'd0;
      iid_has_rd = 1'b0;
      iid_preg = 7'd0;
      iid_rd = 5'd0;
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
            end else begin \
              duplicate = 1'b1; \
              duplicate_idx = N; \
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
      if(!found) begin
        case(slot)
          0: retire_iid = `ROB_RT.rob_retire_inst0_iid;
          1: retire_iid = `ROB_RT.rob_retire_inst1_iid;
          default: retire_iid = `ROB_RT.rob_retire_inst2_iid;
        endcase
        iid_has_rd = logger_iid_has_rd[retire_iid];
        iid_preg   = logger_iid2preg[retire_iid];
        iid_rd     = logger_iid2rd[retire_iid];
        if(iid_has_rd) begin
          preg_idx = iid_preg;
          rd       = iid_rd;
          found    = 1'b1;
          fallback_used = 1'b1;
        end
      end
      if(found) begin
        automatic bit iu1_hit = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_rf_prf_pregfile.iu_idu_ex2_pipe1_wb_preg_expand[preg_idx];
        automatic bit lsu_hit = `CPU_TOP.x_ct_top_0.x_ct_core.lsu_idu_wb_pipe3_wb_preg_expand[preg_idx];
        bus_valid    = 1'b0;
        bus_data     = 64'b0;
        prf_snapshot = 64'b0;
        if (`CPU_TOP.x_ct_top_0.x_ct_core.iu_idu_ex2_pipe0_wb_preg_vld &&
            (`CPU_TOP.x_ct_top_0.x_ct_core.iu_idu_ex2_pipe0_wb_preg == preg_idx)) begin
          bus_valid = 1'b1;
          bus_data  = `CPU_TOP.x_ct_top_0.x_ct_core.iu_idu_ex2_pipe0_wb_preg_data;
        end else if (`CPU_TOP.x_ct_top_0.x_ct_core.iu_idu_ex2_pipe1_wb_preg_vld && iu1_hit) begin
          bus_valid = 1'b1;
          bus_data  = `CPU_TOP.x_ct_top_0.x_ct_core.iu_idu_ex2_pipe1_wb_preg_data;
        end else if (`CPU_TOP.x_ct_top_0.x_ct_core.lsu_idu_wb_pipe3_wb_preg_vld && lsu_hit) begin
          bus_valid = 1'b1;
          bus_data  = `CPU_TOP.x_ct_top_0.x_ct_core.lsu_idu_wb_pipe3_wb_preg_data;
        end else if (`CPU_TOP.x_ct_top_0.x_ct_core.cp0_iu_ex3_rslt_vld &&
                 (`CPU_TOP.x_ct_top_0.x_ct_core.cp0_iu_ex3_rslt_preg == preg_idx)) begin
          bus_valid = 1'b1;
          bus_data  = `CPU_TOP.x_ct_top_0.x_ct_core.cp0_iu_ex3_rslt_data;
        end
        prf_snapshot = get_preg_data(preg_idx);
        if (bus_valid)
          data = bus_data;
        else
          data = prf_snapshot;
`ifdef C910_DBG_XWB
        if (duplicate) begin
          $display("[DBG][X-WARN] pc=0x%010h slot=%0d multiple PST entries matched (mask=0x%024h) -> using entry %0d",
                   {pc40[39:0]}, slot, match_bitmap, preg_idx);
        end
        if (!bus_valid)
          $display("[DBG][X-WARN] pc=0x%010h slot=%0d entry=%0d no upstream WB bus hit, using PRF data=0x%016h",
                   {pc40[39:0]}, slot, preg_idx, prf_snapshot);
        else if (bus_data !== prf_snapshot)
          $display("[DBG][X-WARN] pc=0x%010h slot=%0d entry=%0d upstream=0x%016h PRF=0x%016h (upstream wins)",
                   {pc40[39:0]}, slot, preg_idx, bus_data, prf_snapshot);
        if (fallback_used)
          $display("[DBG][X-INFO] pc=0x%010h slot=%0d iid=%0d recovered via IID map preg=%0d rd=x%0d",
                   {pc40[39:0]}, slot, retire_iid, preg_idx, rd);
        $display("[DBG][X] pc=0x%010h rd=x%0d entry=%0d preg=%0d prf_dout=0x%016h | iu0_vld=%0d iu0_preg=%0d iu0_data=0x%016h | iu1_vld=%0d iu1_hit=%0d iu1_data=0x%016h | lsu_vld=%0d lsu_hit=%0d lsu_data=0x%016h | cp0_vld=%0d cp0_preg=%0d cp0_data=0x%016h",
                 {pc40[39:0]}, rd, preg_idx, preg_idx, prf_snapshot,
                 `CPU_TOP.x_ct_top_0.x_ct_core.iu_idu_ex2_pipe0_wb_preg_vld,
                 `CPU_TOP.x_ct_top_0.x_ct_core.iu_idu_ex2_pipe0_wb_preg,
                 `CPU_TOP.x_ct_top_0.x_ct_core.iu_idu_ex2_pipe0_wb_preg_data,
                 `CPU_TOP.x_ct_top_0.x_ct_core.iu_idu_ex2_pipe1_wb_preg_vld, iu1_hit,
                 `CPU_TOP.x_ct_top_0.x_ct_core.iu_idu_ex2_pipe1_wb_preg_data,
                 `CPU_TOP.x_ct_top_0.x_ct_core.lsu_idu_wb_pipe3_wb_preg_vld, lsu_hit,
                 `CPU_TOP.x_ct_top_0.x_ct_core.lsu_idu_wb_pipe3_wb_preg_data,
                 `CPU_TOP.x_ct_top_0.x_ct_core.cp0_iu_ex3_rslt_vld,
                 `CPU_TOP.x_ct_top_0.x_ct_core.cp0_iu_ex3_rslt_preg,
                 `CPU_TOP.x_ct_top_0.x_ct_core.cp0_iu_ex3_rslt_data);
`endif
        $display("[C910][X-WB] pc=0x%010h rd=x%0d preg=%0d data=0x%016h", {pc40[39:0]}, rd, preg_idx, data);
      end else begin
`ifdef C910_DBG_XWB
        $display("[DBG][X-ERR] pc=0x%010h slot=%0d iid=%0d no DST match in PST or IID map", {pc40[39:0]}, slot, retire_iid);
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
    reg          duplicate;
    reg  [63:0]  match_bitmap;
    integer      match_count;
    reg          fallback_used;
    reg   [6:0]  retire_iid;
    reg          iid_has_vrd;
    reg   [5:0]  iid_vreg;
    reg   [4:0]  iid_frd;
    begin
      found = 1'b0;
      duplicate = 1'b0;
      match_bitmap = 64'b0;
      match_count = 0;
      data = 64'b0;
      fallback_used = 1'b0;
      retire_iid = 7'd0;
      iid_has_vrd = 1'b0;
      iid_vreg = 6'd0;
      iid_frd = 5'd0;
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
              data     = `VREGFILE_FR.vreg``N``_reg_dout; \
              found    = 1'b1; \
            end else begin \
              duplicate = 1'b1; \
            end \
          end \
        end
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
      if(!found) begin
        case(slot)
          0: retire_iid = `ROB_RT.rob_retire_inst0_iid;
          1: retire_iid = `ROB_RT.rob_retire_inst1_iid;
          default: retire_iid = `ROB_RT.rob_retire_inst2_iid;
        endcase
        iid_has_vrd = logger_iid_has_vrd[retire_iid];
        iid_vreg    = logger_iid2vreg[retire_iid];
        iid_frd     = logger_iid2frd[retire_iid];
        if(iid_has_vrd) begin
          vreg_idx      = iid_vreg;
          frd           = iid_frd;
          data          = get_vreg_fr_data(iid_vreg);
          found         = 1'b1;
          fallback_used = 1'b1;
        end
      end
      if(found) begin
`ifdef C910_DBG_XWB
        if (duplicate)
          $display("[DBG][F-WARN] pc=0x%010h slot=%0d multiple PST entries matched (mask=0x%016h) -> using entry %0d",
                   {pc40[39:0]}, slot, match_bitmap, vreg_idx);
        if (fallback_used)
          $display("[DBG][F-INFO] pc=0x%010h slot=%0d iid=%0d recovered via IID map vreg=%0d frd=f%0d",
                   {pc40[39:0]}, slot, retire_iid, vreg_idx, frd);
        $display("[DBG][F] pc=0x%010h rd=f%0d entry=%0d vreg=%0d vreg_dout=0x%016h",
                 {pc40[39:0]}, frd, vreg_idx, vreg_idx, data);
`endif
        $display("[C910][F-WB] pc=0x%010h rd=f%0d vreg=%0d data=0x%016h", {pc40[39:0]}, frd, vreg_idx, data);
      end else begin
`ifdef C910_DBG_XWB
        $display("[DBG][F-ERR] pc=0x%010h slot=%0d iid=%0d no VREG match in PST or IID map", {pc40[39:0]}, slot, retire_iid);
`endif
      end
    end
  endtask

  always @(posedge clk) begin
    if(`tb_retire0) begin
      if(`RETIRE_MOD.retire_pst_wb_retire_inst0_preg_vld)
        log_slot_xwb(0, `retire0_pc);
      if(`RETIRE_MOD.retire_pst_wb_retire_inst0_vreg_vld)
        log_slot_fwb(0, `retire0_pc);
    end
    if(`tb_retire1) begin
      if(`RETIRE_MOD.retire_pst_wb_retire_inst1_preg_vld)
        log_slot_xwb(1, `retire1_pc);
      if(`RETIRE_MOD.retire_pst_wb_retire_inst1_vreg_vld)
        log_slot_fwb(1, `retire1_pc);
    end
    if(`tb_retire2) begin
      if(`RETIRE_MOD.retire_pst_wb_retire_inst2_preg_vld)
        log_slot_xwb(2, `retire2_pc);
      if(`RETIRE_MOD.retire_pst_wb_retire_inst2_vreg_vld)
        log_slot_fwb(2, `retire2_pc);
    end
  end

  `undef ROB_RT
  `undef ROB_MOD
  `undef RETIRE_MOD
  `undef PST_VREG
  `undef PST_PREG
  `undef RTU_TOP
  `undef VREGFILE_FR
  `undef PREGFILE
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
