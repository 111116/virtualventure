-- This VHDL was converted from Verilog using the
-- Icarus Verilog VHDL Code Generator 10.3 (stable) (v10_3)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Generated from Verilog module sram_model (simulation/sram_model.v:24)
entity sram_model is
  port (
    Address : in unsigned(19 downto 0);
    CE_n : in std_logic;
    DataIO : inout unsigned(15 downto 0);
    LB_n : in std_logic;
    OE_n : in std_logic;
    UB_n : in std_logic;
    WE_n : in std_logic
  );
end entity; 

-- Generated from Verilog module sram_model (simulation/sram_model.v:24)
architecture from_verilog of sram_model is
  signal Address_read1 : unsigned(19 downto 0);  -- Declared at simulation/sram_model.v:91
  signal Address_read2 : unsigned(19 downto 0);  -- Declared at simulation/sram_model.v:91
  signal Address_write1 : unsigned(19 downto 0);  -- Declared at simulation/sram_model.v:82
  signal Address_write2 : unsigned(19 downto 0);  -- Declared at simulation/sram_model.v:82
  signal LB_n_start_time : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:50
  signal UB_n_start_time : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:50
  signal WE_dly : std_logic;  -- Declared at simulation/sram_model.v:81
  signal tmp_s1 : std_logic;  -- Temporary created at simulation/sram_model.v:460
  signal tmp_s2 : std_logic;  -- Temporary created at simulation/sram_model.v:460
  signal tmp_s21 : std_logic;  -- Temporary created at simulation/sram_model.v:228
  signal tmp_s4 : unsigned(15 downto 0);  -- Temporary created at simulation/sram_model.v:460
  signal activate_cebar : std_logic := '0';  -- Declared at simulation/sram_model.v:79
  signal activate_webar : std_logic;  -- Declared at simulation/sram_model.v:79
  signal activate_wecebar : std_logic := '0';  -- Declared at simulation/sram_model.v:79
  signal dataIO1 : unsigned(15 downto 0);  -- Declared at simulation/sram_model.v:87
  signal data_read : unsigned(15 downto 0) := "ZZZZZZZZZZZZZZZZ";  -- Declared at simulation/sram_model.v:90
  type dummy_array0_Type is array (1048575 downto 0) of unsigned(7 downto 0);
  signal dummy_array0 : dummy_array0_Type;  -- Declared at simulation/sram_model.v:83
  type dummy_array1_Type is array (1048575 downto 0) of unsigned(7 downto 0);
  signal dummy_array1 : dummy_array1_Type;  -- Declared at simulation/sram_model.v:84
  signal initiate_read1 : std_logic := '0';  -- Declared at simulation/sram_model.v:92
  signal initiate_read2 : std_logic := '0';  -- Declared at simulation/sram_model.v:92
  signal initiate_write1 : std_logic := '0';  -- Declared at simulation/sram_model.v:80
  signal initiate_write2 : std_logic := '0';  -- Declared at simulation/sram_model.v:80
  signal initiate_write3 : std_logic := '0';  -- Declared at simulation/sram_model.v:80
  type mem_array0_Type is array (1048575 downto 0) of unsigned(7 downto 0);
  signal mem_array0 : mem_array0_Type;  -- Declared at simulation/sram_model.v:85
  type mem_array1_Type is array (1048575 downto 0) of unsigned(7 downto 0);
  signal mem_array1 : mem_array1_Type;  -- Declared at simulation/sram_model.v:86
  signal read_CE_n_start_time : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:73
  signal read_OE_n_start_time : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:73
  signal read_WE_n_start_time : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:73
  signal read_address_add : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:53
  signal read_address_oe : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:53
  signal read_address_time : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:73
  signal taa : unsigned(63 downto 0) := X"000000000000000a";  -- Declared at simulation/sram_model.v:59
  signal tace : unsigned(63 downto 0) := X"000000000000000a";  -- Declared at simulation/sram_model.v:60
  signal tah : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:43
  signal tas : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:39
  signal taw : unsigned(63 downto 0) := X"0000000000000007";  -- Declared at simulation/sram_model.v:38
  signal tba : unsigned(63 downto 0) := X"0000000000000005";  -- Declared at simulation/sram_model.v:67
  signal tbhz : unsigned(63 downto 0) := X"0000000000000005";  -- Declared at simulation/sram_model.v:69
  signal tblz : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:68
  signal tbw : unsigned(63 downto 0) := X"0000000000000007";  -- Declared at simulation/sram_model.v:48
  signal tchz : unsigned(63 downto 0) := X"0000000000000005";  -- Declared at simulation/sram_model.v:64
  signal tclz : unsigned(63 downto 0) := X"0000000000000003";  -- Declared at simulation/sram_model.v:63
  signal tcw : unsigned(63 downto 0) := X"0000000000000007";  -- Declared at simulation/sram_model.v:37
  signal tdh : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:45
  signal tdw : unsigned(63 downto 0) := X"0000000000000005";  -- Declared at simulation/sram_model.v:44
  signal temptaa : unsigned(63 downto 0);  -- Declared at simulation/sram_model.v:53
  signal temptoe : unsigned(63 downto 0);  -- Declared at simulation/sram_model.v:53
  signal toe : unsigned(63 downto 0) := X"0000000000000004";  -- Declared at simulation/sram_model.v:61
  signal toh : unsigned(63 downto 0) := X"0000000000000003";  -- Declared at simulation/sram_model.v:62
  signal tohz : unsigned(63 downto 0) := X"0000000000000005";  -- Declared at simulation/sram_model.v:66
  signal tolz : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:65
  signal tow : unsigned(63 downto 0) := X"0000000000000003";  -- Declared at simulation/sram_model.v:47
  signal tpd : unsigned(63 downto 0) := X"000000000000000a";  -- Declared at simulation/sram_model.v:71
  signal tpu : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:70
  signal trc : unsigned(63 downto 0) := X"000000000000000a";  -- Declared at simulation/sram_model.v:58
  signal twc : unsigned(63 downto 0) := X"000000000000000a";  -- Declared at simulation/sram_model.v:36
  signal twp1 : unsigned(63 downto 0) := X"0000000000000007";  -- Declared at simulation/sram_model.v:40
  signal twp2 : unsigned(63 downto 0) := X"000000000000000a";  -- Declared at simulation/sram_model.v:41
  signal twr : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:42
  signal twz : unsigned(63 downto 0) := X"0000000000000005";  -- Declared at simulation/sram_model.v:46
  signal write_CE_n_start_time : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:52
  signal write_CE_n_start_time1 : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:51
  signal write_WE_n_start_time : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:52
  signal write_WE_n_start_time1 : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:51
  signal write_address1_time : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:51
  signal write_address_time : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:52
  signal write_data1_time : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:51
  signal write_data_time : unsigned(63 downto 0) := X"0000000000000000";  -- Declared at simulation/sram_model.v:52
