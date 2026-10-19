module signal_generator(
                 i_clock,
                 i_reset ,
                 i_tick,
                 o_signal                 
                 );

   // Parameters
   parameter NB_DATA    = 18;
   parameter NB_SEL     = 2;

   parameter NB_COUNT   = 10;
   parameter MEM_INIT_FILE = "signal.mem";

   // Ports
   output signed [NB_DATA - 1 : 0] o_signal;
   input                    i_clock;
   input                    i_reset;
   input                    i_tick;

   // Vars
   integer i;
   reg [NB_COUNT  - 1 : 0] counter;
   reg [NB_DATA  - 1 : 0]  data[1023:0];

  initial begin
    if (MEM_INIT_FILE != "") begin
      $readmemh(MEM_INIT_FILE, data);
    end
  end

   always@(posedge i_clock or posedge i_reset) begin
      if(i_reset) begin
         counter  <= {NB_COUNT{1'b0}};
   end
      else if(i_tick)begin
         counter  <= counter + {{NB_COUNT-1{1'b0}},{1'b1}};
      end
   end

   assign o_signal = data[counter];


endmodule
