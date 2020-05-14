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

   component tile_renderer is
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
   end component tile_renderer;

   component tile_buffer_ram is
      port (
         
      );
   end component tile_buffer_ram;

   component texture_filler is
      port (
         -- control signals
         clk0 : in std_logic; -- 100MHz clock
         start_addr : in unsigned(19 downto 0); -- unregistered
         -- ports to tile buffer
         buf_addr : out std_logic_vector(12 downto 0);
         buf_q    : in  std_logic_vector(35 downto 0);
         -- internal ports to SRAM controller
         sram_addr1 : out std_logic_vector(19 downto 0); -- read1
         sram_q1    : in  std_logic_vector(31 downto 0); -- read1
         sram_addr2 : out std_logic_vector(19 downto 0); -- read2
         sram_q2    : in  std_logic_vector(31 downto 0); -- read2
         sram_addrw : out std_logic_vector(19 downto 0); -- write
         sram_dataw : out std_logic_vector(31 downto 0)  -- write
      );
   end component texture_filler;

   -- ports of tile buffer
   signal tilebuf_in_clk  : std_logic;
   signal tilebuf_in_addr : std_logic_vector(12 downto 0);
   signal tilebuf_in_data : std_logic_vector(35 downto 0);
   signal tilebuf_out_clk  : std_logic;
   signal tilebuf_out_addr : std_logic_vector(12 downto 0);
   signal tilebuf_out_q    : std_logic_vector(35 downto 0);

begin

   tilebuf1 : tile_buffer_ram port map (
      
   );

   renderer : tile_renderer port map (
      clk0   => clk0,
      startx => 160,
      starty => 160,
      --start   : in std_logic;
      --busy    : out std_logic;
      -- internal ports to geometry buffer (RAM)
      --geobuf_clk  : out std_logic;
      --geobuf_addr : out std_logic_vector();
      --geobuf_q    : in  std_logic_vector();
      -- internal ports to tile buffer (RAM)
      tilebuf_clk  => tilebuf_in_clk,
      tilebuf_addr => tilebuf_in_data,
      tilebuf_data => tilebuf_in_addr
   );

   filler : texture_filler port map (
      clk0   => clk0,
      start_addr => 0,
      -- ports to tile buffer
      buf_addr   => tilebuf_out_addr,
      buf_q      => tilebuf_out_q,
      -- internal ports to SRAM controller
      sram_addr1 => sram_addr1,
      sram_q1    => sram_q1,
      sram_addr2 => sram_addr2,
      sram_q2    => sram_q2,
      sram_addrw => sram_addrw,
      sram_dataw => sram_dataw
   );
   
end architecture behav;