-- Tile Renderer
-- Renders to a tile buffer of texture address.
-- synchronously triggered by `start` (active high)
-- sets busy='0' when done.

-- procedure: foreach element, fetch params -> calculate overlapped bound -> loop over pixels

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
      -- internal ports to geometry input buffer (RAM)
      n_element   : in unsigned(11 downto 0);
      geobuf_clk  : out std_logic;
      geobuf_addr : out std_logic_vector(11 downto 0);
      geobuf_q    : in  std_logic_vector(31 downto 0);
      -- internal ports to tile output buffer (RAM)
      tilebuf_clk  : out std_logic;
      tilebuf_wren : out std_logic;
      tilebuf_addr : out std_logic_vector(12 downto 0);
      tilebuf_data : out std_logic_vector(35 downto 0)
   );
end entity tile_renderer;


architecture behav of tile_renderer is

   signal x,y : integer range 0 to 79; -- loop variable: current position in tile

   type state_t is (st_idle, st_0, st_1, st_2, st_3, st_4, st_5, st_work);
   signal state : state_t := st_idle;
   signal element_id : integer range 0 to 1023; -- outer loop variable: which element is being drawed

   signal param_x, param_y : integer range -2048 to 2047 := 0;
   signal param_u, param_v : integer range 0 to 4095 := 0;
   signal param_w, param_h : integer range 0 to 4095 := 0;
   signal param_d : unsigned (15 downto 0);

   signal rel_x, rel_y : integer range -2048 to 2047; -- position of drawed rectangle relative to current block
   signal rel_u, rel_v : integer range -2048 to 2047; -- texture coordinate of topleft corner of current block as if it's drawed
   signal rel_xend, rel_yend : integer range -2048 to 2047; -- end position of drawed rectangle relative to current block
   signal loop_xbegin, loop_ybegin, loop_xend, loop_yend : integer range -2048 to 2047; -- range of loop
   signal loop_empty : std_logic;
   signal cur_valid : std_logic;

begin

   busy <= '1' when state /= st_idle else '0';
   geobuf_clk <= clk0;
   
   -- stage 0: update state & select element & current position
   process (clk0, start, state, x, y)
   begin
      if rising_edge(clk0) then
         case state is
            when st_idle =>
               if start = '1' then
                  -- initialize
                  state <= st_0;
                  element_id <= 0;
                  cur_valid <= '0';
               end if;
            when st_0 =>
               if element_id = n_element then -- outer loop is over
                  state <= st_idle;
               else
                  state <= st_1;
               end if;
            when st_1 =>
               state <= st_2;
            when st_2 =>
               state <= st_3;
            when st_3 =>
               state <= st_4;
            when st_4 =>
               state <= st_5;
            when st_5 =>
               -- check if loop range is empty
               if loop_empty = '1' then
                  state <= st_0;
                  element_id <= element_id + 1;
						cur_valid <= '0';
               else
                  state <= st_work;
						cur_valid <= '1';
               end if;
               -- start x-y loop
               x <= loop_xbegin;
               y <= loop_ybegin;
            when st_work =>
               -- loop control
               if x+1=loop_xend then
                  x <= loop_xbegin;
                  if y+1=loop_yend then -- inner loop is over
                     state <= st_0;
                     element_id <= element_id + 1;
                     cur_valid <= '0';
                  else
                     y <= y+1;
                  end if;
               else
                  x <= x+1;
               end if;
         end case;
      end if;
   end process;

   -- fetch parameters of primitive
   process (clk0, state, element_id, geobuf_q)
   begin
      if rising_edge(clk0) then
         case state is
            when st_0 =>
               -- fetch param X,Y
               geobuf_addr <= std_logic_vector(to_unsigned(element_id*4+0, geobuf_addr'length));
            when st_1 =>
               -- fetch param U,V
               geobuf_addr <= std_logic_vector(to_unsigned(element_id*4+1, geobuf_addr'length));
            when st_2 =>
               -- fetch param W,H
               geobuf_addr <= std_logic_vector(to_unsigned(element_id*4+2, geobuf_addr'length));
               param_x <= to_integer(signed(geobuf_q(11 downto 0)));
               param_y <= to_integer(signed(geobuf_q(23 downto 12)));
            when st_3 =>
               -- fetch param D
               geobuf_addr <= std_logic_vector(to_unsigned(element_id*4+3, geobuf_addr'length));
               param_u <= to_integer(unsigned(geobuf_q(11 downto 0)));
               param_v <= to_integer(unsigned(geobuf_q(23 downto 12)));
            when st_4 =>
               param_w <= to_integer(unsigned(geobuf_q(11 downto 0)));
               param_h <= to_integer(unsigned(geobuf_q(23 downto 12)));
            when st_5 =>
               param_d <= unsigned(geobuf_q(15 downto 0));
            when others =>
               null;
         end case;
      end if;
   end process;

   -- comb: calculate overlapped bounding box
   process (param_x, param_y, param_w, param_h, param_u, param_v, startx, starty, rel_x, rel_y, rel_xend, rel_yend, loop_xbegin, loop_xend, loop_ybegin, loop_yend)
   begin
      rel_x <= param_x - to_integer(startx);
      rel_y <= param_y - to_integer(starty);
      rel_xend <= rel_x + param_w;
      rel_yend <= rel_y + param_h;
      rel_u <= param_u - rel_x;
      rel_v <= param_v - rel_y;
      -- loop_xbegin = max(rel_x, 0)
      if rel_x>=0 then
         loop_xbegin <= rel_x;
      else
         loop_xbegin <= 0;
      end if;
      -- loop_ybegin = max(rel_y, 0)
      if rel_y>=0 then
         loop_ybegin <= rel_y;
      else
         loop_ybegin <= 0;
      end if;
      -- loop_xend = min(rel_xend, 80)
      if rel_xend>=80 then
         loop_xend <= 80;
      else
         loop_xend <= rel_xend;
      end if;
      -- loop_yend = min(rel_yend, 80)
      if rel_yend>=80 then
         loop_yend <= 80;
      else
         loop_yend <= rel_yend;
      end if;
      -- check if loop is empty
      if loop_xbegin >= loop_xend or loop_ybegin >= loop_yend then
         loop_empty <= '1';
      else
         loop_empty <= '0';
      end if;
   end process;

   tilebuf_clk <= clk0;

   -- stage 1: fill tile buffer
   process (clk0, x, y, cur_valid, rel_u, rel_v)
      variable tx, ty: integer range 0 to 1023;
   begin
      tilebuf_wren <= cur_valid;
      tilebuf_addr <= std_logic_vector(to_unsigned(x + y * 80, tilebuf_addr'length));
      -- texture address
      tx := x + rel_u;
      ty := y + rel_v;
      tilebuf_data <= x"0000" & std_logic_vector(to_unsigned(tx + ty * 1024, 20));
   end process;
   
end architecture behav;
