`timescale 1ns/1ps

module sica_tb #(
  parameter DATA_WIDTH = 32,
  parameter SAMPLES = 1024,
  parameter DIM = 5,
  parameter MAX_ITERATIONS = 500,
  parameter CORDIC_STAGES = 16,
  parameter CORDIC_WIDTH = 38,
  parameter FRAC_WIDTH = 20,
  parameter LOGM = 10,
  parameter ANGLE_WIDTH = 16
) ();

  reg clk;
  reg signed [DATA_WIDTH-1:0] serial_z_in;
  integer file, r, idx, i;

  reg signed [DATA_WIDTH-1:0] channel_data [0:DIM*SAMPLES-1];
  reg signed [DATA_WIDTH-1:0] temp_int;

  reg nreset;
  reg start;
  reg z_valid;
  reg load_data;
  wire done;
  wire signed [DATA_WIDTH*DIM*SAMPLES-1:0] s_est;

  localparam CLK_CYCLES = 15000;

  sica_top #(
    .DATA_WIDTH(DATA_WIDTH),
    .DIM(DIM),
    .SAMPLES(SAMPLES),
    .MAX_ITERATIONS(MAX_ITERATIONS),
    .CORDIC_WIDTH(CORDIC_WIDTH),
    .ANGLE_WIDTH(ANGLE_WIDTH),
    .FRAC_WIDTH(FRAC_WIDTH),
    .LOGM(LOGM),
    .CORDIC_STAGES(CORDIC_STAGES)
  ) sica_dut (
    .clk(clk),
    .nreset(nreset),
    .sica_start(start),
    .serial_z_in(serial_z_in),
    .serial_z_valid(z_valid),
    .sica_complete(done),
    .load_data(load_data),
    .s_est(s_est)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    idx = 0;

    file = $fopen("dataset/testVectors/channel_1/window_mix_001.txt", "r");
    for (i = 0 ; i < SAMPLES ; i = i+1) begin
      r = $fscanf(file, "%d\n", temp_int);
      channel_data[idx] = temp_int;
      idx = idx + 1;
    end
    $fclose(file);

    file = $fopen("dataset/testVectors/channel_2/window_mix_001.txt", "r");
    for (i = 0 ; i < SAMPLES ; i = i+1) begin
      r = $fscanf(file, "%d\n", temp_int);
      channel_data[idx] = temp_int;
      idx = idx + 1;
    end
    $fclose(file);

    file = $fopen("dataset/testVectors/channel_3/window_mix_001.txt", "r");
    for (i = 0 ; i < SAMPLES ; i = i+1) begin
      r = $fscanf(file, "%d\n", temp_int);
      channel_data[idx] = temp_int;
      idx = idx + 1;
    end
    $fclose(file);

    file = $fopen("dataset/testVectors/channel_4/window_mix_001.txt", "r");
    for (i = 0 ; i < SAMPLES ; i = i+1) begin
      r = $fscanf(file, "%d\n", temp_int);
      channel_data[idx] = temp_int;
      idx = idx + 1;
    end
    $fclose(file);

    file = $fopen("dataset/testVectors/channel_5/window_mix_001.txt", "r");
    for (i = 0 ; i < SAMPLES ; i = i+1) begin
      r = $fscanf(file, "%d\n", temp_int);
      channel_data[idx] = temp_int;
      idx = idx + 1;
    end
    $fclose(file);
  end

 initial begin
  idx = 0;
  nreset = 0;
  z_valid = 0;
  serial_z_in = 0;
  load_data = 0;

  repeat(5) @(posedge clk);
  nreset = 1;

  repeat(2) @(posedge clk);
  z_valid = 1;
  load_data = 1;

  forever begin
    @(posedge clk);
    serial_z_in = channel_data[idx];
    idx = idx + 1;
    if (idx == DIM*SAMPLES) load_data = 0;
  end

  #(CLK_CYCLES) $finish;
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, sica_tb);
end

endmodule
