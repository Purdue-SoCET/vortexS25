module dtt #(
    parameter WARP_COUNT = 32,   
    parameter THREADS_PER_WARP = 32,  
    parameter PC_WIDTH = 32  
)(
    input clk,
    input rst,
    
    // Input: New divergence detected
    input logic divergence_detected,  
    input logic [4:0] warp_id,  
    input logic [THREADS_PER_WARP-1:0] active_mask,  
    input logic [PC_WIDTH-1:0] branch_pc,  
    
    // Output: Signals threads offloaded to scalar core
    output logic scalar_dispatch,  
    output logic [4:0] scalar_warp_id,  
    output logic [THREADS_PER_WARP-1:0] scalar_thread_mask,  
    output logic [PC_WIDTH-1:0] scalar_pc,  
    
    // Input: Reconvergence signal from scalar execution
    input reconverge_done,
    input [4:0] reconverging_warp_id
);

    logic [THREADS_PER_WARP-1:0] dtt [0:WARP_COUNT-1];  
    logic [PC_WIDTH-1:0] dtt_pc [0:WARP_COUNT-1];  

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scalar_dispatch <= '0;
        end else begin
            // If a divergence is detected
            scalar_dispatch <= '0;
            if (divergence_detected) begin
                dtt[warp_id] <= active_mask;  
                dtt_pc[warp_id] <= branch_pc;  
                
                // Dispatch to scalar core if threshold exceeded
                scalar_dispatch <= '1;
                scalar_warp_id <= warp_id;
                scalar_thread_mask <= active_mask;
                scalar_pc <= branch_pc;
            end
            // When reconvergence completes, clear the entry
            if (reconverge_done) begin
                dtt[reconverging_warp_id] <= '0;
                dtt_pc[reconverging_warp_id] <= '0;
            end
        end
    end
endmodule
