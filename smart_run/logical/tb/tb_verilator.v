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
`define tb_core1_retire0    top.x_soc.x_cpu_sub_system_axi.core1_pad_retire0
`define core1_retire0_pc    top.x_soc.x_cpu_sub_system_axi.core1_pad_retire0_pc[39:0]
`define tb_core1_retire1    top.x_soc.x_cpu_sub_system_axi.core1_pad_retire1
`define core1_retire1_pc    top.x_soc.x_cpu_sub_system_axi.core1_pad_retire1_pc[39:0]
`define tb_core1_retire2    top.x_soc.x_cpu_sub_system_axi.core1_pad_retire2
`define core1_retire2_pc    top.x_soc.x_cpu_sub_system_axi.core1_pad_retire2_pc[39:0]
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
  
  wire uart0_sin;
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
  
    $display("\t********* Read program *********");
    $readmemh("inst.pat", mem_inst_temp);
    $readmemh("data.pat", mem_data_temp);
  
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
  reg [127:0] cpu_wdata;
  reg [63:0] value0;
  reg [63:0] value1;
  reg [63:0] value2;
  reg        cx_success_seen;
  reg        cx_fail_seen;
  reg [7:0]  cx_finish_countdown;

  initial
  begin
    cx_success_seen = 1'b0;
    cx_fail_seen = 1'b0;
    cx_finish_countdown = 8'b0;
  end

