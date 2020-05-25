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
		clk:in std_logic;
		UD: out std_logic_vector(1 downto 0);
		LR: out std_logic_vector(1 downto 0);
		Rx : in std_logic
	);
	type array3 is array(10 downto 0) of std_logic_vector(7 downto 0);
end input_controller;

architecture input of input_controller is
	signal angle_lr:std_logic_vector(7 downto 0);---取[-180,180]取整,左负右正，最高位表示正副，其余八位表示数值.大于128则以128计
	signal angle_ud: std_logic_vector(7 downto 0);
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
--------------------------------------------------------------------------------------------------------------------------------------

	component async_receiver
	port(
		clk:in std_logic;
		RxD:in std_logic;
		RxD_data_ready:out std_logic;
		RxD_clear:in std_logic;
		RxD_data:out std_logic_vector(7 downto 0)
	);
	end component;
-------------------------------------------------------------------------------------------------------------------------------------
begin
	a_r:async_receiver port map(clk,Rx,async_ready,Rd_clear,async_buff);
	
	process(async_buff,async_ready)
	begin
	if(rising_edge(clk))then
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
	end if;
	end process;
	
	process(angle_lr,angle_ud)
	begin
		if(rising_edge(clk)) then
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
	
		end if;
	end process;
end input;