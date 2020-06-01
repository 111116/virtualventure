-- This VHDL was converted from Verilog using the
-- Icarus Verilog VHDL Code Generator 10.3 (stable) (v10_3)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Generated from Verilog module ASSERTION_ERROR (async.v:186)
entity ASSERTION_ERROR is
end entity; 

-- Generated from Verilog module ASSERTION_ERROR (async.v:186)
architecture from_verilog of ASSERTION_ERROR is
begin
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Generated from Verilog module async_receiver (async.v:75)
--   Baud = 115200
--   ClkFrequency = 25000000
--   Oversampling = 8
--   l2o = 4
entity async_receiver is
  port (
    RxD : in std_logic;
    RxD_clear : in std_logic;
    RxD_data : out unsigned(7 downto 0);
    RxD_data_ready : out std_logic;
    clk : in std_logic
  );
end entity; 

-- Generated from Verilog module async_receiver (async.v:75)
--   Baud = 115200
--   ClkFrequency = 25000000
--   Oversampling = 8
--   l2o = 4
architecture from_verilog of async_receiver is
  function log2 (
    v : signed(31 downto 0)
  ) 
  return signed;
  
  signal RxD_data_Reg : unsigned(7 downto 0);
  signal RxD_data_ready_Reg : std_logic;
  signal Filter_cnt : unsigned(1 downto 0) := "11";  -- Declared at async.v:119
  signal GapCnt : unsigned(5 downto 0) := "000000";  -- Declared at async.v:175
  signal OversamplingCnt : unsigned(2 downto 0) := "000";  -- Declared at async.v:137
  signal OversamplingTick : std_logic;  -- Declared at async.v:111
  signal RxD_bit : std_logic := '1';  -- Declared at async.v:120
  signal RxD_endofpacket : std_logic;  -- Declared at async.v:101
  signal RxD_idle : std_logic;  -- Declared at async.v:100
  signal RxD_state : unsigned(3 downto 0) := X"0";  -- Declared at async.v:104
  signal RxD_sync : unsigned(1 downto 0) := "11";  -- Declared at async.v:115
  signal tmp_s2 : unsigned(31 downto 0);  -- Temporary created at async.v:139
  signal tmp_s5 : unsigned(28 downto 0);  -- Temporary created at async.v:139
  signal tmp_s6 : unsigned(31 downto 0);  -- Temporary created at async.v:139
  signal tmp_s8 : std_logic;  -- Temporary created at async.v:139
  signal sampleNow : std_logic;  -- Declared at async.v:139
  
  component BaudTickGen is
    port (
      clk : in std_logic;
      enable : in std_logic;
      tick : out std_logic
    );
  end component;
  
  function Signed_To_Boolean(X : signed) return Boolean is
  begin
    return X /= To_Signed(0, X'Length);
  end function;
  
  -- Generated from function log2 at async.v:135
  function log2 (
    v : signed(31 downto 0)
  ) 
  return signed is
    variable log2_Result : signed(31 downto 0);
  begin
    log2_Result := X"00000000";
    while Signed_To_Boolean(v srl To_Integer(Resize(unsigned(log2_Result), 32))) loop
      log2_Result := log2_Result + X"00000001";
    end loop;
    return log2_Result;
  end function;
  
  function Boolean_To_Logic(B : Boolean) return std_logic is
  begin
    if B then
      return '1';
    else
      return '0';
    end if;
  end function;
  
  function Reduce_AND(X : std_logic_vector) return std_logic is
    variable R : std_logic := '1';
  begin
    for I in X'Range loop
      R := X(I) and R;
    end loop;
    return R;
  end function;
begin
  RxD_data <= RxD_data_Reg;
  RxD_data_ready <= RxD_data_ready_Reg;
  sampleNow <= OversamplingTick and tmp_s8;
  tmp_s2 <= tmp_s5 & OversamplingCnt;
  tmp_s8 <= '1' when tmp_s2 = tmp_s6 else '0';
  RxD_idle <= GapCnt(5);
  
  -- Generated from instantiation at async.v:112
  tickgen: BaudTickGen
    port map (
      clk => clk,
      enable => '1',
      tick => OversamplingTick
    );
  tmp_s5 <= "00000000000000000000000000000";
  tmp_s6 <= X"00000003";
  -- Removed one empty process
  
  
  -- Generated from always process in async_receiver (async.v:116)
  process (clk) is
  begin
    if rising_edge(clk) then
      if OversamplingTick = '1' then
        RxD_sync <= RxD_sync(0) & RxD;
      end if;
    end if;
  end process;
  
  -- Generated from always process in async_receiver (async.v:122)
  process (clk) is
  begin
    if rising_edge(clk) then
      if OversamplingTick = '1' then
        if (RxD_sync(1) = '1') and (Filter_cnt /= "11") then
          Filter_cnt <= Filter_cnt + "01";
        else
          if (RxD_sync(1) = '0') and (Filter_cnt /= "00") then
            Filter_cnt <= Filter_cnt - "01";
          end if;
        end if;
        if Filter_cnt = "11" then
          RxD_bit <= '1';
        else
          if Filter_cnt = "00" then
            RxD_bit <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
  
  -- Generated from always process in async_receiver (async.v:138)
  process (clk) is
  begin
    if rising_edge(clk) then
      if OversamplingTick = '1' then
        if Resize(RxD_state, 32) = X"00000000" then
          OversamplingCnt <= "000";
        else
          OversamplingCnt <= OversamplingCnt + "001";
        end if;
      end if;
    end if;
  end process;
  
  -- Generated from always process in async_receiver (async.v:143)
  process (clk) is
  begin
    if rising_edge(clk) then
      case RxD_state is
        when X"0" =>
          if (not RxD_bit) = '1' then
            RxD_state <= X"1";
          end if;
        when X"1" =>
          if sampleNow = '1' then
            RxD_state <= X"8";
          end if;
        when X"8" =>
          if sampleNow = '1' then
            RxD_state <= X"9";
          end if;
        when X"9" =>
          if sampleNow = '1' then
            RxD_state <= X"a";
          end if;
        when X"a" =>
          if sampleNow = '1' then
            RxD_state <= X"b";
          end if;
        when X"b" =>
          if sampleNow = '1' then
            RxD_state <= X"c";
          end if;
        when X"c" =>
          if sampleNow = '1' then
            RxD_state <= X"d";
          end if;
        when X"d" =>
          if sampleNow = '1' then
            RxD_state <= X"e";
          end if;
        when X"e" =>
          if sampleNow = '1' then
            RxD_state <= X"f";
          end if;
        when X"f" =>
          if sampleNow = '1' then
            RxD_state <= X"2";
          end if;
        when X"2" =>
          if sampleNow = '1' then
            RxD_state <= X"0";
          end if;
        when others =>
          RxD_state <= X"0";
      end case;
    end if;
  end process;
  
  -- Generated from always process in async_receiver (async.v:159)
  process (clk) is
  begin
    if rising_edge(clk) then
      if (sampleNow = '1') and (RxD_state(3) = '1') then
        RxD_data_Reg <= RxD_bit & RxD_data_Reg(1 + 6 downto 1);
      end if;
    end if;
  end process;
  
  -- Generated from always process in async_receiver (async.v:163)
  process (clk) is
  begin
    if rising_edge(clk) then
      if RxD_clear = '1' then
        RxD_data_ready_Reg <= '0';
      else
        RxD_data_ready_Reg <= Boolean_To_Logic((RxD_data_ready_Reg = '1') or (((sampleNow = '1') and (RxD_state = X"2")) and (RxD_bit = '1')));
      end if;
    end if;
  end process;
  
  -- Generated from always process in async_receiver (async.v:176)
  process (clk) is
  begin
    if rising_edge(clk) then
      if Resize(RxD_state, 32) /= X"00000000" then
        GapCnt <= "000000";
      else
        if (OversamplingTick and (not GapCnt(To_Integer((log2(X"00000008") + X"00000001"))))) = '1' then
          GapCnt <= GapCnt + "000001";
        end if;
      end if;
    end if;
  end process;
  
  -- Generated from always process in async_receiver (async.v:178)
  process (clk) is
  begin
    if rising_edge(clk) then
      RxD_endofpacket <= (OversamplingTick and (not GapCnt(5))) and Reduce_AND(std_logic_vector(GapCnt(0 + 4 downto 0)));
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Generated from Verilog module BaudTickGen (async.v:191)
--   AccWidth = 16
--   Baud = 115200
--   ClkFrequency = 25000000
--   Inc = 2416
--   Oversampling = 8
--   ShiftLimiter = 5
entity BaudTickGen is
  port (
    clk : in std_logic;
    enable : in std_logic;
    tick : out std_logic
  );
end entity; 

-- Generated from Verilog module BaudTickGen (async.v:191)
--   AccWidth = 16
--   Baud = 115200
--   ClkFrequency = 25000000
--   Inc = 2416
--   Oversampling = 8
--   ShiftLimiter = 5
architecture from_verilog of BaudTickGen is
  signal Acc : unsigned(16 downto 0) := "00000000000000000";  -- Declared at async.v:201
begin
  tick <= Acc(16);
  -- Removed one empty process
  
  
  -- Generated from always process in BaudTickGen (async.v:204)
  process (clk) is
  begin
    if rising_edge(clk) then
      if enable = '1' then
        Acc <= Resize(Acc(0 + 15 downto 0), 17) + "00000100101110000";
      else
        Acc <= "00000100101110000";
      end if;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Generated from Verilog module async_transmitter (async.v:14)
--   Baud = 115200
--   ClkFrequency = 25000000
entity async_transmitter is
  port (
    TxD : out std_logic;
    TxD_busy : out std_logic;
    TxD_data : in unsigned(7 downto 0);
    TxD_start : in std_logic;
    clk : in std_logic
  );
end entity; 

-- Generated from Verilog module async_transmitter (async.v:14)
--   Baud = 115200
--   ClkFrequency = 25000000
architecture from_verilog of async_transmitter is
  signal BitTick : std_logic;  -- Declared at async.v:36
  signal TxD_ready : std_logic;  -- Declared at async.v:41
  signal TxD_shift : unsigned(7 downto 0) := X"00";  -- Declared at async.v:44
  signal TxD_state : unsigned(3 downto 0) := X"0";  -- Declared at async.v:40
  signal tmp_s0 : unsigned(31 downto 0);  -- Temporary created at async.v:41
  signal tmp_s10 : unsigned(31 downto 0);  -- Temporary created at async.v:70
  signal tmp_s13 : unsigned(27 downto 0);  -- Temporary created at async.v:70
  signal tmp_s14 : unsigned(31 downto 0);  -- Temporary created at async.v:70
  signal tmp_s16 : std_logic;  -- Temporary created at async.v:70
  signal tmp_s19 : std_logic;  -- Temporary created at async.v:70
  signal tmp_s21 : std_logic;  -- Temporary created at async.v:70
  signal tmp_s22 : std_logic;  -- Temporary created at async.v:70
  signal tmp_s3 : unsigned(27 downto 0);  -- Temporary created at async.v:41
  signal tmp_s4 : unsigned(31 downto 0);  -- Temporary created at async.v:41
  
  component BaudTickGen1 is
    port (
      clk : in std_logic;
      enable : in std_logic;
      tick : out std_logic
    );
  end component;
  signal enable_Readable : std_logic;  -- Needed to connect outputs
begin
  TxD_busy <= not TxD_ready;
  tmp_s22 <= tmp_s19 and tmp_s21;
  TxD <= tmp_s16 or tmp_s22;
  tmp_s0 <= tmp_s3 & TxD_state;
  TxD_ready <= '1' when tmp_s0 = tmp_s4 else '0';
  tmp_s10 <= tmp_s13 & TxD_state;
  tmp_s16 <= '1' when tmp_s14 > tmp_s10 else '0';
  tmp_s19 <= TxD_state(3);
  tmp_s21 <= TxD_shift(0);
  TxD_busy <= enable_Readable;
  
  -- Generated from instantiation at async.v:37
  tickgen: BaudTickGen1
    port map (
      clk => clk,
      enable => enable_Readable,
      tick => BitTick
    );
  tmp_s13 <= X"0000000";
  tmp_s14 <= X"00000004";
  tmp_s3 <= X"0000000";
  tmp_s4 <= X"00000000";
  -- Removed one empty process
  
  
  -- Generated from always process in async_transmitter (async.v:45)
  process (clk) is
  begin
    if rising_edge(clk) then
      if (TxD_ready and TxD_start) = '1' then
        TxD_shift <= TxD_data;
      else
        if (TxD_state(3) and BitTick) = '1' then
          TxD_shift <= Resize(Resize(TxD_shift, 32) srl 1, 8);
        end if;
      end if;
      case TxD_state is
        when X"0" =>
          if TxD_start = '1' then
            TxD_state <= X"4";
          end if;
        when X"4" =>
          if BitTick = '1' then
            TxD_state <= X"8";
          end if;
        when X"8" =>
          if BitTick = '1' then
            TxD_state <= X"9";
          end if;
        when X"9" =>
          if BitTick = '1' then
            TxD_state <= X"a";
          end if;
        when X"a" =>
          if BitTick = '1' then
            TxD_state <= X"b";
          end if;
        when X"b" =>
          if BitTick = '1' then
            TxD_state <= X"c";
          end if;
        when X"c" =>
          if BitTick = '1' then
            TxD_state <= X"d";
          end if;
        when X"d" =>
          if BitTick = '1' then
            TxD_state <= X"e";
          end if;
        when X"e" =>
          if BitTick = '1' then
            TxD_state <= X"f";
          end if;
        when X"f" =>
          if BitTick = '1' then
            TxD_state <= X"2";
          end if;
        when X"2" =>
          if BitTick = '1' then
            TxD_state <= X"0";
          end if;
        when others =>
          if BitTick = '1' then
            TxD_state <= X"0";
          end if;
      end case;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Generated from Verilog module BaudTickGen (async.v:191)
--   AccWidth = 16
--   Baud = 115200
--   ClkFrequency = 25000000
--   Inc = 302
--   Oversampling = 1
--   ShiftLimiter = 2
entity BaudTickGen1 is
  port (
    clk : in std_logic;
    enable : in std_logic;
    tick : out std_logic
  );
end entity; 

-- Generated from Verilog module BaudTickGen (async.v:191)
--   AccWidth = 16
--   Baud = 115200
--   ClkFrequency = 25000000
--   Inc = 302
--   Oversampling = 1
--   ShiftLimiter = 2
architecture from_verilog of BaudTickGen1 is
  signal Acc : unsigned(16 downto 0) := "00000000000000000";  -- Declared at async.v:201
begin
  tick <= Acc(16);
  -- Removed one empty process
  
  
  -- Generated from always process in BaudTickGen (async.v:204)
  process (clk) is
  begin
    if rising_edge(clk) then
      if enable = '1' then
        Acc <= Resize(Acc(0 + 15 downto 0), 17) + "00000000100101110";
      else
        Acc <= "00000000100101110";
      end if;
    end if;
  end process;
end architecture;

