module top;
  
  typedef enum {FIXED, INCREMENT} burst_t;
  class packet;
  	burst_t packet_type;
    bit [31:0] start_addr;
    int length;
    bit [31:0] data[$];
    function new( bit[31:0] s_addr, int l, burst_t p_type);
      packet_type = p_type;
      start_addr = s_addr;
      length = l;
      for(int i = 0; i < length; i++) begin
        data.push_back(start_addr + i );
      end
    endfunction
    
    function void print();
      $display("start_addr: %d", start_addr);
      
      $display("length: %d", length);
      $display("packet_type %s", packet_type);
    endfunction
    
  endclass
  class memory;
    bit[31:0] mem [255:0];
    function new();
      
    endfunction
    function void write(packet p);
      foreach(p.data[i])
        mem[p.start_addr + i] = p.data[i];
    endfunction
    
    function void read(int start_addr = 0, int length);
      for(int i = start_addr; i <=start_addr + length; i++)
        $display("addr[%d] =: %d", i, mem[i]);
    endfunction
    
  endclass
  
  
  initial begin
    packet pkt1 = new( 100, 10, FIXED);
    packet pkt2 = new( 150, 20, INCREMENT);
    memory m = new();
    foreach(pkt1.data[i])
      $display(pkt1.data[i]);
		pkt1.print();
    pkt2.print();
    m.write(pkt1);
		m.write(pkt2);
    m.read(0, 255);

  end
  
endmodule
