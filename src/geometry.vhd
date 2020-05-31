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
		data_available: buffer std_logic;
		render_busy: in std_logic;
		data_ready: in std_logic
        );
		type array1 is array(5 downto 0) of integer range 0 to 1023;
end geometry ;

------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------

architecture geo of geometry is 
	signal X :std_logic_vector(11 downto 0);---所绘制矩形在屏幕上的左上角横坐标，屏幕最左列为0
	signal Y :std_logic_vector(11 downto 0);---所绘制矩形在屏幕上的左上角纵坐标，屏幕最上行为0
---  8位占位符，会被忽略
	signal U :std_logic_vector(11 downto 0);---所绘制矩形在贴图上的左上角横坐标，贴图最左列为0
	signal V :std_logic_vector(11 downto 0);---所绘制矩形在贴图上的左上角纵坐标，贴图最上行为0
---  8位占位符，会被忽略
	signal W :std_logic_vector(11 downto 0);---所绘制矩形的宽度（横向像素数量）
	signal H :std_logic_vector(11 downto 0);---所绘制矩形的高度（纵向像素数量）
---  8位占位符，会被忽略
	signal D: std_logic_vector(15 downto 0);---所绘制矩形的深度（深度小的矩形覆盖深度大的矩形）
--- 16位占位符，会被忽略
	
	signal geo_busy :std_logic:='0';
	signal cnt : integer :=0;
	signal object_state : integer range 0 to 20:=0;
	signal word_state : integer range 0 to 3:=0;
	
	signal tc:array1;---0没有，1没有斜坡，2有斜坡	
	signal pc:array1;
	signal nc:array1;
	
	signal tb:array1;---0没有，1上过，2下过，3上下都过
	signal pb:array1;
	
	signal state_busy: std_logic :='0';

	signal pos_y : integer range 0 to 1023:=300;
	signal pos_h : integer range 0 to 1023:=0;
	
	signal char_state : std_logic_vector(1 downto 0):="10";
	signal survive_sign : std_logic := '1';

