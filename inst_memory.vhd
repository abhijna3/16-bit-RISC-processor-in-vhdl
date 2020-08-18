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
	type rom_array is array (0 to (2**16)-1) of std_logic_vector (15 downto 0);
--	constant rom: rom_array := ( x"3212",x"3212",x"3401",x"029a",x"5281",x"4881",x"0858",x"8a05",x"0000",x"1234",x"1234",x"1234",x"1d42",x"7abf",
--								x"7823",x"3001",x"6a75",x"6c85",x"7a3a",x"c207",x"8af2",x"3212",x"3401",x"029a",x"5281",x"4881",x"8a05",x"0000",
--								x"1234",x"1234",x"1234",x"1d42",x"7abf",x"1234",x"1234",x"1234");

 constant rom : rom_array := (
      -- 0  => "0011000000000001",--LHI R0 X0080
      -- 1  => "0011001000000010",--LHI R1 X0100
	  -- 2  => "0011010000000100",--LHI R2 X0200
	  -- 3	=>	"0011011000001000",--LHI R3 X0400
	  -- 4	=>	"0011100000010000",--LHI R4 X0800
	  -- 5	=>	"0011101000100000",--LHI R5 X1000
	  -- 6	=>	"0011110001000000",--LHI R6 X2000
	  
	  -- 0  => "0011000000000001",--LHI R0 X0080
      -- 1  => "1000001000100010",--JAL R1 X0020
	  -- 35  => "1100010011100000",--BEQ R2 R3 X0020
  
  -- 0 => "0101000010000000",--SW  R0 R2+X00
	-- 1 => "0000100101110000",--ADD R4 R5 R6
	-- 2 => "0000001010011000",--ADD R1 R2 R3
	-- 3 => "0000011110110010",--ADC R3 R6 R6
	-- 4 => "0000001101110001",--ADZ R1 R5 R6
	-- 5 => "0001100101000001",--ADI R4 R5 X01
	-- 6 => "0100011010000000",--LW  R3 R2+X00
	-- 7 => "1100011100000000",--BEQ R3 R4 X00
	
  0 => "0111000000111010",--SM  R0 11111010
  1 => "0000100101110000",--ADD R4 R5 R6
  2 => "0000001010011000",--ADD R1 R2 R3
  3 => "0000000110110010",--ADC R3 R6 R6
  4 => "0000001101110001",--ADZ R1 R5 R6
  5 => "0001100101000001",--ADI R4 R5 X01
  6 => "0100011010000000",--LW  R3 R2+X00
  7 => "1100011100000000",--BEQ R3 R4 X00
	  others => (others => '0'));
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
