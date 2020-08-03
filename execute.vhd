--------------------STAGE 4: EXECUTE STAGE------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity execute is
port(
	clk, rst	: in std_logic;
	pcplus1in,pcin,imm6in	: in std_logic_vector(15 downto 0);
	aluin		: in std_logic_vector(1 downto 0);
	d1,d2		: in std_logic_vector(15 downto 0);
	a3in,ra,rb		: in std_logic_vector(2 downto 0);
	--for forwarding --
	a3_mem,a3_wb	: in std_logic_vector(2 downto 0);
	dwr_mem,dwr_wb	: in std_logic_vector(15 downto 0);
	rfwr_mem,rfwr_wb: in std_logic;
	--out
	pcplus1out,aluout,dtomem,agen	: out std_logic_vector(15 downto 0);--aluout goes to adr of dmem.
	a3out		: out std_logic_vector(2 downto 0);	
	--control signals
	memrin,memwin,rfwrin : in std_logic;
	wbselin		: in std_logic_vector(1 downto 0);
	memrout,memwout,rfwrout,ismul : out std_logic;
	wbselout		: out std_logic_vector(1 downto 0);
	c_en,z_en,opc,opz,adi_lw_sw,lhi : in std_logic;
	isjump,ismultiple,beq,isjalr : in std_logic;
	equal		: out std_logic;	--to bpt
	pcbranch	: out std_logic_vector(15 downto 0)	--will go to bpt branch_e
	);
end entity;

architecture behav of execute is

signal d11,d22 : std_logic_vector(15 downto 0);
signal aluo1,dalu : std_logic_vector(16 downto 0);
signal carry,zero : std_logic;
type fsm is (idle,start);
signal state: fsm;

----counts the number of 1s in the imm9 for lm,sm instruction
procedure counter(imd:in std_logic_vector(7 downto 0);
	count: inout std_logic_vector(2 downto 0)) is
	begin
		count:="000";
		for i in 0 to 7 loop
			if(imd(i) = '1') then			
				count:=std_logic_vector(unsigned(count)+"001");
			end if;
		end loop;
	end counter;
	
begin
equal<='1' when d11=d22 else '0';

pcbranch<=d22(15 downto 0) when isjalr='1' else imm6in;
--dalu<= ('0' & d11) when adi_lw_sw='0' else ('0' & imm6in);
dalu<= std_logic_vector(resize(signed(d11),17)) when adi_lw_sw='0' else std_logic_vector(resize(signed(imm6in),17));

aluo1 <= std_logic_vector(signed(resize(signed(d22),17)) + signed(dalu)) when aluin="01" else ( not( std_logic_vector(resize(signed(d22),17)) and dalu)) when aluin="10" else (others=>'0');

--carry<=aluo1(16) when c_en='1' else '0';----overflow for signed operation
carry<=(dalu(16) and d22(15) and not(aluo1(16))) or ((not(dalu(16)) and not(d22(15))) and aluo1(16)) when c_en='1' else '0';
zero <= '1' when (z_en='1' and aluo1="00000000000000000") else '0';

--forwarding-----
d11<= dwr_mem when (ra=a3_mem and rfwr_mem='1') else dwr_wb when(ra=a3_wb and rfwr_wb='1') else d1;
d22<= dwr_mem when (rb=a3_mem and rfwr_mem='1') else dwr_wb when (rb=a3_wb and rfwr_wb='1') else d2;

rfwrproc:process(clk,rst) begin
	if(rising_edge(clk)) then
		if(rst='1') then
			dtomem<=(others=>'0');
			rfwrout<='0';
			memrout<='0';
			memwout<='0';
			wbselout<="00";
			a3out<=(others=>'0');
			pcplus1out<=(others=>'0');
			ismul<='0';
			aluout<=(others=>'0');
		else
			rfwrout<=(rfwrin or (carry and opc) or (zero and opz));
			memrout<=memrin;
			memwout<=memwin;
			wbselout<=wbselin;
			a3out<=a3in;
			pcplus1out<=pcplus1in;
			ismul<=ismultiple;
			if(ismultiple='1')then
				dtomem<=d22;
			else
				dtomem<=d11;
			end if;
			
			if(lhi='1') then
				aluout<=imm6in;
			else
				aluout<=aluo1(15 downto 0);
			end if;
		end if;
	end if;
end process;

----generates address of data memory for lm and sm.

adrs_gen_multiple:process(clk,rst) 
variable reg_val:std_logic_vector(15 downto 0);
variable c,c2:std_logic_vector(2 downto 0);
begin

	if(rising_edge(clk)) then
		if(rst='1') then
			state<=idle;
			agen<=(others=>'0');
			c2:="000";
			reg_val:=(others=>'0');
		else
			
			case state is
				when idle=> c2:="000";
							if(ismultiple='1') then
								counter(imm6in(14 downto 7),c);
								if(c/="000" and c/="001") then
									state<=start;
								end if;	
								reg_val:=d11;
								agen<=d11;
								c2:=std_logic_vector(unsigned(c2)+1);
							end if;
				when start=> if(c2<c) then
								agen <=std_logic_vector(unsigned(reg_val) + unsigned(c2));
								c2:=std_logic_vector(unsigned(c2)+1);								
							end if;
							if(c2=c) then
								--donem<='1';
								state<=idle;
							end if;				
			end case;
		end if;
	end if;
end process;
	

end;