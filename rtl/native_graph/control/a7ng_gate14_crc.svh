// CRC16-CCITT-FALSE: init FFFF, poly 1021. PROGRAM=NO.
function automatic logic [15:0] crc16_byte(input logic [15:0] crc, input logic [7:0] b);
  logic [15:0] x;
  integer i;
  x = crc ^ {b, 8'h00};
  for (i = 0; i < 8; i = i + 1) begin
    if (x[15]) x = {x[14:0], 1'b0} ^ 16'h1021;
    else       x = {x[14:0], 1'b0};
  end
  crc16_byte = x;
endfunction
