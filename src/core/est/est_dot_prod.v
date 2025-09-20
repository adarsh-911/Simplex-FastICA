module COMPUTE_DOT_PRODUCT2D #(
  parameter DATA_WIDTH = 16,
  parameter EXT_DIM = 4,
  parameter ANGLE_WIDTH = 16,
  parameter CORDIC_STAGES = 16
) (
  input clk,
  input rstn,
  input start,
  input signed [0:DATA_WIDTH*EXT_DIM-1] vector_a,
  input signed [0:DATA_WIDTH*EXT_DIM-1] vector_b,
  output reg done,
  output reg signed [DATA_WIDTH-1:0] result,

  // CORDIC IO
  output reg cordic_vec_en,
  output reg cordic_rot_en,

  output reg signed [DATA_WIDTH-1:0] cordic_vec_xin,
  output reg signed [DATA_WIDTH-1:0] cordic_vec_yin,

  output reg [1:0] cordic_rot_quad_in,
  output reg signed [DATA_WIDTH-1:0] cordic_rot_xin,
  output reg signed [DATA_WIDTH-1:0] cordic_rot_yin,
  output reg cordic_rot_angle_microRot_n,

  input wire cordic_vec_opvld,
  input wire signed [DATA_WIDTH-1:0] cordic_vec_xout,
  input wire signed [ANGLE_WIDTH-1:0] vec_angle_out,

  input wire cordic_rot_opvld,
  input wire signed [DATA_WIDTH-1:0] cordic_rot_xout,
  input wire signed [DATA_WIDTH-1:0] cordic_rot_yout,

  output reg cordic_nrst,
  input wire [1:0] vec_quad
);

reg [4:0] count;
reg [DATA_WIDTH-1:0] accum;

reg [DATA_WIDTH-1:0] vec1 [0:1];
reg [DATA_WIDTH-1:0] vec2 [0:1];

parameter IDLE = 0;
parameter INIT_PAIR = 1;
parameter VECTORING = 2;
parameter ROTATING = 3;
parameter ROTATE_EN = 4;
parameter ACCUMULATE = 5;
parameter DONE = 6;

reg [2:0] state;

always @(posedge clk) begin
  if (!rstn) begin
    result <= 0;
    done <= 0;

    cordic_vec_en <= 1'b0;
    cordic_rot_en <= 1'b0;
    {cordic_vec_xin, cordic_vec_yin} <= {{DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b0}}};
    {cordic_rot_xin, cordic_rot_yin} <= {{DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b0}}};
    cordic_rot_angle_microRot_n <= 1'b0;
    cordic_nrst <= 0;
    
    accum <= {DATA_WIDTH{1'b0}};

    state <= IDLE;
  end

  else if (start) begin
    
    case (state)

      IDLE : begin
        count <= 0;
        cordic_vec_en <= 1'b0;
        cordic_rot_en <= 1'b0;
        state <= INIT_PAIR;
      end

      INIT_PAIR : begin
        vec1[0] <= vector_a[(count*DATA_WIDTH) +: DATA_WIDTH];
        vec1[1] <= vector_a[((count+1)*DATA_WIDTH) +: DATA_WIDTH];

        vec2[0] <= vector_b[(count*DATA_WIDTH) +: DATA_WIDTH];
        vec2[1] <= vector_b[((count+1)*DATA_WIDTH) +: DATA_WIDTH];

        cordic_vec_en <= 1'b0;
        cordic_rot_en <= 1'b0;
        cordic_rot_angle_microRot_n <= 1'b0;

        cordic_nrst <= 1;

        state <= VECTORING;
      end

      VECTORING : begin
        cordic_vec_xin <= vec1[0];
        cordic_vec_yin <= vec1[1];
        cordic_vec_en <= 1'b1;

        state <= ROTATING;
      end

      ROTATING : begin
        
        if (cordic_vec_opvld) begin

          cordic_rot_xin <= vec2[0];
          cordic_rot_yin <= vec2[1];
          cordic_rot_quad_in <= vec_quad;

          state <= ROTATE_EN;
        end
      end

      ROTATE_EN : begin
        cordic_rot_en <= 1'b1;

        state <= ACCUMULATE;
      end

      ACCUMULATE : begin
        
        if (cordic_rot_opvld) begin
          accum <= accum + (cordic_vec_xout * cordic_rot_xout);

          if (count == EXT_DIM - 2) state <= DONE;
          else begin
            count <= count + 2;
            state <= INIT_PAIR;
          end

          cordic_nrst <= 0;
        end
      end

      DONE : begin
        done <= 1;
        state <= IDLE;
      end
    endcase
  end
end

always @(*) begin
  if (done) begin
    result = accum;
  end
end
  
endmodule