begin
  tmp_s2 <= tmp_s1 and WE_dly;
  tmp_s21 <= CE_n and WE_n;
  tmp_s1 <= not OE_n;
  DataIO <= data_read when tmp_s2 = '1' else tmp_s4;
  tmp_s4 <= (others => 'Z');
  -- Removed one empty process
  
  
  -- Generated from initial process in sram_model (simulation/sram_model.v:98)
  process is
  begin
    wait for 0 ns;  -- Read target of blocking assignment (simulation/sram_model.v:142)
    temptaa <= taa;
    wait for 0 ns;  -- Read target of blocking assignment (simulation/sram_model.v:143)
    temptoe <= toe;
    wait;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:151)
  process (CE_n) is
  begin
    if falling_edge(CE_n) then
      activate_cebar <= '0';
      activate_wecebar <= '0';
      write_CE_n_start_time <= To_Unsigned(0, 64);
      read_CE_n_start_time <= To_Unsigned(0, 64);
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:162)
  process (CE_n) is
  begin
    if rising_edge(CE_n) then
      if (0 - write_CE_n_start_time) >= To_Integer(tcw) then
        if (WE_n = '0') and ((0 - write_WE_n_start_time) >= To_Integer(twp1)) then
          Address_write2 <= Address_write1;
          dummy_array0(To_Integer(Resize(Address_write1, 22))) <= dataIO1(0 + 7 downto 0);
          dummy_array1(To_Integer(Resize(Address_write1, 22))) <= dataIO1(8 + 7 downto 8);
          activate_cebar <= '1';
        else
          activate_cebar <= '0';
        end if;
      else
        activate_cebar <= '0';
      end if;
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:185)
  process (UB_n) is
  begin
    if falling_edge(UB_n) then
      UB_n_start_time <= To_Unsigned(0, 64);
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:190)
  process (LB_n) is
  begin
    if falling_edge(LB_n) then
      LB_n_start_time <= To_Unsigned(0, 64);
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:197)
  process is
  begin
    wait until falling_edge(WE_n);
    activate_webar <= '0';
    activate_wecebar <= '0';
    write_WE_n_start_time <= To_Unsigned(0, 64);
    wait for To_Integer((twz * X"00000000000003e8")) * 1 ps;
    WE_dly <= WE_n;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:205)
  process (WE_n) is
  begin
    if rising_edge(WE_n) then
      WE_dly <= WE_n;
      read_WE_n_start_time <= To_Unsigned(0, 64);
      if (0 - write_WE_n_start_time) >= To_Integer(twp1) then
        if (CE_n = '0') and ((0 - write_CE_n_start_time) >= To_Integer(tcw)) then
          Address_write2 <= Address_write1;
          dummy_array0(To_Integer(Resize(Address_write1, 22))) <= dataIO1(0 + 7 downto 0);
          dummy_array1(To_Integer(Resize(Address_write1, 22))) <= dataIO1(8 + 7 downto 8);
          activate_webar <= '1';
        else
          activate_webar <= '0';
        end if;
      else
        activate_webar <= '0';
      end if;
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:228)
  process (tmp_s21) is
  begin
    if (CE_n = '1') and (WE_n = '1') then
      if ((0 - write_WE_n_start_time) >= To_Integer(twp1)) and ((0 - write_CE_n_start_time) >= To_Integer(tcw)) then
        Address_write2 <= Address_write1;
        dummy_array0(To_Integer(Resize(Address_write1, 22))) <= dataIO1(0 + 7 downto 0);
        dummy_array1(To_Integer(Resize(Address_write1, 22))) <= dataIO1(8 + 7 downto 8);
        activate_webar <= '1';
      else
        activate_wecebar <= '0';
      end if;
    else
      activate_wecebar <= '0';
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:248)
  process (DataIO, Address, OE_n, WE_n, CE_n) is
  begin
    if (CE_n = '0') and (WE_n = '0') then
      Address_write1 <= Address;
      Address_write2 <= Address_write1;
      dataIO1 <= DataIO;
      dummy_array0(To_Integer(Resize(Address_write1, 22))) <= dataIO1(0 + 7 downto 0);
      dummy_array1(To_Integer(Resize(Address_write1, 22))) <= dataIO1(8 + 7 downto 8);
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:263)
  process (DataIO) is
  begin
    write_data_time <= To_Unsigned(0, 64);
    write_data1_time <= write_data_time;
    write_WE_n_start_time1 <= To_Unsigned(0, 64);
    write_CE_n_start_time1 <= To_Unsigned(0, 64);
    if (0 - write_data_time) >= To_Integer(tdw) then
      if (WE_n = '0') and (CE_n = '0') then
        if (((0 - write_CE_n_start_time) >= To_Integer(tcw)) and ((0 - write_WE_n_start_time) >= To_Integer(twp1))) and ((0 - write_address_time) >= To_Integer(twc)) then
          initiate_write2 <= '1';
        else
          initiate_write2 <= '0';
        end if;
      end if;
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:285)
  process (Address) is
  begin
    write_address_time <= To_Unsigned(0, 64);
    write_address1_time <= write_address_time;
    write_WE_n_start_time1 <= To_Unsigned(0, 64);
    write_CE_n_start_time1 <= To_Unsigned(0, 64);
    if (0 - write_address_time) >= To_Integer(twc) then
      if (WE_n = '0') and (CE_n = '0') then
        if (((0 - write_CE_n_start_time) >= To_Integer(tcw)) and ((0 - write_WE_n_start_time) >= To_Integer(twp1))) and ((0 - write_data_time) >= To_Integer(tdw)) then
          initiate_write3 <= '1';
        else
          initiate_write3 <= '0';
        end if;
      else
        initiate_write3 <= '0';
      end if;
    else
      initiate_write3 <= '0';
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:310)
  process (activate_wecebar, activate_webar, activate_cebar) is
  begin
    if ((activate_cebar = '1') or (activate_webar = '1')) or (activate_wecebar = '1') then
      if ((0 - write_data1_time) >= To_Integer(tdw)) and ((0 - write_address1_time) >= To_Integer(twc)) then
        initiate_write1 <= '1';
      else
        initiate_write1 <= '0';
      end if;
    else
      initiate_write1 <= '0';
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:327)
  process (initiate_write1) is
  begin
    if ((0 - write_WE_n_start_time) >= To_Integer(twp1)) and ((0 - write_CE_n_start_time) >= To_Integer(tcw)) then
      if (UB_n = '0') and ((0 - UB_n_start_time) >= To_Integer(tbw)) then
        mem_array1(To_Integer(Resize(Address_write2, 22))) <= dummy_array1(To_Integer(Resize(Address_write2, 22)));
      end if;
      if (LB_n = '0') and ((0 - LB_n_start_time) >= To_Integer(tbw)) then
        mem_array0(To_Integer(Resize(Address_write2, 22))) <= dummy_array0(To_Integer(Resize(Address_write2, 22)));
      end if;
    end if;
    initiate_write1 <= '0';
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:343)
  process (initiate_write2) is
  begin
    if ((0 - write_WE_n_start_time) >= To_Integer(twp1)) and ((0 - write_CE_n_start_time) >= To_Integer(tcw)) then
      if (UB_n = '0') and ((0 - UB_n_start_time) >= To_Integer(tbw)) then
        mem_array1(To_Integer(Resize(Address_write2, 22))) <= dummy_array1(To_Integer(Resize(Address_write2, 22)));
      end if;
      if (LB_n = '0') and ((0 - LB_n_start_time) >= To_Integer(tbw)) then
        mem_array0(To_Integer(Resize(Address_write2, 22))) <= dummy_array0(To_Integer(Resize(Address_write2, 22)));
      end if;
    end if;
    if initiate_write2 = '1' then
      initiate_write2 <= '0';
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:363)
  process (initiate_write3) is
  begin
    if ((0 - write_WE_n_start_time) >= To_Integer(twp1)) and ((0 - write_CE_n_start_time) >= To_Integer(tcw)) then
      if (UB_n = '0') and ((0 - UB_n_start_time) >= To_Integer(tbw)) then
        mem_array1(To_Integer(Resize(Address_write2, 22))) <= dummy_array1(To_Integer(Resize(Address_write2, 22)));
      end if;
      if (LB_n = '0') and ((0 - LB_n_start_time) >= To_Integer(tbw)) then
        mem_array0(To_Integer(Resize(Address_write2, 22))) <= dummy_array0(To_Integer(Resize(Address_write2, 22)));
      end if;
    end if;
    if initiate_write3 = '1' then
      initiate_write3 <= '0';
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:386)
  process (Address) is
  begin
    read_address_time <= To_Unsigned(0, 64);
    Address_read1 <= Address;
    Address_read2 <= Address_read1;
    if (0 - read_address_time) = To_Integer(trc) then
      if (CE_n = '0') and (WE_n = '1') then
        initiate_read1 <= '1';
      else
        initiate_read1 <= '0';
      end if;
    else
      initiate_read1 <= '0';
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:404)
  process is
  begin
    wait for 1000 ps;
    if (0 - read_address_time) >= To_Integer(trc) then
      if (CE_n = '0') and (WE_n = '1') then
        Address_read2 <= Address_read1;
        initiate_read2 <= '1';
      else
        initiate_read2 <= '0';
      end if;
    else
      initiate_read2 <= '0';
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:423)
  process (OE_n) is
  begin
    if falling_edge(OE_n) then
      read_OE_n_start_time <= To_Unsigned(0, 64);
      data_read <= "ZZZZZZZZZZZZZZZZ";
    end if;
  end process;
  
  -- Generated from always process in sram_model (simulation/sram_model.v:431)
  process is
  begin
    if (initiate_read1 = '1') or (initiate_read2 = '1') then
      if (CE_n = '0') and (WE_n = '1') then
        if (((0 - read_WE_n_start_time) >= To_Integer(trc)) and ((0 - read_CE_n_start_time) >= To_Integer(tace))) and ((0 - read_OE_n_start_time) >= To_Integer(toe)) then
          if (LB_n = '0') and ((0 - LB_n_start_time) >= To_Integer(tba)) then
            data_read(0 + 7 downto 0) <= mem_array0(To_Integer(Resize(Address_read2, 22)));
          else
            data_read(0 + 7 downto 0) <= "ZZZZZZZZ";
          end if;
          if (UB_n = '0') and ((0 - UB_n_start_time) >= To_Integer(tba)) then
            data_read(8 + 7 downto 8) <= mem_array1(To_Integer(Resize(Address_read2, 22)));
          else
            data_read(8 + 7 downto 8) <= "ZZZZZZZZ";
          end if;
        end if;
      else
        wait for To_Integer((toh * X"00000000000003e8")) * 1 ps;
        data_read <= "ZZZZZZZZZZZZZZZZ";
      end if;
    end if;
    initiate_read1 <= '0';
    initiate_read2 <= '0';
    wait on initiate_read2, initiate_read1;
  end process;
end architecture;

