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
         --geobuf_clk  : out std_logic;
         --geobuf_addr : out std_logic_vector();
         --geobuf_q    : in  std_logic_vector();
         -- internal ports to tile buffer (RAM)
         tilebuf_clk  : out std_logic;
         tilebuf_wren : out std_logic;
         tilebuf_addr : out std_logic_vector(12 downto 0);
         tilebuf_data : out std_logic_vector(35 downto 0)
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

   component texture_filler is
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
         sram_addr1 : out std_logic_vector(19 downto 0); -- read1
         sram_q1    : in  std_logic_vector(31 downto 0); -- read1
         sram_addr2 : out std_logic_vector(19 downto 0); -- read2
         sram_q2    : in  std_logic_vector(31 downto 0); -- read2
         sram_addrw : out std_logic_vector(19 downto 0); -- write
         sram_dataw : out std_logic_vector(31 downto 0); -- write
         sram_wren  : out std_logic
      );
   end component texture_filler;

   -- ports of tile buffer
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

begin

   tilebuf1 : tile_buffer_ram port map (
      data      => tilebuf_in_data,
      rdaddress => tilebuf_out_addr,
      rdclock   => tilebuf_out_clk,
      rden      => '1',
      wraddress => tilebuf_in_addr,
      wrclock   => tilebuf_in_clk,
      wren      => tilebuf_in_wren,
      q         => tilebuf_out_q
   );

   renderer : tile_renderer port map (
      clk0   => clk0,
      startx => to_unsigned(160, 10),
      starty => to_unsigned(160, 10),
      start  => start_renderer,
      busy   => busy_renderer,
      -- internal ports to geometry buffer (RAM)
      --geobuf_clk  : out std_logic;
      --geobuf_addr : out std_logic_vector();
      --geobuf_q    : in  std_logic_vector();
      -- internal ports to tile buffer (RAM)
      tilebuf_clk  => tilebuf_in_clk,
      tilebuf_wren => tilebuf_in_wren,
      tilebuf_addr => tilebuf_in_addr,
      tilebuf_data => tilebuf_in_data
   );

   filler : texture_filler port map (
      clk0   => clk0,
      start_addr => to_unsigned(0, 20),
      start  => start_filler,
      busy   => busy_filler,
      -- ports to tile buffer
      buf_clk    => tilebuf_out_clk,
      buf_addr   => tilebuf_out_addr,
      buf_q      => tilebuf_out_q,
      -- internal ports to SRAM controller
      sram_addr1 => sram_addr1,
      sram_q1    => sram_q1,
      sram_addr2 => sram_addr2,
      sram_q2    => sram_q2,
      sram_addrw => sram_addrw,
      sram_dataw => sram_dataw,
      sram_wren  => sram_wren
   );

   process (clk0, clkcnt)
   begin
      if rising_edge(clk0) then
         if clkcnt < 90 then
            clkcnt <= clkcnt + 1;
			elsif busy_filler='0' then
				clkcnt <= 0;
         end if;
         if clkcnt >= 32 and clkcnt < 64 then
            start_renderer <= '1';
            start_filler <= '1';
         else
            start_renderer <= '0';
            start_filler <= '0';
         end if;
      end if;
   end process;

end architecture behav;