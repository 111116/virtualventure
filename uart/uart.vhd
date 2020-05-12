 ----------------UART的异步串口通信协议的VHDL语言实现 ----------------
 --异步串行通信的采用的波特率为9600b/s,外配晶体振荡器的频率为50MHz，故还要采取分频电路
 
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity uart is
    port(clk : in  std_logic;                        --系统时钟
       rst_n: in std_logic;                        --复位信号 
   rs232_rx: in std_logic;                     --RS232接收数据信号;
   rs232_tx: out std_logic                     --RS232发送数据信号;
   );
end uart;

architecture behav of uart is

 
   component uart_rx port(clk : in  std_logic;                   --系统时钟
       rst_n: in std_logic;                        --复位信号 
       rs232_rx: in std_logic;                     --RS232接收数据信号
       clk_bps: in std_logic;                      --此时clk_bps的高电平为接收数据的采样点
       bps_start:out std_logic;  --接收到数据后，波特率时钟启动置位
       rx_data: out std_logic_vector(7 downto 0);  --接收数据寄存器，保存直至下一个数据来到
       rx_int: out std_logic                       --接收数据中断信号，接收数据期间时钟为高电平，传送给串口发送
               );
 end component;
 
 component speed_select port(clk : in  std_logic;               --系统时钟
        rst_n: in std_logic;                      --复位信号
        clk_bps: out std_logic;                   --此时clk_bps的高电平为接收或者发送数据位的中间采样点
        bps_start:in std_logic   --接收数据后，波特率时钟启动信号置位
          );
 end component;
 
 component uart_tx port(clk : in  std_logic;                    --系统时钟
       rst_n: in std_logic;                         --复位信号
       rs232_tx: out std_logic;                     --RS232接收数据信号
       clk_bps: in std_logic;                       --此时clk_bps的高电平为接收数据的采样点
       bps_start:out std_logic;   --接收到数据后，波特率时钟启动置位
       rx_data: in std_logic_vector(7 downto 0);    --接收数据寄存器，保存直至下一个数据来到
       rx_int: in std_logic                         --接收数据中断信号，接收数据期间时钟为高电平，传送给串口发送
                        --模块，使得串口正在进行接收数据的时候，发送模块不工作，避免
                        --了一个完整的数据（1位起始位、8位数据位、1位停止位）还没有
                        --接收完全时，发送模块就已经将不正确的数据传输出去
       );
 end component;

 signal bps_start_1:std_logic;
 signal bps_start_2:std_logic;
 signal clk_bps_1:std_logic;
 signal clk_bps_2:std_logic;
 signal rx_data:std_logic_vector(7 downto 0);
 signal rx_int:std_logic;
 
 
 begin
 RX_TOP: uart_rx port map(clk=>clk,
        rst_n=>rst_n,
        rs232_rx=>rs232_rx,
        clk_bps=>clk_bps_1,
        bps_start=>bps_start_1,
        rx_data=>rx_data,
        rx_int=>rx_int
        );
       
   SPEED_TOP_RX: speed_select port map(clk=>clk,
            rst_n=>rst_n,
            clk_bps=>clk_bps_1,
            bps_start=>bps_start_1
            );
           
 TX_TOP:uart_tx port map(clk=>clk,                             --系统时钟
       rst_n=>rst_n,                               --复位信号 
       rs232_tx=>rs232_tx,                         --RS232发送数据信号
       clk_bps=>clk_bps_2,                         --此时clk_bps的高电平为发送数据的采样点
       bps_start=>bps_start_2,     --接收到数据后，波特率时钟启动置位
       rx_data=>rx_data,                           --接收数据寄存器，保存直至下一个数据来到
       rx_int=>rx_int                              --接收数据中断信号，接收数据期间时钟为高电平，传送给串口发送
                       --模块，使得串口正在进行接收数据的时候，发送模块不工作，避免
       
         );
   SPEED_TOP_TX: speed_select port map(clk=>clk,
            rst_n=>rst_n,
            clk_bps=>clk_bps_2,
            bps_start=>bps_start_2
            );
           
end behav;


--------------------------------------------------------------------------------------
---------------------------------3个子模块---------------------------------------------







