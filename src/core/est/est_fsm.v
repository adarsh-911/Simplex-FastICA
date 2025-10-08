module ESTIMATION #(
  parameter DATA_WIDTH = 16,
  parameter DIM = 3,
  parameter EXT_DIM = 4,
  parameter SAMPLES = 4
) (
  input en,
  input rstn,
  input clk,
  input signed [0:DATA_WIDTH*DIM*SAMPLES-1] Z_in,
  input signed [0:DATA_WIDTH*DIM*DIM-1] W_mat,
  output reg est_opvld,
  output reg signed [0:DATA_WIDTH*DIM*SAMPLES-1] S_est,

  output reg start_dot_product,
  output reg rstn_dot,
  input wire dot_product_done,
  output reg signed [0:DATA_WIDTH*EXT_DIM-1] vector_a,
  output reg signed [0:DATA_WIDTH*EXT_DIM-1] vector_b,
  input wire signed [DATA_WIDTH-1:0] dot_product_result
);

reg [3:0] w_count, z_count;
reg [2:0] state;
reg done_flag;

integer i, j;

parameter IDLE = 0;
parameter LOAD_VEC = 1;
parameter CAL_DOT_PRODUCT = 2;
parameter STORE = 3;
parameter INCR = 4;
parameter DONE = 5;

always @(posedge clk) begin
  if (!rstn) begin
    for (i = 0 ; i < DIM ; i = i + 1) begin
      for (j = 0 ; j < SAMPLES ; j = j + 1) begin
        S_est[(i*SAMPLES + j)*DATA_WIDTH +: DATA_WIDTH] <= {DATA_WIDTH{1'b0}};
      end
    end

    state <= IDLE;
    est_opvld <= 0;
    rstn_dot <= 0;
    w_count <= 0;
    z_count <= 0;
  end

  else if (en) begin

    case (state)
      IDLE : begin
        w_count <= 0;
        z_count <= 0;

        state <= LOAD_VEC;
        est_opvld <= 0;
      end

      LOAD_VEC : begin
        
        for (i = 0 ; i < DIM ; i = i + 1) begin
          vector_a[(i*DATA_WIDTH) +: DATA_WIDTH] <= W_mat[(i*DIM + w_count)*DATA_WIDTH +: DATA_WIDTH];
          vector_b[(i*DATA_WIDTH) +: DATA_WIDTH] <= Z_in[(i*SAMPLES + z_count)*DATA_WIDTH +: DATA_WIDTH];
        end

        if (EXT_DIM != DIM) begin
          vector_a[(EXT_DIM-1)*DATA_WIDTH +: DATA_WIDTH] <= 0;
          vector_b[(EXT_DIM-1)*DATA_WIDTH +: DATA_WIDTH] <= 0;
        end

        rstn_dot <= 1;
        state <= CAL_DOT_PRODUCT;
      end

      CAL_DOT_PRODUCT : begin
        start_dot_product <= 1;
        state <= STORE;
      end

      STORE : begin
        if (dot_product_done) begin
          S_est[(w_count*SAMPLES + z_count)*DATA_WIDTH +: DATA_WIDTH] <= dot_product_result;
          start_dot_product <= 0;
          state <= INCR;
        end
      end

      INCR : begin
        if (z_count == SAMPLES - 1) begin
          z_count <= 0;

          if (w_count == DIM - 1) begin
            state <= DONE;
            w_count <= 0;
          end else begin
            w_count <= w_count + 1;
            state <= LOAD_VEC;
          end

        end else begin
          z_count <= z_count + 1;
          state <= LOAD_VEC;
        end
        rstn_dot <= 0;
      end

      DONE : begin
        est_opvld <= 1;
        state <= IDLE;
      end
    endcase

  end else begin

    if (state == IDLE) est_opvld <= 0;
  end
end
  
endmodule
