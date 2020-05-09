
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

   component sram_controller is
      port (
         clk: in std_logic; -- sync clock
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
	
	component hyper is
		port (inclk0: in std_logic; c0: out std_logic);
	end component;

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
   signal sram_clk : std_logic := '0';
	signal clkk: std_logic;

begin

	wtf: hyper port map (clk0, clkk);

   process (clk0)
   begin
      if rising_edge(clk0) then
         sram_clk <= not sram_clk;
      end if;
   end process;

   sram: sram_controller port map (
      clk      => sram_clk,
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

   -- renderer placeholder (doesn't write anything)
   mem_addr2 <= (others => '0');
   mem_data2 <= (others => '0');
   mem_wren2 <= '0';

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
