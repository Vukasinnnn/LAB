class frame ;
  rand bit[7:0] payload;
  bit parity;
  bit toggle;
  function frame copy;
    copy = new();
    copy.payload = this.payload;
    copy.parity   = this.parity;
    return copy;
  endfunction
 // constraint payload_c {payload inside {8'b11100000};}
  virtual function void parity_function();
    $display("\Payload have value =%0b",payload);
    parity=^payload;
    $display("\Parity is =%0b",parity);
  endfunction
  virtual function void corrupt();
    toggle=~parity;
    $display("\Parity after toggle is =%0b",toggle);
  endfunction
    virtual function int check_parity();
      bit[7:0] check_payload;
      for(int i=0;i<$size(payload);i++) begin
        if(parity!=1) begin
        check_payload[i]=payload[i]+parity;
        end
        else begin
          check_payload[i]=payload[i] * parity;
        end
        end
      if(check_payload==payload) begin
        return 0;
      end
      else begin
        return 1;
      end
    endfunction
 endclass
class  start_frame extends frame;
  constraint start_frame_{super.payload==8'hFF;}
endclass
class end_frame extends frame;
  constraint start_frame_{super.payload==8'hFE;}
endclass
class high_payload_frames extends frame;
  constraint start_frame_{super.payload dist {[8'h00:8'hF0]:/1, [8'hF1:8'hFF]:/10};}
  
endclass
class base_packet;
  frame frames_q[$];
  bit [4:0] queue_lenth;
  virtual task populate;
    frame frame_s=new();
    //frame frame_sc = new();
    for(int i=0;i<queue_lenth;i++) begin
      frame frame_sc = new();
      //frame_sc = frame_s.copy();
      frame_sc.randomize();
      frame_sc.parity_function();
      frames_q.push_back(frame_sc);
    end
  endtask
  virtual function void print_frames();
    foreach(frames_q[i])
      $display("\nPayload frame %x parity frame =%0b",frames_q[i].payload,frames_q[i].parity);
  endfunction
  
  virtual function void replace_frame1(frame new_frame, int position);
    frames_q[position]=new_frame;
  endfunction
endclass

class uart_packet extends base_packet;
  constraint queue_lenth_c {queue_lenth==8;}
  
  virtual task populate1;
    start_frame s_f=new();
    end_frame e_f=new();
    frame ua_f;
     s_f.randomize();
    frames_q.push_back(s_f);
    for(int i=0; i<queue_lenth-2;i++) begin 
      ua_f=new();
      ua_f.randomize();
      frames_q.push_back(ua_f);
    end
    e_f.randomize();
    frames_q.push_back(e_f);
  endtask
  
  virtual function void print_frames1();
    $display("\nUart_packet frames");
    super.print_frames;
  endfunction
  virtual function replace_frame(frame ua_f, int position);
    if(position==0 || position==queue_lenth-1) begin
      $display("You can't diplay first and last frame in uart");
      
    end
    else begin
      replace_frame(ua_f, position);
    end
  endfunction
  function void check_frame_corruption();
    foreach(frames_q[i]) begin
        if(frames_q[i].check_parity() == -1)
          $display("ERROR: parity corrupted for frames_q[%0d], payload = %b, parity = %0b", i, frames_q[i].payload, frames_q[i].parity);
      end
    endfunction
endclass
module fr;
  int x;
  initial begin
    base_packet base_pack=new();
    uart_packet u_packet=new();
    frame fra=new();
    base_packet packet_q[$];
    high_payload_frames  sf=new();
    fra=sf;
    base_pack.queue_lenth=5;
    repeat(3) begin
      
      base_pack.randomize();
      base_pack.populate();
       base_pack.print_frames();
      packet_q.push_back(base_pack);
    end
    
    repeat(3)begin 
      u_packet.randomize();
      //u_packet.populate1();
     // u_packet.print_frames1();
      //packet_q.push_back(u_packet);  
    end
    
    base_pack.print_frames();
    
      
    x = fra.check_parity();
      $display("\nCheck parity: %0d", x);
  end
    endmodule
