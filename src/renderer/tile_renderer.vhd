-- Tile Renderer
-- Renders to a tile buffer of texture address.
-- synchronously triggered by `start` (active high), sets busy='1' after a cycle.
-- sets busy='0' when done.

library  ieee;
use      ieee.std_logic_1164.all;
use      ieee.numeric_std.all;


entity tile_renderer is
   port (
      -- control signals
      clk0   : in std_logic;              -- must not exceed max freq of RAM
      startx : in unsigned(9 downto 0);   -- leftmost position of tile rendered
      starty : in unsigned(9 downto 0);   -- uppermost position of tile rendered
      start   : in std_logic;             -- start trigger, active high
      busy    : out std_logic;            -- indicates working, active high
      -- internal ports to geometry buffer (RAM)
      --geobuf_clk  : out std_logic;
      --geobuf_addr : out std_logic_vector();
      --geobuf_q    : in  std_logic_vector();
      -- internal ports to tile buffer (RAM)
      tilebuf_clk  : out std_logic;
      tilebuf_wren : out std_logic;
      tilebuf_addr : out std_logic_vector(12 downto 0);
      tilebuf_data : out std_logic_vector(35 downto 0)
   );
end entity tile_renderer;


architecture behav of tile_renderer is

   signal x, x_reg : integer range 0 to 79 := 0; -- current position in tile
   signal y, y_reg : integer range 0 to 79 := 0; -- current position in tile
   signal state_busy : std_logic := '0';

begin
   
   -- stage 0: update state & current position
   process (clk0, x, y, start, state_busy)
   begin
      if rising_edge(clk0) then
         if state_busy = '0' and start = '1' then
            -- initialize
            state_busy <= '1';
            x <= 0;
            y <= 0;
         -- otherwise continue update x and y in [0..79]^2
         elsif x = 79 then
            if y = 79 then
               -- finished
               state_busy <= '0';
            else
               y <= y+1;
            end if;
            x <= 0;
         else
            x <= x+1;
         end if;
      end if;
   end process;

   tilebuf_clk <= clk0;

   -- stage 1: fill tile buffer
   process (clk0, x, y, startx, starty, state_busy)
      variable tx, ty: integer range 0 to 1023;
   begin
      tilebuf_wren <= state_busy;
      busy <= state_busy;
      tilebuf_addr <= std_logic_vector(to_unsigned(x + y * 80, tilebuf_addr'length));
      -- texture address
      tx := to_integer(startx) + x;
      ty := to_integer(starty) + y + 150;
      tilebuf_data <= x"0000" & std_logic_vector(to_unsigned(tx + ty * 1024, 20));
   end process;
   
end architecture behav;
