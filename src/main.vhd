
library  ieee;
use      ieee.std_logic_1164.all;

entity main is
   port (
      -- 100MHz master clock input
      clk0 : in std_logic;
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

   component main_pll is 
      port (
         inclk0: in std_logic;
         c0: out std_logic -- 8.5ns low, 1.5ns high 
      );
   end component;

   component renderer2d is
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
   end component renderer2d;

   component sram_controller is
      port (
         clk0: in std_logic; -- 100MHz master clock input
         widepulse: in std_logic; -- 8.5ns low, 1.5ns high 
         -- internal ports to VGA
         addr1: in std_logic_vector(19 downto 0);
         q1:   out std_logic_vector(31 downto 0);
         -- internal ports to renderer
         addr2: in std_logic_vector(19 downto 0);
         q2:   out std_logic_vector(31 downto 0);
         data2: in std_logic_vector(31 downto 0);
         wren2: in std_logic;
         acc2: out std_logic;
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

   signal widepulse: std_logic; -- 8.5ns low, 1.5ns high 
   -- internal ports: vga_controller - sram_controller
   signal mem_addr1: std_logic_vector(19 downto 0);
   signal mem_q1:    std_logic_vector(31 downto 0);
   -- internal ports: renderer - sram_controller
   signal mem_addr2: std_logic_vector(19 downto 0);
   signal mem_q2:    std_logic_vector(31 downto 0);
   signal mem_data2: std_logic_vector(31 downto 0);
   signal mem_wren2: std_logic;
   signal mem_acc2:  std_logic;

begin

   pll: main_pll port map (
      inclk0   => clk0,
      c0       => widepulse
   );

   renderer: renderer2d port map (
      clk0        => clk0,
      sram_addr   => mem_addr2,
      sram_data   => mem_data2,
      sram_q      => mem_q2,
      sram_wren   => mem_wren2,
      sram_ready  => mem_acc2
   );

   sram: sram_controller port map (
      clk0     => clk0,
      widepulse=> widepulse,
      -- internal ports to VGA
      addr1    => mem_addr1,
      q1       => mem_q1,
      -- internal ports to renderer
      addr2    => mem_addr2,
      data2    => mem_data2,
      q2       => mem_q2,
      wren2    => mem_wren2,
      acc2     => mem_acc2,
      -- external ports to SRAM
      addr_e   => sram_addr,
      data_e   => sram_data,
      rden_e   => sram_oe,
      wren_e   => sram_we,
      chsl_e   => sram_ce
   );

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