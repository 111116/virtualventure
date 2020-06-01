-------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--geometry
Library IEEE ;
use IEEE.std_logic_1164.all ;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


entity geometry is
   port (
		clk: in std_logic;
		-- internal ports to main game logic
		type_carriage:in std_logic_vector(11 downto 0);
		pos_carriage:in std_logic_vector(71 downto 0);
		num_carriage:in std_logic_vector(17 downto 0);
		pos_barrier:in std_logic_vector(71 downto 0);
		type_barrier:in std_logic_vector(11 downto 0);
		character_y:in std_logic_vector(11 downto 0);
		character_h:in std_logic_vector(11 downto 0);
		character_state:in std_logic_vector(1 downto 0);
		survive_signal :in std_logic;
		
-- internal ports to geometry buffer (RAM)
		ram_clk: out std_logic;
		ram_addr: out std_logic_vector(11 downto 0);
		ram_data: out std_logic_vector(31 downto 0);
		wren: out std_logic;
		start:out std_logic;
		render_busy: in std_logic;
		data_ready: in std_logic;
		pyc: in std_logic_vector(9 downto 0);
		phc: in std_logic_vector(9 downto 0);
		tmy: in std_logic_vector(9 downto 0);
		tmh: in std_logic_vector(9 downto 0)
        );
		type array1 is array(5 downto 0) of integer range 0 to 5000;
end geometry ;

------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------

architecture geo of geometry is 
	
	signal geo_busy :std_logic:='0';
	signal cnt : integer :=0;
	signal object_state : integer range 0 to 26:=0;
	signal word_state : integer range 0 to 3:=0;
	
	signal tc:array1;---0没有，1没有斜坡，2有斜坡	
	signal pc:array1;
	signal nc:array1;
	
	signal tb:array1;---0没有，1上过，2下过，3上下都过
	signal pb:array1;
	
	signal state_busy: std_logic :='0';

	signal pos_y : integer range 0 to 5000:=300;
	signal pos_h : integer range 0 to 5000:=0;
	
	signal char_state : std_logic_vector(1 downto 0):="10";
	signal survive_sign : std_logic := '1';
	
	signal data_available_in: std_logic:='0';
	
	signal pos_y_center : integer:=1;
	signal pos_h_center : integer:=0;
	signal time_mov_y : integer:=0;
	signal time_mov_h : integer:=0;

------------------------------------------------------------------------------------------------------------------------------
begin
	ram_clk <=clk;
	wren <= not data_available_in;