`ifdef CX_TRACE
  integer cx_trace_file;
  reg [4095:0] cx_trace_path;

  initial
  begin
    if(!$value$plusargs("cx_trace=%s", cx_trace_path)) begin
      cx_trace_path = "openc910_trace_hart_00000000.log";
    end
    cx_trace_file = $fopen(cx_trace_path, "w");
  end

  always @(posedge clk)
  begin
    if(cx_trace_file != 0) begin
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_preg_vld) begin
        $fwrite(cx_trace_file, "dispatch cycle=%0d hart=0 iid=%0d rd=x%0d preg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_preg_iid[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_dst_reg[4:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_preg[6:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_preg_vld) begin
        $fwrite(cx_trace_file, "dispatch cycle=%0d hart=0 iid=%0d rd=x%0d preg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_preg_iid[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_dst_reg[4:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_preg[6:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_preg_vld) begin
        $fwrite(cx_trace_file, "dispatch cycle=%0d hart=0 iid=%0d rd=x%0d preg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_preg_iid[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_dst_reg[4:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_preg[6:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_preg_vld) begin
        $fwrite(cx_trace_file, "dispatch cycle=%0d hart=0 iid=%0d rd=x%0d preg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_preg_iid[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_dst_reg[4:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_preg[6:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_freg_vld) begin
        $fwrite(cx_trace_file, "fdispatch cycle=%0d hart=0 iid=%0d rd=f%0d fpreg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_vreg_iid[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_dstv_reg[4:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_vreg[5:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_freg_vld) begin
        $fwrite(cx_trace_file, "fdispatch cycle=%0d hart=0 iid=%0d rd=f%0d fpreg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_vreg_iid[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_dstv_reg[4:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_vreg[5:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_freg_vld) begin
        $fwrite(cx_trace_file, "fdispatch cycle=%0d hart=0 iid=%0d rd=f%0d fpreg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_vreg_iid[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_dstv_reg[4:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_vreg[5:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_freg_vld) begin
        $fwrite(cx_trace_file, "fdispatch cycle=%0d hart=0 iid=%0d rd=f%0d fpreg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_vreg_iid[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_dstv_reg[4:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_vreg[5:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg_vld) begin
        $fwrite(cx_trace_file, "pregwrite cycle=%0d hart=0 preg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg_data[63:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg_vld) begin
        $fwrite(cx_trace_file, "pregwrite cycle=%0d hart=0 preg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg_data[63:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg_vld) begin
        $fwrite(cx_trace_file, "pregwrite cycle=%0d hart=0 preg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg_data[63:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_vreg_fr_vld) begin
        $fwrite(cx_trace_file, "fpregwrite cycle=%0d hart=0 fpreg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_fwd_vreg[5:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_vreg_fr_data[63:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.vfpu_idu_ex5_pipe6_wb_vreg_fr_vld) begin
        $fwrite(cx_trace_file, "fpregwrite cycle=%0d hart=0 fpreg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.rbus_pipe6_wb_vreg[5:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.vfpu_idu_ex5_pipe6_wb_vreg_fr_data[63:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.vfpu_idu_ex5_pipe7_wb_vreg_fr_vld) begin
        $fwrite(cx_trace_file, "fpregwrite cycle=%0d hart=0 fpreg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.rbus_pipe7_wb_vreg[5:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.vfpu_idu_ex5_pipe7_wb_vreg_fr_data[63:0]);
      end
      if(`tb_retire0) begin
        $fwrite(cx_trace_file, "commit cycle=%0d hart=0 pc=0x%010x iid=%0d",
                cycle_count[31:0], `retire0_pc,
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit0_iid[6:0]);
        if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_cp0_expt_vld) begin
          $fwrite(cx_trace_file, " exc_cause=%0d", `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_expt_vec[4:0]);
        end
        $fwrite(cx_trace_file, "\n");
      end
      if(`tb_retire1) begin
        $fwrite(cx_trace_file, "commit cycle=%0d hart=0 pc=0x%010x iid=%0d\n",
                cycle_count[31:0], `retire1_pc,
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit1_iid[6:0]);
      end
      if(`tb_retire2) begin
        $fwrite(cx_trace_file, "commit cycle=%0d hart=0 pc=0x%010x iid=%0d\n",
                cycle_count[31:0], `retire2_pc,
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit2_iid[6:0]);
      end
      if(`tb_retire0 || `tb_retire1 || `tb_retire2) begin
        $fflush(cx_trace_file);
      end
      // === hart 1 tracing inside the same always block to keep $fwrite output
      // === serialized; Verilator does not guarantee ordering across separate
      // === always blocks writing to the same file descriptor.
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_preg_vld) begin
        $fwrite(cx_trace_file, "dispatch cycle=%0d hart=1 iid=%0d rd=x%0d preg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_preg_iid[6:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_dst_reg[4:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_preg[6:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_preg_vld) begin
        $fwrite(cx_trace_file, "dispatch cycle=%0d hart=1 iid=%0d rd=x%0d preg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_preg_iid[6:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_dst_reg[4:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_preg[6:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_preg_vld) begin
        $fwrite(cx_trace_file, "dispatch cycle=%0d hart=1 iid=%0d rd=x%0d preg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_preg_iid[6:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_dst_reg[4:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_preg[6:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_preg_vld) begin
        $fwrite(cx_trace_file, "dispatch cycle=%0d hart=1 iid=%0d rd=x%0d preg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_preg_iid[6:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_dst_reg[4:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_preg[6:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_freg_vld) begin
        $fwrite(cx_trace_file, "fdispatch cycle=%0d hart=1 iid=%0d rd=f%0d fpreg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_vreg_iid[6:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_dstv_reg[4:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_vreg[5:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_freg_vld) begin
        $fwrite(cx_trace_file, "fdispatch cycle=%0d hart=1 iid=%0d rd=f%0d fpreg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_vreg_iid[6:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_dstv_reg[4:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_vreg[5:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_freg_vld) begin
        $fwrite(cx_trace_file, "fdispatch cycle=%0d hart=1 iid=%0d rd=f%0d fpreg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_vreg_iid[6:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_dstv_reg[4:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_vreg[5:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_freg_vld) begin
        $fwrite(cx_trace_file, "fdispatch cycle=%0d hart=1 iid=%0d rd=f%0d fpreg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_vreg_iid[6:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_dstv_reg[4:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_vreg[5:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg_vld) begin
        $fwrite(cx_trace_file, "pregwrite cycle=%0d hart=1 preg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg[6:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg_data[63:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg_vld) begin
        $fwrite(cx_trace_file, "pregwrite cycle=%0d hart=1 preg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg[6:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg_data[63:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg_vld) begin
        $fwrite(cx_trace_file, "pregwrite cycle=%0d hart=1 preg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg[6:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg_data[63:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_vreg_fr_vld) begin
        $fwrite(cx_trace_file, "fpregwrite cycle=%0d hart=1 fpreg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_fwd_vreg[5:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_vreg_fr_data[63:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.vfpu_idu_ex5_pipe6_wb_vreg_fr_vld) begin
        $fwrite(cx_trace_file, "fpregwrite cycle=%0d hart=1 fpreg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.rbus_pipe6_wb_vreg[5:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.vfpu_idu_ex5_pipe6_wb_vreg_fr_data[63:0]);
      end
      if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.vfpu_idu_ex5_pipe7_wb_vreg_fr_vld) begin
        $fwrite(cx_trace_file, "fpregwrite cycle=%0d hart=1 fpreg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.rbus_pipe7_wb_vreg[5:0],
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.vfpu_idu_ex5_pipe7_wb_vreg_fr_data[63:0]);
      end
      if(`tb_core1_retire0) begin
        $fwrite(cx_trace_file, "commit cycle=%0d hart=1 pc=0x%010x iid=%0d",
                cycle_count[31:0], `core1_retire0_pc,
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit0_iid[6:0]);
        if(`CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.rtu_cp0_expt_vld) begin
          $fwrite(cx_trace_file, " exc_cause=%0d", `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.rtu_yy_xx_expt_vec[4:0]);
        end
        $fwrite(cx_trace_file, "\n");
      end
      if(`tb_core1_retire1) begin
        $fwrite(cx_trace_file, "commit cycle=%0d hart=1 pc=0x%010x iid=%0d\n",
                cycle_count[31:0], `core1_retire1_pc,
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit1_iid[6:0]);
      end
      if(`tb_core1_retire2) begin
        $fwrite(cx_trace_file, "commit cycle=%0d hart=1 pc=0x%010x iid=%0d\n",
                cycle_count[31:0], `core1_retire2_pc,
                `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit2_iid[6:0]);
      end
      if(`tb_core1_retire0 || `tb_core1_retire1 || `tb_core1_retire2 ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_preg_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_preg_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_preg_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_preg_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_freg_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_freg_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_freg_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_freg_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_vreg_fr_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.vfpu_idu_ex5_pipe6_wb_vreg_fr_vld ||
         `CPU_TOP.x_ct_top_1.x_ct_core.x_ct_vfpu_top.x_ct_vfpu_rbus.vfpu_idu_ex5_pipe7_wb_vreg_fr_vld) begin
        $fflush(cx_trace_file);
      end
    end
  end