---------------------------------异步接收模块-------------------------------------------    

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity uart_rx is
    port(clk : in  std_logic;                        --系统时钟
       rst_n: in std_logic;                        --复位信号 
   rs232_rx: in std_logic;                     --RS232接收数据信号
   clk_bps: in std_logic;                      --此时clk_bps的高电平为接收数据的采样点
   bps_start:out std_logic;  --接收到数据后，波特率时钟启动置位
   rx_data: out std_logic_vector(7 downto 0);  --接收数据寄存器，保存直至下一个数据来到
       rx_int: out std_logic                       --接收数据中断信号，接收数据期间时钟为高电平，传送给串口发送
                                               --模块，使得串口正在进行接收数据的时候，发送模块不工作，避免
                   --了一个完整的数据（1位起始位、8位数据位、1位停止位）还没有
                   --接收完全时，发送模块就已经将不正确的数据传输出去
   );
end uart_rx;
architecture behav of uart_rx is
         signal    rs232_rx0: std_logic;
         signal    rs232_rx1: std_logic;
         signal    rs232_rx2: std_logic;
         signal    rs232_rx3: std_logic;
   signal    neg_rs232_rx:std_logic;
         signal    bps_start_r:std_logic;
   signal    num:integer;
         signal    rx_data_r:std_logic_vector(7 downto 0);  --串口接收数据寄存器，保存直至下一个数据到来
begin
 
 process(clk,rst_n)
     begin
         if (rst_n='0')then
    rs232_rx0<='0';
    rs232_rx1<='0';
    rs232_rx2<='0';
    rs232_rx3<='0';
   else
    if (rising_edge(clk)) then
     rs232_rx0<=rs232_rx;
     rs232_rx1<=rs232_rx0;
     rs232_rx2<=rs232_rx1;
     rs232_rx3<=rs232_rx2;
    end if;
   end if;
   neg_rs232_rx <=rs232_rx3 and rs232_rx2 and not(rs232_rx1)and not(rs232_rx0);
   end process;
 

   process(clk,rst_n)
     begin
         if (rst_n='0')then
    bps_start_r<='0';
    rx_int<='0';
   else
    if (rising_edge(clk)) then
         if(neg_rs232_rx='1') then    --接收到串口数据线rs232_rx的下降沿标志信号
     bps_start_r<='1';        --启动串口准备数据接收
     rx_int<='1';    --接收数据中断信号使能
     else if((num= 15) and (clk_bps='1')) then --接收完有用数据信息
         bps_start_r<='0';  --数据接收完毕，释放波特率启动信号
       rx_int<='0'; --接收数据中断信号关闭
       end if;
     end if;
       end if;
    end if;
  bps_start<=bps_start_r;
   end process;
 
 
   process(clk,rst_n)
     begin
         if (rst_n='0')then
    rx_data_r<="00000000";
    rx_data<="00000000";
    num<=0;
   else
    if (rising_edge(clk)) then
     if(clk_bps='1')then
       num<=num+1;
       case num is
        when  1=>rx_data_r(0)<=rs232_rx;--锁存第0bit
        when  2=>rx_data_r(1)<=rs232_rx;--锁存第0bit
        when  3=>rx_data_r(2)<=rs232_rx;--锁存第0bit
        when  4=>rx_data_r(3)<=rs232_rx;--锁存第0bit
        when  5=>rx_data_r(4)<=rs232_rx;--锁存第0bit
        when  6=>rx_data_r(5)<=rs232_rx;--锁存第0bit
        when  7=>rx_data_r(6)<=rs232_rx;--锁存第0bit
        when  8=>rx_data_r(7)<=rs232_rx;--锁存第0bit
        when  10=>rx_data<=rx_data_r;
        when  11=>num<=15;
        when  others=>null;
       end case;
       if(num=15) then
        num<=0;
       end if;
      end if;
     end if;
   end if;
  end process;
 
 end behav;
   

   
   
   
---------------------------------波特率控制模块-----------------------------------------  

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity speed_select is
    port(clk : in  std_logic;                        --系统时钟
       rst_n: in std_logic;                        --复位信号 
   clk_bps: out std_logic;                     --此时clk_bps的高电平为接收或者发送数据位的中间采样点
   bps_start:in std_logic     --接收数据后，波特率时钟启动信号置位
                   --或者开始发送数据时，波特率时钟启动信号置位
   );
end speed_select;
architecture behav of speed_select is

signal cnt:std_logic_vector(12 downto 0);
signal clk_bps_r:std_logic;
constant BPS_PARA:integer:=5207;
constant BPS_PARA_2:integer:=2603;

