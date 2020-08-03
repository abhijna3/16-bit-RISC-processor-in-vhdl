---------STAGE 3: REGISTER READ------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity regfile is
port ( adr_read1 : in std_logic_vector(2 downto 0);
		adr_read2 : in std_logic_vector(2 downto 0);
		a3_wb,a3in : in std_logic_vector(2 downto 0);
		dinwb : in std_logic_vector(15 downto 0);
		data_read1,data_read2: out std_logic_vector (15 downto 0);
		--reg8	: in std_logic_vector (15 downto 0);
		rst,flush : in std_logic;
		rfwrwb : in std_logic;
		--equal: out std_logic;
		clk,rfwrin : in std_logic;
		--control signal
		pcplus1in,pcin,imm6	: in std_logic_vector(15 downto 0);
		c_en,z_en,opc,opz,adi_lw_sw,lhiin : in std_logic;
		isjump,ismultiple,beq,isjalr : in std_logic;
		memrin,memwin	: in std_logic;
		wbselin,aluin	: in std_logic_vector(1 downto 0);
		wbselout,aluout : out std_logic_vector(1 downto 0);
		a3out,ra,rb: out std_logic_vector(2 downto 0);
		rfwrout	: out std_logic;
		pcplus1out,pcout,imm6out	: out std_logic_vector(15 downto 0);
		c_eno,z_eno,opco,opzo,adi_lw_swo,lhiout : out std_logic;
		isjumpo,ismultipleo,beqo,isjalro : out std_logic;
		memrout,memwout	: out std_logic
	);
end entity;

architecture rtl of regfile is
begin

controlproc:process(clk,rst) is
	begin
		if(rising_edge(clk)) then
			if(rst='1' or flush='1') then
				aluout<=(others=>'0');
				pcout<=pcin;
				pcplus1out<=pcplus1in;
				imm6out<=(others=>'0');
				a3out<=(others=>'0');
				ra<=adr_read1;
				rb<=adr_read2;
				rfwrout<='0';
				isjalro<='0';
				isjumpo<='0';
				ismultipleo<='0';
				beqo<='0';
				adi_lw_swo<='0';
				c_eno<='0';
				z_eno<='0';
				opco<='0';
				opzo<='0';
				memrout<='0';
				memwout<='0';
				wbselout<=(others=>'0');
				lhiout<='0';
			else
				aluout<=aluin;
				pcout<=pcin;
				pcplus1out<=pcplus1in;
				imm6out<=imm6;
				a3out<=a3in;
				ra<=adr_read1;
				rb<=adr_read2;
				rfwrout<=rfwrin;
				isjalro<=isjalr;
				isjumpo<=isjump;
				ismultipleo<=ismultiple;
				beqo<=beq;
				adi_lw_swo<=adi_lw_sw;
				c_eno<=c_en;
				z_eno<=z_en;
				opco<=opc;
				opzo<=opz;
				memrout<=memrin;
				memwout<=memwin;
				wbselout<=wbselin;
				lhiout<=lhiin;
			end if;
		end if;
	end process;

reg_proc: process(clk,rst) is
	type regf is array (0 to 7) of std_logic_vector (15 downto 0);
	variable dram: regf;
	begin
		if(rising_edge(clk) ) then
			if(rst='1') then	
				dram:=(others=>(others=>'0'));
				data_read1<=(others=>'0');
				data_read2<=(others=>'0');
			else
				if(rfwrwb='1') then
				dram(to_integer(unsigned(a3_wb))):=dinwb;
				end if;				
				dram(7) := pcin;
				data_read1<=dram(to_integer(unsigned(adr_read1)));
				data_read2<=dram(to_integer(unsigned(adr_read2)));
			end if;
		end if;
	end process;
end rtl;