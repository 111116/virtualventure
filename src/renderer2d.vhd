-- 2D renderer

library  ieee;
use      ieee.std_logic_1164.all;
use      ieee.numeric_std.all;

entity renderer2d is
   port(
      clk0: in std_logic; -- 100MHz master clock input
      -- internal ports to geometry buffer (RAM)
      --ram_clk: out std_logic;
      --ram_addr: out std_logic_vector();
      --ram_q: in std_logic_vector();
      -- internal ports to geometry generator
      --data_available : in std_logic;
      --busy : out std_logic;
      -- internal ports to SRAM controller
      sram_addr  : out std_logic_vector(19 downto 0);
      sram_data  : out std_logic_vector(31 downto 0);
      sram_q     : in std_logic_vector(31 downto 0);
      sram_wren  : out std_logic;
      sram_ready : in std_logic
   );
end renderer2d;

architecture behav of renderer2d is

   signal x: integer range 0 to 1000 := 0;
   signal y: integer range 0 to 1000 := 0;
   signal xyaddr: integer range 0 to 1000000 := 0;

begin

   sram_wren <= '1';
   sram_addr <= std_logic_vector(to_unsigned(xyaddr, 20));
   sram_data <= std_logic_vector(to_unsigned(xyaddr, 32));

   process (clk0, sram_ready)
   begin
      if rising_edge(clk0) and sram_ready = '1' then
         -- update x and y
         if x = 639 then
				if y = 479 then
					y <= 0;
				else
					y <= y+1;
				end if;
            x <= 0;
			else
				x <= x+1;
         end if;
         -- update addr
			if xyaddr = 640*480-1 then
				xyaddr <= 0;
			else
				xyaddr <= xyaddr + 1;
			end if;
      end if;
   end process;

end architecture ; -- behav