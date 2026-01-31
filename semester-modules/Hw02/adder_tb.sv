module four_bit_addr_tb();

    logic [3:0] a;
    logic [3:0] b;
    logic cin;
    logic [3:0] sum;
    logic co;

    four_bit_addr iDUT (.A(a), .B(b), .Cin(cin), .Sum(sum), .Co(co));

    // index variables
    int a_index;
    int b_index;
    int cin_index;

    // Signals we will use to exhaustively test the adder
    logic [3:0] sum_ref;
    logic co_ref;
    assign {co_ref, sum_ref} = a + b + cin; // reference adder signals we will test against


    initial begin

        // loop through every combniation of a value, b value, and carry in
        for (a_index = 0; a_index < 5'h10; a_index++) begin
            for (b_index = 0; b_index < 5'h10; b_index++) begin
                for (cin_index = 0; cin_index < 2'b10; cin_index++) begin
                    a   = a_index;
                    b   = b_index;
                    cin = cin_index;

                    #1; // allow propagation

                    // Ensure adder module matches reference values
                    if ((sum !== sum_ref) || (co !== co_ref)) begin
                        $display("ERROR: a=%0d b=%0d cin=%0d -> DUT sum=%0d co=%0d, REF sum=%0d co=%0d",
                                 a, b, cin, sum, co, sum_ref, co_ref);
                        $stop;
                    end
                end
            end
        end
        $display("All tests passed!");
        $stop();

    end



endmodule