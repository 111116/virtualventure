-- 2D renderer

library  ieee;
use      ieee.std_logic_1164.all;
use      ieee.numeric_std.all;

entity renderer2d is
   port(
      clk0: in std_logic; -- 100MHz master clock input
      -- internal ports to geometry buffer (RAM)
      n_element   : in unsigned(11 downto 0);
      geobuf_clk  : out std_logic;
      geobuf_addr : out std_logic_vector(11 downto 0);
      geobuf_q    : in  std_logic_vector(31 downto 0);
      -- controls
      start : in std_logic; -- set HIGH to start
      busy : out std_logic; -- HIGH when busy
      -- internal ports to SRAM controller
      sram_addr1 : out std_logic_vector(19 downto 0);
      sram_q1    : in  std_logic_vector(31 downto 0);
      sram_addr2 : out std_logic_vector(19 downto 0);
      sram_q2    : in  std_logic_vector(31 downto 0);
      sram_addrw : out std_logic_vector(19 downto 0);
      sram_dataw : out std_logic_vector(31 downto 0);
      sram_wren  : out std_logic
   );
end renderer2d;

architecture behav of renderer2d is

   component tile_renderer is
      port (
         -- control signals
         clk0   : in std_logic;
         startx : in unsigned(9 downto 0);
         starty : in unsigned(9 downto 0);
         start  : in std_logic;
         busy   : out std_logic;
         -- internal ports to geometry buffer (RAM)
         n_element   : in unsigned(11 downto 0);
         geobuf_clk  : out std_logic;
         geobuf_addr : out std_logic_vector(11 downto 0);
         geobuf_q    : in  std_logic_vector(31 downto 0);
         -- internal ports to tile buffer (RAM)
         tilebuf_clk  : out std_logic;
         tilebuf_wren : out std_logic;
         tilebuf_addr : out std_logic_vector(12 downto 0);
         tilebuf_data : out std_logic_vector(35 downto 0);
         -- internal ports to SRAM controller
         sram_addr1 : out std_logic_vector(19 downto 0); -- read1
         sram_q1    : in  std_logic_vector(31 downto 0); -- read1
         sram_addr2 : out std_logic_vector(19 downto 0); -- read2
         sram_q2    : in  std_logic_vector(31 downto 0)  -- read2
      );
   end component tile_renderer;

   component tile_buffer_ram is
      PORT
      (
         data        : IN STD_LOGIC_VECTOR (35 DOWNTO 0);
         rdaddress   : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
         rdclock     : IN STD_LOGIC ;
         rden        : IN STD_LOGIC  := '1';
         wraddress   : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
         wrclock     : IN STD_LOGIC  := '1';
         wren        : IN STD_LOGIC  := '0';
         q           : OUT STD_LOGIC_VECTOR (35 DOWNTO 0)
      );
   end component tile_buffer_ram;

   component fb_filler is
      port (
         -- control signals
         clk0       : in std_logic; -- 100MHz clock
         start_addr : in unsigned(19 downto 0); -- unregistered
         start      : in std_logic;
         busy       : out std_logic;
         -- ports to tile buffer
         buf_clk  : out std_logic;
         buf_addr : out std_logic_vector(12 downto 0);
         buf_q    : in  std_logic_vector(35 downto 0);
         -- internal ports to SRAM controller
         sram_addrw : out std_logic_vector(19 downto 0); -- write
         sram_dataw : out std_logic_vector(31 downto 0); -- write
         sram_wren  : out std_logic
      );
   end component fb_filler;

   -- ports of tile buffer
   signal tilebuf1_out_rden : std_logic;
   signal tilebuf2_out_rden : std_logic;
   signal tilebuf1_in_wren : std_logic;
   signal tilebuf2_in_wren : std_logic;
   signal tilebuf1_out_q : std_logic_vector(35 downto 0);
   signal tilebuf2_out_q : std_logic_vector(35 downto 0);
   -- shared ports
   signal tilebuf_in_clk  : std_logic;
   signal tilebuf_in_wren : std_logic;
   signal tilebuf_in_addr : std_logic_vector(12 downto 0);
   signal tilebuf_in_data : std_logic_vector(35 downto 0);
   signal tilebuf_out_clk  : std_logic;
   signal tilebuf_out_addr : std_logic_vector(12 downto 0);
   signal tilebuf_out_q    : std_logic_vector(35 downto 0);

   -- control
   signal start_renderer : std_logic := '0';
   signal start_filler   : std_logic := '0';
   signal busy_renderer  : std_logic;
   signal busy_filler    : std_logic;

   -- slow clock
   signal clkcnt : integer range 0 to 100 := 0;
   -- progress=0~48: working
   -- progress=49: idle
   signal progress : integer range 0 to 100 := 49;

   -- control params
   signal block_x0 : unsigned (9 downto 0);
   signal block_y0 : unsigned (9 downto 0);
   signal framebuf_start_addr : unsigned (19 downto 0);
   signal renderer_enable : std_logic := '0';
   signal filler_enable : std_logic := '0';

   signal write_buf_select : std_logic := '0';
   signal read_buf_select : std_logic := '0';