------------------------------------------------------------------------------------------------------------------------------
begin
	ram_clk <=clk;
	
	process(clk)---receive
	begin
		if(rising_edge(clk))then
			NULL;
		end if;
	end process;
	
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
	variable i :integer;
	begin
		if(rising_edge(clk)) then
			if(data_ready = '1' and render_busy = '0' and geo_busy = '0')then
				data_available <= '0';
				geo_busy <= '1';
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
			end if;
			
			if(geo_busy = '1' and data_available = '0')then
				case object_state is
				----gen road
				----
				----
				----
				----
				when 0|1|2 =>
					ram_addr <= std_logic_vector(to_unsigned((object_state + word_state),12));
					--------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						ram_data(31 downto 20) <= "000000000000";
						ram_data(19 downto 8) <=std_logic_vector(to_unsigned((120+140*object_state),12));
						ram_data(7 downto 0) <="00000000";
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						ram_data(31 downto 20) <= std_logic_vector(to_unsigned(550,12));
						ram_data(19 downto 8) <="000000000000";
						ram_data(7 downto 0) <="00000000";
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						ram_data(31 downto 20) <= std_logic_vector(to_unsigned(640,12));
						ram_data(19 downto 8) <=std_logic_vector(to_unsigned(40,12));
						ram_data(7 downto 0) <="00000000";
						word_state <= 3;
					---------------------------------------------------------------------------------------------d
					else
						ram_data <= "0111111111111111"&"00000000"&"00000000";
						word_state <= 0;
						object_state <= object_state + 1;
					end if;
				----gen gap
				----
				----
				----
				----
				when 3|4|5 =>
					ram_addr <= std_logic_vector(to_unsigned((object_state + word_state),12));
					--------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						ram_data(31 downto 20) <= "000000000000";
						ram_data(19 downto 8) <=std_logic_vector(to_unsigned((30+140*object_state),12));
						ram_data(7 downto 0) <="00000000";
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						ram_data(31 downto 20) <= std_logic_vector(to_unsigned(590,12));
						ram_data(19 downto 8) <="000000000000";
						ram_data(7 downto 0) <="00000000";
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						ram_data(31 downto 20) <= std_logic_vector(to_unsigned(640,12));
						ram_data(19 downto 8) <=std_logic_vector(to_unsigned(60,12));
						ram_data(7 downto 0) <="00000000";
						word_state <= 3;
					---------------------------------------------------------------------------------------------d
					else
						ram_data <= "0111111111111110"&"00000000"&"00000000";
						word_state <= 0;
						object_state <= object_state + 1;
					end if;
				----gen scene
				----
				----
				----
				----
				when 6 =>
					ram_addr <= std_logic_vector(to_unsigned((object_state + word_state),12));
					--------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						ram_data(31 downto 20) <= "000000000000";
						ram_data(19 downto 8) <= "000000000000";
						ram_data(7 downto 0) <="00000000";
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						ram_data(31 downto 20) <= std_logic_vector(to_unsigned(650,12));
						ram_data(19 downto 8) <="000000000000";
						ram_data(7 downto 0) <="00000000";
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						ram_data(31 downto 20) <= std_logic_vector(to_unsigned(640,12));
						ram_data(19 downto 8) <=std_logic_vector(to_unsigned(60,12));
						ram_data(7 downto 0) <="00000000";
						word_state <= 3;
					---------------------------------------------------------------------------------------------d
					else
						ram_data <= "0111111111111101"&"00000000"&"00000000";
						word_state <= 0;
						object_state <= object_state + 1;
					end if;
				when 7|8|9|10|11|12 =>  
					i := object_state - 7;
					ram_addr <= std_logic_vector(to_unsigned((4*object_state + word_state),12));
					------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						if(tc(i) = 0) then
							ram_data <= "000000000000"&"000000000000"&"00000000";
						else
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned((tc(i) - 500),12));
							if(i = 0 or i = 1) then-----------y
								ram_data(19 downto 8) <= std_logic_vector(to_unsigned(70,12));
							elsif(i = 2 or i = 3) then
								ram_data(19 downto 8) <= std_logic_vector(to_unsigned(210,12));
							else
								ram_data(19 downto 8) <= std_logic_vector(to_unsigned(350,12));
							end if;
							ram_data(7 downto 0) <= "00000000";
						end if;
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						if(tc(i) = 1 and nc(i) = 1) then
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned(150,12));
							ram_data(19 downto 8) <=std_logic_vector(to_unsigned(0,12));
							ram_data(7 downto 0) <="00000000";
						elsif(tc(i) = 1 and nc(i) = 2) then
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned(150,12));
							ram_data(19 downto 8) <=std_logic_vector(to_unsigned(160,12));
							ram_data(7 downto 0) <="00000000";
						elsif(tc(i) = 1 and nc(i) = 3) then
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned(150,12));
							ram_data(19 downto 8) <=std_logic_vector(to_unsigned(440,12));
							ram_data(7 downto 0) <="00000000";
						elsif(tc(i) = 1 and nc(i) = 4) then
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned(350,12));
							ram_data(19 downto 8) <=std_logic_vector(to_unsigned(0,12));
							ram_data(7 downto 0) <="00000000";
						elsif(tc(i) = 2 and nc(i) = 1) then
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned(250,12));
							ram_data(19 downto 8) <=std_logic_vector(to_unsigned(0,12));
							ram_data(7 downto 0) <="00000000";
						elsif(tc(i) = 2 and nc(i) = 2) then
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned(250,12));
							ram_data(19 downto 8) <=std_logic_vector(to_unsigned(160,12));
							ram_data(7 downto 0) <="00000000";
						elsif(tc(i) = 2 and nc(i) = 3) then
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned(250,12));
							ram_data(19 downto 8) <=std_logic_vector(to_unsigned(440,12));
							ram_data(7 downto 0) <="00000000";
						elsif(tc(i) = 2 and nc(i) = 4) then
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned(450,12));
							ram_data(19 downto 8) <=std_logic_vector(to_unsigned(0,12));
							ram_data(7 downto 0) <="00000000";
						end if;
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						if(tc(i) = 0)then
							ram_data <= "000000000000"&"000000000000"&"00000000";
						else
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned((40+nc(i)*120),12));
							ram_data(19 downto 8) <= std_logic_vector(to_unsigned(100,12));
							ram_data(7 downto 0) <= "00000000";
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
					i := object_state - 13;
					ram_addr <= std_logic_vector(to_unsigned((4*object_state + word_state),12));
					------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						if(tb(i) = 0) then
							ram_data <= "000000000000"&"000000000000"&"00000000";
						else
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned((tb(i) - 500),12));
							if(i = 0 or i = 1) then-----------y
								if(((tc(0)/=0) and (pc(0)<pb(i)) and (pc(0)+nc(0)*120 >pb(i))) or ((tc(1)/=0) and (pc(1)<pb(i)) and (pc(1)+nc(1)*120 >pb(i)))) then
									ram_data(19 downto 8) <= std_logic_vector(to_unsigned(20,12));
								else
									ram_data(19 downto 8) <= std_logic_vector(to_unsigned(70,12));
								end if;
							elsif(i = 2 or i = 3) then
								if(((tc(2)/=0) and (pc(2)<pb(i)) and (pc(2)+nc(2)*120 >pb(i))) or ((tc(3)/=0) and (pc(3)<pb(i)) and (pc(3)+nc(3)*120 >pb(i)))) then
									ram_data(19 downto 8) <= std_logic_vector(to_unsigned(160,12));
								else
									ram_data(19 downto 8) <= std_logic_vector(to_unsigned(210,12));
								end if;
							else
								if(((tc(4)/=0) and (pc(4)<pb(i)) and (pc(4)+nc(4)*120 >pb(i))) or ((tc(5)/=0) and (pc(5)<pb(i)) and (pc(5)+nc(5)*120 >pb(i)))) then
									ram_data(19 downto 8) <= std_logic_vector(to_unsigned(300,12));
								else
									ram_data(19 downto 8) <= std_logic_vector(to_unsigned(350,12));
								end if;
							end if;
							ram_data(7 downto 0) <= "00000000";
						end if;
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						if(tc(i) = 1 ) then
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned(350,12));
							ram_data(19 downto 8) <=std_logic_vector(to_unsigned(520,12));
							ram_data(7 downto 0) <="00000000";
						elsif(tc(i) = 2) then
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned(350,12));
							ram_data(19 downto 8) <=std_logic_vector(to_unsigned(570,12));
							ram_data(7 downto 0) <="00000000";
						elsif(tc(i) = 3) then
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned(550,12));
							ram_data(19 downto 8) <=std_logic_vector(to_unsigned(520,12));
							ram_data(7 downto 0) <="00000000";
						end if;
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						if(tb(i) = 0)then
							ram_data <= "000000000000"&"000000000000"&"00000000";
						else
							ram_data(31 downto 20) <= std_logic_vector(to_unsigned(10,12));
							ram_data(19 downto 8) <= std_logic_vector(to_unsigned(70,12));
							ram_data(7 downto 0) <= "00000000";
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
					ram_addr <= std_logic_vector(to_unsigned((4*19 + word_state),12));
					------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						ram_data(31 downto 20)<=std_logic_vector(to_unsigned(150+pos_h,12));
						ram_data(19 downto 8)<=std_logic_vector(to_unsigned (pos_y+60,12));
						ram_data(7 downto 0) <= "00000000";
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						if(char_state =  "00")then
							ram_data(31 downto 20)<=std_logic_vector(to_unsigned(590,12));
							ram_data(19 downto 8)<=std_logic_vector(to_unsigned (680,12));
							ram_data(7 downto 0) <= "00000000";
						elsif(char_state =  "11")then
							ram_data(31 downto 20)<=std_logic_vector(to_unsigned(590,12));
							ram_data(19 downto 8)<=std_logic_vector(to_unsigned (740,12));
							ram_data(7 downto 0) <= "00000000";
						else
							ram_data(31 downto 20)<=std_logic_vector(to_unsigned(590,12));
							ram_data(19 downto 8)<=std_logic_vector(to_unsigned (640,12));
							ram_data(7 downto 0) <= "00000000";
						end if;
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						if(char_state =  "00")then
							ram_data(31 downto 20)<=std_logic_vector(to_unsigned(60,12));
							ram_data(19 downto 8)<=std_logic_vector(to_unsigned (30,12));
							ram_data(7 downto 0) <= "00000000";
						elsif(char_state =  "11")then
							ram_data(31 downto 20)<=std_logic_vector(to_unsigned(40,12));
							ram_data(19 downto 8)<=std_logic_vector(to_unsigned (50,12));
							ram_data(7 downto 0) <= "00000000";
						else
							ram_data(31 downto 20)<=std_logic_vector(to_unsigned(40,12));
							ram_data(19 downto 8)<=std_logic_vector(to_unsigned (60,12));
							ram_data(7 downto 0) <= "00000000";
						end if;
						word_state <= 3;
					---------------------------------------------------------------------------------------------d
					else
						ram_data <= "0111111111101111"&"00000000"&"00000000";
						word_state <= 0;
						object_state <= 20;
					end if;		
					---------------------------------------------------------------------------------------------
				---gen character
				----
				----
				----
				----
				when 20 =>
					ram_addr <= std_logic_vector(to_unsigned((4*20 + word_state),12));
					------------------------------------------------------------------------------------------x,y
					if(word_state = 0) then
						ram_data(31 downto 20)<=std_logic_vector(to_unsigned(180,12));
						ram_data(19 downto 8)<=std_logic_vector(to_unsigned (240,12));
						ram_data(7 downto 0) <= "00000000";
						word_state <= 1;
					--------------------------------------------------------------------------------------------u,v
					elsif(word_state = 1) then
						ram_data(31 downto 20)<=std_logic_vector(to_unsigned(710,12));
						ram_data(19 downto 8)<=std_logic_vector(to_unsigned (0,12));
						ram_data(7 downto 0) <= "00000000";
						word_state <= 2;
					---------------------------------------------------------------------------------------------w,h
					elsif(word_state = 2) then
						if(survive_sign =  '0')then
							ram_data(31 downto 20)<=std_logic_vector(to_unsigned(200,12));
							ram_data(19 downto 8)<=std_logic_vector(to_unsigned (100,12));
							ram_data(7 downto 0) <= "00000000";
						else
							ram_data <= "000000000000"&"000000000000"&"00000000";
						end if;
						word_state <= 3;
					---------------------------------------------------------------------------------------------d
					else
						ram_data <= "0111111111011111"&"00000000"&"00000000";
						word_state <= 0;
						object_state <= 0;
						geo_busy <= '0';
						data_available <= '1';
					end if;		
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
				data_available <='0';
			end if;
			
		end if;---risingedge
	end process;
	
		
end geo ;