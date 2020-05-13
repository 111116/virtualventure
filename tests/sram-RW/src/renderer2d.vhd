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
      sram_addr1 : out std_logic_vector(19 downto 0);
      sram_q1    : in  std_logic_vector(31 downto 0);
      sram_addr2 : out std_logic_vector(19 downto 0);
      sram_q2    : in  std_logic_vector(31 downto 0);
      sram_addrw : out std_logic_vector(19 downto 0);
      sram_dataw : out std_logic_vector(31 downto 0)
   );
end renderer2d;

architecture behav of renderer2d is

   signal x: integer range 0 to 1000 := 0;
   signal y: integer range 0 to 1000 := 0;
   signal xyaddr: integer range 0 to 1000000 := 0;

   signal clkslow: std_logic := '0';
   signal clkcnt: integer range 0 to 3 := 0;
   signal r0,g0,b0,r1,g1,b1: unsigned(2 downto 0);

begin

   -- clk divider 1/8
   process (clk0, clkcnt)
   begin
      if rising_edge(clk0) then
         if clkcnt = 0 then
            clkslow <= not clkslow;
         end if;
         if clkcnt = 3 then
            clkcnt <= 0;
         else
            clkcnt <= clkcnt + 1;
         end if;
      end if;
   end process;

   sram_addr1 <= x"CCCCC";
   sram_addr2 <= x"CCCCC";
   sram_addrw <= std_logic_vector(to_unsigned(xyaddr, 20));
   sram_dataw <= "00000000000000"&
                  std_logic_vector(b1)&
                  std_logic_vector(g1)&
                  std_logic_vector(r1)&
                  std_logic_vector(b0)&
                  std_logic_vector(g0)&
                  std_logic_vector(r0);

   process (clkslow, x, y)
   begin
      if falling_edge(clkslow) then
         -- update x and y
         if x = 638 then
				if y = 479 then
					y <= 0;
				else
					y <= y+1;
				end if;
            x <= 0;
			else
				x <= x+2;
         end if;
         -- update addr (1 clk behind x,y)
         xyaddr <= x+y*320;
         r0 <= to_unsigned(x/100, 3);
         g0 <= to_unsigned(y/100, 3);
         b0 <= to_unsigned(0, 3);
         r1 <= to_unsigned(x/100, 3);
         g1 <= to_unsigned(y/100, 3);
         b1 <= to_unsigned(0, 3);
      end if;
   end process;

end architecture ; -- behav