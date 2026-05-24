# Silicon-Neurons

8x8 Pipelined TPU Tile (Matrix-Vector Multiplier)

This repository contains a high-performance, fully parallelized, and pipelined $8 \times 8$ Matrix-Vector Multiplication (MVM) Tile implemented in Verilog. The design is optimized for hardware efficiency (FPGA/ASIC) using a balanced Adder Tree structure and features an integrated ReLU Activation Function.
## Architecture Overview
The TPU Tile calculates the dot product of an $8 \times 8$ signed matrix and an $8 \times 1$ signed vector simultaneously across 8 parallel hardware rows (computing engines).Data Path Specifications:Inputs:matrix_in [511:0]: Representing an $8 \times 8$ matrix of 8-bit signed elements ($64 \times 8\text{-bit} = 512\text{-bits}$).vector_in [63:0]: Representing an $8 \times 1$ vector of 8-bit signed elements ($8 \times 8\text{-bit} = 64\text{-bits}$).Outputs:vector_out [191:0]: Representing the final $8 \times 1$ output vector. Each element is sign-extended to 24-bit signed format ($8 \times 24\text{-bit} = 192\text{-bits}$).
## Pipeline Design & Hardware Boundaries
To maintain high clock frequencies and maximize throughput, the architecture implements a 3-Stage Pipeline Assembly Line.Stage 1: Multiplication (MAC Units)Hardware: 64 parallel mac_unit instances perform $8\text{-bit} \times 8\text{-bit}$ signed multiplication.Output Boundary: 16-bit intermediate product registers (p0_0 to p7_7).Stage 2: Balanced Adder Tree (Partial Sums)Hardware: Standard + operators structured as a balanced tree to minimize combinational propagation delay.Logic: (p_0 + p_1) + (p_2 + p_3) and (p_4 + p_5) + (p_6 + p_7).Output Boundary: 18-bit pipeline registers (s_L2_L and s_L2_R) to accommodate bit growth and prevent overflow.Stage 3: Final Summation & ReLU ActivationHardware: Combinational 19-bit final adder (f_sum) followed by Sign-Bit Check Logic.ReLU Logic: Hardware inspects the Most Significant Bit (MSB/Sign-Bit) f_sum[18].If f_sum[18] == 1'b1 (Negative), output is forced to 24'd0.If f_sum[18] == 1'b0 (Positive/Zero), the value is sign-extended to 24-bits.Output Boundary: Final 24-bit vector_out registers.
## Timing Diagram (Clock Ticks Flow)
The control path (valid_in to valid_out) is fully synchronized with the data path. The system possesses a latency of 3 clock cycles with a throughput of 1 vector-result per cycle after the pipeline is full.


<img width="926" height="637" alt="image" src="https://github.com/user-attachments/assets/e68d623b-bde2-4e84-95cb-05b24a71eacf" />



## Module Descriptions1.
mac_unit.vA fundamental building block that executes signed sequential multiplication. It latches the 16-bit signed output product on the rising edge of the clock.2. 

tpu_tile.v The top-level module containing 8 parallel computing rows. It instantiates 64 MAC units, manages the internal pipeline registers for control signals (valid_p1, valid_p2, valid_p3), structures the adder trees, and maps the activation function to the output bus.

##EDA Playground link

https://edaplayground.com/x/D2zt

##Simulation Wveform (for provided tb file)


<img width="1439" height="309" alt="image" src="https://github.com/user-attachments/assets/8583ab97-ea70-44ac-95bd-bce8f6d12aae" />

