module sica_top#(
    parameter DATA_WIDTH = 32,
    parameter CORDIC_WIDTH = 22,
    parameter ANGLE_WIDTH = 16,
    parameter CORDIC_STAGES = 16,
    parameter MAX_ITERATIONS = 1000,
    parameter VECTOR_DIM = 7
)(
    // Clock and active low reset signal
    input clk,
    input nreset, 
    input sica_start, // Flag signal from the top most module to start the SICA process
    input signed [DATA_WIDTH-1: 0] z_samples
);

    // FSM States 
    localparam S_IDLE              = 0;
    localparam S_INIT_K            = 1;
    localparam S_GSO               = 2;
    localparam S_CHECK_SIMPLEX     = 3;
    localparam S_ITER_LOOP_INIT    = 4; // iter count init
    localparam S_NORMALIZE         = 5;
    localparam S_CONVERGENCE_CHECK = 6;
    localparam S_UPDATE            = 7;
    localparam S_FINISH_K          = 8;
    localparam S_ALL_DONE          = 9;

    // Flags
    reg gso_start;
    reg gso_done;
    reg normalize_start;
    reg normalize_done;
    reg start;
    reg finish;

    // Parameters
   
    
    // Temp
    reg [3:0] state;
    reg signed [DATA_WIDTH-1:0] w_init_k [0:VECTOR_DIM-1];
    reg signed [DATA_WIDTH-1:0] w_curr_k [0:VECTOR_DIM-1];
    reg signed [DATA_WIDTH-1:0] w_prev_k [0:VECTOR_DIM-1];
    reg signed [DATA_WIDTH-1:0] w_conv [0:VECTOR_DIM-1][0:VECTOR_DIM-1];

    wire signed [DATA_WIDTH-1:0] normalized_out [0:VECTOR_DIM-1];



    // Counters and indices
    reg [$clog2(VECTOR_DIM):0] k; // Current vector index (1 to n)
    reg [$clog2(MAX_ITERATIONS):0] iter_count;

    always@(posedge clk or negedge nreset) begin
        if(!nreset) begin
            k <= 0;
            state <= S_IDLE;
        end
        else begin
            case(state)
                S_IDLE: begin
                    if(sica_start) begin
                    state <= S_INIT_K;
                    end
                end
                S_INIT_K: begin
                    finish <= 0;
                    k <= 1;
                    state <= S_GSO;
                end
                S_GSO: begin
                    if (k == 1) state = S_CHECK_SIMPLEX;

                    gso_start <= 1;
                    if (gso_done) begin
                        state <= S_CHECK_SIMPLEX;
                    end
                end
                S_CHECK_SIMPLEX: begin
                    state <= (k == VECTOR_DIM) ? S_FINISH_K : S_ITER_LOOP_INIT;
                end
                S_ITER_LOOP_INIT: begin
                    iter_count <= 0;
                    state <= S_NORMALIZE;
                end
                S_NORMALIZE: begin
                    normalize_start <= 1;

                    if (normalize_done) begin
                        w_prev_k <= w_curr_k;
                        w_curr_k <= normalized_out;
                        state <= S_CONVERGENCE_CHECK;
                    end
                end
                S_CONVERGENCE_CHECK: begin
                    if (((w_prev_k - w_curr_k) < TOL && (w_prev_k - w_curr_k) > 0) || ((w_curr_k - w_prev_k) < TOL && (w_curr_k - w_prev_k) > 0))
                        state <= S_FINISH_K;
                    else state <= S_UPDATE;
                end
                S_UPDATE: begin
                    w_curr_k <= w_prev_k;
                    iter_count <= iter_count + 1;
                    state <= S_GSO;
                end
                S_FINISH_K: begin
                    w_conv[k-1] <= w_curr_k;
                    if (k < VECTOR_DIM) begin
                        k <= k + 1;
                        w_curr_k <= w_init_k[k + 1];
                        state <= S_GSO;
                    end
                    else begin
                        state <= S_ALL_DONE;
                    end
                end
                S_ALL_DONE: begin
                    finish <= 1;
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule