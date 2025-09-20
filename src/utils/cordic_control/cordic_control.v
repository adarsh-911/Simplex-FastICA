module CONTROL_MUX_CORDIC #(
  parameter DATA_WIDTH = 16,
  parameter CORDIC_STAGES = 16,
  parameter CORDIC_WIDTH = 22,
  parameter ANGLE_WIDTH = 16
) (
  input clk,
  input en,
  input nrst,

  input [1:0] block, // Current working block

  // GSO BLOCK
  input gso_cordic_vec_en,
  input gso_cordic_rot_en,

  input signed [DATA_WIDTH-1:0] gso_cordic_vec_xin,
  input signed [DATA_WIDTH-1:0] gso_cordic_vec_yin,
  input gso_cordic_vec_angle_calc_en,

  input [1:0] gso_cordic_rot_quad_in,
  input signed [DATA_WIDTH-1:0] gso_cordic_rot_xin,
  input signed [DATA_WIDTH-1:0] gso_cordic_rot_yin,
  input signed [ANGLE_WIDTH-1:0] gso_cordic_rot_angle_in,
  input [CORDIC_STAGES-1:0] gso_cordic_rot_microRot_ext_in,
  input gso_cordic_rot_angle_microRot_n,
  input gso_cordic_rot_microRot_ext_vld,
  input gso_cordic_nrst,

  // NORMALIZATION BLOCK
  input norm_cordic_vec_en,
  input norm_cordic_rot_en,

  input signed [DATA_WIDTH-1:0] norm_cordic_vec_xin,
  input signed [DATA_WIDTH-1:0] norm_cordic_vec_yin,
  input norm_cordic_vec_angle_calc_en,

  input [1:0] norm_cordic_rot_quad_in,
  input signed [DATA_WIDTH-1:0] norm_cordic_rot_xin,
  input signed [DATA_WIDTH-1:0] norm_cordic_rot_yin,
  input signed [ANGLE_WIDTH-1:0] norm_cordic_rot_angle_in,
  input [CORDIC_STAGES-1:0] norm_cordic_rot_microRot_ext_in,
  input norm_cordic_rot_angle_microRot_n,
  input norm_cordic_rot_microRot_ext_vld,
  input norm_cordic_nrst,

  // UPDATE BLOCK
  input updt_cordic_vec_en,
  input updt_cordic_rot_en,

  input signed [DATA_WIDTH-1:0] updt_cordic_vec_xin,
  input signed [DATA_WIDTH-1:0] updt_cordic_vec_yin,
  input updt_cordic_vec_angle_calc_en,

  input [1:0] updt_cordic_rot_quad_in,
  input signed [DATA_WIDTH-1:0] updt_cordic_rot_xin,
  input signed [DATA_WIDTH-1:0] updt_cordic_rot_yin,
  input signed [ANGLE_WIDTH-1:0] updt_cordic_rot_angle_in,
  input [CORDIC_STAGES-1:0] updt_cordic_rot_microRot_ext_in,
  input updt_cordic_rot_angle_microRot_n,
  input updt_cordic_rot_microRot_ext_vld,
  input updt_cordic_nrst,

  // ESTIMATION BLOCK
  input est_cordic_vec_en,
  input est_cordic_rot_en,

  input signed [DATA_WIDTH-1:0] est_cordic_vec_xin,
  input signed [DATA_WIDTH-1:0] est_cordic_vec_yin,
  input est_cordic_vec_angle_calc_en,

  input [1:0] est_cordic_rot_quad_in,
  input signed [DATA_WIDTH-1:0] est_cordic_rot_xin,
  input signed [DATA_WIDTH-1:0] est_cordic_rot_yin,
  input signed [ANGLE_WIDTH-1:0] est_cordic_rot_angle_in,
  input [CORDIC_STAGES-1:0] est_cordic_rot_microRot_ext_in,
  input est_cordic_rot_angle_microRot_n,
  input est_cordic_rot_microRot_ext_vld,
  input est_cordic_nrst,

  // OUTPUT TO CORDIC
  output reg cordic_vec_en,
  output reg cordic_rot_en,

  output reg signed [DATA_WIDTH-1:0] cordic_vec_xin,
  output reg signed [DATA_WIDTH-1:0] cordic_vec_yin,
  output reg cordic_vec_angle_calc_en,

  output reg [1:0] cordic_rot_quad_in,
  output reg signed [DATA_WIDTH-1:0] cordic_rot_xin,
  output reg signed [DATA_WIDTH-1:0] cordic_rot_yin,
  output reg signed [ANGLE_WIDTH-1:0] cordic_rot_angle_in,
  output reg [CORDIC_STAGES-1:0] cordic_rot_microRot_ext_in,
  output reg cordic_rot_angle_microRot_n,
  output reg cordic_rot_microRot_ext_vld,

  output reg nreset
);

