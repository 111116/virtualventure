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

   -- 80ns cycled clock
   signal clkslow : std_logic := '0';
   signal clkcnt : integer range 0 to 3 := 0;

   -- pipeline registers
   signal x : integer range 0 to 1000 := 0;
   signal y : integer range 0 to 1000 := 0;
   signal writeaddr        : std_logic_vector(19 downto 0);
   signal writeaddr_reg1   : std_logic_vector(19 downto 0);
   signal sram_q1_reg1     : std_logic_vector(31 downto 0);
   signal sram_q2_reg1     : std_logic_vector(31 downto 0);

begin

   -- clk divider 1/8
   -- hopefully clk is ahead of SRAM fetch timing
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

   -- stage 0: update coordinate
   process (clkslow, x, y)
   begin
      if rising_edge(clkslow) then
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
      end if;
   end process;

   -- stage 1: calc fetch & write addr
   process (clkslow, x, y)
      variable x0,y0,x1,y1: integer range 0 to 1000;
   begin
      if rising_edge(clkslow) then
         -- texture coordinate
         x0 := x;
         y0 := y + 150;
         x1 := x + 1;
         y1 := y + 150;
         -- texture address
         sram_addr1 <= std_logic_vector(to_unsigned(x0+y0*1024,20));
         sram_addr2 <= std_logic_vector(to_unsigned(x1+y1*1024,20));
         writeaddr  <= std_logic_vector(to_unsigned(x/2+y*320, 20));
      end if;
   end process;

   -- stage 2: fetch data
   process (clkslow, sram_q1, sram_q2, writeaddr)
   begin
      if rising_edge(clkslow) then
         sram_q1_reg1 <= sram_q1;
         sram_q2_reg1 <= sram_q2;
         writeaddr_reg1 <= writeaddr;
      end if;
   end process;

   -- state 3: calculate quantized color
   process (clkslow, sram_q1_reg1, sram_q2_reg1, writeaddr_reg1)
      variable r1,g1,b1,r2,g2,b2: std_logic_vector(2 downto 0); -- to fill
   begin
      if rising_edge(clkslow) then
         -- direct quantize (floor)
         r1 := sram_q1_reg1(7 downto 5);
         g1 := sram_q1_reg1(15 downto 13);
         g1 := sram_q1_reg1(23 downto 21);
         r2 := sram_q2_reg1(7 downto 5);
         g2 := sram_q2_reg1(15 downto 13);
         g2 := sram_q2_reg1(23 downto 21);
         sram_addrw <= writeaddr_reg1;
         sram_dataw <= "00000000000000"&b2&g2&r2&b1&g1&r1;
      end if;
   end process;

end architecture ; -- behav