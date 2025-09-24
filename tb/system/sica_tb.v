`timescale 1ns/1ps

module sica_tb #(
  parameter DATA_WIDTH = 32,
  parameter SAMPLES = 1024,
  parameter DIM = 5
) ();

  reg clk;
  reg signed [DATA_WIDTH-1:0] serial_z_in;
  integer file, r, idx, i;

  reg signed [DATA_WIDTH-1:0] channel_data [0:DIM*SAMPLES-1];
  reg signed [DATA_WIDTH-1:0] temp_int;

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
    @(posedge clk);
    forever begin
      @(posedge clk);
      serial_z_in = channel_data[idx];
      //$display("Cycle %0d: %d", idx, data_reg);
      idx = idx + 1;
      if (idx == DIM*SAMPLES) $finish;
    end
  end

endmodule
