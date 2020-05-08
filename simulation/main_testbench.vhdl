library ieee;
use ieee.std_logic_1164.all;

entity main_testbench is
end entity ; -- main_testbench

architecture arch of main_testbench is

   component sram_model is
      port (
         Address: in std_logic_vector(19 downto 0);
         DataIO: inout std_logic_vector(15 downto 0);
         OE_n,CE_n,WE_n, LB_n, UB_n: in std_logic
      );
   end component sram_model;

   component main is
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
   end component main;

   signal clk100: std_logic := '0';
   signal sram_addr: std_logic_vector(19 downto 0);
   signal sram_data: std_logic_vector(31 downto 0);
   signal sram_oe: std_logic;
   signal sram_we: std_logic;
   signal sram_ce: std_logic;

begin

   game: main port map (
      clk0        => clk100,
      sram_addr   => sram_addr,
      sram_data   => sram_data,
      sram_oe     => sram_oe,
      sram_we     => sram_we,
      sram_ce     => sram_ce,
      vga_r       => open,
      vga_g       => open,
      vga_b       => open,
      vga_hs      => open,
      vga_vs      => open
   );

   sram1: sram_model port map (
      Address  => sram_addr,
      DataIO   => sram_data(15 downto 0),
      OE_n     => sram_oe,
      CE_n     => sram_ce,
      WE_n     => sram_we,
      LB_n     => '0',
      UB_n     => '0'
   );

   sram2: sram_model port map (
      Address  => sram_addr,
      DataIO   => sram_data(31 downto 16),
      OE_n     => sram_oe,
      CE_n     => sram_ce,
      WE_n     => sram_we,
      LB_n     => '0',
      UB_n     => '0'
   );

   process
   begin
      clk100 <= not clk100;
      wait for 5 ns;
   end process;

end architecture ; -- arch
