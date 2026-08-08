// CX Trace V2 instrumentation for OpenC910.
//
// This file is included inside both simulation top-level modules.  Dynamic
// identity is allocated only when the IDU really creates a ROB entry.  The
// 7-bit OpenC910 IID is used only to find the live sidecar entry; the 64-bit
// token remains the long-lived dynamic identity written to the trace.

reg [63:0] cx_trace_cycle;
reg        cx_trace_armed;
reg        cx_trace_header_written;
integer    cx_trace_harts;
reg [255:0] cx_trace_isa;

reg        cx_h0_valid [0:63];
reg [6:0]  cx_h0_full_iid [0:63];
reg [63:0] cx_h0_start_cycle [0:63];
reg [2:0]  cx_h0_inst_count [0:63];
reg [63:0] cx_h0_token0 [0:63];
reg [63:0] cx_h0_token1 [0:63];
reg [63:0] cx_h0_token2 [0:63];
reg [31:0] cx_h0_insn0 [0:63];
reg [31:0] cx_h0_insn1 [0:63];
reg [31:0] cx_h0_insn2 [0:63];
reg [2:0]  cx_h0_insn0_len [0:63];
reg [2:0]  cx_h0_insn1_len [0:63];
reg [2:0]  cx_h0_insn2_len [0:63];
reg        cx_h0_split [0:63];
reg [63:0] cx_h0_next_token;
reg [63:0] cx_h0_term_seq;
reg [63:0] cx_h0_instret_seq;
reg        cx_h0_split_pending;
reg [39:0] cx_h0_split_pc;
reg [63:0] cx_h0_split_token;
reg [63:0] cx_h0_split_start_cycle;

reg        cx_h1_valid [0:63];
reg [6:0]  cx_h1_full_iid [0:63];
reg [63:0] cx_h1_start_cycle [0:63];
reg [2:0]  cx_h1_inst_count [0:63];
reg [63:0] cx_h1_token0 [0:63];
reg [63:0] cx_h1_token1 [0:63];
reg [63:0] cx_h1_token2 [0:63];
reg [31:0] cx_h1_insn0 [0:63];
reg [31:0] cx_h1_insn1 [0:63];
reg [31:0] cx_h1_insn2 [0:63];
reg [2:0]  cx_h1_insn0_len [0:63];
reg [2:0]  cx_h1_insn1_len [0:63];
reg [2:0]  cx_h1_insn2_len [0:63];
reg        cx_h1_split [0:63];
reg [63:0] cx_h1_next_token;
reg [63:0] cx_h1_term_seq;
reg [63:0] cx_h1_instret_seq;
reg        cx_h1_split_pending;
reg [39:0] cx_h1_split_pc;
reg [63:0] cx_h1_split_token;
reg [63:0] cx_h1_split_start_cycle;

integer cx_trace_i;

wire [63:0] cx_trace_now = cx_trace_cycle + 64'd1;

wire cx_h0_alloc0 =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_ctrl.idu_rtu_rob_create0_en;
wire cx_h0_alloc1 =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_ctrl.idu_rtu_rob_create1_en;
wire cx_h0_alloc2 =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_ctrl.idu_rtu_rob_create2_en;
wire cx_h0_alloc3 =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_ctrl.idu_rtu_rob_create3_en;

wire [6:0] cx_h0_alloc0_iid =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.rtu_idu_rob_inst0_iid;
wire [6:0] cx_h0_alloc1_iid =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.rtu_idu_rob_inst1_iid;
wire [6:0] cx_h0_alloc2_iid =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.rtu_idu_rob_inst2_iid;
wire [6:0] cx_h0_alloc3_iid =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.rtu_idu_rob_inst3_iid;

wire [1:0] cx_h0_alloc0_sel =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.ctrl_dp_is_dis_rob_create0_sel;
wire [2:0] cx_h0_alloc1_sel =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.ctrl_dp_is_dis_rob_create1_sel;
wire [1:0] cx_h0_alloc2_sel =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.ctrl_dp_is_dis_rob_create2_sel;

