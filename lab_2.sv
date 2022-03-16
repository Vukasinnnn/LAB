module top;
  
  typedef enum {FIXED, INCREMENT} burst_t;
  typedef enum {READ, WRITE} direction;
  enum {ENABLE, THRESHOLD_ADDRESS, THRESHOLD_LENGTH, RESET} regis;
  
  
  class packet;
  	burst_t packet_type;
    bit [31:0] start_addr;
    int length;
    bit [31:0] data[$];
    
    function new( bit[31:0] s_addr = 0, int l = 5, burst_t p_type = FIXED);
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
  
  typedef class Configuration; 
  
  class memory;
    bit[31:0] mem[512];
    bit parity[512];
    bit[31:0] register[4];
    
    function new();
      foreach(mem[i])
        parity[i] = 0;
    endfunction
    
    function void write(packet p);
      int j=0;
      if(register[ENABLE] == 0)
        $display("MEMORY ACCESS DISABLED");
      else begin 
        if(p.length > register[THRESHOLD_LENGTH])
          $display("PACKET TOO LONG. PACKET DROPPED.");
        else begin 
          if(p.start_addr + p.length > register[THRESHOLD_ADDRESS]) begin //1
          	$display("THRESHOLD ADDRESS OVERRIDE");
          	for(int i=p.start_addr; i<register[THRESHOLD_ADDRESS];i++) begin
           	 	mem[p.start_addr + j] = p.data[j];
            	parity[p.start_addr + j] = ^p.data[j];
            	j++;
          	end
          end 
          else begin
            foreach(p.data[i]) begin
              mem[p.start_addr + i] = p.data[i];
              parity[p.start_addr + i] = ^p.data[i];
            end
          end
        end
      end 
    endfunction
    
    function void read(int start_addr = 0, int length);
      for(int i = start_addr; i < start_addr + length; i++) 
        begin
          $display("addr[%-0d] =: %0b, parity[%-0d] =: %0d", i, mem[i], i, parity[i]);
        end
    endfunction
    
    function void corrupt(bit[511:0] memory_location_index, bit[31:0] memory_bit_position_index);
      mem[memory_location_index][memory_bit_position_index] = ~mem[memory_location_index][memory_bit_position_index];
    endfunction
    
    function void parity_check();
      foreach(mem[i])
       	begin
          if(parity[i] != ^mem[i])
            $display("ERROR: PARITY CHECK FAILED - ADDRESS: %-0d, DATA: %b, PARITY: %b", i, mem[i], parity[i]);
        end
    endfunction
    
    function void configure(Configuration cfg);
      if(cfg.rw == WRITE)
        begin
          register[cfg.address] = cfg.data;
          
          if(register[RESET] == 0 && cfg.address == RESET)
            foreach(mem[i])
              begin
              	mem[i] = 0;
                parity[i] = 0;
              end
        end
      else
        begin
          $display("ENABLE = %0d", register[ENABLE]);
          $display("THRESHOLD ADDRESS = %0d", register[THRESHOLD_ADDRESS]);
          $display("THRESHOLD LENGTH = %0d", register[THRESHOLD_LENGTH]);
          $display("RESET = %0d", register[RESET]);
        end
    endfunction
    
  endclass
  
  
  class Configuration;
    
    bit [1:0] address;
    bit [15:0] data;
    direction rw;
    
    function new(bit [1:0] address, bit[15:0] data, direction rw);
      this.address = address;
      this.data = data;
      this.rw = rw;
    endfunction
    
  endclass
  

      
  
  initial begin
    
    packet pkt1 = new(.s_addr(0), .l(20), .p_type (FIXED));
    packet pkt2 = new(150, 20, INCREMENT);
    packet pkt3 = new(100, 50, FIXED);
    packet pkt4 = new(195, 15, FIXED);
    
    packet pkt5 = new();
    
    memory m = new();

    Configuration cfg_en = new(ENABLE, 1, WRITE);
    Configuration cfg_ta = new(THRESHOLD_ADDRESS, 200, WRITE);
    Configuration cfg_tl = new(THRESHOLD_LENGTH, 24, WRITE);
    Configuration cfg_rs = new(RESET, 0, WRITE);
    Configuration cfg_rd = new(ENABLE, 1, READ);
    
    m.configure(cfg_en);
    m.configure(cfg_ta);
    m.configure(cfg_tl);
    m.configure(cfg_rd);
    
    m.write(pkt1);
    m.write(pkt2);
    m.write(pkt3);
    m.write(pkt4);
    
    $display("Read pkt1");
    m.read(0, 20);
    $display("Read pkt2");
    m.read(150, 20);
    $display("Read pkt3");
    m.read(100, 30);
    $display("Read pkt4");
    m.read(195, 20);
    $display("Reset memory");
    m.parity_check();
    m.corrupt(195, 5);
    m.parity_check();
    m.configure(cfg_rs);
    m.read(0, 20);
  end
  
endmodule
