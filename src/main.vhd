
library  ieee;
use      ieee.std_logic_1164.all;
use      ieee.numeric_std.all;

entity main is
   port (
      -- 100MHz master clock input
      clk0 : in std_logic;
      -- restart button
      rst  : in std_logic;
      rst_indicator : out std_logic;
      -- player input
      UD: in std_logic_vector(1 downto 0);
      LR: in std_logic_vector(1 downto 0);
      -- external ports to SRAM
      sram_addr: out std_logic_vector(19 downto 0);
      sram_data: inout std_logic_vector(31 downto 0);
      sram_oe: out std_logic; -- low valid
      sram_we: out std_logic; -- low valid
      sram_ce: out std_logic; -- low valid
      -- external ports to VGA
      vga_r, vga_g, vga_b : out std_logic_vector(2 downto 0);
      vga_hs, vga_vs : out std_logic
   );
end entity main; -- main


architecture arch of main is

   component game
      port (
         UD: in std_logic_vector(1 downto 0);
         LR: in std_logic_vector(1 downto 0);
         clk:in std_logic;
         type_carriage: out std_logic_vector(11 downto 0);
         pos_carriage:out std_logic_vector(71 downto 0);
         num_carriage:out std_logic_vector(17 downto 0);
         pos_barrier:out std_logic_vector(71 downto 0);
         type_barrier:out std_logic_vector(11 downto 0);
         character_y:out std_logic_vector(11 downto 0);
         character_h:out std_logic_vector(11 downto 0);
         character_state:out std_logic_vector(1 downto 0);
         survive_sign :out std_logic;
         data_ready:out std_logic;
         reset : in std_logic
      );
   end component;

   signal data_ready:  std_logic;
   signal type_carriage: std_logic_vector(11 downto 0);
   signal pos_carriage :std_logic_vector(71 downto 0);
   signal num_carriage: std_logic_vector(17 downto 0);
   signal pos_barrier: std_logic_vector(71 downto 0);
   signal type_barrier: std_logic_vector(11 downto 0);
   signal character_y: std_logic_vector(11 downto 0);
   signal character_h: std_logic_vector(11 downto 0);
   signal character_state: std_logic_vector(1 downto 0);
   signal survive : std_logic:='1';

   component geometry 
      port (
         clk: in std_logic;
         render_busy: in std_logic;
         data_ready: in std_logic;
         type_carriage:in std_logic_vector(11 downto 0);
         pos_carriage:in std_logic_vector(71 downto 0);
         num_carriage:in std_logic_vector(17 downto 0);
         pos_barrier:in std_logic_vector(71 downto 0);
         type_barrier:in std_logic_vector(11 downto 0);
         character_y:in std_logic_vector(11 downto 0);
         character_h:in std_logic_vector(11 downto 0);
         character_state:in std_logic_vector(1 downto 0);
         survive_signal :in std_logic;
         ram_clk: out std_logic;
         ram_addr: out std_logic_vector(11 downto 0);
         ram_data: out std_logic_vector(31 downto 0);
         wren: out std_logic;
         start:out std_logic
      );
   end component;

   component geometry_buffer_ram is
      port (
         data        : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         rdaddress   : IN STD_LOGIC_VECTOR (11 DOWNTO 0);
         rdclock     : IN STD_LOGIC ;
         wraddress   : IN STD_LOGIC_VECTOR (11 DOWNTO 0);
         wrclock     : IN STD_LOGIC  := '1';
         wren        : IN STD_LOGIC  := '0';
         q           : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
      );
   end component geometry_buffer_ram;

   component renderer2d is
      port(
         clk0: in std_logic; -- 100MHz master clock input
         start : in std_logic;
         busy : out std_logic;
         -- internal ports to geometry buffer (RAM)
         n_element   : in unsigned(11 downto 0);
         geobuf_clk  : out std_logic;
         geobuf_addr : out std_logic_vector(11 downto 0);
         geobuf_q    : in  std_logic_vector(31 downto 0);
         -- internal ports to SRAM controller
         sram_addr1 : out std_logic_vector(19 downto 0);
         sram_q1    : in  std_logic_vector(31 downto 0);
         sram_addr2 : out std_logic_vector(19 downto 0);
         sram_q2    : in  std_logic_vector(31 downto 0);
         sram_addrw : out std_logic_vector(19 downto 0);
         sram_dataw : out std_logic_vector(31 downto 0);
         sram_wren  : out std_logic
      );
   end component renderer2d;

   component sram_controller is
      port(
         clk: in std_logic; -- sram sync clock
         clk_sramsample: in std_logic; -- shifted, on rising edge samples sram data
         -- read port 1
         addr1: in std_logic_vector(19 downto 0);
         q1:   out std_logic_vector(31 downto 0);
         -- read port 2
         addr2: in std_logic_vector(19 downto 0);
         q2:   out std_logic_vector(31 downto 0);
         -- read port 3
         addr3: in std_logic_vector(19 downto 0);
         q3:   out std_logic_vector(31 downto 0);
         -- write port
         addrw: in std_logic_vector(19 downto 0);
         dataw: in std_logic_vector(31 downto 0);
         wren : in std_logic;
         -- external ports to SRAM
         addr_e: out std_logic_vector(19 downto 0);
         data_e: inout std_logic_vector(31 downto 0);
         rden_e: out std_logic; -- low valid
         wren_e: out std_logic; -- low valid
         chsl_e: out std_logic  -- low valid
      );
   end component sram_controller;

   component vga_controller is
      port(
         -- internal ports
         clk_0 : in std_logic; -- 100MHz master clock input
         reset : in  std_logic; -- async reset (low valid)
         -- internal ports to SRAM controller
         addr  : out std_logic_vector(19 downto 0);
         q     : in std_logic_vector(31 downto 0);
         -- external ports to VGA DAC
         hs,vs : out std_logic;
         r,g,b : out std_logic_vector(2 downto 0)
      );
   end component vga_controller;
	
	component main_pll is
		port (inclk0: in std_logic; c0: out std_logic);
	end component;

   -- internal ports: vga_controller - sram_controller
   signal mem_addr1: std_logic_vector(19 downto 0);
   signal mem_q1:    std_logic_vector(31 downto 0);
   -- internal ports: renderer - sram_controller
   signal mem_addr2: std_logic_vector(19 downto 0);
   signal mem_q2:    std_logic_vector(31 downto 0);
   signal mem_addr3: std_logic_vector(19 downto 0);
   signal mem_q3:    std_logic_vector(31 downto 0);
   signal mem_addrw: std_logic_vector(19 downto 0);
   signal mem_dataw: std_logic_vector(31 downto 0);
   signal mem_wren : std_logic;
   -- pll output to sram
	signal srampulse: std_logic;

   signal render_n_element: unsigned(11 downto 0) := to_unsigned(21,12);
   signal render_start : std_logic;
   signal render_busy : std_logic;
   -- ports of geometry buffers
   signal geobuf_in_clk  : std_logic;
   signal geobuf_in_wren : std_logic;
   signal geobuf_in_addr : std_logic_vector(11 downto 0);
   signal geobuf_in_data : std_logic_vector(31 downto 0);
   signal geobuf_out_clk  : std_logic;
   signal geobuf_out_addr : std_logic_vector(11 downto 0);
   signal geobuf_out_q    : std_logic_vector(31 downto 0);

