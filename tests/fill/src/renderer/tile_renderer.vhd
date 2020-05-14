
library  ieee;
use      ieee.std_logic_1164.all;
use      ieee.numeric_std.all;


entity tile_renderer is
   port (
      -- control signals
      clk0   : in std_logic;
      startx : in unsigned(9 downto 0);
      starty : in unsigned(9 downto 0);
      --start   : in std_logic;
      --busy    : out std_logic;
      -- internal ports to geometry buffer (RAM)
      --geobuf_clk  : out std_logic;
      --geobuf_addr : out std_logic_vector();
      --geobuf_q    : in  std_logic_vector();
      -- internal ports to tile buffer (RAM)
      tilebuf_clk  : out std_logic;
      tilebuf_addr : out std_logic_vector(12 downto 0);
      tilebuf_data : out std_logic_vector(35 downto 0)
   );
end entity tile_renderer;


architecture behav of tile_renderer is

   signal x, x_reg : integer range 0 to 79 := 0;
   signal y, y_reg : integer range 0 to 79 := 0;

begin
   
   process (clk0, x, y)
   begin
      if rising_edge(clk0) then
         if x = 79 then
            if y = 79 then
               y <= 0;
            else
               y <= y+1;
            end if;
            x <= 0;
         else
            x <= x+1;
         end if;
      end if;
   end process;

   process (clk0, x, y)
      variable tx, ty: integer range 0 to 1023;
   begin
      tilebuf_addr <= std_logic_vector(to_unsigned(x + y * 80, tilebuf_addr'length));
      -- texture address
      tx := to_integer(startx) + x;
      ty := to_integer(starty) + y + 150;
      tilebuf_data <= x"0000" & std_logic_vector(to_unsigned(tx + ty * 1024, 20));
   end process;
   
end architecture behav;
