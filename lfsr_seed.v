module lfsr_seed (
    input wire clk,           // Clock signal
    input wire reset,         // Reset signal
    input wire enable,        // Enable signal
    output reg [3:0] out      // 4-bit output
);
    
    // Internal signal for the LFSR state
    reg [3:0] lfsr_reg;  // 4-bit LFSR register
    
    // Feedback polynomial: x^4 + x + 1 (one of the possible feedback taps)
    wire feedback;
    assign feedback = lfsr_reg[3] ^ lfsr_reg[0];  // XOR the taps at bit 3 and bit 0
    
    always @(posedge clk or negedge reset) begin
        if (reset == 1'b0) begin
            // On reset, set the LFSR to a non-zero value (to avoid locking at zero)
            lfsr_reg <= 4'b0101;
            out <= 4'b0001;
        end
        else if (enable == 1'b1) begin
            // Shift the LFSR and apply the feedback
            lfsr_reg <= {lfsr_reg[2:0], feedback};
            out <= lfsr_reg;
        end
    end
    
endmodule