begin

   process(clk,rst_n)
     begin
         if (rst_n='0')then
    cnt<="0000000000000";
   else
    if (rising_edge(clk)) then
     if((cnt=BPS_PARA)or(bps_start='0')) then
       cnt<="0000000000000";   --波特率计数器清零
     else
      cnt<=cnt+'1'; --波特率时钟计数启动
     end if;
    end if;
   end if;
 end process;
 
 process(clk,rst_n)
     begin
         if (rst_n='0')then
    clk_bps_r<='0';
   else  
    if (rising_edge(clk)) then
     if(cnt=BPS_PARA_2) then
        clk_bps_r<='1';   --clk_bps_r高电平为接收数据位的中间采样点，同时也作为发送数据的数据改变点
     else
      clk_bps_r<='0';   --波特率计数器清零
     end if;
    end if;
   end if;
  clk_bps<=clk_bps_r;
 end process;
end behav;




---------------------------------异步发送模块  -------------------------------------------  
 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity uart_tx is
    port(clk : in  std_logic;                        --系统时钟
       rst_n: in std_logic;                        --复位信号 
   rs232_tx: out std_logic;                     --RS232接收数据信号
   clk_bps: in std_logic;                      --此时clk_bps的高电平为接收数据的采样点
   bps_start:out std_logic;  --接收到数据后，波特率时钟启动置位
   rx_data: in std_logic_vector(7 downto 0);  --接收数据寄存器，保存直至下一个数据来到
       rx_int: in std_logic                       --接收数据中断信号，接收数据期间时钟为高电平，传送给串口发送
                                               --模块，使得串口正在进行接收数据的时候，发送模块不工作，避免
                   --了一个完整的数据（1位起始位、8位数据位、1位停止位）还没有
                   --接收完全时，发送模块就已经将不正确的数据传输出去
   );
end uart_tx;
architecture behav of uart_tx is
         signal    rx_int0: std_logic;
         signal    rx_int1: std_logic;
         signal    rx_int2: std_logic;
   signal    neg_rx_int:std_logic;
         signal    bps_start_r:std_logic;
   signal    num:integer;
         signal    tx_data:std_logic_vector(7 downto 0);  --串口接收数据寄存器，保存直至下一个数据到来
begin
 
 process(clk,rst_n)
     begin
         if (rst_n='0')then
    rx_int0<='0';
    rx_int1<='0';
    rx_int2<='0';
   else
    if (rising_edge(clk)) then
     rx_int0<=rx_int;
     rx_int1<=rx_int0;
     rx_int2<=rx_int1;
    end if;
   end if;
   neg_rx_int <=not(rx_int1)and (rx_int2);
   end process;
 

   process(clk,rst_n)
     begin
         if (rst_n='0')then
    bps_start_r<='0';
    tx_data<="00000000";
   else
    if (rising_edge(clk)) then
         if(neg_rx_int='1') then    --接收到串口数据线rs232_rx的下降沿标志信号
     bps_start_r<='1';        --启动串口准备数据接收
     tx_data<=rx_data;    --接收数据中断信号使能
     else if((num= 15) and (clk_bps='1')) then --接收完有用数据信息
         bps_start_r<='0';  --数据接收完毕，释放波特率启动信号
       end if;
     end if;
       end if;
    end if;
  bps_start<=bps_start_r;
   end process;
 
 
   process(clk,rst_n)
     begin
         if (rst_n='0')then
    rs232_tx<='1';
    num<=0;
   else
    if (rising_edge(clk)) then
     if(clk_bps='1')then
       num<=num+1;
       case num is
        when  1=>rs232_tx<='0';
        when  2=>rs232_tx<=tx_data(0);--发送第1bit
        when  3=>rs232_tx<=tx_data(1);--发送第2bit
        when  4=>rs232_tx<=tx_data(2);--发送第3bit
        when  5=>rs232_tx<=tx_data(3);--发送第4bit
        when  6=>rs232_tx<=tx_data(4);--发送第5bit
        when  7=>rs232_tx<=tx_data(5);--发送第6bit
        when  8=>rs232_tx<=tx_data(6);--发送第7bit
        when  9=>rs232_tx<=tx_data(7);--发送第8bit
        when  10=>rs232_tx<='1';
        when  11=>num<=15;
        when  others=>null;
       end case;
       if(num=15) then
        num<=0;
       end if;
      end if;
     end if;
   end if;
  end process;
 
 end behav; 



 ----------------UART的异步串口通信协议的VHDL语言实现 ----------------
 --异步串行通信的采用的波特率为9600b/s,外配晶体振荡器的频率为50MHz，故还要采取分频电路
 
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity uart is
    port(clk : in  std_logic;                        --系统时钟
       rst_n: in std_logic;                        --复位信号 
   rs232_rx: in std_logic;                     --RS232接收数据信号;
   rs232_tx: out std_logic                     --RS232发送数据信号;
   );