always @(*) begin
  if (!nrst) begin
    cordic_vec_en <= 0;
    cordic_rot_en <= 0;
    cordic_vec_xin <= {DATA_WIDTH{1'b0}};
    cordic_vec_yin <= {DATA_WIDTH{1'b0}};
    cordic_vec_angle_calc_en <= 0;
    cordic_rot_quad_in <= 2'b00;
    cordic_rot_xin <= {DATA_WIDTH{1'b0}};
    cordic_rot_yin <= {DATA_WIDTH{1'b0}};
    cordic_rot_angle_in <= {ANGLE_WIDTH{1'b0}};
    cordic_rot_microRot_ext_in <= {CORDIC_STAGES{1'b0}};
    cordic_rot_angle_microRot_n <= 0;
    cordic_rot_microRot_ext_vld <= 0;
    nreset <= 0;
  end

  else if (en) begin
    case (block)
      2'b00 : begin
        // GSO CORDIC
        cordic_vec_en <= gso_cordic_vec_en;
        cordic_rot_en <= gso_cordic_rot_en;
        cordic_vec_xin <= gso_cordic_vec_xin;
        cordic_vec_yin <= gso_cordic_vec_yin;
        cordic_vec_angle_calc_en <= gso_cordic_vec_angle_calc_en;
        cordic_rot_quad_in <= gso_cordic_rot_quad_in;
        cordic_rot_xin <= gso_cordic_rot_xin;
        cordic_rot_yin <= gso_cordic_rot_yin;
        cordic_rot_angle_in <= gso_cordic_rot_angle_in;
        cordic_rot_microRot_ext_in <= gso_cordic_rot_microRot_ext_in;
        cordic_rot_angle_microRot_n <= gso_cordic_rot_angle_microRot_n;
        cordic_rot_microRot_ext_vld <= gso_cordic_rot_microRot_ext_vld;
        nreset <= gso_cordic_nrst;
      end

      2'b01 : begin
        // NORMALIZATION CORDIC
        cordic_vec_en <= norm_cordic_vec_en;
        cordic_rot_en <= norm_cordic_rot_en;
        cordic_vec_xin <= norm_cordic_vec_xin;
        cordic_vec_yin <= norm_cordic_vec_yin;
        cordic_vec_angle_calc_en <= norm_cordic_vec_angle_calc_en;
        cordic_rot_quad_in <= norm_cordic_rot_quad_in;
        cordic_rot_xin <= norm_cordic_rot_xin;
        cordic_rot_yin <= norm_cordic_rot_yin;
        cordic_rot_angle_in <= norm_cordic_rot_angle_in;
        cordic_rot_microRot_ext_in <= norm_cordic_rot_microRot_ext_in;
        cordic_rot_angle_microRot_n <= norm_cordic_rot_angle_microRot_n;
        cordic_rot_microRot_ext_vld <= norm_cordic_rot_microRot_ext_vld;
        nreset <= norm_cordic_nrst;
      end

      2'b10 : begin
        // UPDATE CORDIC
        cordic_vec_en <= updt_cordic_vec_en;
        cordic_rot_en <= updt_cordic_rot_en;
        cordic_vec_xin <= updt_cordic_vec_xin;
        cordic_vec_yin <= updt_cordic_vec_yin;
        cordic_vec_angle_calc_en <= updt_cordic_vec_angle_calc_en;
        cordic_rot_quad_in <= updt_cordic_rot_quad_in;
        cordic_rot_xin <= updt_cordic_rot_xin;
        cordic_rot_yin <= updt_cordic_rot_yin;
        cordic_rot_angle_in <= updt_cordic_rot_angle_in;
        cordic_rot_microRot_ext_in <= updt_cordic_rot_microRot_ext_in;
        cordic_rot_angle_microRot_n <= updt_cordic_rot_angle_microRot_n;
        cordic_rot_microRot_ext_vld <= updt_cordic_rot_microRot_ext_vld;
        nreset <= updt_cordic_nrst;
      end

      2'b11 : begin
        // ESTIMATION CORDIC
        cordic_vec_en <= est_cordic_vec_en;
        cordic_rot_en <= est_cordic_rot_en;
        cordic_vec_xin <= est_cordic_vec_xin;
        cordic_vec_yin <= est_cordic_vec_yin;
        cordic_vec_angle_calc_en <= est_cordic_vec_angle_calc_en;
        cordic_rot_quad_in <= est_cordic_rot_quad_in;
        cordic_rot_xin <= est_cordic_rot_xin;
        cordic_rot_yin <= est_cordic_rot_yin;
        cordic_rot_angle_in <= est_cordic_rot_angle_in;
        cordic_rot_microRot_ext_in <= est_cordic_rot_microRot_ext_in;
        cordic_rot_angle_microRot_n <= est_cordic_rot_angle_microRot_n;
        cordic_rot_microRot_ext_vld <= est_cordic_rot_microRot_ext_vld;
        nreset <= est_cordic_nrst;
      end
    endcase
  end
end
  
endmodule
