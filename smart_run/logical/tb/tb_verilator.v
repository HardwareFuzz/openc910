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
  
  wire uart0_sin;
  wire [7:0]b_pad_gpio_porta;
  wire [15:0] cx_lsu_dbg_st_bytes_vld;
  wire [39:0] cx_lsu_dbg_st_addr;
  wire [63:0] cx_lsu_dbg_st_data;
  wire [6:0]  cx_lsu_dbg_st_iid;
  wire        cx_lsu_dbg_st_atomic;
  wire        cx_lsu_dbg_st_is_sc;
  wire        cx_lsu_dbg_st_req;
  wire        cx_wmb_ce_create_vld;
  wire        cx_wmb_ce_create_merge;
  wire [7:0]  cx_wmb_ce_create_merge_ptr;
  wire [7:0]  cx_wmb_entry_create_vld;
  wire [6:0]  cx_wmb_ce_iid;
  wire [39:0] cx_wmb_ce_addr;
  wire [15:0] cx_wmb_ce_bytes_vld;
  wire [127:0] cx_wmb_ce_data128;
  wire        cx_wmb_st_wb_cmplt_req;
  wire [7:0]  cx_wmb_st_wb_cmplt_ptr;
  wire [6:0]  cx_wmb_st_wb_iid;
  wire        cx_wmb_write_dcache_success;
  wire [7:0]  cx_wmb_write_dcache_ptr;
  wire [6:0]  cx_wmb_write_dcache_iid;
  wire [39:0] cx_wmb_write_dcache_addr;
  wire [15:0] cx_wmb_write_dcache_bytes_vld;
  wire [127:0] cx_wmb_write_dcache_data;
  wire [7:0]  cx_wmb_write_ptr;
  wire [6:0]  cx_wmb_write_iid;
  wire [7:0]  cx_wmb_data_ptr;
  wire [6:0]  cx_wmb_data_iid;
  wire        cx_wmb_biu_aw_req;
  wire        cx_wmb_biu_aw_grnt;
  wire [39:0] cx_wmb_biu_aw_addr;
  wire [1:0]  cx_wmb_biu_aw_len;
  wire [2:0]  cx_wmb_biu_aw_size;
  wire        cx_wmb_biu_w_req;
  wire        cx_wmb_biu_w_grnt;
  wire [127:0] cx_wmb_biu_w_data;
  wire [15:0] cx_wmb_biu_w_strb;
  wire        cx_wmb_biu_w_last;
  wire [39:0] cx_wmb_complete_addr;
  wire [15:0] cx_wmb_complete_bytes_vld;
  wire [127:0] cx_wmb_complete_data128;
  wire        cx_wmb_ld_wb_data_req;
  wire [6:0]  cx_wmb_ld_wb_data_iid;
  wire [63:0] cx_wmb_ld_wb_data;
  wire [7:0]  cx_wmb_entry_sc_wb_success;
  wire        cx_wmb_complete_atomic;
  wire        cx_wmb_complete_sc_wb_success;
  wire [1:0]  cx_wmb_complete_inst_type;
  reg         cx_pending_commit_valid [0:255];
  reg [6:0]   cx_pending_commit_iid [0:255];
  reg [39:0]  cx_pending_commit_pc [0:255];
  reg [31:0]  cx_pending_commit_cycle [0:255];
  reg         cx_pending_store_valid [0:255];
  reg [6:0]   cx_pending_store_iid [0:255];
  reg [15:0]  cx_pending_store_bytes_vld [0:255];
  reg [39:0]  cx_pending_store_addr [0:255];
  reg [63:0]  cx_pending_store_data [0:255];
  reg [31:0]  cx_pending_store_cycle [0:255];
  reg         cx_suppressed_store_valid [0:255];
  reg [6:0]   cx_suppressed_store_iid [0:255];
  reg         cx_pending_wmb_store_valid [0:255];
  reg [6:0]   cx_pending_wmb_store_iid [0:255];
  reg         cx_pending_wmb_store_is_sc [0:255];
  reg [15:0]  cx_pending_wmb_store_bytes_vld [0:255];
  reg [39:0]  cx_pending_wmb_store_addr [0:255];
  reg [63:0]  cx_pending_wmb_store_data [0:255];
  reg [31:0]  cx_pending_wmb_store_cycle [0:255];
  reg         cx_iid_rd_valid [0:255];
  reg [6:0]   cx_iid_preg [0:255];
  reg         cx_iid_rd_wdata_valid [0:255];
  reg [63:0]  cx_iid_rd_wdata [0:255];
  integer     cx_pending_idx;

  assign pad_yy_gate_clk_en_b = 1'b1;
  assign cx_lsu_dbg_st_bytes_vld = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_sq.sq_dbg_st_bytes_vld_ff[15:0];
  assign cx_lsu_dbg_st_addr      = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_sq.sq_dbg_st_addr_ff[39:0];
  assign cx_lsu_dbg_st_atomic    = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_sq.sq_dbg_st_atomic_ff;
  assign cx_lsu_dbg_st_is_sc     = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_sq.sq_dbg_st_is_sc_ff;
  assign cx_lsu_dbg_st_data      = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_sq.sq_dbg_st_data_ff[63:0];
  assign cx_lsu_dbg_st_iid       = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_sq.sq_dbg_st_iid_ff[6:0];
  assign cx_lsu_dbg_st_req       = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_sq.sq_dbg_st_req_ff;
  assign cx_wmb_ce_create_vld      = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_ce_create_vld;
  assign cx_wmb_ce_create_merge    = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_ce_create_merge;
  assign cx_wmb_ce_create_merge_ptr = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_ce_create_merge_ptr[7:0];
  assign cx_wmb_entry_create_vld   = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_create_vld[7:0];
  assign cx_wmb_ce_iid             = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_ce_iid[6:0];
  assign cx_wmb_ce_addr            = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_ce_addr[39:0];
  assign cx_wmb_ce_bytes_vld       = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_ce_bytes_vld[15:0];
  assign cx_wmb_ce_data128         = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_ce_data128[127:0];
  assign cx_wmb_st_wb_cmplt_req    = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_st_wb_cmplt_req;
  assign cx_wmb_st_wb_cmplt_ptr    = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_st_wb_cmplt_ptr[7:0];
  assign cx_wmb_st_wb_iid          = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_st_wb_iid[6:0];
  assign cx_wmb_write_dcache_success = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_write_dcache_success_ori;
  assign cx_wmb_write_dcache_ptr     = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_write_dcache_ptr[7:0];
  assign cx_wmb_write_dcache_iid     = {7{cx_wmb_write_dcache_ptr[0]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_0[6:0]
                                     | {7{cx_wmb_write_dcache_ptr[1]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_1[6:0]
                                     | {7{cx_wmb_write_dcache_ptr[2]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_2[6:0]
                                     | {7{cx_wmb_write_dcache_ptr[3]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_3[6:0]
                                     | {7{cx_wmb_write_dcache_ptr[4]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_4[6:0]
                                     | {7{cx_wmb_write_dcache_ptr[5]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_5[6:0]
                                     | {7{cx_wmb_write_dcache_ptr[6]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_6[6:0]
                                     | {7{cx_wmb_write_dcache_ptr[7]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_7[6:0];
  assign cx_wmb_write_dcache_addr    = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_write_dcache_addr[39:0];
  assign cx_wmb_write_dcache_bytes_vld = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_write_dcache_bytes_vld[15:0];
  assign cx_wmb_write_dcache_data    = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_write_dcache_data[127:0];
  assign cx_wmb_write_ptr            = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_write_ptr[7:0];
  assign cx_wmb_write_iid            = {7{cx_wmb_write_ptr[0]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_0[6:0]
                                     | {7{cx_wmb_write_ptr[1]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_1[6:0]
                                     | {7{cx_wmb_write_ptr[2]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_2[6:0]
                                     | {7{cx_wmb_write_ptr[3]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_3[6:0]
                                     | {7{cx_wmb_write_ptr[4]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_4[6:0]
                                     | {7{cx_wmb_write_ptr[5]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_5[6:0]
                                     | {7{cx_wmb_write_ptr[6]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_6[6:0]
                                     | {7{cx_wmb_write_ptr[7]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_7[6:0];
  assign cx_wmb_data_ptr             = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_data_ptr[7:0];
  assign cx_wmb_data_iid             = {7{cx_wmb_data_ptr[0]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_0[6:0]
                                     | {7{cx_wmb_data_ptr[1]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_1[6:0]
                                     | {7{cx_wmb_data_ptr[2]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_2[6:0]
                                     | {7{cx_wmb_data_ptr[3]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_3[6:0]
                                     | {7{cx_wmb_data_ptr[4]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_4[6:0]
                                     | {7{cx_wmb_data_ptr[5]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_5[6:0]
                                     | {7{cx_wmb_data_ptr[6]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_6[6:0]
                                     | {7{cx_wmb_data_ptr[7]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_iid_7[6:0];
  assign cx_wmb_biu_aw_req           = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_biu_aw_req;
  assign cx_wmb_biu_aw_grnt          = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.bus_arb_wmb_aw_grnt;
  assign cx_wmb_biu_aw_addr          = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_biu_aw_addr[39:0];
  assign cx_wmb_biu_aw_len           = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_biu_aw_len[1:0];
  assign cx_wmb_biu_aw_size          = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_biu_aw_size[2:0];
  assign cx_wmb_biu_w_req            = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_biu_w_req;
  assign cx_wmb_biu_w_grnt           = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.bus_arb_wmb_w_grnt;
  assign cx_wmb_biu_w_data           = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_biu_w_data[127:0];
  assign cx_wmb_biu_w_strb           = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_biu_w_strb[15:0];
  assign cx_wmb_biu_w_last           = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_biu_w_last;
  assign cx_wmb_complete_addr      = {40{cx_wmb_st_wb_cmplt_ptr[0]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_addr_0[39:0]
                                   | {40{cx_wmb_st_wb_cmplt_ptr[1]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_addr_1[39:0]
                                   | {40{cx_wmb_st_wb_cmplt_ptr[2]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_addr_2[39:0]
                                   | {40{cx_wmb_st_wb_cmplt_ptr[3]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_addr_3[39:0]
                                   | {40{cx_wmb_st_wb_cmplt_ptr[4]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_addr_4[39:0]
                                   | {40{cx_wmb_st_wb_cmplt_ptr[5]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_addr_5[39:0]
                                   | {40{cx_wmb_st_wb_cmplt_ptr[6]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_addr_6[39:0]
                                   | {40{cx_wmb_st_wb_cmplt_ptr[7]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_addr_7[39:0];
  assign cx_wmb_complete_bytes_vld = {16{cx_wmb_st_wb_cmplt_ptr[0]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_bytes_vld_0[15:0]
                                   | {16{cx_wmb_st_wb_cmplt_ptr[1]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_bytes_vld_1[15:0]
                                   | {16{cx_wmb_st_wb_cmplt_ptr[2]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_bytes_vld_2[15:0]
                                   | {16{cx_wmb_st_wb_cmplt_ptr[3]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_bytes_vld_3[15:0]
                                   | {16{cx_wmb_st_wb_cmplt_ptr[4]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_bytes_vld_4[15:0]
                                   | {16{cx_wmb_st_wb_cmplt_ptr[5]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_bytes_vld_5[15:0]
                                   | {16{cx_wmb_st_wb_cmplt_ptr[6]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_bytes_vld_6[15:0]
                                   | {16{cx_wmb_st_wb_cmplt_ptr[7]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_bytes_vld_7[15:0];
  assign cx_wmb_complete_data128   = {128{cx_wmb_st_wb_cmplt_ptr[0]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_data_0[127:0]
                                   | {128{cx_wmb_st_wb_cmplt_ptr[1]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_data_1[127:0]
                                   | {128{cx_wmb_st_wb_cmplt_ptr[2]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_data_2[127:0]
                                   | {128{cx_wmb_st_wb_cmplt_ptr[3]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_data_3[127:0]
                                   | {128{cx_wmb_st_wb_cmplt_ptr[4]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_data_4[127:0]
                                   | {128{cx_wmb_st_wb_cmplt_ptr[5]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_data_5[127:0]
                                   | {128{cx_wmb_st_wb_cmplt_ptr[6]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_data_6[127:0]
                                   | {128{cx_wmb_st_wb_cmplt_ptr[7]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_data_7[127:0];
  assign cx_wmb_ld_wb_data_req      = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_ld_wb_data_req;
  assign cx_wmb_ld_wb_data_iid      = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_ld_wb_data_iid[6:0];
  assign cx_wmb_ld_wb_data          = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_ld_wb_data[63:0];
  assign cx_wmb_entry_sc_wb_success = `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_sc_wb_success[7:0];
  assign cx_wmb_complete_atomic     = cx_pick_entry_flag(
                                        cx_wmb_st_wb_cmplt_ptr,
                                        `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_atomic[7:0]
                                      );
  assign cx_wmb_complete_sc_wb_success = cx_pick_entry_flag(
                                           cx_wmb_st_wb_cmplt_ptr,
                                           cx_wmb_entry_sc_wb_success
                                         );
  assign cx_wmb_complete_inst_type  = {2{cx_wmb_st_wb_cmplt_ptr[0]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_inst_type_0[1:0]
                                    | {2{cx_wmb_st_wb_cmplt_ptr[1]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_inst_type_1[1:0]
                                    | {2{cx_wmb_st_wb_cmplt_ptr[2]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_inst_type_2[1:0]
                                    | {2{cx_wmb_st_wb_cmplt_ptr[3]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_inst_type_3[1:0]
                                    | {2{cx_wmb_st_wb_cmplt_ptr[4]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_inst_type_4[1:0]
                                    | {2{cx_wmb_st_wb_cmplt_ptr[5]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_inst_type_5[1:0]
                                    | {2{cx_wmb_st_wb_cmplt_ptr[6]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_inst_type_6[1:0]
                                    | {2{cx_wmb_st_wb_cmplt_ptr[7]}} & `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_wmb.wmb_entry_inst_type_7[1:0];

  initial begin
    for(cx_pending_idx = 0; cx_pending_idx < 256; cx_pending_idx = cx_pending_idx + 1) begin
      cx_pending_commit_valid[cx_pending_idx] = 1'b0;
      cx_pending_commit_iid[cx_pending_idx] = 7'b0;
      cx_pending_commit_pc[cx_pending_idx] = 40'b0;
      cx_pending_commit_cycle[cx_pending_idx] = 32'b0;
      cx_pending_store_valid[cx_pending_idx] = 1'b0;
      cx_pending_store_iid[cx_pending_idx] = 7'b0;
      cx_pending_store_bytes_vld[cx_pending_idx] = 16'b0;
      cx_pending_store_addr[cx_pending_idx] = 40'b0;
      cx_pending_store_data[cx_pending_idx] = 64'b0;
      cx_pending_store_cycle[cx_pending_idx] = 32'b0;
      cx_suppressed_store_valid[cx_pending_idx] = 1'b0;
      cx_suppressed_store_iid[cx_pending_idx] = 7'b0;
      cx_pending_wmb_store_valid[cx_pending_idx] = 1'b0;
      cx_pending_wmb_store_iid[cx_pending_idx] = 7'b0;
      cx_pending_wmb_store_is_sc[cx_pending_idx] = 1'b0;
      cx_pending_wmb_store_bytes_vld[cx_pending_idx] = 16'b0;
      cx_pending_wmb_store_addr[cx_pending_idx] = 40'b0;
      cx_pending_wmb_store_data[cx_pending_idx] = 64'b0;
      cx_pending_wmb_store_cycle[cx_pending_idx] = 32'b0;
      cx_iid_rd_valid[cx_pending_idx] = 1'b0;
      cx_iid_preg[cx_pending_idx] = 7'b0;
      cx_iid_rd_wdata_valid[cx_pending_idx] = 1'b0;
      cx_iid_rd_wdata[cx_pending_idx] = 64'b0;
    end
  end
  
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

  function [63:0] cx_mask_from_bytes_vld;
    input [15:0] bytes_vld;
    integer idx;
    reg [63:0] mask;
    begin
      mask = 64'b0;
      // The trace data is 64-bit wide, so byte-valid bits are paired down to
      // 8 lanes to match the plugin's memory-width model.
      for(idx = 0; idx < 8; idx = idx + 1) begin
        if(bytes_vld[idx] || bytes_vld[idx + 8]) begin
          mask[idx] = 1'b1;
        end
      end
      cx_mask_from_bytes_vld = mask;
    end
  endfunction

  function [39:0] cx_store_base_addr;
    input [39:0] addr;
    begin
      cx_store_base_addr = {addr[39:3], 3'b000};
    end
  endfunction

  function cx_pick_entry_flag;
    input [7:0] entry_ptr;
    input [7:0] flags;
    integer idx;
    begin
      cx_pick_entry_flag = 1'b0;
      for(idx = 0; idx < 8; idx = idx + 1) begin
        if(entry_ptr[idx]) begin
          cx_pick_entry_flag = flags[idx];
        end
      end
    end
  endfunction

  task automatic cx_emit_store_line;
    input [31:0] event_cycle;
    input [31:0] commit_cycle;
    input [39:0] commit_pc;
    input [6:0]  iid;
    input [39:0] addr;
    input [15:0] bytes_vld;
    input [63:0] data;
    begin
      $fwrite(cx_trace_file,
              "store cycle=%0d commit_cycle=%0d hart=0 pc=0x%010x iid=%0d mem_addr=0x%010x mem_mask=0x%016x mem_data=0x%016x\n",
              event_cycle,
              commit_cycle,
              commit_pc,
              iid,
              cx_store_base_addr(addr),
              cx_mask_from_bytes_vld(bytes_vld),
              data);
      $fflush(cx_trace_file);
    end
  endtask

  task automatic cx_emit_store_raw_line;
    input [31:0] event_cycle;
    input [6:0]  iid;
    input [39:0] addr;
    input [15:0] bytes_vld;
    input [63:0] data;
    begin
      $fwrite(cx_trace_file,
              "store_raw cycle=%0d hart=0 iid=%0d raw_addr=0x%010x raw_bytes_vld=0x%04x raw_data=0x%016x\n",
              event_cycle,
              iid,
              addr,
              bytes_vld,
              data);
      $fflush(cx_trace_file);
    end
  endtask

  task automatic cx_emit_store_link_line;
    input [31:0] event_cycle;
    input [6:0]  iid;
    input [7:0]  entry_ptr;
    input        merge_event;
    input [39:0] addr;
    input [15:0] bytes_vld;
    input [127:0] data128;
    begin
      if(entry_ptr != 8'b0) begin
        if(merge_event) begin
          $fwrite(cx_trace_file,
                  "storelink cycle=%0d hart=0 kind=merge iid=%0d entry=0x%02x addr=0x%010x bytes_vld=0x%04x data=0x%032x\n",
                  event_cycle,
                  iid,
                  entry_ptr,
                  addr,
                  bytes_vld,
                  data128);
        end else begin
          $fwrite(cx_trace_file,
                  "storelink cycle=%0d hart=0 kind=create iid=%0d entry=0x%02x addr=0x%010x bytes_vld=0x%04x data=0x%032x\n",
                  event_cycle,
                  iid,
                  entry_ptr,
                  addr,
                  bytes_vld,
                  data128);
        end
        $fflush(cx_trace_file);
      end
    end
  endtask

  task automatic cx_emit_store_complete_line;
    input [31:0] event_cycle;
    input [6:0]  iid;
    input [7:0]  entry_ptr;
    input [39:0] addr;
    input [15:0] bytes_vld;
    input [127:0] data128;
    begin
      if(entry_ptr != 8'b0) begin
        $fwrite(cx_trace_file,
                "storecomplete cycle=%0d hart=0 entry=0x%02x iid=%0d addr=0x%010x bytes_vld=0x%04x data=0x%032x\n",
                event_cycle,
                entry_ptr,
                iid,
                addr,
                bytes_vld,
                data128);
        $fflush(cx_trace_file);
      end
    end
  endtask

  task automatic cx_emit_store_final_dcache_line;
    input [31:0] event_cycle;
    input [6:0]  iid;
    input [7:0]  entry_ptr;
    input [39:0] addr;
    input [15:0] bytes_vld;
    input [127:0] data128;
    begin
      if(entry_ptr != 8'b0) begin
        $fwrite(cx_trace_file,
                "storefinal cycle=%0d hart=0 kind=dcache iid=%0d entry=0x%02x addr=0x%010x bytes_vld=0x%04x data=0x%032x\n",
                event_cycle,
                iid,
                entry_ptr,
                addr,
                bytes_vld,
                data128);
        $fflush(cx_trace_file);
      end
    end
  endtask

  task automatic cx_emit_store_final_biu_aw_line;
    input [31:0] event_cycle;
    input [6:0]  iid;
    input [7:0]  entry_ptr;
    input [39:0] addr;
    input [1:0]  burst_len;
    input [2:0]  burst_size;
    begin
      if(entry_ptr != 8'b0) begin
        $fwrite(cx_trace_file,
                "storefinal cycle=%0d hart=0 kind=biu_aw iid=%0d entry=0x%02x addr=0x%010x len=0x%01x size=0x%01x\n",
                event_cycle,
                iid,
                entry_ptr,
                addr,
                burst_len,
                burst_size);
        $fflush(cx_trace_file);
      end
    end
  endtask

  task automatic cx_emit_store_final_biu_w_line;
    input [31:0] event_cycle;
    input [6:0]  iid;
    input [7:0]  entry_ptr;
    input [15:0] bytes_vld;
    input [127:0] data128;
    input        last_beat;
    begin
      if(entry_ptr != 8'b0) begin
        $fwrite(cx_trace_file,
                "storefinal cycle=%0d hart=0 kind=biu_w iid=%0d entry=0x%02x bytes_vld=0x%04x data=0x%032x last=%0d\n",
                event_cycle,
                iid,
                entry_ptr,
                bytes_vld,
                data128,
                last_beat);
        $fflush(cx_trace_file);
      end
    end
  endtask

  task automatic cx_try_match_commit_slot;
    input integer commit_slot;
    integer store_slot;
    begin
      store_slot = -1;
      for(cx_pending_idx = 0; cx_pending_idx < 256; cx_pending_idx = cx_pending_idx + 1) begin
        if(store_slot < 0
           && cx_pending_store_valid[cx_pending_idx]
           && cx_pending_store_iid[cx_pending_idx] == cx_pending_commit_iid[commit_slot]) begin
          store_slot = cx_pending_idx;
        end
      end
      if(store_slot >= 0) begin
        cx_emit_store_line(
          cx_pending_store_cycle[store_slot],
          cx_pending_commit_cycle[commit_slot],
          cx_pending_commit_pc[commit_slot],
          cx_pending_commit_iid[commit_slot],
          cx_pending_store_addr[store_slot],
          cx_pending_store_bytes_vld[store_slot],
          cx_pending_store_data[store_slot]
        );
        cx_pending_commit_valid[commit_slot] = 1'b0;
        cx_pending_store_valid[store_slot] = 1'b0;
      end
    end
  endtask

  task automatic cx_queue_pending_commit;
    input [6:0]  iid;
    input [39:0] pc;
    input [31:0] commit_cycle;
    integer slot;
    integer suppressed_slot;
    begin
      suppressed_slot = -1;
      for(cx_pending_idx = 0; cx_pending_idx < 256; cx_pending_idx = cx_pending_idx + 1) begin
        if(suppressed_slot < 0
           && cx_suppressed_store_valid[cx_pending_idx]
           && cx_suppressed_store_iid[cx_pending_idx] == iid) begin
          suppressed_slot = cx_pending_idx;
        end
      end
      if(suppressed_slot >= 0) begin
        cx_suppressed_store_valid[suppressed_slot] = 1'b0;
      end else begin
      slot = -1;
      for(cx_pending_idx = 0; cx_pending_idx < 256; cx_pending_idx = cx_pending_idx + 1) begin
        if(slot < 0 && !cx_pending_commit_valid[cx_pending_idx]) begin
          slot = cx_pending_idx;
        end
      end
      if(slot >= 0) begin
        cx_pending_commit_valid[slot] = 1'b1;
        cx_pending_commit_iid[slot] = iid;
        cx_pending_commit_pc[slot] = pc;
        cx_pending_commit_cycle[slot] = commit_cycle;
        cx_try_match_commit_slot(slot);
        cx_try_resolve_pending_sc_store_iid(iid);
      end
      end
    end
  endtask

  task automatic cx_try_match_store_slot;
    input integer store_slot;
    integer commit_slot;
    begin
      commit_slot = -1;
      for(cx_pending_idx = 0; cx_pending_idx < 256; cx_pending_idx = cx_pending_idx + 1) begin
        if(commit_slot < 0
           && cx_pending_commit_valid[cx_pending_idx]
           && cx_pending_commit_iid[cx_pending_idx] == cx_pending_store_iid[store_slot]) begin
          commit_slot = cx_pending_idx;
        end
      end
      if(commit_slot >= 0) begin
        cx_emit_store_line(
          cx_pending_store_cycle[store_slot],
          cx_pending_commit_cycle[commit_slot],
          cx_pending_commit_pc[commit_slot],
          cx_pending_commit_iid[commit_slot],
          cx_pending_store_addr[store_slot],
          cx_pending_store_bytes_vld[store_slot],
          cx_pending_store_data[store_slot]
        );
        cx_pending_store_valid[store_slot] = 1'b0;
        cx_pending_commit_valid[commit_slot] = 1'b0;
      end
    end
  endtask

  task automatic cx_try_resolve_pending_sc_store_iid;
    input integer iid;
    integer store_slot;
    integer commit_slot;
    begin
      if(iid >= 0 && iid < 256) begin
        store_slot = -1;
        commit_slot = -1;
        for(cx_pending_idx = 0; cx_pending_idx < 256; cx_pending_idx = cx_pending_idx + 1) begin
          if(store_slot < 0
             && cx_pending_wmb_store_valid[cx_pending_idx]
             && cx_pending_wmb_store_is_sc[cx_pending_idx]
             && cx_pending_wmb_store_iid[cx_pending_idx] == iid[6:0]) begin
            store_slot = cx_pending_idx;
          end
          if(commit_slot < 0
             && cx_pending_commit_valid[cx_pending_idx]
             && cx_pending_commit_iid[cx_pending_idx] == iid[6:0]) begin
            commit_slot = cx_pending_idx;
          end
        end
        if(store_slot >= 0 && commit_slot >= 0 && cx_iid_rd_wdata_valid[iid]) begin
          if(cx_iid_rd_wdata[iid] == 64'b0) begin
            cx_emit_store_line(
              cx_pending_wmb_store_cycle[store_slot],
              cx_pending_commit_cycle[commit_slot],
              cx_pending_commit_pc[commit_slot],
              cx_pending_commit_iid[commit_slot],
              cx_pending_wmb_store_addr[store_slot],
              cx_pending_wmb_store_bytes_vld[store_slot],
              cx_pending_wmb_store_data[store_slot]
            );
          end
          cx_pending_wmb_store_valid[store_slot] = 1'b0;
          cx_pending_wmb_store_is_sc[store_slot] = 1'b0;
          cx_pending_commit_valid[commit_slot] = 1'b0;
          cx_clear_iid_rd_state(iid[6:0]);
        end
      end
    end
  endtask

  task automatic cx_clear_iid_rd_state;
    input [6:0] iid;
    begin
      cx_iid_rd_valid[iid] = 1'b0;
      cx_iid_preg[iid] = 7'b0;
      cx_iid_rd_wdata_valid[iid] = 1'b0;
      cx_iid_rd_wdata[iid] = 64'b0;
    end
  endtask

  task automatic cx_queue_pending_store;
    input [31:0] event_cycle;
    input [6:0]  iid;
    input [39:0] addr;
    input [15:0] bytes_vld;
    input [63:0] data;
    integer slot;
    begin
      slot = -1;
      for(cx_pending_idx = 0; cx_pending_idx < 256; cx_pending_idx = cx_pending_idx + 1) begin
        if(slot < 0 && !cx_pending_store_valid[cx_pending_idx]) begin
          slot = cx_pending_idx;
        end
      end
      if(slot >= 0) begin
        cx_pending_store_valid[slot] = 1'b1;
        cx_pending_store_iid[slot] = iid;
        cx_pending_store_addr[slot] = addr;
        cx_pending_store_bytes_vld[slot] = bytes_vld;
        cx_pending_store_data[slot] = data;
        cx_pending_store_cycle[slot] = event_cycle;
        cx_try_match_store_slot(slot);
      end
    end
  endtask

  task automatic cx_record_dispatch_rd;
    input [6:0] iid;
    input [6:0] preg;
    begin
      cx_iid_rd_valid[iid] = 1'b1;
      cx_iid_preg[iid] = preg;
      cx_iid_rd_wdata_valid[iid] = 1'b0;
      cx_iid_rd_wdata[iid] = 64'b0;
    end
  endtask

  task automatic cx_record_pregwrite;
    input [6:0] preg;
    input [63:0] value;
    integer iid_slot;
    begin
      for(iid_slot = 0; iid_slot < 256; iid_slot = iid_slot + 1) begin
        if(cx_iid_rd_valid[iid_slot] && cx_iid_preg[iid_slot] == preg) begin
          cx_iid_rd_wdata_valid[iid_slot] = 1'b1;
          cx_iid_rd_wdata[iid_slot] = value;
          cx_try_resolve_pending_sc_store_iid(iid_slot);
        end
      end
    end
  endtask

  task automatic cx_buffer_pending_wmb_store;
    input [31:0] event_cycle;
    input [6:0]  iid;
    input        is_sc;
    input [39:0] addr;
    input [15:0] bytes_vld;
    input [63:0] data;
    integer slot;
    begin
      slot = -1;
      for(cx_pending_idx = 0; cx_pending_idx < 256; cx_pending_idx = cx_pending_idx + 1) begin
        if(slot < 0 && !cx_pending_wmb_store_valid[cx_pending_idx]) begin
          slot = cx_pending_idx;
        end
      end
      if(slot >= 0) begin
        cx_pending_wmb_store_valid[slot] = 1'b1;
        cx_pending_wmb_store_iid[slot] = iid;
        cx_pending_wmb_store_is_sc[slot] = 1'b0;
        cx_pending_wmb_store_addr[slot] = addr;
        cx_pending_wmb_store_bytes_vld[slot] = bytes_vld;
        cx_pending_wmb_store_data[slot] = data;
        cx_pending_wmb_store_cycle[slot] = event_cycle;
      end
    end
  endtask

  task automatic cx_complete_pending_wmb_store;
    input [6:0] iid;
    input [1:0] inst_type;
    integer slot;
    begin
      slot = -1;
      for(cx_pending_idx = 0; cx_pending_idx < 256; cx_pending_idx = cx_pending_idx + 1) begin
        if(slot < 0
           && cx_pending_wmb_store_valid[cx_pending_idx]
           && cx_pending_wmb_store_iid[cx_pending_idx] == iid) begin
          slot = cx_pending_idx;
        end
      end
      if(slot >= 0) begin
        if(inst_type == 2'b01) begin
          cx_pending_wmb_store_is_sc[slot] = 1'b1;
          cx_resolve_pending_sc_store(iid, cx_wmb_complete_sc_wb_success);
        end else begin
          cx_queue_pending_store(
            cx_pending_wmb_store_cycle[slot],
            cx_pending_wmb_store_iid[slot],
            cx_pending_wmb_store_addr[slot],
            cx_pending_wmb_store_bytes_vld[slot],
            cx_pending_wmb_store_data[slot]
          );
          cx_pending_wmb_store_valid[slot] = 1'b0;
          cx_pending_wmb_store_is_sc[slot] = 1'b0;
        end
      end
    end
  endtask

  task automatic cx_resolve_pending_sc_store;
    input [6:0] iid;
    input       emit_store;
    integer slot;
    integer commit_slot;
    integer suppressed_slot;
    begin
      slot = -1;
      for(cx_pending_idx = 0; cx_pending_idx < 256; cx_pending_idx = cx_pending_idx + 1) begin
        if(slot < 0
           && cx_pending_wmb_store_valid[cx_pending_idx]
           && cx_pending_wmb_store_is_sc[cx_pending_idx]
           && cx_pending_wmb_store_iid[cx_pending_idx] == iid) begin
          slot = cx_pending_idx;
        end
      end
      if(slot >= 0) begin
        if(emit_store) begin
          cx_queue_pending_store(
            cx_pending_wmb_store_cycle[slot],
            cx_pending_wmb_store_iid[slot],
            cx_pending_wmb_store_addr[slot],
            cx_pending_wmb_store_bytes_vld[slot],
            cx_pending_wmb_store_data[slot]
          );
        end else begin
          commit_slot = -1;
          for(cx_pending_idx = 0; cx_pending_idx < 256; cx_pending_idx = cx_pending_idx + 1) begin
            if(commit_slot < 0
               && cx_pending_commit_valid[cx_pending_idx]
               && cx_pending_commit_iid[cx_pending_idx] == iid) begin
              commit_slot = cx_pending_idx;
            end
          end
          if(commit_slot >= 0) begin
            cx_pending_commit_valid[commit_slot] = 1'b0;
          end else begin
            suppressed_slot = -1;
            for(cx_pending_idx = 0; cx_pending_idx < 256; cx_pending_idx = cx_pending_idx + 1) begin
              if(suppressed_slot < 0 && !cx_suppressed_store_valid[cx_pending_idx]) begin
                suppressed_slot = cx_pending_idx;
              end
            end
            if(suppressed_slot >= 0) begin
              cx_suppressed_store_valid[suppressed_slot] = 1'b1;
              cx_suppressed_store_iid[suppressed_slot] = iid;
            end
          end
        end
        cx_pending_wmb_store_valid[slot] = 1'b0;
        cx_pending_wmb_store_is_sc[slot] = 1'b0;
        cx_clear_iid_rd_state(iid);
      end
    end
  endtask

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

  `include "cx_trace_v2.vh"

  always @(posedge clk)
  begin
      if(cx_trace_file != 0) begin
      if(cx_lsu_dbg_st_req) begin
        if(cx_lsu_dbg_st_atomic) begin
          cx_buffer_pending_wmb_store(
            cycle_count[31:0],
            cx_lsu_dbg_st_iid,
            cx_lsu_dbg_st_is_sc,
            cx_lsu_dbg_st_addr,
            cx_lsu_dbg_st_bytes_vld,
            cx_lsu_dbg_st_data
          );
        end else begin
          cx_queue_pending_store(
            cycle_count[31:0],
            cx_lsu_dbg_st_iid,
            cx_lsu_dbg_st_addr,
            cx_lsu_dbg_st_bytes_vld,
            cx_lsu_dbg_st_data
          );
        end
      end
      if(cx_wmb_st_wb_cmplt_req) begin
        if(cx_wmb_complete_atomic
           && (cx_wmb_complete_inst_type != 2'b01 || cx_wmb_complete_sc_wb_success)) begin
          cx_emit_store_complete_line(
            cycle_count[31:0],
            cx_wmb_st_wb_iid,
            cx_wmb_st_wb_cmplt_ptr,
            cx_wmb_complete_addr,
            cx_wmb_complete_bytes_vld,
            cx_wmb_complete_data128
          );
        end
        cx_complete_pending_wmb_store(
          cx_wmb_st_wb_iid,
          cx_wmb_complete_inst_type
        );
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_preg_vld) begin
        cx_record_dispatch_rd(
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_preg_iid[6:0],
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_preg[6:0]
        );
        $fwrite(cx_trace_file, "dispatch cycle=%0d hart=0 iid=%0d rd=x%0d preg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_preg_iid[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_dst_reg[4:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst0_preg[6:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_preg_vld) begin
        cx_record_dispatch_rd(
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_preg_iid[6:0],
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_preg[6:0]
        );
        $fwrite(cx_trace_file, "dispatch cycle=%0d hart=0 iid=%0d rd=x%0d preg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_preg_iid[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_dst_reg[4:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst1_preg[6:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_preg_vld) begin
        cx_record_dispatch_rd(
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_preg_iid[6:0],
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_preg[6:0]
        );
        $fwrite(cx_trace_file, "dispatch cycle=%0d hart=0 iid=%0d rd=x%0d preg=%0d\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_preg_iid[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_dst_reg[4:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst2_preg[6:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_preg_vld) begin
        cx_record_dispatch_rd(
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_preg_iid[6:0],
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.idu_rtu_pst_dis_inst3_preg[6:0]
        );
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
        cx_record_pregwrite(
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg[6:0],
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg_data[63:0]
        );
        $fwrite(cx_trace_file, "pregwrite cycle=%0d hart=0 preg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe0_wb_preg_data[63:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg_vld) begin
        cx_record_pregwrite(
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg[6:0],
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg_data[63:0]
        );
        $fwrite(cx_trace_file, "pregwrite cycle=%0d hart=0 preg=%0d value=0x%016x\n",
                cycle_count[31:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg[6:0],
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_iu_top.x_ct_iu_rbus.iu_idu_ex2_pipe1_wb_preg_data[63:0]);
      end
      if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg_vld) begin
        cx_record_pregwrite(
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg[6:0],
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_lsu_top.x_ct_lsu_ld_wb.lsu_idu_wb_pipe3_wb_preg_data[63:0]
        );
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
        if(`CPU_TOP.x_ct_top_0.x_ct_core.rtu_ifu_retire_inst0_store) begin
          cx_queue_pending_commit(
            `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit0_iid[6:0],
            `retire0_pc,
            cycle_count[31:0]
          );
        end
      end
      if(`tb_retire1) begin
        $fwrite(cx_trace_file, "commit cycle=%0d hart=0 pc=0x%010x iid=%0d",
                cycle_count[31:0], `retire1_pc,
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit1_iid[6:0]);
        $fwrite(cx_trace_file, "\n");
        if(`CPU_TOP.x_ct_top_0.x_ct_core.rtu_ifu_retire_inst1_store) begin
          cx_queue_pending_commit(
            `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit1_iid[6:0],
            `retire1_pc,
            cycle_count[31:0]
          );
        end
      end
      if(`tb_retire2) begin
        $fwrite(cx_trace_file, "commit cycle=%0d hart=0 pc=0x%010x iid=%0d",
                cycle_count[31:0], `retire2_pc,
                `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit2_iid[6:0]);
        $fwrite(cx_trace_file, "\n");
        if(`CPU_TOP.x_ct_top_0.x_ct_core.rtu_ifu_retire_inst2_store) begin
          cx_queue_pending_commit(
            `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit2_iid[6:0],
            `retire2_pc,
            cycle_count[31:0]
          );
        end
      end
      if(`tb_retire0 || `tb_retire1 || `tb_retire2) begin
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
