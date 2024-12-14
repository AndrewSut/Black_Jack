module lfsr_cards (
    input wire clk,           // Clock signal
    input wire reset,         // Reset signal
    input wire enable,
    input wire seed,
    output reg ace_pres,
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
            lfsr_reg <= 4'b1010; // removed seed
            out <= 4'b0000;
        end else if(enable == 1'b1) begin
        // Shift the LFSR and apply the feedback
            lfsr_reg <= {lfsr_reg[2:0], feedback};

            if(lfsr_reg > 4'd10) begin lfsr_reg[3] <= 1'b0; end
            if(lfsr_reg == 4'd0) lfsr_reg <= 4'd1;
            
            out <= lfsr_reg;

            if(out == 4'd1) ace_pres <= 1'b1;
            else ace_pres <= 1'b0;

        end
        else begin 
            lfsr_reg <= seed; out <= 4'b0000; 
        end
    end
    
endmodule
