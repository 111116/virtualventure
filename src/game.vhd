-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
---clk
library  ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
entity clock is
	port(
		clk:in std_logic;
		clk_out:out std_logic
	);
end clock;

architecture clocker of clock is
	signal cnt:integer :=0;
begin
	process(clk)
	begin
		if(rising_edge(clk))then
			if(cnt = 166660)then
				cnt<=0;
				clk_out<='1';
			elsif (cnt = 0)then
				cnt<=cnt+1;
				clk_out<='0';
			else
				cnt<=cnt+1;
			end if;
		end if;
	end process;
end clocker;

-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
---lfsr for rand
Library IEEE ;
use IEEE.std_logic_1164.all ;
use IEEE.std_logic_arith.all ;
use ieee.std_logic_unsigned.all;


entity lfsr is
   port (
         clk      : in  std_logic ;
         reset    : in  std_logic ;
         data_out : out std_logic_vector(39 downto 0)
        );
end lfsr ;


architecture rtl of lfsr is 
	signal feedback : std_logic:='0' ;
	signal lfsr_reg : UNSIGNED(39 downto 0):="0111010000101101010010101101111110101010" ;
	begin
	feedback <= lfsr_reg(39) xor lfsr_reg(0) ;
	latch_it :  process(clk,reset)
	begin
          if (reset = '1') then
           lfsr_reg <= (others => '0') ;
          elsif (clk = '1' and clk'event) then
            lfsr_reg <= lfsr_reg(lfsr_reg'high - 1 downto 0) & feedback ;
          end if;
        end process ;
   data_out <= std_logic_vector(lfsr_reg) ;
end RTL ;


-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
library  ieee;
use ieee.std_logic_1164.all;
---use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
---map_gen + game_logic
entity game is
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

	type array1 is array(2 downto 0) of integer range 0 to 2047;
	
end game;
-------------------------------------------------------------------------------------------------------------------------------------------
architecture func of game is
	signal sent:std_logic;
	signal survive_signal:std_logic_vector(3 downto 0):="1111";
	signal survive :std_logic := '1';
	signal clk_in:std_logic; 	
	
	signal tc1:array1:=(2,0,0);---0没有，1没有斜坡，2有斜坡
	signal tc2:array1:=(1,1,0);
	
	signal pc1:array1:=(500,0,0);
	signal pc2:array1:=(1000,800,0);
	
	signal nc1:array1:=(4,0,0);
	signal nc2:array1:=(4,4,0);
	
	signal tb1:array1:=(0,2,0);---0没有，1上过，2下过，3上下都过
	signal tb2:array1:=(1,0,3);
	
	signal pb1:array1:=(0,700,0);
	signal pb2:array1:=(600,0,800);
	
	signal rand_b :std_logic_vector(39 downto 0);
	signal rand: std_logic_vector (9 downto 0);

	signal pos_y : integer:=300;
	signal pos_y_center : integer:=1;
	signal pos_h : integer:=0;
	signal pos_h_center : integer:=0;
	signal time_mov_y : integer:=0;
	signal time_mov_h : integer:=0;
-------------------------------------------------------------------------------------------------------------------------------------------
	component clock 
		port(
			clk:in std_logic;
			clk_out:out std_logic
		);
	end component;
	
	component lfsr
   port (
         clk      : in  std_logic ;
         reset    : in  std_logic ;
         data_out : out std_logic_vector(39 downto 0)
        );
	end component ;

-------------------------------------------------------------------------------------------------------------------------------------------	
begin
	ck: clock port map(clk,clk_out=>clk_in);
	rad: lfsr port map(clk,'0',rand_b);
	
	process(rand_b)
	begin
		if(rand_b(39 downto 38)="00")then
			rand <= rand_b(9 downto 0);
		elsif(rand_b(39 downto 38)="10")then
			rand <= rand_b(19 downto 10);
		elsif(rand_b(39 downto 38)="11")then
			rand <= rand_b(29 downto 20);
		else
			rand <= rand_b(37 downto 28);
		end if;
	end process;
-------------------------------------------------------------------------------------------------------------------------------------------
	process(pos_y,pos_y_center)
	begin
		if(pos_y <200)then
			pos_y_center<=0;
		elsif(pos_y > 340)then
			pos_y_center <=2;
		else
			pos_y_center <=1;
		end if;
	end process;
	
process(clk,reset,clk_in,sent,survive_signal,tc1,tc2,pc1,pc2,nc1,nc2,tb1,tb2,pb1,pb2,rand,pos_y,pos_y_center,pos_h,pos_h_center,time_mov_y,time_mov_h)
begin

if(rising_edge(clk)) then
	if(reset = '1') then
		sent<= '1';
		survive_signal<="1111";
		survive <= '1';		
	
		tc1<=(2,0,0);
		tc2<=(1,1,0);
	
		pc1<=(500,0,0);
		pc2<=(1000,800,0);
	
		nc1<=(4,0,0);
		nc2<=(4,4,0);
	
		tb1<=(0,2,0);
		tb2<=(1,0,3);
	
		pb1<=(0,700,0);
		pb2<=(600,0,800);

		pos_y <=300;
		pos_h <=0;
		pos_h_center<=0;
		time_mov_y <=0;
		time_mov_h<=0;	
	elsif((clk_in = '1') and (survive = '1')) then
	---delete
		for i in 0 to 2 loop
			if(pc1(i)<500-120*nc1(i))then
				tc1(i) <= 0;
			end if;
			if(pc2(i)<500-120*nc2(i))then
				tc2(i) <= 0;
			end if;		
			if(pb1(i) < 500)then
				tb1(i) <= 0;
			end if;
			if(tb2(i) < 500)then
				tb2(i) <= 0;
			end if;
		end loop;
-------------------------------------------------------------------------------------------------------------------------------------------
	---maintain
		for i in 0 to 2 loop
			if(tc1(i) /= 0)then
				pc1(i) <= pc1(i)-1;
			else
				pc1(i) <= 1140;
			end if;
			if(tc2(i) /= 0)then
				pc2(i) <= pc2(i)-1;
			else
				pc2(i) <= 1140;
			end if;
			if(tb1(i) /= 0)then
				pb1(i) <= pb1(i)-1;
			else
				pb1(i) <= 1140;
			end if;
			if(tb2(i) /= 0)then
				pb2(i) <= pb2(i)-1;
			else
				pb2(i) <= 1140;
			end if;
		end loop;
	

-------------------------------------------------------------------------------------------------------------------------------------------	
	---new
	
		for i in 0 to 2 loop
			if(tc1(i) = 0) then
				if(tc2(i) = 0) then
			---create 1
					if(std_logic_vector(rand(6 downto 0))="0000000")then
						if(rand(7)='0') then
							tc1(i)<=1;
						else
							tc1(i)<=2;
						end if;
						pc1(i)<= 1140;
						if(std_logic_vector(rand(9 downto 8))="00")then
							nc1(i)<= 1;
						elsif(std_logic_vector(rand(9 downto 8))="01")then
							nc1(i)<= 2;
						elsif(std_logic_vector(rand(9 downto 8))="10")then
							nc1(i)<= 3;
						else
							nc1(i)<= 4;
						end if;
					end if;
					
				elsif(pc2(i)+120*nc2(i)<1000)then
				---create 1;
					if(std_logic_vector(rand(6 downto 0))="0000000")then
						if(rand(7)='0') then
							tc1(i)<=1;
						else
							tc1(i)<=2;
						end if;
						pc1(i)<= 1140;
						if(std_logic_vector(rand(9 downto 8))="00")then
							nc1(i)<= 1;
						elsif(std_logic_vector(rand(9 downto 8))="01")then
							nc1(i)<= 2;
						elsif(std_logic_vector(rand(9 downto 8))="10")then
							nc1(i)<= 3;
						else
							nc1(i)<= 4;
						end if;
					end if;
				end if;
			elsif((tc2(i)=0) and (pc1(i)+120*nc1(i)<1000))then
			---create 2;
					if(std_logic_vector(rand(6 downto 0))="0000000")then
						if(rand(7)='0') then
							tc2(i)<=1;
						else
							tc2(i)<=2;
						end if;
						pc2(i)<= 1140;
						if(std_logic_vector(rand(9 downto 8))="00")then
							nc2(i)<= 1;
						elsif(std_logic_vector(rand(9 downto 8))="01")then
							nc2(i)<= 2;
						elsif(std_logic_vector(rand(9 downto 8))="10")then
							nc2(i)<= 3;
						else
							nc2(i)<= 4;
						end if;
					end if;
			end if;
		
			if(tb1(i) = 0) then
				if(tb2(i) = 0) then
			---create 1;
					if(std_logic_vector(rand(5 downto 0))="101101")then
						if(std_logic_vector(rand(7 downto 6))="00") then
							tb1(i)<=0;
						elsif(std_logic_vector(rand(7 downto 6))="01") then
							tb1(i)<=1;
						elsif(std_logic_vector(rand(7 downto 6))="10") then	
							tb1(i)<=2;
						else
							tb1(i)<=3;
						end if;					
						pb1(i)<= 1140;
					end if;
				elsif(pb2(i)<1000)then
			---create 1;
					if(std_logic_vector(rand(5 downto 0))="000000")then
						if(std_logic_vector(rand(7 downto 6))="00") then
							tb1(i)<=0;
						elsif(std_logic_vector(rand(7 downto 6))="01") then
							tb1(i)<=1;
						elsif(std_logic_vector(rand(7 downto 6))="10") then	
							tb1(i)<=2;
						else
							tb1(i)<=3;
						end if;					
						pb1(i)<= 1140;
					end if;
				end if;
			elsif((tb2(i)=0) and (pb1(i)<1000))then
		---create 2;
				if(std_logic_vector(rand(5 downto 0))="000000")then
					if(std_logic_vector(rand(7 downto 6))="00") then
						tb2(i)<=0;
					elsif(std_logic_vector(rand(7 downto 6))="01") then
						tb2(i)<=1;
					elsif(std_logic_vector(rand(7 downto 6))="10") then	
						tb2(i)<=2;
					else
						tb2(i)<=3;
					end if;					
					pb2(i)<= 1140;
				end if;
			end if;
		end loop;
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------	
---game logic

---a:
		if((pc1(pos_y_center)+120*nc1(pos_y_center) = 650) or (pc2(pos_y_center)+120*nc2(pos_y_center) = 650)) then
			if(time_mov_h>0) then
				time_mov_h <= time_mov_h+60;
			else
				time_mov_h <= 60;
			end if;	
		else
			if((UD = "00" and (time_mov_h = 0 or time_mov_h < 0))) then
				time_mov_h <= 40;
			elsif(UD = "11") then
				time_mov_h <= -20;
			end if;	
		end if;
	
		if(time_mov_y = 0)then
			if(LR = "00") then
				time_mov_y <= 70;
			elsif(LR = "11") then
				time_mov_y <= -70;
			end if;
		end if;
	
---v:
		if(time_mov_h>0 ) then
			pos_h <= pos_h_center + time_mov_h;
			time_mov_h <= time_mov_h - 1;
		elsif (time_mov_h < 0) then
			pos_h <= pos_h_center;
			time_mov_h <= time_mov_h + 1;
		else
			pos_h <= pos_h_center;
		end if;
	
		if(time_mov_y>0 )then
			time_mov_y <= time_mov_y -1;
			pos_y <=pos_y -2;
		elsif(time_mov_y <0) then 
			time_mov_y <= time_mov_y +1;
			pos_y <=pos_y +2;
		end if;
	
---collision detection
	---collision
		if((tc1(pos_y_center) = 2)and (pc1(pos_y_center)+60 > 650) and (pc1(pos_y_center) < 650) and (pos_h<60)) then
			pos_h_center<=650 - pc1(pos_y_center);
		elsif((tc2(pos_y_center) = 2)and (pc2(pos_y_center)+60 > 650) and (pc2(pos_y_center) < 650) and (pos_h<60)) then
			pos_h_center<=650 - pc2(pos_y_center);
		elsif((tc1(pos_y_center) = 1)and (pc1(pos_y_center)+120*nc1(pos_y_center) > 650) and (pc1(pos_y_center) < 650)) then
			if(pos_h > 55) then
				pos_h_center <= 60;
			else
				survive_signal(0)<='0';
			end if;
		elsif((tc2(pos_y_center) = 1)and (pc2(pos_y_center)+120*nc2(pos_y_center) > 650) and (pc2(pos_y_center) < 650)) then
			if(pos_h > 55) then
				pos_h_center <= 60;
			else
				survive_signal(0)<='0';
			end if;
		elsif((tc1(pos_y_center) = 2)and (pc1(pos_y_center)+120*nc1(pos_y_center) > 650) and (pc1(pos_y_center) < 590)) then
			if(pos_h > 55) then
				pos_h_center <= 60;
			else
				survive_signal(0)<='0';
			end if;
		elsif((tc2(pos_y_center) = 2)and (pc2(pos_y_center)+120*nc2(pos_y_center) > 650) and (pc2(pos_y_center) < 590)) then
			if(pos_h > 55) then
				pos_h_center <= 60;
			else
				survive_signal(0)<='0';
			end if;
		elsif((tb1(pos_y_center) /=0) and (pb1(pos_y_center) < 645) and (pb1(pos_y_center) > 655)) then
			if((tb1(pos_y_center)=1) and (time_mov_h <10)) then
				survive_signal(2)<='0';
			elsif((tb1(pos_y_center)=2) and (time_mov_h> -1)) then
				survive_signal(2)<='0';
			elsif((tb1(pos_y_center)=3) and (time_mov_h >-1 and time_mov_h < 10)) then
				survive_signal(2)<='0';
			end if;
		elsif((tb2(pos_y_center) /=0) and (pb2(pos_y_center) < 645) and (pb2(pos_y_center) > 655)) then
			if((tb2(pos_y_center)=1) and (time_mov_h<10)) then
				survive_signal(3)<='0';
			elsif((tb2(pos_y_center)=2) and (time_mov_h>-1)) then
				survive_signal(3)<='0';
			elsif((tb2(pos_y_center)=3) and (time_mov_h >-1 and time_mov_h < 10)) then
				survive_signal(3)<='0';
			end if;
		else
			pos_h_center <= 0;
		end if;
	
		sent <= '1';
		if(survive_signal = "1111")then
			survive <= '1';
		else
			survive <= '0';
		end if;
	elsif(clk_in = '1' and survive = '0') then
		sent <= '1';
	elsif(clk_in = '0') then
		sent <= '0';
	end if;
end if;
end process;
-------------------------------------------------------------------------------------------------------------------------------------------	

	process(sent,clk,tc1,tc2,pc1,pc2,nc1,nc2,pb1,pb2,tb1,tb2,pos_y,pos_h,clk_in,time_mov_h)
	begin
	if(rising_edge(clk))then
		if(sent = '1')then
			for i in 0 to 2 loop
				type_carriage(2*i+1 downto 2*i) <= std_logic_vector(to_unsigned(tc1(i),2));
				type_carriage(7+2*i downto 6+2*i) <= std_logic_vector(to_unsigned(tc2(i),2));
				pos_carriage(12*i+11 downto 12*i) <= std_logic_vector(to_unsigned(pc1(i)-500,12));
				pos_carriage(47+12*i downto 36+12*i) <= std_logic_vector(to_unsigned(pc2(i)-500,12));
				num_carriage(3*i+2 downto 3*i)<= std_logic_vector(to_unsigned(nc1(i),3));
				num_carriage(3*i+11 downto 3*i+9)<= std_logic_vector(to_unsigned(nc2(i),3));
				pos_barrier(12*i+11 downto 12*i) <= std_logic_vector(to_unsigned(pb1(i)-500,12));
				pos_barrier(47+12*i downto 36+12*i) <= std_logic_vector(to_unsigned(pb2(i)-500,12));
				type_barrier(2*i+1 downto 2*i) <= std_logic_vector(to_unsigned(tb1(i),2));
				type_barrier(7+2*i downto 6+2*i) <= std_logic_vector(to_unsigned(tb2(i),2));
			end loop;
			character_y <= std_logic_vector(to_unsigned(pos_y,12));
			character_h <= std_logic_vector(to_unsigned(pos_h,12));
			if(time_mov_h<0)then
				character_state<="00";
			elsif (time_mov_h>0)then
				character_state<="11";
			else
				character_state<="01";
			end if;
			survive_sign <= survive;
		end if;
		data_ready <= sent;
	end if;
	end process;

end func;