end uart;

architecture behav of uart is

 
   component uart_rx port(clk : in  std_logic;                   --系统时钟
       rst_n: in std_logic;                        --复位信号 
       rs232_rx: in std_logic;                     --RS232接收数据信号
       clk_bps: in std_logic;                      --此时clk_bps的高电平为接收数据的采样点
       bps_start:out std_logic;  --接收到数据后，波特率时钟启动置位
       rx_data: out std_logic_vector(7 downto 0);  --接收数据寄存器，保存直至下一个数据来到
       rx_int: out std_logic                       --接收数据中断信号，接收数据期间时钟为高电平，传送给串口发送
               );
 end component;
 
 component speed_select port(clk : in  std_logic;               --系统时钟
        rst_n: in std_logic;                      --复位信号
        clk_bps: out std_logic;                   --此时clk_bps的高电平为接收或者发送数据位的中间采样点
        bps_start:in std_logic   --接收数据后，波特率时钟启动信号置位
          );
 end component;
 
 component uart_tx port(clk : in  std_logic;                    --系统时钟
       rst_n: in std_logic;                         --复位信号
       rs232_tx: out std_logic;                     --RS232接收数据信号
       clk_bps: in std_logic;                       --此时clk_bps的高电平为接收数据的采样点
       bps_start:out std_logic;   --接收到数据后，波特率时钟启动置位
       rx_data: in std_logic_vector(7 downto 0);    --接收数据寄存器，保存直至下一个数据来到
       rx_int: in std_logic                         --接收数据中断信号，接收数据期间时钟为高电平，传送给串口发送
                        --模块，使得串口正在进行接收数据的时候，发送模块不工作，避免
                        --了一个完整的数据（1位起始位、8位数据位、1位停止位）还没有
                        --接收完全时，发送模块就已经将不正确的数据传输出去
       );
 end component;

 signal bps_start_1:std_logic;
 signal bps_start_2:std_logic;
 signal clk_bps_1:std_logic;
 signal clk_bps_2:std_logic;
 signal rx_data:std_logic_vector(7 downto 0);
 signal rx_int:std_logic;
 
 
 begin
 RX_TOP: uart_rx port map(clk=>clk,
        rst_n=>rst_n,
        rs232_rx=>rs232_rx,
        clk_bps=>clk_bps_1,
        bps_start=>bps_start_1,
        rx_data=>rx_data,
        rx_int=>rx_int
        );
       
   SPEED_TOP_RX: speed_select port map(clk=>clk,
            rst_n=>rst_n,
            clk_bps=>clk_bps_1,
            bps_start=>bps_start_1
            );
           
 TX_TOP:uart_tx port map(clk=>clk,                             --系统时钟
       rst_n=>rst_n,                               --复位信号 
       rs232_tx=>rs232_tx,                         --RS232发送数据信号
       clk_bps=>clk_bps_2,                         --此时clk_bps的高电平为发送数据的采样点
       bps_start=>bps_start_2,     --接收到数据后，波特率时钟启动置位
       rx_data=>rx_data,                           --接收数据寄存器，保存直至下一个数据来到
       rx_int=>rx_int                              --接收数据中断信号，接收数据期间时钟为高电平，传送给串口发送
                       --模块，使得串口正在进行接收数据的时候，发送模块不工作，避免
       
         );
   SPEED_TOP_TX: speed_select port map(clk=>clk,
            rst_n=>rst_n,
            clk_bps=>clk_bps_2,
            bps_start=>bps_start_2
            );
           
end behav;


--------------------------------------------------------------------------------------
---------------------------------3个子模块---------------------------------------------