begin

   tilebuf1 : tile_buffer_ram port map (
      data      => tilebuf_in_data,
      rdaddress => tilebuf_out_addr,
      rdclock   => tilebuf_out_clk,
      rden      => tilebuf1_out_rden,
      wraddress => tilebuf_in_addr,
      wrclock   => tilebuf_in_clk,
      wren      => tilebuf1_in_wren,
      q         => tilebuf1_out_q
   );

   tilebuf2 : tile_buffer_ram port map (
      data      => tilebuf_in_data,
      rdaddress => tilebuf_out_addr,
      rdclock   => tilebuf_out_clk,
      rden      => tilebuf2_out_rden,
      wraddress => tilebuf_in_addr,
      wrclock   => tilebuf_in_clk,
      wren      => tilebuf2_in_wren,
      q         => tilebuf2_out_q
   );

   tilebuf1_out_rden <= '1' when read_buf_select='0' else '0';
   tilebuf2_out_rden <= '1' when read_buf_select='1' else '0';
   tilebuf_out_q <= tilebuf1_out_q when read_buf_select='0' else tilebuf2_out_q;
   tilebuf1_in_wren <= tilebuf_in_wren when write_buf_select='0' else '0';
   tilebuf2_in_wren <= tilebuf_in_wren when write_buf_select='1' else '0';

   renderer : tile_renderer port map (
      clk0   => clk0,
      startx => block_x0,
      starty => block_y0,
      start  => start_renderer,
      busy   => busy_renderer,
      -- internal ports to geometry buffer (RAM)
      n_element   => n_element,
      geobuf_clk  => geobuf_clk,
      geobuf_addr => geobuf_addr,
      geobuf_q    => geobuf_q,
      -- internal ports to tile buffer (RAM)
      tilebuf_clk  => tilebuf_in_clk,
      tilebuf_wren => tilebuf_in_wren,
      tilebuf_addr => tilebuf_in_addr,
      tilebuf_data => tilebuf_in_data,
      -- internal ports to SRAM controller
      sram_addr1 => sram_addr1,
      sram_q1    => sram_q1,
      sram_addr2 => sram_addr2,
      sram_q2    => sram_q2
   );

   filler : fb_filler port map (
      clk0       => clk0,
      start_addr => framebuf_start_addr,
      start      => start_filler,
      busy       => busy_filler,
      -- ports to tile buffer
      buf_clk    => tilebuf_out_clk,
      buf_addr   => tilebuf_out_addr,
      buf_q      => tilebuf_out_q,
      -- internal ports to SRAM controller
      sram_addrw => sram_addrw,
      sram_dataw => sram_dataw,
      sram_wren  => sram_wren
   );

   -- state control
   process (clk0, clkcnt)
   begin
      if rising_edge(clk0) then
         if clkcnt < 90 then
            clkcnt <= clkcnt + 1;
			else
            -- clkcnt>=90: wait for current block to finish
            if busy_filler='0' and busy_renderer='0' then
               -- current block finished
               if progress < 49 then
                  -- continue work on next block
                  progress <= progress + 1;
   			      clkcnt <= 0;
               else
                  -- job batch finished, wait for next start signal
                  if start='1' then
                     busy <= '1';
                     progress <= 0;
                     clkcnt <= 0;
                  else
                     busy <= '0';
                  end if;
               end if;
            end if;
         end if;
      end if;
   end process;

   -- calc submodule control params
   process (progress) -- comb
      variable progress_prev: integer range 0 to 100;
      variable x,y: integer range 0 to 1000;
      variable x_prev,y_prev: integer range 0 to 1000;
   begin
      if progress = 0 then
         progress_prev := 0;
      else
         progress_prev := progress-1;
      end if;
      x := 80 * (progress mod 8);
      y := 80 * (progress / 8);
      x_prev := 80 * (progress_prev mod 8);
      y_prev := 80 * (progress_prev / 8);
      -- select RAM connection
      if progress mod 2 = 0 then
         write_buf_select <= '0';
      else
         write_buf_select <= '1';
      end if;
      if progress_prev mod 2 = 0 then
         read_buf_select <= '0';
      else
         read_buf_select <= '1';
      end if;
      -- coordinate signals
      block_x0 <= to_unsigned(x, block_x0'length);
      block_y0 <= to_unsigned(y, block_y0'length);
      framebuf_start_addr <= to_unsigned(x_prev / 2 + y_prev * 320, framebuf_start_addr'length);
      -- enable signals
      if progress < 48 then
         renderer_enable <= '1';
      else
         renderer_enable <= '0';
      end if;
      if progress > 0 and progress < 49 then
         filler_enable <= '1';
      else
         filler_enable <= '0';
      end if;
   end process;

   -- submodule start control
   process (clk0, clkcnt)
   begin
      if rising_edge(clk0) then
         if clkcnt >= 32 and clkcnt < 64 then
            start_renderer <= renderer_enable;
            start_filler <= filler_enable;
         else
            start_renderer <= '0';
            start_filler <= '0';
         end if;
      end if;
   end process;

end architecture behav;