wire [31:0] cx_h0_alloc0_insn =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.is_inst0_read_data[31:0];
wire [31:0] cx_h0_alloc1_insn =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.is_inst1_read_data[31:0];
wire [31:0] cx_h0_alloc2_insn =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.is_inst2_read_data[31:0];
wire [31:0] cx_h0_alloc3_insn =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.is_inst3_read_data[31:0];
wire [2:0] cx_h0_alloc0_len =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.is_inst0_read_data[203] ? 3'd4 : 3'd2;
wire [2:0] cx_h0_alloc1_len =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.is_inst1_read_data[203] ? 3'd4 : 3'd2;
wire [2:0] cx_h0_alloc2_len =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.is_inst2_read_data[203] ? 3'd4 : 3'd2;
wire [2:0] cx_h0_alloc3_len =
    `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.is_inst3_read_data[203] ? 3'd4 : 3'd2;

// The cx-build harness instantiates only x_ct_top_0.  Keep the common
// sidecar/task declarations but tie all hart-1 event sources off explicitly.
wire        cx_h1_alloc0 = 1'b0;
wire        cx_h1_alloc1 = 1'b0;
wire        cx_h1_alloc2 = 1'b0;
wire        cx_h1_alloc3 = 1'b0;
wire [6:0]  cx_h1_alloc0_iid = 7'd0;
wire [6:0]  cx_h1_alloc1_iid = 7'd0;
wire [6:0]  cx_h1_alloc2_iid = 7'd0;
wire [6:0]  cx_h1_alloc3_iid = 7'd0;
wire [1:0]  cx_h1_alloc0_sel = 2'd0;
wire [2:0]  cx_h1_alloc1_sel = 3'd0;
wire [1:0]  cx_h1_alloc2_sel = 2'd0;
wire [31:0] cx_h1_alloc0_insn = 32'd0;
wire [31:0] cx_h1_alloc1_insn = 32'd0;
wire [31:0] cx_h1_alloc2_insn = 32'd0;
wire [31:0] cx_h1_alloc3_insn = 32'd0;
wire [2:0]  cx_h1_alloc0_len = 3'd0;
wire [2:0]  cx_h1_alloc1_len = 3'd0;
wire [2:0]  cx_h1_alloc2_len = 3'd0;
wire [2:0]  cx_h1_alloc3_len = 3'd0;

// A C910 ROB entry may fold one, two, or three architectural instructions.
// The create selects say which dispatch slots belong to each entry; the ROB
// INST_NUM field and retire_instN_num carry the matching architectural count.
wire [2:0] cx_h0_alloc0_num = cx_h0_alloc0
    ? {1'b0, `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.idu_rtu_rob_create0_data[18:17]}
    : 3'd0;
