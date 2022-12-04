module edge_detector (
    input  d,
    input  clk,
    input  rst,
    output out_posedge,
    output out_negedge
);

reg q;

    always @(posedge clk or negedge rst)
    begin
        
        if (rst) begin
            q <= 1'b0;
        end

        else begin
            q <= d;
        end

    end

    assign out_posedge = D &~q;                     // Positive Edge Detection Logic
    assign out_negedge = ~D &q;                     // Negative Edge Detection Logic

endmodule