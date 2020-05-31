-- renderer usage example

library  ieee;
use      ieee.std_logic_1164.all;
use      ieee.numeric_std.all;

entity geometry_demo is
	port (
      -- control signals
      clk0   : in std_logic;              -- must not exceed max freq of RAM
      render_start : out std_logic;
      -- internal ports to geometry input buffer (RAM)
      n_element   : out unsigned(11 downto 0);
      geobuf_clk  : out std_logic;
      geobuf_wren : out std_logic;
      geobuf_addr : out std_logic_vector(11 downto 0);
      geobuf_data : out std_logic_vector(31 downto 0)
	);
end entity geometry_demo;

architecture arch of geometry_demo is

	signal state : integer range 0 to 65535 := 0;
	
begin
	n_element <= to_unsigned(2, n_element'length);
	render_start <= '1';
	geobuf_clk <= clk0;
	geobuf_data(31 downto 24) <= (others => '0');

	-- update state
	process (clk0, state)
	begin
		if rising_edge(clk0) then
			if state = 65535 then
				state <= 0;
			else
				state <= state + 1;
			end if;
		end if;
	end process;

	-- write content
	process (clk0, state)
		variable x,y,u,v,w,h,d:integer;
	begin
		if rising_edge(clk0) then
			case state is
				when 0 =>
					x := 0;
					y := 0;
					geobuf_addr <= std_logic_vector(to_unsigned(0, geobuf_addr'length));
					geobuf_data(11 downto 0)  <= std_logic_vector(to_unsigned(x, 12));
					geobuf_data(23 downto 12) <= std_logic_vector(to_unsigned(y, 12));
					geobuf_wren <= '1';
				when 1 =>
					u := 0;
					v := 300;
					geobuf_addr <= std_logic_vector(to_unsigned(1, geobuf_addr'length));
					geobuf_data(11 downto 0)  <= std_logic_vector(to_unsigned(u, 12));
					geobuf_data(23 downto 12) <= std_logic_vector(to_unsigned(v, 12));
					geobuf_wren <= '1';
				when 2 =>
					w := 640;
					h := 480;
					geobuf_addr <= std_logic_vector(to_unsigned(2, geobuf_addr'length));
					geobuf_data(11 downto 0)  <= std_logic_vector(to_unsigned(w, 12));
					geobuf_data(23 downto 12) <= std_logic_vector(to_unsigned(h, 12));
					geobuf_wren <= '1';
				when 3 =>
					d := 0;
					geobuf_addr <= std_logic_vector(to_unsigned(3, geobuf_addr'length));
					geobuf_data(15 downto 0)  <= std_logic_vector(to_unsigned(d, 16));
					geobuf_data(23 downto 16) <= std_logic_vector(to_unsigned(0, 8));
					geobuf_wren <= '1';
				when 4 =>
					x := 100;
					y := 100;
					geobuf_addr <= std_logic_vector(to_unsigned(4, geobuf_addr'length));
					geobuf_data(11 downto 0)  <= std_logic_vector(to_unsigned(x, 12));
					geobuf_data(23 downto 12) <= std_logic_vector(to_unsigned(y, 12));
					geobuf_wren <= '1';
				when 5 =>
					u := 238;
					v := 1043;
					geobuf_addr <= std_logic_vector(to_unsigned(5, geobuf_addr'length));
					geobuf_data(11 downto 0)  <= std_logic_vector(to_unsigned(u, 12));
					geobuf_data(23 downto 12) <= std_logic_vector(to_unsigned(v, 12));
					geobuf_wren <= '1';
				when 6 =>
					w := 500;
					h := 400;
					geobuf_addr <= std_logic_vector(to_unsigned(6, geobuf_addr'length));
					geobuf_data(11 downto 0)  <= std_logic_vector(to_unsigned(w, 12));
					geobuf_data(23 downto 12) <= std_logic_vector(to_unsigned(h, 12));
					geobuf_wren <= '1';
				when 7 =>
					d := 0;
					geobuf_addr <= std_logic_vector(to_unsigned(7, geobuf_addr'length));
					geobuf_data(15 downto 0)  <= std_logic_vector(to_unsigned(d, 16));
					geobuf_data(23 downto 16) <= std_logic_vector(to_unsigned(0, 8));
					geobuf_wren <= '1';
				when others =>
					geobuf_wren <= '0';
			end case;
		end if;
	end process;
end architecture arch;