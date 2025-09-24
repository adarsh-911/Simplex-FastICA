module updateTop #(
    parameter N = 7,
    parameter M = 1024,
    parameter DATA_WIDTH = 16,
    parameter FRAC_WIDTH = 10,
    parameter CORDIC_WIDTH = 22,
    parameter ANGLE_WIDTH = 16,
    parameter CORDIC_STAGES = 16,
    parameter LOGM = 10
) (
    input                          clk,
    input                          rst_n,
    input                          en,
    input  [N*DATA_WIDTH-1:0]      W_in,
    input  [N*M*DATA_WIDTH-1:0]    Z_in, 

    input                          cordic_vec_opvld,
    input  signed [DATA_WIDTH-1:0] cordic_vec_xout,
    input  [1:0]                   cordic_vec_quad_out,
    input                          cordic_vec_microRot_out_start,

    input                          cordic_rot1_opvld,
    input  signed [DATA_WIDTH-1:0] cordic_rot1_xout,

    output reg                     ica_cordic_vec_en,
    output reg signed [DATA_WIDTH-1:0] ica_cordic_vec_xin,
    output reg signed [DATA_WIDTH-1:0] ica_cordic_vec_yin,
    output reg                     ica_cordic_vec_angle_calc_en,
    output reg                     ica_cordic_rot1_en,
    output reg signed [DATA_WIDTH-1:0] ica_cordic_rot1_xin,
    output reg signed [DATA_WIDTH-1:0] ica_cordic_rot1_yin,
    output reg signed [ANGLE_WIDTH-1:0] ica_cordic_rot1_angle_in,
    output reg                     ica_cordic_rot1_angle_microRot_n,
    output reg [CORDIC_STAGES-1:0] ica_cordic_rot1_microRot_ext_in,
    output reg                     ica_cordic_rot1_microRot_ext_vld,
    output reg [1:0]               ica_cordic_rot1_quad_in,

    output reg [N*DATA_WIDTH-1:0]   W_out,
    output reg                     output_valid
);

    // G_kin cube latched for processing
    reg [M*DATA_WIDTH-1:0]         G_kin_cube;
    // Norm of G^3
    reg signed [DATA_WIDTH-1:0]    G_norm_cube;
    // output P vector
    reg [N*DATA_WIDTH-1:0]         P_vector;

    // upto N=7
    reg [2:0]  Ncounter;
    // upto M=1024
    reg [9:0]  Mcounter;
    reg [1:0]  stage_counter;

    /// temporary registers
    wire signed [3*DATA_WIDTH-1:0] cube_temp;
    assign cube_temp = (cordic_rot1_xout * cordic_rot1_xout * cordic_rot1_xout);
    // vedic_cube_32 cuber (
    //     .a(cordic_rot1_xout),
    //     .cube(cube_temp)
    // );

    wire signed [2*DATA_WIDTH-1:0] ZG1;
    assign ZG1 = (Z_wire[(Mcounter-1)*N + Ncounter] * G_norm_cube);
    wire signed [2*DATA_WIDTH-1:0] ZG2;
    assign ZG2 = (Z_wire[(Mcounter)*N + Ncounter] * G_norm_cube);
    
    /////////// Only because vivado does not support unpacked arrays as input ports
    wire signed [DATA_WIDTH-1:0] W_wire [0:N-1];
    wire signed [DATA_WIDTH-1:0] Z_wire [0:N*M-1];
    wire signed [DATA_WIDTH-1:0] G_wire [0:M-1];
    wire signed [DATA_WIDTH-1:0] P_wire [0:N-1];
    
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_w_wires
            assign W_wire[i] = W_in[i*DATA_WIDTH +: DATA_WIDTH];
        end
        
        for (i = 0; i < N*M; i = i + 1) begin : gen_z_wires  
            assign Z_wire[i] = Z_in[i*DATA_WIDTH +: DATA_WIDTH];
        end
        
        for (i = 0; i < M; i = i + 1) begin : gen_g_wires
            assign G_wire[i] = G_kin_cube[i*DATA_WIDTH +: DATA_WIDTH];
        end
        
        for (i = 0; i < N; i = i + 1) begin : gen_p_wires
            assign P_wire[i] = P_vector[i*DATA_WIDTH +: DATA_WIDTH];
        end
    endgenerate
    //////////////////

    // Condition wires to reduce LUT usage
    wire ncounter_le_n2 = (Ncounter <= N-2);
    wire ncounter_eq_0 = (Ncounter == 0);
    wire ncounter_eq_1 = (Ncounter == 1);
    wire mcounter_lt_m1 = (Mcounter < M-1);
    wire mcounter_eq_m1 = (Mcounter == M-1);
    wire mcounter_eq_0 = (Mcounter == 0);
    wire mcounter_eq_1 = (Mcounter == 1);
    wire mcounter_le_m2 = (Mcounter <= M-2);
    wire ncounter_lt_n1 = (Ncounter < N-1);
    wire ncounter_eq_n1 = (Ncounter == N-1);

    // Cubing module signals
    reg                            cuber_start;
    reg  signed [DATA_WIDTH-1:0]   cuber_data_in;
    wire signed [DATA_WIDTH-1:0]   cuber_out;
    wire                           cuber_valid;
    reg                            cube_ready;

    sequential_cuber #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_WIDTH(FRAC_WIDTH)
    ) cuber_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(cuber_start),
        .data_in(cuber_data_in),
        .cube_out(cuber_out),
        .valid_out(cuber_valid)
    );
    
    integer j;
 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            G_kin_cube <= {M*DATA_WIDTH{1'b0}};
            G_norm_cube <= {DATA_WIDTH{1'b0}};
            P_vector <= {(N*DATA_WIDTH){1'b0}};
            Ncounter <= 0;
            Mcounter <= 0;
            stage_counter <= 2'b00;
            ica_cordic_vec_en <= 1'b0;
            ica_cordic_vec_xin <= {DATA_WIDTH{1'b0}};
            ica_cordic_vec_yin <= {DATA_WIDTH{1'b0}};
            ica_cordic_vec_angle_calc_en <= 1'b0;
            ica_cordic_rot1_en <= 1'b0;
            ica_cordic_rot1_xin <= {DATA_WIDTH{1'b0}};
            ica_cordic_rot1_yin <= {DATA_WIDTH{1'b0}};
            ica_cordic_rot1_angle_in <= {ANGLE_WIDTH{1'b0}};
            ica_cordic_rot1_angle_microRot_n <= 1'b0;
            ica_cordic_rot1_microRot_ext_in <= {CORDIC_STAGES{1'b0}};
            ica_cordic_rot1_microRot_ext_vld <= 1'b0;
            ica_cordic_rot1_quad_in <= 2'b00;
            W_out <= {(N*DATA_WIDTH){1'b0}};
            output_valid <= 1'b0;
            cuber_start <= 1'b0;
            cuber_data_in <= {DATA_WIDTH{1'b0}};
        end else if (en) begin
            ica_cordic_vec_en <= 1'b0;
            ica_cordic_rot1_en <= 1'b0;
            output_valid <= 1'b0;
            cuber_start <= 1'b0;
            
            if (cuber_valid) begin
                if (mcounter_eq_0) begin
                    G_kin_cube[(M-1)*DATA_WIDTH +: DATA_WIDTH] <= cuber_out;
                    Ncounter <= 0;
                    stage_counter <= 2'b01;
                end
                else begin
                    G_kin_cube[(Mcounter-1)*DATA_WIDTH +: DATA_WIDTH] <= cuber_out;
                end
            end


            case (stage_counter)
                2'b00: begin
                    if (cordic_vec_microRot_out_start) begin
                        ica_cordic_rot1_en <= 1'b1;
                        ica_cordic_rot1_xin <= ncounter_eq_1 ? Z_wire[Mcounter*N + 0] : Z_wire[Mcounter*N + Ncounter];
                        ica_cordic_rot1_yin <= ncounter_eq_1 ? Z_wire[Mcounter*N + 1] : cordic_rot1_xout;
                        ica_cordic_rot1_angle_in <= {ANGLE_WIDTH{1'b0}};
                        ica_cordic_rot1_angle_microRot_n <= 1'b0;
                        ica_cordic_rot1_microRot_ext_in <= {CORDIC_STAGES{1'b0}};
                        ica_cordic_rot1_microRot_ext_vld <= 1'b0;
                        ica_cordic_rot1_quad_in <= cordic_vec_quad_out;
                    end
                    if (ncounter_le_n2) begin
                        if (ncounter_eq_0) begin
                            ica_cordic_vec_en <= 1'b1;
                            ica_cordic_vec_xin <= W_wire[0];
                            ica_cordic_vec_yin <= W_wire[1];
                            ica_cordic_vec_angle_calc_en <= 1'b1;
                            Ncounter <= Ncounter + 1;
                        end
                        else if (cordic_rot1_opvld == 1) begin
                            ica_cordic_vec_en <= 1'b1;
                            ica_cordic_vec_xin <= W_wire[Ncounter+1];
                            ica_cordic_vec_yin <= cordic_vec_xout;
                            ica_cordic_vec_angle_calc_en <= 1'b1;
                            Ncounter <= Ncounter + 1;
                        end
                    end
                    else if (mcounter_lt_m1 && cordic_rot1_opvld == 1) begin
                        Ncounter <= 0;
                        cuber_start <= 1'b1;
                        cuber_data_in <= cordic_rot1_xout;
                        // G_kin_cube[Mcounter*DATA_WIDTH +: DATA_WIDTH] <= ((cube_temp) >>> (2*FRAC_WIDTH));
                        Mcounter <= Mcounter + 1;
                    end
                    else if (mcounter_eq_m1 && cordic_rot1_opvld == 1) begin
                        cuber_start <= 1'b1;
                        cuber_data_in <= cordic_rot1_xout;
                        // G_kin_cube[Mcounter*DATA_WIDTH +: DATA_WIDTH] <= ((cube_temp) >>> (2*FRAC_WIDTH));
                        Mcounter <= 0;
                        // stage_counter <= 2'b01;
                    end
                end
                2'b01: begin
                    if (mcounter_eq_0) begin
                        ica_cordic_vec_en <= 1'b1;
                        ica_cordic_vec_xin <= G_wire[0];
                        ica_cordic_vec_yin <= G_wire[1];
                        ica_cordic_vec_angle_calc_en <= 1'b0;
                        Mcounter <= Mcounter + 1;
                    end
                    else if (mcounter_lt_m1 && cordic_vec_opvld == 1) begin
                        ica_cordic_vec_en <= 1'b1;
                        ica_cordic_vec_xin <= G_wire[Mcounter+1];
                        ica_cordic_vec_yin <= cordic_vec_xout;
                        ica_cordic_vec_angle_calc_en <= 1'b0;
                        Mcounter <= Mcounter + 1;
                    end
                    else if (mcounter_eq_m1 && cordic_vec_opvld == 1) begin
                        G_norm_cube <= cordic_vec_xout;
                        Mcounter <= 0;
                        stage_counter <= 2'b10;
                    end
                end
                2'b10: begin
                    if (cordic_vec_microRot_out_start) begin
                        ica_cordic_rot1_en <= 1'b1;
                        ica_cordic_rot1_xin <= mcounter_eq_1 ? ZG1 >>> FRAC_WIDTH : ZG2 >>> FRAC_WIDTH;
                        // ZG1 definition (Z_wire[(Mcounter-1)*N + Ncounter] * G_norm_cube);
                        ica_cordic_rot1_yin <= mcounter_eq_1 ? (ZG2) >>> FRAC_WIDTH : cordic_rot1_xout;
                        ica_cordic_rot1_angle_in <= {ANGLE_WIDTH{1'b0}};
                        ica_cordic_rot1_angle_microRot_n <= 1'b0;
                        ica_cordic_rot1_microRot_ext_in <= {CORDIC_STAGES{1'b0}};
                        ica_cordic_rot1_microRot_ext_vld <= 1'b0;
                        ica_cordic_rot1_quad_in <= cordic_vec_quad_out;
                    end
                    if (mcounter_le_m2) begin
                        if (mcounter_eq_0) begin
                            ica_cordic_vec_en <= 1'b1;
                            ica_cordic_vec_xin <= G_wire[0];
                            ica_cordic_vec_yin <= G_wire[1];
                            ica_cordic_vec_angle_calc_en <= 1'b0;
                            Mcounter <= Mcounter + 1;
                        end
                        else if (cordic_rot1_opvld == 1) begin
                            ica_cordic_vec_en <= 1'b1;
                            ica_cordic_vec_xin <= G_wire[Mcounter+1];
                            ica_cordic_vec_yin <= cordic_vec_xout;
                            ica_cordic_vec_angle_calc_en <= 1'b0;
                            Mcounter <= Mcounter + 1;
                        end
                    end
                    else if (ncounter_lt_n1 && cordic_rot1_opvld == 1) begin
                        Mcounter <= 0;
                        P_vector[Ncounter*DATA_WIDTH +: DATA_WIDTH] <= cordic_rot1_xout;
                        Ncounter <= Ncounter + 1;
                    end
                    else if (ncounter_eq_n1 && cordic_rot1_opvld == 1) begin
                        P_vector[Ncounter*DATA_WIDTH +: DATA_WIDTH] <= cordic_rot1_xout;
                        Mcounter <= 0;
                        Ncounter <= 0;
                        stage_counter <= 2'b11;
                    end
                end
                2'b11: begin
                    for (j = 0; j < N; j = j + 1) begin
                        W_out[j*DATA_WIDTH +: DATA_WIDTH] <= (P_wire[j] >>> LOGM) - (3*W_wire[j]);
                    end
                    output_valid <= 1'b1;
                    stage_counter <= 2'b00;
                end
                default: stage_counter <= 2'b00;
            endcase
        end
        else begin
            ica_cordic_vec_en                <= 1'b0;
            ica_cordic_vec_xin               <= {DATA_WIDTH{1'b0}};
            ica_cordic_vec_yin               <= {DATA_WIDTH{1'b0}};
            ica_cordic_vec_angle_calc_en     <= 1'b0;
            ica_cordic_rot1_en               <= 1'b0;
            ica_cordic_rot1_xin              <= {DATA_WIDTH{1'b0}};
            ica_cordic_rot1_yin              <= {DATA_WIDTH{1'b0}};
            ica_cordic_rot1_angle_in         <= {ANGLE_WIDTH{1'b0}};
            ica_cordic_rot1_angle_microRot_n <= 1'b0;
            ica_cordic_rot1_microRot_ext_in  <= {CORDIC_STAGES{1'b0}};
            ica_cordic_rot1_microRot_ext_vld <= 1'b0;
            ica_cordic_rot1_quad_in          <= 2'b00;
            W_out                            <= {(N*DATA_WIDTH){1'b0}};
            output_valid                     <= 1'b0;
        end
    end

endmodule