begin

	pll: main_pll port map (clk0, srampulse);

   rst_indicator <= rst;

   ga: game port map(UD,LR,clk0,type_carriage,pos_carriage,num_carriage,pos_barrier,type_barrier,character_y,character_h,character_state,survive,data_ready,rst);
   ge: geometry port map(clk0,render_busy,data_ready,type_carriage,pos_carriage,num_carriage,pos_barrier,type_barrier,character_y,character_h,character_state,survive,
         geobuf_in_clk,geobuf_in_addr,geobuf_in_data,geobuf_in_wren,render_start);

   -- genmetry instantiation module
   --demo: geometry_demo port map (
   --   clk0         => clk0,
   --   render_start => render_start,
   --   n_element    => render_n_element,
   --   geobuf_clk   => geobuf_in_clk,
   --   geobuf_wren  => geobuf_in_wren,
   --   geobuf_addr  => geobuf_in_addr,
   --   geobuf_data  => geobuf_in_data
   --);

   geometry_buffer : geometry_buffer_ram port map (
      data      => geobuf_in_data,
      rdaddress => geobuf_out_addr,
      rdclock   => geobuf_out_clk,
      wraddress => geobuf_in_addr,
      wrclock   => geobuf_in_clk,
      wren      => geobuf_in_wren,
      q         => geobuf_out_q
   );

   renderer: renderer2d port map (
      clk0        => clk0,
      start       => render_start,
      busy        => render_busy,
      -- geometry info
      n_element   => render_n_element,
      geobuf_clk  => geobuf_out_clk,
      geobuf_addr => geobuf_out_addr,
      geobuf_q    => geobuf_out_q,
      -- sram ports
      sram_addr1  => mem_addr2,
      sram_q1     => mem_q2,
      sram_addr2  => mem_addr3,
      sram_q2     => mem_q3,
      sram_addrw  => mem_addrw,
      sram_dataw  => mem_dataw,
      sram_wren   => mem_wren
   );

   sram: sram_controller port map (
      clk      => clk0,
      clk_sramsample => srampulse,
      -- read port 1 to VGA
      addr1    => mem_addr1,
      q1       => mem_q1,
      -- read port 2 unused
      addr2    => mem_addr2,
      q2       => mem_q2,
      -- read port 3 unused
      addr3    => mem_addr3,
      q3       => mem_q3,
      -- write port unused
      addrw    => mem_addrw,
      dataw    => mem_dataw,
      wren     => mem_wren,
      -- external ports to SRAM
      addr_e   => sram_addr,
      data_e   => sram_data,
      rden_e   => sram_oe,
      wren_e   => sram_we,
      chsl_e   => sram_ce
   );

   -- display control module
   vga: vga_controller port map (
      clk_0    => clk0,
      reset    => '1',
      -- internal ports to SRAM controller
      addr     => mem_addr1,
      q        => mem_q1,
      -- external ports to VGA DAC
      hs       => vga_hs,
      vs       => vga_vs,
      r        => vga_r,
      g        => vga_g,
      b        => vga_b
   );

end architecture arch; -- arch