---------------------------------异步接收模块-------------------------------------------    

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity uart_rx is
    port(clk : in  std_logic;                        --系统时钟
       rst_n: in std_logic;                        --复位信号 
   rs232_rx: in std_logic;                     --RS232接收数据信号
   clk_bps: in std_logic;                      --此时clk_bps的高电平为接收数据的采样点
   bps_start:out std_logic;  --接收到数据后，波特率时钟启动置位
   rx_data: out std_logic_vector(7 downto 0);  --接收数据寄存器，保存直至下一个数据来到
       rx_int: out std_logic                       --接收数据中断信号，接收数据期间时钟为高电平，传送给串口发送
                                               --模块，使得串口正在进行接收数据的时候，发送模块不工作，避免
                   --了一个完整的数据（1位起始位、8位数据位、1位停止位）还没有
                   --接收完全时，发送模块就已经将不正确的数据传输出去
   );
end uart_rx;
architecture behav of uart_rx is
         signal    rs232_rx0: std_logic;
         signal    rs232_rx1: std_logic;
         signal    rs232_rx2: std_logic;
         signal    rs232_rx3: std_logic;
   signal    neg_rs232_rx:std_logic;
         signal    bps_start_r:std_logic;
   signal    num:integer;
         signal    rx_data_r:std_logic_vector(7 downto 0);  --串口接收数据寄存器，保存直至下一个数据到来
begin
 
 process(clk,rst_n)
     begin
         if (rst_n='0')then
    rs232_rx0<='0';
    rs232_rx1<='0';
    rs232_rx2<='0';
    rs232_rx3<='0';
   else
    if (rising_edge(clk)) then
     rs232_rx0<=rs232_rx;
     rs232_rx1<=rs232_rx0;
     rs232_rx2<=rs232_rx1;
     rs232_rx3<=rs232_rx2;
    end if;
   end if;
   neg_rs232_rx <=rs232_rx3 and rs232_rx2 and not(rs232_rx1)and not(rs232_rx0);
   end process;
 

   process(clk,rst_n)
     begin
         if (rst_n='0')then
    bps_start_r<='0';
    rx_int<='0';
   else
    if (rising_edge(clk)) then
         if(neg_rs232_rx='1') then    --接收到串口数据线rs232_rx的下降沿标志信号
     bps_start_r<='1';        --启动串口准备数据接收
     rx_int<='1';    --接收数据中断信号使能
     else if((num= 15) and (clk_bps='1')) then --接收完有用数据信息
         bps_start_r<='0';  --数据接收完毕，释放波特率启动信号
       rx_int<='0'; --接收数据中断信号关闭
       end if;
     end if;
       end if;
    end if;
  bps_start<=bps_start_r;
   end process;
 
 
   process(clk,rst_n)
     begin
         if (rst_n='0')then
    rx_data_r<="00000000";
    rx_data<="00000000";
    num<=0;
   else
    if (rising_edge(clk)) then
     if(clk_bps='1')then
       num<=num+1;
       case num is
        when  1=>rx_data_r(0)<=rs232_rx;--锁存第0bit
        when  2=>rx_data_r(1)<=rs232_rx;--锁存第0bit
        when  3=>rx_data_r(2)<=rs232_rx;--锁存第0bit
        when  4=>rx_data_r(3)<=rs232_rx;--锁存第0bit
        when  5=>rx_data_r(4)<=rs232_rx;--锁存第0bit
        when  6=>rx_data_r(5)<=rs232_rx;--锁存第0bit
        when  7=>rx_data_r(6)<=rs232_rx;--锁存第0bit
        when  8=>rx_data_r(7)<=rs232_rx;--锁存第0bit
        when  10=>rx_data<=rx_data_r;
        when  11=>num<=15;
        when  others=>null;
       end case;
       if(num=15) then
        num<=0;
       end if;
      end if;
     end if;
   end if;
  end process;
 
 end behav;
   

   
   
   
---------------------------------波特率控制模块-----------------------------------------  

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity speed_select is
    port(clk : in  std_logic;                        --系统时钟
       rst_n: in std_logic;                        --复位信号 
   clk_bps: out std_logic;                     --此时clk_bps的高电平为接收或者发送数据位的中间采样点
   bps_start:in std_logic     --接收数据后，波特率时钟启动信号置位
                   --或者开始发送数据时，波特率时钟启动信号置位
   );
end speed_select;
architecture behav of speed_select is

signal cnt:std_logic_vector(12 downto 0);
signal clk_bps_r:std_logic;
constant BPS_PARA:integer:=5207;
constant BPS_PARA_2:integer:=2603;

