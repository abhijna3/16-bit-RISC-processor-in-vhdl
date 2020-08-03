-----------------------STAGE 5: MEMORY READ/WRITE---------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity memstage is
port(
	clk, rst	: in std_logic;
	din		: in std_logic_vector(15 downto 0);
	dout,pcplus1out,aluout		: out std_logic_vector(15 downto 0);
	memr,memw,rfwrin,ismul	: in std_logic;
	a3			: in std_logic_vector(2 downto 0);
	pcplus1in,aluin,adr_gen	: in std_logic_vector(15 downto 0);
	a3out		: out std_logic_vector(2 downto 0);
	wbmuxin		: in std_logic_vector(1 downto 0);
	wbmuxout	: out std_logic_vector(1 downto 0);
	rfwrout		: out std_logic
	);
end entity;

architecture behav of memstage is

type ram_type is array (0 to 10000) of std_logic_vector(15 downto 0);
   signal ram : ram_type;
 --  signal read_address : std_logic_vector(15 downto 0);
   signal adr	: std_logic_vector(15 downto 0);
begin

adr<=adr_gen when ismul='1' else aluin;

RamProc: process(clk) is

  begin
    if rising_edge(clk) then
	if rst='0' then
      if memw = '1' then
        ram(to_integer(unsigned(adr))) <= din;
      end if;
	  if(memr = '1') then
		dout <= ram(to_integer(unsigned(adr)));
		end if;
	end if;
	end if;
  end process RamProc;

  
process(clk,rst) is
begin
	if(rising_edge(clk)) then
		if(rst='1') then
			pcplus1out<=(others=>'0');
			aluout<=(others=>'0');
			rfwrout<='0';
			wbmuxout<=(others=>'0');
			a3out<=(others=>'0');
		else
			pcplus1out<=pcplus1in;
			aluout<=aluin;
			rfwrout<=rfwrin;
			wbmuxout<=wbmuxin;
			a3out<=a3;
		end if;
	end if;
end process;

end;