-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
---clk
library  ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
entity clock is
	port(
		clk:in std_logic;
		clk_out:out std_logic
	);
end clock;

architecture clocker of clock is
	signal cnt:integer :=0;
begin
	process(clk)
	begin
		if(rising_edge(clk))then
			if(cnt = 1000000)then
				cnt<=0;
				clk_out<='1';
			elsif (cnt = 0)then
				cnt<=cnt+1;
				clk_out<='0';
			else
				cnt<=cnt+1;
			end if;
		end if;
	end process;
end clocker;

-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
---lfsr for rand
Library IEEE ;
use IEEE.std_logic_1164.all ;
use IEEE.std_logic_arith.all ;


entity lfsr is
	generic (data_width    : natural := 10 );
   port (
         clk      : in  std_logic ;
         reset    : in  std_logic ;
         data_out : out UNSIGNED(data_width - 1 downto 0)
        );
end lfsr ;

 

architecture rtl of lfsr is 
	signal feedback : std_logic ;
	signal lfsr_reg : UNSIGNED(data_width - 1 downto 0) ;
	begin
	feedback <= lfsr_reg(7) xor lfsr_reg(0) ;
	latch_it :  process(clk,reset)
	begin
          if (reset = '1') then
           lfsr_reg <= (others => '0') ;
          elsif (clk = '1' and clk'event) then
            lfsr_reg <= lfsr_reg(lfsr_reg'high - 1 downto 0) & feedback ;
          end if;
        end process ;
   data_out <= lfsr_reg ;

end RTL ;

-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
---input_controller
library  ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity input_controller is
	port (
		angle_lr: in std_logic_vector(7 downto 0);---取[-180,180]取整,左负右正，最高位表示正副，其余八位表示数值.大于128则以128计
		angle_ud: in std_logic_vector(7 downto 0);---取[-180,180]取整,左负右正，最高位表示正副，其余八位表示数值.大于128则以128计
		---acceleration: in std_logic_vector(6 downto 0);---高位表示正负，上正下负，然后3位表示整数，低3位浮点。大于4则以4计
		clk:in std_logic;
		UD: out std_logic_vector(1 downto 0);
		LR: out std_logic_vector(1 downto 0)
	);
end input_controller;

architecture input of input_controller is
	signal clk_in:std_logic; 
	component clock 
		port(
			clk:in std_logic;
			clk_out:out std_logic
		);
	end component;
begin
	ck: clock port map(clk,clk_out=>clk_in);
	process(angle_lr,angle_ud)
	begin
		if(rising_edge(clk)and clk_in = '1') then
			if(angle_lr(6)= '0' and angle_lr(5)='0' and angle_lr(4)='0') then---绝对值小
				LR <= "01";---不操作
			else---绝对值大，由正负判断操作
				if(angle_lr(7)='0')then
					LR <= "00";
				else
					LR <= "11";
				end if;
			end if;
			
			if(angle_ud(6)= '0' and angle_ud(5)='0' and angle_ud(4)='0') then---绝对值小
				UD <= "01";---不操作
			else---绝对值大，由正负判断操作
				if(angle_ud(7)='0')then
					UD <= "00";
				else
					UD <= "11";
				end if;
			end if;
	
			---if(acceleration(5)='0' and acceleration(4)='0' and acceleration(3)='0') then----绝对值小
			---	UD <= "01";
			---else
			---	if(acceleration(6)='0')then
			---		UD <= "11";
			---	else
			---		UD <= "00";
			---	end if;
			---end if;
		end if;
	end process;
end input;
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
library  ieee;
use ieee.std_logic_1164.all;
---use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
---map_gen + game_logic
entity game is
	port (
		clk:in std_logic;
		type_carriage: out std_logic_vector(11 downto 0);
		pos_carriage:out std_logic_vector(71 downto 0);
		num_carriage:out std_logic_vector(17 downto 0);
		pos_barrier:out std_logic_vector(71 downto 0);
		type_barrier:out std_logic_vector(11 downto 0);
		survive : buffer std_logic;
		rst : in std_logic;
		Rx : in std_logic
		
		);

	type array1 is array(2 downto 0) of integer;
	---type array2 is array(3 downto 0) of SIGNED(11 downto 0);
	type array2 is array(3 downto 0) of integer;
	---type array4 is array(3 downto 0) of bit;
	type array3 is array(10 downto 0) of std_logic_vector(7 downto 0);
end game;
-------------------------------------------------------------------------------------------------------------------------------------------
architecture func of game is
	signal sent:std_logic;
	signal survive_signal:std_logic;
	signal clk_in:std_logic; 
	signal cnt:integer range 0 to 159:=0;---地铁位数 2^5*5
	signal cnt0:integer range 0 to 31:=0;---随机数
	
	signal tc1:array1:=(2,0,0);---0没有，1没有斜坡，2有斜坡
	signal tc2:array1:=(1,1,0);
	
	signal pc1:array1:=(500,0,0);
	signal pc2:array1:=(1000,800,0);
	
	signal nc1:array1:=(4,0,0);
	signal nc2:array1:=(4,4,0);
	
	signal tb1:array1:=(0,2,0);---0没有，1上过，2下过，3上下都过
	signal tb2:array1:=(1,0,3);
	
	signal pb1:array1:=(0,700,0);
	signal pb2:array1:=(600,0,800);
	---signal tb1:array2:=(0,0,0,0);---0没有，1上过，2下过，3上下都过
	---signal tb2:array2:=(0,0,0,0);
	---signal tb3:array2:=(0,0,0,0);
	
	signal rand: unsigned (9 downto 0);
	
	signal UD: std_logic_vector(1 downto 0);
	signal LR: std_logic_vector(1 downto 0);
	signal pos_y : integer:=300;
	signal pos_y_center : integer:=1;
	signal pos_h : integer:=0;
	signal pos_h_center : integer:=0;
	signal time_mov_y : integer:=0;
	signal time_mov_h : integer:=0;
	
	signal angle_lr: std_logic_vector(7 downto 0);---取[-180,180]取整,左负右正，最高位表示正副，其余八位表示数值.大于128则以128计
	signal angle_ud: std_logic_vector(7 downto 0);---取[-180,180]取整,左负右正，最高位表示正副，其余八位表示数值.大于128则以128计
	signal async_ready: std_logic:='0';
	signal async_buff : std_logic_vector(7 downto 0);
	signal Rd_clear: std_logic:='1';
	signal my_buffer : array3;
	signal state_buffer:integer:=0;
	signal temp0:std_logic_vector(15 downto 0);
	signal temp1:integer;
	signal temp2:std_logic_vector(15 downto 0):="0000000000000000";
	signal temp3:std_logic_vector(15 downto 0);
	signal temp4:integer;
	signal temp5:std_logic_vector(15 downto 0);
-------------------------------------------------------------------------------------------------------------------------------------------
	component clock 
		port(
			clk:in std_logic;
			clk_out:out std_logic
		);
	end component;
	
	component lfsr
	generic (data_width    : natural := 10 );
   port (
         clk      : in  std_logic ;
         reset    : in  std_logic ;
         data_out : out UNSIGNED(data_width - 1 downto 0)
        );
	end component ;
	
	component input_controller
	port (
		angle_lr: in std_logic_vector(7 downto 0);---取[-180,180]取整,左负右正，最高位表示正副，其余八位表示数值.大于128则以128计
		angle_ud: in std_logic_vector(7 downto 0);---取[-180,180]取整,左负右正，最高位表示正副，其余八位表示数值.大于128则以128计
		clk:in std_logic;
		UD: buffer std_logic_vector(1 downto 0);
		LR: buffer std_logic_vector(1 downto 0)
	);
	end component;

	component async_receiver
	port(
		clk:in std_logic;
		RxD:in std_logic;
		RxD_data_ready:out std_logic;
		RxD_clear:in std_logic;
		RxD_data:out std_logic_vector(7 downto 0)
	);
	end component;
-------------------------------------------------------------------------------------------------------------------------------------------	
begin
	ck: clock port map(clk,clk_out=>clk_in);
	rad: lfsr port map(clk,'0',rand);
	od: input_controller port map(angle_lr,angle_ud,clk,UD,LR);
	a_r:async_receiver port map(clk,Rx,async_ready,Rd_clear,async_buff);
-------------------------------------------------------------------------------------------------------------------------------------------	
	process(async_buff,async_ready)
	begin
	if(async_ready = '1')then
		case state_buffer is
		when 0 =>
			if(async_buff = "01010101") then
				my_buffer(0) <= async_buff;
				state_buffer <= 1;
				Rd_clear <= '1';
			else 
				Rd_clear <= '1';
			end if;
		when 12 =>
			if(my_buffer(1)="01010011") then
				if(my_buffer(10)=my_buffer(0)+my_buffer(1)+my_buffer(2)+my_buffer(3)+my_buffer(4)+my_buffer(5)+my_buffer(6)+my_buffer(7)+my_buffer(8)+my_buffer(9))then
					temp0(15 downto 8) <= my_buffer(3);
					temp0(7 downto 0) <=my_buffer(2);
					temp1 <= to_integer(unsigned(temp0))*180;
					temp2 <= std_logic_vector(to_unsigned(temp1,16));
					angle_lr<=temp2(15 downto 8);
					temp3(15 downto 8) <= my_buffer(5);
					temp3(7 downto 0) <=my_buffer(4);
					temp4 <= to_integer(unsigned(temp3))*180;
					temp5 <= std_logic_vector(to_unsigned(temp4,16));
					angle_ud<=temp5(15 downto 8);
					state_buffer <= 0;
				end if;
				Rd_clear <= '1';
			else 
				Rd_clear <= '1';
			end if;
			state_buffer <= 0;
		when others =>
			my_buffer(state_buffer-1) <= async_buff;
			state_buffer <= state_buffer+1;
			Rd_clear <= '1';
		end case;
		
	end if;
	end process;
-------------------------------------------------------------------------------------------------------------------------------------------
	process(clk_in)
	begin
	sent <= '0';
	survive_signal <= survive;
	if(survive_signal = '0') then
	---delete
	for i in 0 to 2 loop
		if(pc1(i)<500-120*nc1(i))then
			tc1(i) <= 0;
		end if;
		if(pc2(i)<500-120*nc2(i))then
			tc2(i) <= 0;
		end if;		
		if(pb1(i) < 600)then
			tb1(i) <= 0;
		end if;
		if(tb2(i) < 600)then
			tb2(i) <= 0;
		end if;
	end loop;
-------------------------------------------------------------------------------------------------------------------------------------------
	---maintain
	for i in 0 to 2 loop
		if(tc1(i) /= 0)then
			pc1(i) <= pc1(i)-1;
		else
			pc1(i) <= 1140;
		end if;
		if(tc2(i) /= 0)then
			pc2(i) <= pc2(i)-1;
		else
			pc2(i) <= 1140;
		end if;
		if(tb1(i) /= 0)then
			pb1(i) <= pb1(i)-1;
		else
			pb1(i) <= 1140;
		end if;
		if(tb2(i) /= 0)then
			pb2(i) <= pb2(i)-1;
		else
			pb2(i) <= 1140;
		end if;
	end loop;
	

-------------------------------------------------------------------------------------------------------------------------------------------	
	---new
	
	for i in 0 to 2 loop
		if(tc1(i) = 0) then
			if(tc2(i) = 0) then
			---create 1
				if(std_logic_vector(rand(6 downto 0))="0000000")then
					if(rand(7)='0') then
						tc1(i)<=1;
					else
						tc1(i)<=2;
					end if;
					pc1(i)<= 1140;
					nc1(i)<= 1;
					if(rand(8)='1')then
						nc1(i)<= nc1(i)+1;
					end if;
					if(rand(9)='1')then
						nc1(i)<= nc1(i)+2;
					end if;
				end if;
					
			elsif(pc2(i)+120*nc2(i)<1140)then
				---create 1;
				if(std_logic_vector(rand(6 downto 0))="0000000")then
					if(rand(7)='0') then
						tc1(i)<=1;
					else
						tc1(i)<=2;
					end if;
					pc1(i)<= 1140;
					nc1(i)<= 1;
					if(rand(8)='1')then
						nc1(i)<= nc1(i)+1;
					end if;
					if(rand(9)='1')then
						nc1(i)<= nc1(i)+2;
					end if;
				end if;
				
			end if;
		elsif((tc2(i)=0) and (pc1(i)+120*nc1(i)<1140))then
			---create 2;
				if(std_logic_vector(rand(6 downto 0))="0000000")then
					if(rand(7)='0') then
						tc2(i)<=1;
					else
						tc2(i)<=2;
					end if;
					pc2(i)<= 1140;
					nc2(i)<= 1;
					if(rand(8)='1')then
						nc2(i)<= nc2(i)+1;
					end if;
					if(rand(9)='1')then
						nc2(i)<= nc2(i)+2;
					end if;
				end if;
			
		end if;
		
		if(tb1(i) = 0) then
			if(tb2(i) = 0) then
			---create 1;
				if(std_logic_vector(rand(5 downto 0))="000000")then
					if(std_logic_vector(rand(7 downto 6))="00") then
						tb1(i)<=0;
					elsif(std_logic_vector(rand(7 downto 6))="01") then
						tb1(i)<=1;
					elsif(std_logic_vector(rand(7 downto 6))="10") then	
						tb1(i)<=2;
					else
						tb1(i)<=3;
					end if;					
					pb1(i)<= 1140;
				end if;
			
			elsif(pb2(i)<1000)then
			---create 1;
				if(std_logic_vector(rand(5 downto 0))="000000")then
					if(std_logic_vector(rand(7 downto 6))="00") then
						tb1(i)<=0;
					elsif(std_logic_vector(rand(7 downto 6))="01") then
						tb1(i)<=1;
					elsif(std_logic_vector(rand(7 downto 6))="10") then	
						tb1(i)<=2;
					else
						tb1(i)<=3;
					end if;					
					pb1(i)<= 1140;
				end if;
			
			end if;
		elsif((tb2(i)=0) and (pb1(i)<1000))then
		---create 2;
			if(std_logic_vector(rand(5 downto 0))="000000")then
				if(std_logic_vector(rand(7 downto 6))="00") then
					tb2(i)<=0;
				elsif(std_logic_vector(rand(7 downto 6))="01") then
					tb2(i)<=1;
				elsif(std_logic_vector(rand(7 downto 6))="10") then	
					tb2(i)<=2;
				else
					tb2(i)<=3;
				end if;					
				pb2(i)<= 1140;
			end if;
		end if;
	end loop;
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------	
---game logic
---a:
	if(UD = "00") then
		time_mov_h <= 60;
		pos_h <= pos_h_center;
	elsif(UD = "11") then
		time_mov_h <= -60;
		pos_h <= pos_h_center;
	end if;
	
	if(time_mov_y = 0)then
		if(LR = "00") then
			time_mov_y <= 140;
		elsif(LR = "11") then
			time_mov_y <= -140;
		end if;
	end if;
	
---v:
	if(time_mov_h>0) then
		pos_h <= pos_h_center +30;
		time_mov_h <= time_mov_h-1;
	elsif (time_mov_h < 0) then
		pos_h <= pos_h_center;
		time_mov_h <= time_mov_h+1;
	else
		pos_h <= pos_h_center;
	end if;
	
	if(time_mov_y>0 )then
		time_mov_y <= time_mov_y -1;
		pos_y <=pos_y -1;
	elsif(time_mov_y <0) then 
		time_mov_y <= time_mov_y +1;
		pos_y <=pos_y +1;
	end if;
	
---collision detection
	if(pos_y <200)then
		pos_y_center<=0;
	elsif(pos_y > 340)then
		pos_y_center <=2;
	else
		pos_y_center <=1;
	end if;
	
	survive_signal<='1';
	
	if((tc1(pos_y_center)=2 )and (pc1(pos_y_center)+120*nc1(pos_y_center) > 650) and (pc1(pos_y_center) < 650) and (pos_h<60)) then
		survive_signal<='0';
	end if;
	
	if((tc2(pos_y_center)=2 )and (pc2(pos_y_center)+120*nc2(pos_y_center) > 650) and (pc2(pos_y_center) < 650) and (pos_h<60)) then
		survive_signal<='0';
	end if;
	
	if((tb1(pos_y_center) /=0) and (pb1(pos_y_center) < 640) and (pb1(pos_y_center) > 670)) then
		if((tb1(pos_y_center)=1) and (time_mov_h<0 or time_mov_h = 0)) then
			survive_signal<='0';
		elsif((tb1(pos_y_center)=2) and (time_mov_h>0 or time_mov_h = 0)) then
			survive_signal<='0';
		elsif((tb1(pos_y_center)=3) and (time_mov_h = 0)) then
			survive_signal<='0';
		end if;
	end if;
	
	if((tb2(pos_y_center) /=0) and (pb2(pos_y_center) < 640) and (pb2(pos_y_center) > 670)) then
		if((tb2(pos_y_center)=1) and (time_mov_h<0 or time_mov_h = 0)) then
			survive_signal<='0';
		elsif((tb2(pos_y_center)=2) and (time_mov_h>0 or time_mov_h = 0)) then
			survive_signal<='0';
		elsif((tb2(pos_y_center)=3) and (time_mov_h = 0)) then
			survive_signal<='0';
		end if;
	end if;
	
-------------------------------------------------------------------------------------------------------------------------------------------	
	sent <= '1';
end if;
	end process;
	
	process(sent)
	begin
		if(sent = '1' and survive_signal = '1')then
			for i in 0 to 2 loop
				type_carriage(2*i+1 downto 2*i) <= std_logic_vector(to_unsigned(tc1(i),2));
				type_carriage(7+2*i downto 6+2*i) <= std_logic_vector(to_unsigned(tc2(i),2));
				pos_carriage(12*i+11 downto 12*i) <= std_logic_vector(to_unsigned(pc1(i),12));
				pos_carriage(47+12*i downto 36+12*i) <= std_logic_vector(to_unsigned(pc2(i),12));
				num_carriage(3*i+2 downto 3*i)<= std_logic_vector(to_unsigned(nc1(i),3));
				num_carriage(3*i+11 downto 3*i+9)<= std_logic_vector(to_unsigned(nc2(i),3));
				pos_barrier(12*i+11 downto 12*i) <= std_logic_vector(to_unsigned(pb1(i),12));
				pos_barrier(47+12*i downto 36+12*i) <= std_logic_vector(to_unsigned(pb2(i),12));
				type_barrier(2*i+1 downto 2*i) <= std_logic_vector(to_unsigned(tb1(i),2));
				type_barrier(7+2*i downto 6+2*i) <= std_logic_vector(to_unsigned(tb2(i),2));
				survive <= survive_signal;
			end loop;
		end if;
	end process;
end func;
		