begin

   process(clk,rst_n)
     begin
         if (rst_n='0')then
    cnt<="0000000000000";
   else
    if (rising_edge(clk)) then
     if((cnt=BPS_PARA)or(bps_start='0')) then
       cnt<="0000000000000";   --波特率计数器清零
     else
      cnt<=cnt+'1'; --波特率时钟计数启动
     end if;
    end if;
   end if;
 end process;
 
 process(clk,rst_n)
     begin
         if (rst_n='0')then
    clk_bps_r<='0';
   else  
    if (rising_edge(clk)) then
     if(cnt=BPS_PARA_2) then
        clk_bps_r<='1';   --clk_bps_r高电平为接收数据位的中间采样点，同时也作为发送数据的数据改变点
     else
      clk_bps_r<='0';   --波特率计数器清零
     end if;
    end if;
   end if;
  clk_bps<=clk_bps_r;
 end process;
end behav;




---------------------------------异步发送模块  -------------------------------------------  
 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity uart_tx is
    port(clk : in  std_logic;                        --系统时钟
       rst_n: in std_logic;                        --复位信号 
   rs232_tx: out std_logic;                     --RS232接收数据信号
   clk_bps: in std_logic;                      --此时clk_bps的高电平为接收数据的采样点
   bps_start:out std_logic;  --接收到数据后，波特率时钟启动置位
   rx_data: in std_logic_vector(7 downto 0);  --接收数据寄存器，保存直至下一个数据来到
       rx_int: in std_logic                       --接收数据中断信号，接收数据期间时钟为高电平，传送给串口发送
                                               --模块，使得串口正在进行接收数据的时候，发送模块不工作，避免
                   --了一个完整的数据（1位起始位、8位数据位、1位停止位）还没有
                   --接收完全时，发送模块就已经将不正确的数据传输出去
   );
end uart_tx;
architecture behav of uart_tx is
         signal    rx_int0: std_logic;
         signal    rx_int1: std_logic;
         signal    rx_int2: std_logic;
   signal    neg_rx_int:std_logic;
         signal    bps_start_r:std_logic;
   signal    num:integer;
         signal    tx_data:std_logic_vector(7 downto 0);  --串口接收数据寄存器，保存直至下一个数据到来
begin
 
 process(clk,rst_n)
     begin
         if (rst_n='0')then
    rx_int0<='0';
    rx_int1<='0';
    rx_int2<='0';
   else
    if (rising_edge(clk)) then
     rx_int0<=rx_int;
     rx_int1<=rx_int0;
     rx_int2<=rx_int1;
    end if;
   end if;
   neg_rx_int <=not(rx_int1)and (rx_int2);
   end process;
 

   process(clk,rst_n)
     begin
         if (rst_n='0')then
    bps_start_r<='0';
    tx_data<="00000000";
   else
    if (rising_edge(clk)) then
         if(neg_rx_int='1') then    --接收到串口数据线rs232_rx的下降沿标志信号
     bps_start_r<='1';        --启动串口准备数据接收
     tx_data<=rx_data;    --接收数据中断信号使能
     else if((num= 15) and (clk_bps='1')) then --接收完有用数据信息
         bps_start_r<='0';  --数据接收完毕，释放波特率启动信号
       end if;
     end if;
       end if;
    end if;
  bps_start<=bps_start_r;
   end process;
 
 
   process(clk,rst_n)
     begin
         if (rst_n='0')then
    rs232_tx<='1';
    num<=0;
   else
    if (rising_edge(clk)) then
     if(clk_bps='1')then
       num<=num+1;
       case num is
        when  1=>rs232_tx<='0';
        when  2=>rs232_tx<=tx_data(0);--发送第1bit
        when  3=>rs232_tx<=tx_data(1);--发送第2bit
        when  4=>rs232_tx<=tx_data(2);--发送第3bit
        when  5=>rs232_tx<=tx_data(3);--发送第4bit
        when  6=>rs232_tx<=tx_data(4);--发送第5bit
        when  7=>rs232_tx<=tx_data(5);--发送第6bit
        when  8=>rs232_tx<=tx_data(6);--发送第7bit
        when  9=>rs232_tx<=tx_data(7);--发送第8bit
        when  10=>rs232_tx<='1';
        when  11=>num<=15;
        when  others=>null;
       end case;
       if(num=15) then
        num<=0;
       end if;
      end if;
     end if;
   end if;
  end process;
 
 end behav; 