---signal X :std_logic_vector(11 downto 0);---所绘制矩形在屏幕上的左上角横坐标，屏幕最左列为0
---signal Y :std_logic_vector(11 downto 0);---所绘制矩形在屏幕上的左上角纵坐标，屏幕最上行为0
---  8位占位符，会被忽略
---signal U :std_logic_vector(11 downto 0);---所绘制矩形在贴图上的左上角横坐标，贴图最左列为0
---signal V :std_logic_vector(11 downto 0);---所绘制矩形在贴图上的左上角纵坐标，贴图最上行为0
---  8位占位符，会被忽略
---signal W :std_logic_vector(11 downto 0);---所绘制矩形的宽度（横向像素数量）
---signal H :std_logic_vector(11 downto 0);---所绘制矩形的高度（纵向像素数量）
---  8位占位符，会被忽略
---signal D: std_logic_vector(15 downto 0);---所绘制矩形的深度（深度小的矩形覆盖深度大的矩形）
--- 16位占位符，会被忽略
	
	process(clk,object_state,word_state,tc,pc,nc,pb,tb,pos_y,pos_h,data_ready)---trans
		variable hiteffect_offset : integer range 0 to 100;
	begin
		if(rising_edge(clk)) then
			if(data_ready = '1' and render_busy = '0' and geo_busy = '0')then
				data_available_in <= '0';
				geo_busy <= '1';
				start <= '0';
				for i in 0 to 5 loop
					tc(i) <= to_integer(unsigned(type_carriage(2*i+1 downto 2*i)));
					pc(i) <= to_integer(unsigned(pos_carriage(12*i+11 downto 12*i)));
					nc(i) <= to_integer(unsigned(num_carriage(3*i+2 downto 3*i)));
					tb(i) <= to_integer(unsigned(type_barrier(2*i+1 downto 2*i)));
					pb(i) <= to_integer(unsigned(pos_barrier(12*i+11 downto 12*i)));
				end loop;
				pos_y <= to_integer(unsigned(character_y));
				pos_h <= to_integer(unsigned(character_h));
				char_state <= character_state;
				survive_sign <= survive_signal;
				object_state <= 0;
				word_state  <= 0;
				pos_y_center<=to_integer(signed(pyc));
				pos_h_center<=to_integer(signed(phc));
				time_mov_y<=to_integer(signed(tmy));
				time_mov_h<=to_integer(signed(tmh));

			end if;

			if(geo_busy = '1' and data_available_in = '0')then
				ram_addr <= std_logic_vector(to_unsigned((object_state*4 + word_state),12));
				
				case object_state is
				----gen background
				----
				----
				----
				----
				when 0 =>
					--------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						ram_data(11 downto 0) <= "000000000000";
						ram_data(23 downto 12) <="000000000000";
						ram_data(31 downto 24) <="00000000";
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						ram_data(23 downto 12) <= std_logic_vector(to_unsigned(960,12));
						ram_data(11 downto 0) <="000000000000";
						ram_data(31 downto 24) <="00000000";
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						ram_data(11 downto 0) <= std_logic_vector(to_unsigned(640,12));
						ram_data(23 downto 12) <=std_logic_vector(to_unsigned(480,12));
						ram_data(31 downto 24) <="00000000";
						word_state <= 3;
					---------------------------------------------------------------------------------------------d
					else
						ram_data <= "0111111111111111"&"00000000"&"00000000";
						word_state <= 0;
						object_state <= object_state + 1;
					end if;
				----gen 
				----
				----
				----
				----
				when 1|2|3|4|5|6 =>
					--------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						ram_data(11 downto 0) <= "000000000000";
						ram_data(23 downto 12) <= "000000000000";
						ram_data(31 downto 24) <="00000000";
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						ram_data(23 downto 12) <= std_logic_vector(to_unsigned(800,12));
						ram_data(11 downto 0) <="000000000000";
						ram_data(31 downto 24) <="00000000";
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						ram_data(11 downto 0) <= std_logic_vector(to_unsigned(0,12));
						ram_data(23 downto 12) <=std_logic_vector(to_unsigned(0,12));
						ram_data(31 downto 24) <="00000000";
						word_state <= 3;
					---------------------------------------------------------------------------------------------d
					else
						ram_data <= "0111111111111101"&"00000000"&"00000000";
						word_state <= 0;
						object_state <= object_state + 1;
					end if;
				when 7|8|9|10|11|12 =>  
					------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						if(tc(object_state - 7) = 0) then
							ram_data <= "000000000000"&"000000000000"&"00000000";
						else
							ram_data(11 downto 0) <= std_logic_vector(to_unsigned(pc(object_state - 7),12));
							if(object_state  = 7 or object_state  = 8) then-----------y
								ram_data(23 downto 12) <= std_logic_vector(to_unsigned(70,12));
							elsif(object_state  = 9 or object_state  = 10) then
								ram_data(23 downto 12) <= std_logic_vector(to_unsigned(210,12));
							else
								ram_data(23 downto 12) <= std_logic_vector(to_unsigned(350,12));
							end if;
							ram_data(31 downto 24) <= "00000000";
						end if;
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						if(tc(object_state - 7) = 1 and nc(object_state - 7) = 1) then
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(300,12));
							ram_data(11 downto 0) <=std_logic_vector(to_unsigned(0,12));
							ram_data(31 downto 24) <="00000000";
						elsif(tc(object_state - 7) = 1 and nc(object_state - 7) = 2) then
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(300,12));
							ram_data(11 downto 0) <=std_logic_vector(to_unsigned(160,12));
							ram_data(31 downto 24) <="00000000";
						elsif(tc(object_state - 7) = 1 and nc(object_state - 7) = 3) then
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(300,12));
							ram_data(11 downto 0) <=std_logic_vector(to_unsigned(440,12));
							ram_data(31 downto 24) <="00000000";
						elsif(tc(object_state - 7) = 1 and nc(object_state - 7) = 4) then
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(500,12));
							ram_data(11 downto 0) <=std_logic_vector(to_unsigned(0,12));
							ram_data(31 downto 24) <="00000000";
						elsif(tc(object_state - 7) = 2 and nc(object_state - 7) = 1) then
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(400,12));
							ram_data(11 downto 0) <=std_logic_vector(to_unsigned(0,12));
							ram_data(31 downto 24) <="00000000";
						elsif(tc(object_state - 7) = 2 and nc(object_state - 7) = 2) then
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(400,12));
							ram_data(11 downto 0) <=std_logic_vector(to_unsigned(160,12));
							ram_data(31 downto 24) <="00000000";
						elsif(tc(object_state - 7) = 2 and nc(object_state - 7) = 3) then
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(400,12));
							ram_data(11 downto 0) <=std_logic_vector(to_unsigned(440,12));
							ram_data(31 downto 24) <="00000000";
						elsif(tc(object_state - 7) = 2 and nc(object_state - 7) = 4) then
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(600,12));
							ram_data(11 downto 0) <=std_logic_vector(to_unsigned(0,12));
							ram_data(31 downto 24) <="00000000";
						end if;
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						if(tc(object_state - 7) = 0)then
							ram_data <= "000000000000"&"000000000000"&"00000000";
						else
							ram_data(11 downto 0) <= std_logic_vector(to_unsigned((40+nc(object_state - 7)*120),12));
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(100,12));
							ram_data(31 downto 24) <= "00000000";
						end if;
						word_state <= 3;
					---------------------------------------------------------------------------------------------d
					else
						ram_data <= "0111111111111011"&"00000000"&"00000000";
						word_state <= 0;
						object_state <= object_state + 1;
					end if;
					---------------------------------------------------------------------------------------------
				---gen barr
				----
				----
				----
				----
				when 13|14|15|16|17|18 =>
					------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						if(tb(object_state - 13) = 0) then
							ram_data <= "000000000000"&"000000000000"&"00000000";
						else
							ram_data(11 downto 0) <= std_logic_vector(to_unsigned(pb(object_state - 13),12));
							if(object_state = 13 or object_state = 14) then-----------y
								if(((tc(0)/=0) and (pc(0)<pb(object_state - 13)) and (pc(0)+nc(0)*120+40 >pb(object_state - 13))) or ((tc(1)/=0) and (pc(1)<pb(object_state - 13)) and (pc(1)+nc(1)*120+40 >pb(object_state - 13)))) then
									ram_data(23 downto 12) <= std_logic_vector(to_unsigned(10,12));
								else
									ram_data(23 downto 12) <= std_logic_vector(to_unsigned(70,12));
								end if;
							elsif(object_state = 15 or object_state = 16) then
								if(((tc(2)/=0) and (pc(2)<pb(object_state - 13)) and (pc(2)+nc(2)*120+40 >pb(object_state - 13))) or ((tc(3)/=0) and (pc(3)<pb(object_state - 13)) and (pc(3)+nc(3)*120+40 >pb(object_state - 13)))) then
									ram_data(23 downto 12) <= std_logic_vector(to_unsigned(150,12));
								else
									ram_data(23 downto 12) <= std_logic_vector(to_unsigned(210,12));
								end if;
							else
								if(((tc(4)/=0) and (pc(4)<pb(object_state - 13)) and (pc(4)+nc(4)*120+40 >pb(object_state - 13))) or ((tc(5)/=0) and (pc(5)<pb(object_state - 13)) and (pc(5)+nc(5)*120+40 >pb(object_state - 13)))) then
									ram_data(23 downto 12) <= std_logic_vector(to_unsigned(290,12));
								else
									ram_data(23 downto 12) <= std_logic_vector(to_unsigned(350,12));
								end if;
							end if;
							ram_data(31 downto 24) <= "00000000";
						end if;
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						if(tb(object_state - 13) = 1 ) then
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(500,12));
							ram_data(11 downto 0) <=std_logic_vector(to_unsigned(520,12));
							ram_data(31 downto 24) <="00000000";
						elsif(tb(object_state - 13) = 2) then
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(500,12));
							ram_data(11 downto 0) <=std_logic_vector(to_unsigned(570,12));
							ram_data(31 downto 24) <="00000000";
						elsif(tb(object_state - 13) = 3) then
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(600,12));
							ram_data(11 downto 0) <=std_logic_vector(to_unsigned(520,12));
							ram_data(31 downto 24) <="00000000";
						end if;
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						if(tb(object_state - 13) = 0)then
							ram_data <= "000000000000"&"000000000000"&"00000000";
						else
							ram_data(11 downto 0) <= std_logic_vector(to_unsigned(50,12));
							ram_data(23 downto 12) <= std_logic_vector(to_unsigned(100,12));
							ram_data(31 downto 24) <= "00000000";
						end if;
						word_state <= 3;
					---------------------------------------------------------------------------------------------d
					else
						ram_data <= "0111111111110111"&"00000000"&"00000000";
						word_state <= 0;
						object_state <= object_state + 1;
					end if;
					---------------------------------------------------------------------------------------------
				---gen character
				----
				----
				----
				----
				when 19 =>
					------------------------------------------------------------------------------------------x,y
					if survive_sign = '1' then
						hiteffect_offset := 0;
					else
						hiteffect_offset := 80;
					end if;
					if(word_state = 0) then
						ram_data(11 downto 0)<=std_logic_vector(to_unsigned(150,12));
						if(char_state =  "00")then
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (pos_y+pos_h+30,12));
						elsif(char_state =  "00")then
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (pos_y+pos_h-10,12));
						else
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (pos_y+pos_h,12));
						end if;
						ram_data(31 downto 24) <= "00000000";
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						if(char_state =  "00")then
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned(740+hiteffect_offset,12));
							ram_data(11 downto 0)<=std_logic_vector(to_unsigned (680,12));
							ram_data(31 downto 24) <= "00000000";
						elsif(char_state =  "11")then
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned(740+hiteffect_offset,12));
							ram_data(11 downto 0)<=std_logic_vector(to_unsigned (740,12));
							ram_data(31 downto 24) <= "00000000";
						else
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned(740+hiteffect_offset,12));
							ram_data(11 downto 0)<=std_logic_vector(to_unsigned (640,12));
							ram_data(31 downto 24) <= "00000000";
						end if;
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						if(char_state =  "00")then
							ram_data(11 downto 0)<=std_logic_vector(to_unsigned(60,12));
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (30,12));
							ram_data(31 downto 24) <= "00000000";
						elsif(char_state =  "11")then
							ram_data(11 downto 0)<=std_logic_vector(to_unsigned(40,12));
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (50,12));
							ram_data(31 downto 24) <= "00000000";
						else
							ram_data(11 downto 0)<=std_logic_vector(to_unsigned(40,12));
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (60,12));
							ram_data(31 downto 24) <= "00000000";
						end if;
						word_state <= 3;
					---------------------------------------------------------------------------------------------d
					else
						ram_data <= "0111111111101111"&"00000000"&"00000000";
						word_state <= 0;
						object_state <= 20;
					end if;		
					---------------------------------------------------------------------------------------------
				---gen "fail"-tips
				----
				----
				----
				----
				when 20 =>
					------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						ram_data(11 downto 0)<=std_logic_vector(to_unsigned(180,12));
						ram_data(23 downto 12)<=std_logic_vector(to_unsigned (240,12));
						ram_data(31 downto 24) <= "00000000";
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						ram_data(23 downto 12)<=std_logic_vector(to_unsigned(860,12));
						ram_data(11 downto 0)<=std_logic_vector(to_unsigned (0,12));
						ram_data(31 downto 24) <= "00000000";
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						if(survive_sign =  '0')then
							ram_data(11 downto 0)<=std_logic_vector(to_unsigned(200,12));
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (100,12));
							ram_data(31 downto 24) <= "00000000";
						else
							ram_data <= "000000000000"&"000000000000"&"00000000";
						end if;
						word_state <= 3;
					---------------------------------------------------------------------------------------------d
					else
						ram_data <= "0111111111011111"&"00000000"&"00000000";
						word_state <= 0;
						object_state <= 21;
					end if;
				when 21|22|23|24=>
					------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						ram_data(11 downto 0)<=std_logic_vector(to_unsigned(object_state*40-800,12));
						if(object_state = 21) then---y center						
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (240+pos_y_center,12));
						elsif(object_state = 22) then---y center						
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (240+pos_h_center,12));
						elsif(object_state = 23) then---y center						
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (240+time_mov_y,12));
						elsif(object_state = 24) then ---y center						
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (240+time_mov_h,12));
						end if;
						ram_data(31 downto 24) <= "00000000";
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						if(object_state = 21) then---y center						
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (2000,12));
							ram_data(11 downto 0)<=std_logic_vector(to_unsigned(75,12));
						elsif(object_state = 22) then---y center						
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (2000,12));
							ram_data(11 downto 0)<=std_logic_vector(to_unsigned(100,12));
						elsif(object_state = 23) then---y center						
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (2000,12));
							ram_data(11 downto 0)<=std_logic_vector(to_unsigned(125,12));
						elsif(object_state = 24) then---y center						
							ram_data(23 downto 12)<=std_logic_vector(to_unsigned (2000,12));
							ram_data(11 downto 0)<=std_logic_vector(to_unsigned(150,12));
						end if;
						ram_data(31 downto 24) <= "00000000";
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						ram_data(11 downto 0)<=std_logic_vector(to_unsigned(25,12));
						ram_data(23 downto 12)<=std_logic_vector(to_unsigned (25,12));
						ram_data(31 downto 24) <= "00000000";
						word_state <= 3;
					---------------------------------------------------------------------------------------------d
					else
						ram_data <= "0111111111011111"&"00000000"&"00000000";
						word_state <= 0;
						object_state <= object_state+1;
					end if;
				when 25=>
					start<= '1';
					object_state <= 26;
				when 26=>
					object_state <= 0;
					geo_busy <= '0';
					data_available_in <= '1';
					start<= '0';
				when others =>
					NULL;
				end case;
			end if;
			
			if(render_busy = '0' and state_busy = '0')then
				NULL;
			elsif(render_busy = '1' and state_busy = '0') then
				state_busy <= '1';
			elsif(render_busy = '0' and state_busy = '1') then
				state_busy <= '0';
				data_available_in <='0';
			end if;
			
		end if;---risingedge
	end process;
	
		
end geo ;