wire [2:0] cx_h0_alloc1_num = cx_h0_alloc1
    ? {1'b0, `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.idu_rtu_rob_create1_data[18:17]}
    : 3'd0;
wire [2:0] cx_h0_alloc2_num = cx_h0_alloc2
    ? {1'b0, `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.idu_rtu_rob_create2_data[18:17]}
    : 3'd0;
wire [2:0] cx_h0_alloc3_num = cx_h0_alloc3
    ? {1'b0, `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.idu_rtu_rob_create3_data[18:17]}
    : 3'd0;
wire [2:0] cx_h1_alloc0_num = 3'd0;
wire [2:0] cx_h1_alloc1_num = 3'd0;
wire [2:0] cx_h1_alloc2_num = 3'd0;
wire [2:0] cx_h1_alloc3_num = 3'd0;

wire [63:0] cx_h0_alloc_count = {61'd0, cx_h0_alloc0_num}
                                      + {61'd0, cx_h0_alloc1_num}
                                      + {61'd0, cx_h0_alloc2_num}
                                      + {61'd0, cx_h0_alloc3_num};
wire [63:0] cx_h1_alloc_count = {61'd0, cx_h1_alloc0_num}
                                      + {61'd0, cx_h1_alloc1_num}
                                      + {61'd0, cx_h1_alloc2_num}
                                      + {61'd0, cx_h1_alloc3_num};

wire [2:0] cx_h0_retire0_num = `tb_retire0
    ? {1'b0, `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.x_ct_rtu_rob.x_ct_rtu_rob_rt.retire_inst0_num}
    : 3'd0;
wire [2:0] cx_h0_retire1_num = `tb_retire1
    ? {1'b0, `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.x_ct_rtu_rob.x_ct_rtu_rob_rt.retire_inst1_num}
    : 3'd0;
wire [2:0] cx_h0_retire2_num = `tb_retire2
    ? {1'b0, `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.x_ct_rtu_rob.x_ct_rtu_rob_rt.retire_inst2_num}
    : 3'd0;
wire [2:0] cx_h1_retire0_num = 3'd0;
wire [2:0] cx_h1_retire1_num = 3'd0;
wire [2:0] cx_h1_retire2_num = 3'd0;

wire cx_h0_retire0_split = `tb_retire0
    && cx_h0_valid[`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit0_iid[5:0]]
    && cx_h0_split[`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit0_iid[5:0]];
wire cx_h0_retire1_split = `tb_retire1
    && cx_h0_valid[`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit1_iid[5:0]]
    && cx_h0_split[`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit1_iid[5:0]];
wire cx_h0_retire2_split = `tb_retire2
    && cx_h0_valid[`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit2_iid[5:0]]
    && cx_h0_split[`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit2_iid[5:0]];
wire cx_h1_retire0_split = 1'b0;
wire cx_h1_retire1_split = 1'b0;
wire cx_h1_retire2_split = 1'b0;

wire cx_h0_trap0 = `tb_retire0
    && `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_cp0_expt_vld
    && !`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_cp0_int_ack;
wire cx_h1_trap0 = 1'b0;
wire [2:0] cx_h0_retire0_arch_num = (cx_h0_retire0_split && !cx_h0_trap0)
    ? 3'd0 : cx_h0_retire0_num;
wire [2:0] cx_h0_retire1_arch_num = cx_h0_retire1_split
    ? 3'd0 : cx_h0_retire1_num;
wire [2:0] cx_h0_retire2_arch_num = cx_h0_retire2_split
    ? 3'd0 : cx_h0_retire2_num;
wire [2:0] cx_h1_retire0_arch_num = (cx_h1_retire0_split && !cx_h1_trap0)
    ? 3'd0 : cx_h1_retire0_num;
wire [2:0] cx_h1_retire1_arch_num = cx_h1_retire1_split
    ? 3'd0 : cx_h1_retire1_num;
wire [2:0] cx_h1_retire2_arch_num = cx_h1_retire2_split
    ? 3'd0 : cx_h1_retire2_num;
wire [63:0] cx_h0_terminal_count = {61'd0, cx_h0_retire0_arch_num}
                                      + {61'd0, cx_h0_retire1_arch_num}
                                      + {61'd0, cx_h0_retire2_arch_num};
wire [63:0] cx_h1_terminal_count = {61'd0, cx_h1_retire0_arch_num}
                                      + {61'd0, cx_h1_retire1_arch_num}
                                      + {61'd0, cx_h1_retire2_arch_num};
wire [63:0] cx_h0_retired_count = cx_h0_terminal_count - {63'd0, cx_h0_trap0};
wire [63:0] cx_h1_retired_count = cx_h1_terminal_count - {63'd0, cx_h1_trap0};

function cx_h0_index_released;
  input [5:0] idx;
  begin
    cx_h0_index_released =
      (`tb_retire0 &&
       `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit0_iid[5:0] == idx)
      || (`tb_retire1 &&
       `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit1_iid[5:0] == idx)
      || (`tb_retire2 &&
       `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit2_iid[5:0] == idx);
  end
endfunction

function cx_h1_index_released;
  input [5:0] idx;
  begin
    cx_h1_index_released = 1'b0;
  end
endfunction

// The IDU replaces architectural split instructions with internal uops.  The
// testbench's immutable instruction image is therefore the authoritative raw
// encoding for an architectural PC.  Read eight adjacent bytes so a 32-bit
// instruction beginning at a halfword boundary may cross a 32-bit image word.
function [31:0] cx_trace_program_insn;
  input [39:0] pc;
  integer word_index;
  reg [31:0] image_word0;
  reg [31:0] image_word1;
  reg [31:0] little_word0;
  reg [31:0] little_word1;
  reg [63:0] little_window;
  reg [31:0] shifted_insn;
  begin
    word_index = pc[39:2];
    image_word0 = mem_inst_temp[word_index];
    image_word1 = mem_inst_temp[word_index + 1];
    little_word0 = {image_word0[7:0], image_word0[15:8],
                    image_word0[23:16], image_word0[31:24]};
    little_word1 = {image_word1[7:0], image_word1[15:8],
                    image_word1[23:16], image_word1[31:24]};
    little_window = {little_word1, little_word0};
    shifted_insn = little_window >> ({62'd0, pc[1:0]} * 8);
    // CX Trace V2 carries the exact architectural instruction encoding.  A
    // compressed instruction is 16 bits, not the following halfword packed
    // into the upper half of a 32-bit image window.
    cx_trace_program_insn = (shifted_insn[1:0] == 2'b11)
      ? shifted_insn
      : {16'b0, shifted_insn[15:0]};
  end
endfunction

function [2:0] cx_trace_program_insn_len;
  input [39:0] pc;
  reg [31:0] insn;
  begin
    insn = cx_trace_program_insn(pc);
    cx_trace_program_insn_len = (insn[1:0] == 2'b11) ? 3'd4 : 3'd2;
  end
endfunction

task cx_trace_allocate;
  input integer hart;
  input [6:0] iid;
  input [2:0] inst_count;
  input [63:0] token_base;
  input [31:0] insn0;
  input [2:0] insn0_len;
  input [31:0] insn1;
  input [2:0] insn1_len;
  input [31:0] insn2;
  input [2:0] insn2_len;
  integer idx;
  reg old_valid;
  reg [6:0] old_iid;
  begin
    idx = iid[5:0];
    if(hart == 0) begin
      old_valid = cx_h0_valid[idx];
      old_iid = cx_h0_full_iid[idx];
    end
    else begin
      old_valid = cx_h1_valid[idx];
      old_iid = cx_h1_full_iid[idx];
    end

    if(inst_count < 1 || inst_count > 3)
      $error("OpenC910 CX Trace V2 invalid ROB instruction count: hart=%0d iid=%0d count=%0d cycle=%0d",
             hart, iid, inst_count, cx_trace_now);
    else if(old_valid
            && !((hart == 0) ? cx_h0_index_released(idx)
                             : cx_h1_index_released(idx)))
      $error("OpenC910 CX Trace V2 live IID reuse: hart=%0d iid=%0d old_iid=%0d cycle=%0d",
             hart, iid, old_iid, cx_trace_now);

    if(hart == 0) begin
      cx_h0_valid[idx] <= 1'b1;
      cx_h0_full_iid[idx] <= iid;
      cx_h0_start_cycle[idx] <= cx_trace_now;
      cx_h0_inst_count[idx] <= inst_count;
      cx_h0_token0[idx] <= token_base;
      cx_h0_token1[idx] <= token_base + 64'd1;
      cx_h0_token2[idx] <= token_base + 64'd2;
      cx_h0_insn0[idx] <= (insn0_len == 2) ? {16'd0, insn0[15:0]} : insn0;
      cx_h0_insn1[idx] <= (insn1_len == 2) ? {16'd0, insn1[15:0]} : insn1;
      cx_h0_insn2[idx] <= (insn2_len == 2) ? {16'd0, insn2[15:0]} : insn2;
      cx_h0_insn0_len[idx] <= insn0_len;
      cx_h0_insn1_len[idx] <= insn1_len;
      cx_h0_insn2_len[idx] <= insn2_len;
    end
    else begin
      cx_h1_valid[idx] <= 1'b1;
      cx_h1_full_iid[idx] <= iid;
      cx_h1_start_cycle[idx] <= cx_trace_now;
      cx_h1_inst_count[idx] <= inst_count;
      cx_h1_token0[idx] <= token_base;
      cx_h1_token1[idx] <= token_base + 64'd1;
      cx_h1_token2[idx] <= token_base + 64'd2;
      cx_h1_insn0[idx] <= (insn0_len == 2) ? {16'd0, insn0[15:0]} : insn0;
      cx_h1_insn1[idx] <= (insn1_len == 2) ? {16'd0, insn1[15:0]} : insn1;
      cx_h1_insn2[idx] <= (insn2_len == 2) ? {16'd0, insn2[15:0]} : insn2;
      cx_h1_insn0_len[idx] <= insn0_len;
      cx_h1_insn1_len[idx] <= insn1_len;
      cx_h1_insn2_len[idx] <= insn2_len;
    end
  end
endtask

task cx_trace_terminal;
  input integer hart;
  input [3:0] slot_base;
  input [6:0] iid;
  input [39:0] pc;
  input [2:0] retire_count;
  input [63:0] term_seq;
  input [63:0] instret_seq;
  input trap;
  input [5:0] cause;
  input [1:0] priv;
  integer idx;
  reg valid;
  reg [6:0] full_iid;
  reg [63:0] start_cycle;
  reg [2:0] inst_count;
  reg [63:0] token0;
  reg [63:0] token1;
  reg [63:0] token2;
  reg [31:0] insn0;
  reg [31:0] insn1;
  reg [31:0] insn2;
  reg [2:0] insn0_len;
  reg [2:0] insn1_len;
  reg [2:0] insn2_len;
  reg is_split;
  reg split_pending;
  reg [39:0] split_pc;
  reg [63:0] split_token;
  reg [63:0] split_start_cycle;
  reg [63:0] token;
  reg [31:0] insn;
  reg [2:0] insn_len;
  reg [39:0] inst_pc;
  integer subslot;
  begin
    idx = iid[5:0];
    if(hart == 0) begin
      valid       = cx_h0_valid[idx];
      full_iid    = cx_h0_full_iid[idx];
      start_cycle = cx_h0_start_cycle[idx];
      inst_count  = cx_h0_inst_count[idx];
      token0      = cx_h0_token0[idx];
      token1      = cx_h0_token1[idx];
      token2      = cx_h0_token2[idx];
      insn0       = cx_h0_insn0[idx];
      insn1       = cx_h0_insn1[idx];
      insn2       = cx_h0_insn2[idx];
      insn0_len   = cx_h0_insn0_len[idx];
      insn1_len   = cx_h0_insn1_len[idx];
      insn2_len   = cx_h0_insn2_len[idx];
      is_split    = cx_h0_split[idx];
      split_pending = cx_h0_split_pending;
      split_pc = cx_h0_split_pc;
      split_token = cx_h0_split_token;
      split_start_cycle = cx_h0_split_start_cycle;
      cx_h0_valid[idx] <= 1'b0;
    end
    else begin
      valid       = cx_h1_valid[idx];
      full_iid    = cx_h1_full_iid[idx];
      start_cycle = cx_h1_start_cycle[idx];
      inst_count  = cx_h1_inst_count[idx];
      token0      = cx_h1_token0[idx];
      token1      = cx_h1_token1[idx];
      token2      = cx_h1_token2[idx];
      insn0       = cx_h1_insn0[idx];
      insn1       = cx_h1_insn1[idx];
      insn2       = cx_h1_insn2[idx];
      insn0_len   = cx_h1_insn0_len[idx];
      insn1_len   = cx_h1_insn1_len[idx];
      insn2_len   = cx_h1_insn2_len[idx];
      is_split    = cx_h1_split[idx];
      split_pending = cx_h1_split_pending;
      split_pc = cx_h1_split_pc;
      split_token = cx_h1_split_token;
      split_start_cycle = cx_h1_split_start_cycle;
      cx_h1_valid[idx] <= 1'b0;
    end

    if(!valid) begin
      $error("OpenC910 CX Trace V2 commit without live allocation: hart=%0d iid=%0d cycle=%0d",
             hart, iid, cx_trace_now);
    end
    else if(full_iid != iid) begin
      $error("OpenC910 CX Trace V2 IID epoch mismatch: hart=%0d commit_iid=%0d live_iid=%0d cycle=%0d",
             hart, iid, full_iid, cx_trace_now);
    end
    else if(start_cycle == 0 || cx_trace_now < start_cycle) begin
      $error("OpenC910 CX Trace V2 invalid interval: hart=%0d iid=%0d start=%0d end=%0d",
             hart, iid, start_cycle, cx_trace_now);
    end
    else if(inst_count != retire_count) begin
      $error("OpenC910 CX Trace V2 folded instruction count mismatch: hart=%0d iid=%0d alloc_count=%0d retire_count=%0d cycle=%0d",
             hart, iid, inst_count, retire_count, cx_trace_now);
    end
    else if(trap && inst_count != 1) begin
      $error("OpenC910 CX Trace V2 precise trap unexpectedly folded: hart=%0d iid=%0d count=%0d cycle=%0d",
             hart, iid, inst_count, cx_trace_now);
    end
    else if(is_split && inst_count != 1) begin
      $error("OpenC910 CX Trace V2 split uop unexpectedly folded: hart=%0d iid=%0d count=%0d cycle=%0d",
             hart, iid, inst_count, cx_trace_now);
    end
    else if(is_split && !trap) begin
      if(split_pending && split_pc != pc) begin
        $error("OpenC910 CX Trace V2 interleaved split groups: hart=%0d pending_pc=0x%010x pc=0x%010x cycle=%0d",
               hart, split_pc, pc, cx_trace_now);
      end
      else if(!split_pending) begin
        if(hart == 0) begin
          cx_h0_split_pending = 1'b1;
          cx_h0_split_pc = pc;
          cx_h0_split_token = token0;
          cx_h0_split_start_cycle = start_cycle;
        end
        else begin
          cx_h1_split_pending = 1'b1;
          cx_h1_split_pc = pc;
          cx_h1_split_token = token0;
          cx_h1_split_start_cycle = start_cycle;
        end
      end
    end
    else begin
      if(split_pending) begin
        if(split_pc != pc)
          $error("OpenC910 CX Trace V2 split-last PC mismatch: hart=%0d pending_pc=0x%010x pc=0x%010x cycle=%0d",
                 hart, split_pc, pc, cx_trace_now);
        else if(inst_count != 1)
          $error("OpenC910 CX Trace V2 split-last unexpectedly folded: hart=%0d pc=0x%010x count=%0d cycle=%0d",
                 hart, pc, inst_count, cx_trace_now);
        start_cycle = split_start_cycle;
        token0 = split_token;
        if(hart == 0)
          cx_h0_split_pending = 1'b0;
        else
          cx_h1_split_pending = 1'b0;
      end
      inst_pc = pc;
      for(subslot = 0; subslot < inst_count; subslot = subslot + 1) begin
        case(subslot)
          0: token = token0;
          1: token = token1;
          default: token = token2;
        endcase
        insn = cx_trace_program_insn(inst_pc);
        insn_len = cx_trace_program_insn_len(inst_pc);
        if(insn_len != 2 && insn_len != 4)
          $error("OpenC910 CX Trace V2 invalid instruction length: hart=%0d token=%0d len=%0d",
                 hart, token, insn_len);
        else if(cx_trace_file != 0) begin
          if(trap) begin
            $fwrite(cx_trace_file,
              "CXTRACE v=2 event=inst_terminal core=openc910 hart=%0d token=%0d term_seq=%0d instret_seq=- commit_slot=%0d pc=0x%010x insn=0x%08x insn_len=%0d iid=%0d start_cycle=%0d end_cycle=%0d span=%0d start_kind=backend_alloc end_kind=precise_trap retired=0 trap=1 cause=%0d priv=%0d\n",
              hart, token, term_seq + subslot, slot_base + subslot,
              inst_pc, insn, insn_len, iid, start_cycle, cx_trace_now,
              cx_trace_now - start_cycle + 64'd1, cause, priv);
          end
          else begin
            $fwrite(cx_trace_file,
              "CXTRACE v=2 event=inst_terminal core=openc910 hart=%0d token=%0d term_seq=%0d instret_seq=%0d commit_slot=%0d pc=0x%010x insn=0x%08x insn_len=%0d iid=%0d start_cycle=%0d end_cycle=%0d span=%0d start_kind=backend_alloc end_kind=arch_commit retired=1 trap=0 cause=none priv=%0d\n",
              hart, token, term_seq + subslot, instret_seq + subslot,
              slot_base + subslot, inst_pc, insn, insn_len, iid,
              start_cycle, cx_trace_now, cx_trace_now - start_cycle + 64'd1,
              priv);
          end
        end
        inst_pc = inst_pc + insn_len;
      end
    end
  end
endtask

initial begin
  cx_trace_cycle = 64'd0;
  cx_trace_armed = 1'b0;
  cx_trace_header_written = 1'b0;
  cx_trace_harts = 2;
  cx_trace_isa = "rv64fd";
  cx_h0_next_token = 64'd0;
  cx_h0_term_seq = 64'd0;
  cx_h0_instret_seq = 64'd0;
  cx_h0_split_pending = 1'b0;
  cx_h1_next_token = 64'd0;
  cx_h1_term_seq = 64'd0;
  cx_h1_instret_seq = 64'd0;
  cx_h1_split_pending = 1'b0;
  for(cx_trace_i = 0; cx_trace_i < 64; cx_trace_i = cx_trace_i + 1) begin
    cx_h0_valid[cx_trace_i] = 1'b0;
    cx_h1_valid[cx_trace_i] = 1'b0;
    cx_h0_split[cx_trace_i] = 1'b0;
    cx_h1_split[cx_trace_i] = 1'b0;
  end
  if(!$value$plusargs("cx_harts=%d", cx_trace_harts)) begin
    cx_trace_harts = 2;
  end
  if(!$value$plusargs("cx_isa=%s", cx_trace_isa)) begin
    cx_trace_isa = "rv64fd";
  end
end

always @(posedge `CPU_CLK or negedge `CPU_RST) begin
  if(!`CPU_RST) begin
    cx_trace_cycle <= 64'd0;
    cx_trace_armed <= 1'b1;
    cx_trace_header_written <= 1'b0;
    cx_h0_next_token <= 64'd0;
    cx_h0_term_seq <= 64'd0;
    cx_h0_instret_seq <= 64'd0;
    cx_h0_split_pending = 1'b0;
    cx_h1_next_token <= 64'd0;
    cx_h1_term_seq <= 64'd0;
    cx_h1_instret_seq <= 64'd0;
    cx_h1_split_pending = 1'b0;
    for(cx_trace_i = 0; cx_trace_i < 64; cx_trace_i = cx_trace_i + 1) begin
      cx_h0_valid[cx_trace_i] <= 1'b0;
      cx_h1_valid[cx_trace_i] <= 1'b0;
      cx_h0_split[cx_trace_i] <= 1'b0;
      cx_h1_split[cx_trace_i] <= 1'b0;
    end
  end
  else if(cx_trace_armed) begin
    cx_trace_cycle <= cx_trace_now;

    if(!cx_trace_header_written && cx_trace_file != 0) begin
      $fwrite(cx_trace_file,
        "CXTRACE_HEADER v=2 cycle_domain=core_ref_clk cycle_base=first_post_reset_posedge_is_1 interval=inclusive start_kind=backend_alloc end_kind=arch_commit_or_precise_trap core=openc910 harts=%0d isa=%0s build_config=smart_run\n",
        cx_trace_harts, cx_trace_isa);
      cx_trace_header_written <= 1'b1;
    end

    // Architectural terminals are consumed oldest-to-youngest.  Prefix sums
    // keep term_seq and instret_seq correct for all three retire slots.
    if(`tb_retire0)
      cx_trace_terminal(0, 0,
        `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit0_iid,
        `retire0_pc, cx_h0_retire0_num,
        cx_h0_term_seq, cx_h0_instret_seq, cx_h0_trap0,
        `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_expt_vec,
        `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_cp0_top.cp0_yy_priv_mode);
    if(`tb_retire1)
      cx_trace_terminal(0, cx_h0_retire0_arch_num,
        `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit1_iid,
        `retire1_pc, cx_h0_retire1_num,
        cx_h0_term_seq + cx_h0_retire0_arch_num,
        cx_h0_instret_seq + cx_h0_retire0_arch_num - cx_h0_trap0,
        1'b0, 6'd0,
        `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_cp0_top.cp0_yy_priv_mode);
    if(`tb_retire2)
      cx_trace_terminal(0, cx_h0_retire0_arch_num + cx_h0_retire1_arch_num,
        `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_commit2_iid,
        `retire2_pc, cx_h0_retire2_num,
        cx_h0_term_seq + cx_h0_retire0_arch_num + cx_h0_retire1_arch_num,
        cx_h0_instret_seq + cx_h0_retire0_arch_num - cx_h0_trap0
                              + cx_h0_retire1_arch_num,
        1'b0, 6'd0,
        `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_cp0_top.cp0_yy_priv_mode);
    cx_h0_term_seq <= cx_h0_term_seq + cx_h0_terminal_count;
    cx_h0_instret_seq <= cx_h0_instret_seq + cx_h0_retired_count;

    if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_cp0_int_ack
       && cx_trace_file != 0)
      $fwrite(cx_trace_file,
        "CXTRACE v=2 event=interrupt core=openc910 hart=0 cycle=%0d cause=%0d priv=%0d\n",
        cx_trace_now,
        `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_expt_vec,
        `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_cp0_top.cp0_yy_priv_mode);
    // Backend flush invalidates every speculative sidecar entry.  Committed
    // terminals above are emitted first; allocation is suppressed on flush.
    if(`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_flush) begin
      cx_h0_split_pending = 1'b0;
      for(cx_trace_i = 0; cx_trace_i < 64; cx_trace_i = cx_trace_i + 1)
        cx_h0_valid[cx_trace_i] <= 1'b0;
    end
    if(!`CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_yy_xx_flush) begin
      if(cx_h0_alloc0) begin
        cx_h0_split[cx_h0_alloc0_iid[5:0]] <=
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.idu_rtu_rob_create0_data[7];
        case(cx_h0_alloc0_sel)
          0: cx_trace_allocate(0, cx_h0_alloc0_iid, cx_h0_alloc0_num,
               cx_h0_next_token, cx_h0_alloc0_insn, cx_h0_alloc0_len,
               32'd0, 3'd0, 32'd0, 3'd0);
          1: cx_trace_allocate(0, cx_h0_alloc0_iid, cx_h0_alloc0_num,
               cx_h0_next_token, cx_h0_alloc0_insn, cx_h0_alloc0_len,
               cx_h0_alloc1_insn, cx_h0_alloc1_len, 32'd0, 3'd0);
          2: cx_trace_allocate(0, cx_h0_alloc0_iid, cx_h0_alloc0_num,
               cx_h0_next_token, cx_h0_alloc0_insn, cx_h0_alloc0_len,
               cx_h0_alloc1_insn, cx_h0_alloc1_len,
               cx_h0_alloc2_insn, cx_h0_alloc2_len);
          default: $error("OpenC910 CX Trace V2 invalid create0 select: hart=0 sel=%0d cycle=%0d",
                          cx_h0_alloc0_sel, cx_trace_now);
        endcase
      end
      if(cx_h0_alloc1) begin
        cx_h0_split[cx_h0_alloc1_iid[5:0]] <=
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.idu_rtu_rob_create1_data[7];
        case(cx_h0_alloc1_sel)
          0: cx_trace_allocate(0, cx_h0_alloc1_iid, cx_h0_alloc1_num,
               cx_h0_next_token + cx_h0_alloc0_num,
               cx_h0_alloc1_insn, cx_h0_alloc1_len,
               32'd0, 3'd0, 32'd0, 3'd0);
          1: cx_trace_allocate(0, cx_h0_alloc1_iid, cx_h0_alloc1_num,
               cx_h0_next_token + cx_h0_alloc0_num,
               cx_h0_alloc1_insn, cx_h0_alloc1_len,
               cx_h0_alloc2_insn, cx_h0_alloc2_len, 32'd0, 3'd0);
          2: cx_trace_allocate(0, cx_h0_alloc1_iid, cx_h0_alloc1_num,
               cx_h0_next_token + cx_h0_alloc0_num,
               cx_h0_alloc2_insn, cx_h0_alloc2_len,
               32'd0, 3'd0, 32'd0, 3'd0);
          3: cx_trace_allocate(0, cx_h0_alloc1_iid, cx_h0_alloc1_num,
               cx_h0_next_token + cx_h0_alloc0_num,
               cx_h0_alloc3_insn, cx_h0_alloc3_len,
               32'd0, 3'd0, 32'd0, 3'd0);
          4: cx_trace_allocate(0, cx_h0_alloc1_iid, cx_h0_alloc1_num,
               cx_h0_next_token + cx_h0_alloc0_num,
               cx_h0_alloc1_insn, cx_h0_alloc1_len,
               cx_h0_alloc2_insn, cx_h0_alloc2_len,
               cx_h0_alloc3_insn, cx_h0_alloc3_len);
          default: $error("OpenC910 CX Trace V2 invalid create1 select: hart=0 sel=%0d cycle=%0d",
                          cx_h0_alloc1_sel, cx_trace_now);
        endcase
      end
      if(cx_h0_alloc2) begin
        cx_h0_split[cx_h0_alloc2_iid[5:0]] <=
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.idu_rtu_rob_create2_data[7];
        case(cx_h0_alloc2_sel)
          0: cx_trace_allocate(0, cx_h0_alloc2_iid, cx_h0_alloc2_num,
               cx_h0_next_token + cx_h0_alloc0_num + cx_h0_alloc1_num,
               cx_h0_alloc2_insn, cx_h0_alloc2_len,
               32'd0, 3'd0, 32'd0, 3'd0);
          2: cx_trace_allocate(0, cx_h0_alloc2_iid, cx_h0_alloc2_num,
               cx_h0_next_token + cx_h0_alloc0_num + cx_h0_alloc1_num,
               cx_h0_alloc2_insn, cx_h0_alloc2_len,
               cx_h0_alloc3_insn, cx_h0_alloc3_len, 32'd0, 3'd0);
          3: cx_trace_allocate(0, cx_h0_alloc2_iid, cx_h0_alloc2_num,
               cx_h0_next_token + cx_h0_alloc0_num + cx_h0_alloc1_num,
               cx_h0_alloc3_insn, cx_h0_alloc3_len,
               32'd0, 3'd0, 32'd0, 3'd0);
          default: $error("OpenC910 CX Trace V2 invalid create2 select: hart=0 sel=%0d cycle=%0d",
                          cx_h0_alloc2_sel, cx_trace_now);
        endcase
      end
      if(cx_h0_alloc3) begin
        cx_h0_split[cx_h0_alloc3_iid[5:0]] <=
          `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_idu_top.x_ct_idu_is_dp.idu_rtu_rob_create3_data[7];
        cx_trace_allocate(0, cx_h0_alloc3_iid, cx_h0_alloc3_num,
          cx_h0_next_token + cx_h0_alloc0_num + cx_h0_alloc1_num
            + cx_h0_alloc2_num,
          cx_h0_alloc3_insn, cx_h0_alloc3_len,
          32'd0, 3'd0, 32'd0, 3'd0);
      end
      cx_h0_next_token <= cx_h0_next_token + cx_h0_alloc_count;
    end

    if((cx_h0_terminal_count != 0 || cx_h1_terminal_count != 0
        || `CPU_TOP.x_ct_top_0.x_ct_core.x_ct_rtu_top.rtu_cp0_int_ack)
       && cx_trace_file != 0)
      $fflush(cx_trace_file);
  end
end
