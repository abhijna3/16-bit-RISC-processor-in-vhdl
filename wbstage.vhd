------------------------STAGE 6: WRITEBACK --------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity wbstage is
port(
	clk, rst	: in std_logic;
	pcplus1,memd,aluo: in std_logic_vector(15 downto 0);
	rfwr:	in std_logic;
	a3: in std_logic_vector(2 downto 0);
	a3write: out std_logic_vector(2 downto 0);
	dout:out std_logic_vector(15 downto 0);
	rfwro,flush_r7: out std_logic;
	wbmux: in std_logic_vector(1 downto 0)
	);
end entity;

architecture behav of wbstage is

begin

dout<=pcplus1 when wbmux="00" else memd when wbmux="01" else aluo when wbmux="10" else (others=>'0');
rfwro<=rfwr;
a3write<=a3;
-- rao<=ra;
-- rbo<=rb;
flush_r7<='1' when (a3="111" and rfwr='1') else '0';

end;