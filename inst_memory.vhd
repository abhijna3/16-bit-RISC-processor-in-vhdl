------STAGE 1: INSTRUCTION FETCH-----------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity inst_mem is
port(clk,rst,pcen:in std_logic;
	address: in std_logic_vector(15 downto 0);
	empty : out std_logic;
	data: out std_logic_vector(15 downto 0));
end entity;

architecture behav of inst_mem is
	type rom_array is array (0 to 35) of std_logic_vector (15 downto 0);
	constant rom: rom_array := ( x"3212",x"3212",x"3401",x"029a",x"5281",x"4881",x"0858",x"8a05",x"0000",x"1234",x"1234",x"1234",x"1d42",x"7abf",
								x"7823",x"3001",x"6a75",x"6c85",x"7a3a",x"c207",x"8af2",x"3212",x"3401",x"029a",x"5281",x"4881",x"8a05",x"0000",
								x"1234",x"1234",x"1234",x"1d42",x"7abf",x"1234",x"1234",x"1234");
begin

process(clk) begin
	if(rising_edge(clk)) then
		if(rst='1') then
			data<=(others=>'0');
			empty<='1';
		elsif(pcen='1') then		
		empty<='0';
		data <= rom(to_integer(unsigned(address)));
		end if;
	end if;
end process;
	
end architecture;
------------------------------------instruction fetch stage--------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity if_stage is
port(
	clk,rst,pcen:in std_logic;
	ir : out std_logic_vector(15 downto 0);
	empty: out std_logic;
	pcplus1,pcout: out std_logic_vector(15 downto 0);
	pcin,pcpin: in std_logic_vector(15 downto 0)
);	
end entity;

architecture struct of if_stage is
	component inst_mem is
	port(clk,rst,pcen:in std_logic;
	address: in std_logic_vector(15 downto 0);
	empty : out std_logic;
	data: out std_logic_vector(15 downto 0));
	end component;
	
begin
	
	imem: inst_mem port map(clk=>clk,rst=>rst,address=>pcin,pcen=>pcen,empty=>empty,data=>ir);
	
	 pc_proc:process(clk,rst) begin
		 if(rising_edge(clk)) then
			 if(rst='1') then
				 pcplus1<=(others=>'0');
				 pcout<=pcin;
			 elsif(pcen='1') then
				 pcplus1<=pcpin;
				 pcout<=pcin;
			 end if;
		 end if;
	 end process;	
	
end struct;