`endif


  always @(posedge clk)
  begin
    cpu_awlen[3:0]   <= `SOC_TOP.x_axi_slave128.awlen[3:0];
    cpu_awaddr[31:0] <= `SOC_TOP.x_axi_slave128.mem_addr[31:0];
    cpu_wvalid       <= `SOC_TOP.biu_pad_wvalid;
    cpu_wstrb        <= `SOC_TOP.biu_pad_wstrb;
    cpu_wdata        <= `SOC_TOP.biu_pad_wdata;
    // value0           <= `CPU_TOP.core0_pad_wb0_data[63:0];
    // value1           <= `CPU_TOP.core0_pad_wb1_data[63:0];
    // value2           <= `CPU_TOP.core0_pad_wb2_data[63:0];
    value0              <= `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.rbus_pipe0_wb_data[63:0];
    value1              <= `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.rbus_pipe1_wb_data[63:0];
    value2              <= `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.ld_wb_preg_data_sign_extend[63:0];
  end
  
  always @(posedge clk)
  begin
      if(!cx_success_seen && !cx_fail_seen && (cpu_awlen[3:0] == 4'b0) && (cpu_awaddr[31:0] == 32'h0004_0000) && cpu_wvalid && `clk_en)
    begin
      cx_success_seen <= 1'b1;
      cx_finish_countdown <= 8'd32;
    end
      else if(cx_finish_countdown != 8'b0)
    begin
      cx_finish_countdown <= cx_finish_countdown - 1'b1;
      if(cx_finish_countdown == 8'd1)
      begin
        if(cx_success_seen)
        begin
          $display("**********************************************");
          $display("*    simulation finished successfully        *");
          $display("**********************************************");
          FILE = $fopen("run_case.report","w");
          $fwrite(FILE,"TEST PASS");
        end
        else
        begin
          $display("**********************************************");
          $display("*    simulation finished with error          *");
          $display("**********************************************");
          FILE = $fopen("run_case.report","w");
          $fwrite(FILE,"TEST FAIL");
        end
        $finish;
      end
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
  
endmodule
