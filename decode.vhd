-------------------------------STAGE 2: DECODE-----------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity decode is
port(
	clk, rst	: in std_logic;
	ir	:		in std_logic_vector(15 downto 0);
	pcplus1_i	:	in std_logic_vector(15 downto 0);
	pc	:		in std_logic_vector(15 downto 0);
	a1,a2:	out std_logic_vector(2 downto 0);
	a3	: inout std_logic_vector(2 downto 0);
	pcplus1_o	:out std_logic_vector(15 downto 0);
	pc_o		:out std_logic_vector(15 downto 0);
	im_se		:out std_logic_vector(15 downto 0);
	isjump,ismultiple		: inout std_logic;
	beq,isjalr		:out std_logic;
	c_en,z_en,opc,opz,adi_lw_sw	,lhi	: out std_logic;
	rfwr : out std_logic;
	dmemr : inout	std_logic;
	dmemw: out std_logic;
	if_en,wr_bpt,flush_reg : out std_logic;	
	wb_muxsel,aluop : out std_logic_vector(1 downto 0)
	);

end entity;

architecture behav of decode is

signal opcode: std_logic_vector(3 downto 0);
signal ra,rb,rc:std_logic_vector(2 downto 0);
signal imm6:std_logic_vector(5 downto 0);
signal imm6_se , irint:std_logic_vector(15 downto 0);
signal imm9:std_logic_vector(8 downto 0);
signal cond2 : std_logic_vector( 1 downto 0);
signal donem,donem2,done_mul,stall_lw:std_logic;
type complex is array(7 downto 0)  of std_logic_vector(2 downto 0);

type fsm is (idle,ismul);
signal state,state2: fsm;

---generates addresses of register used in lm,sm instruction
procedure genadr(imd:in std_logic_vector(7 downto 0);
	count: inout std_logic_vector(2 downto 0);
	adr: out complex) is
	begin
		count:="000";
		adr:=(others=>(others=>'0'));
		for i in 0 to 7 loop
			if(imd(i) = '1') then
				
				adr(to_integer(unsigned(count))) := std_logic_vector(to_unsigned(i,3));
				count:=std_logic_vector(unsigned(count)+1);
			end if;
		end loop;
	end genadr;
	
	
begin

opcode<= irint(15 downto 12);
ra	<=irint(11 downto 9);
rb	<=irint(8 downto 6);
rc	<=irint(5 downto 3);
imm6 <= irint(5 downto 0);
imm9 <= irint(8 downto 0);
imm6_se(5 downto 0) <= imm6;
imm6_se(15 downto 6) <= (others=>imm6(5));
cond2<=irint(1 downto 0);
irint<=ir;
wr_bpt<='1' when (opcode="1100" or opcode="1000") else '0';
			
done_mul<=donem and donem2 and not(stall_lw);	
--if_en<='0' when (opcode="0111" or opcode="0110") else done_mul;
------if_en used as stall for fetch stage and bpt.
if_en<=done_mul;

----process to generate a stall of fetch and flush of register read when a load word dependency is encountered.
ldr_proc:process (clk,rst) is
	variable ad3:complex;
	variable c:std_logic_vector(2 downto 0);
	begin
		if(rising_edge(clk)) then
			if(rst='1') then
				flush_reg<='0';
				stall_lw<='0';
			else
				if(dmemr='1' and done_mul='1') then
					case to_integer(unsigned(opcode)) is
						when 0|2|5|12 => if(ra=a3 or rb=a3) then
											flush_reg<='1';
											stall_lw<='1';
										else
											flush_reg<='0';
											stall_lw<='0';
										end if;
						when 1|4|9 => if(rb=a3) then
											flush_reg<='1';
											stall_lw<='1';
										else
											flush_reg<='0';
											stall_lw<='0';
										end if;
						when 6 => if(ra=a3) then
									flush_reg<='1';
									stall_lw<='1';
								end if;
						when 7 => if(ra=a3) then
									flush_reg<='1';
									stall_lw<='1';
								else
									flush_reg<='0';
									stall_lw<='0';
									genadr(imm9(7 downto 0),c,ad3);
									if(c/="000" and ad3(0)=a3) then
										flush_reg<='1';
										stall_lw<='1';
									end if;
									
									
								end if;
						when others=> flush_reg<='0';
										stall_lw<='0';
					end case;
				else
					flush_reg<='0';
					stall_lw<='0';
				end if;
			end if;
		end if;
	end process;

-----generates control signals based on opcode.
control_proc:process(clk,rst) is
	begin
		if(rising_edge(clk)) then
			if(rst='1') then
				rfwr<='0';
				isjump<= '0';
				beq<= '0';
				isjalr <= '0';
				opc <= '0';
				opz <= '0';
				dmemr <= '0';
				dmemw <= '0';
				adi_lw_sw<='0';
				wb_muxsel<="00";
				aluop<="00";
				c_en<='0';
				z_en<='0';
				lhi<='0';
				--wr_bpt<='0';
				ismultiple<='0';
				im_se<=(others=>'0');
				a1<=(others=>'0');
			elsif(done_mul='1') then
				
				pcplus1_o<=pcplus1_i;
				pc_o<=pc;
				a1<=ra;
				if(opcode="0000" or opcode="0001" or opcode="0100" or opcode="0101") then
					aluop<="01";	--add opc
					c_en<='1';
				elsif(opcode="0010") then
					aluop <= "10"; --nand
					c_en<='0';
				else
					aluop<="00";
					c_en<='0';
				end if;
				if(opcode="0111" or opcode="1100" or opcode="0101" or ((opcode="0000" or opcode="0010") and cond2/="00")) then
					rfwr<='0';
				else
					rfwr<='1';
				end if;
				
				if(opcode="1000" or opcode="1001") then
					isjump<= '1';
				else
					isjump<= '0';
				end if;
				if(opcode="1100") then
					beq<= '1';
				else
					beq<= '0';
				end if;
				if(opcode="1001") then
					isjalr <= '1';
				else
					isjalr <= '0';
				end if;
				if(opcode="0110" or opcode="0111") then
					ismultiple <= '1';
				else
					ismultiple <= '0';
				end if;
				if((opcode="0000" or opcode="0010") and cond2="10") then
					opc <= '1';
				else
					opc <= '0';
				end if;
				if((opcode="0000" or opcode="0010") and cond2="01") then
					opz <= '1';
				else
					opz <= '0';
				end if;
				if(opcode="0100" or opcode="0110") then
					dmemr <= '1';
				else
					dmemr <= '0';
				end if;
				if(opcode="0101" or opcode="0111") then
					dmemw <= '1';
				else
					dmemw <= '0';
				end if;
				
				if(opcode="0001" or opcode="0100" or opcode="0101") then
					adi_lw_sw<='1';
				else
					adi_lw_sw<='0';
				end if;
				-- if(opcode="1100" or opcode="1000") then
					-- wr_bpt<='1';
				-- else
					-- wr_bpt<='0';
				-- end if;
				if(opcode="0011" or opcode="0110" or opcode="0111") then
					im_se(15 downto 7)<=imm9;
					im_se(6 downto 0) <= (others=>'0');
				elsif(opcode="0001" or opcode="0100" or opcode="0101") then --adi,lw,sw
					im_se<=imm6_se;
				elsif(opcode="1100" or opcode="1000") then --beq and jal
					im_se<=std_logic_vector(signed(pc) + signed(imm6_se)) ;
				else
					im_se<=(others=>'0');
				end if;
			
				if(opcode="0100" or opcode="0110") then
					wb_muxsel<="01";
				elsif(opcode="1000" or opcode="1001") then
					wb_muxsel<="00";
				else
					wb_muxsel<="10";
				end if;
				if(opcode="0000" or opcode="0001" or opcode="0010" or opcode="0100") then
					z_en<='1';
				else
					z_en<='0';
				end if;
				if(opcode="0011") then
					lhi<='1';
				else
					lhi<='0';
				end if;
				
			end if;	
		end if;
	end process;

-----process which gives the operand 2 address 	
a2_proc:process(clk,rst) is
	variable c,c2:std_logic_vector(2 downto 0);
	variable ad2:complex;
	
	begin
		if(rising_edge(clk)) then
			if(rst='1') then
				donem<='1';
				state<=idle;
				c2:="000";
				a2<=rb;
			else 
				
			case state is
				when idle=> if(stall_lw='0') then
							a2<=rb;
							donem<='1';
							c2:="000";
							if(opcode="0111" and done_mul='1') then
								genadr(imm9(7 downto 0),c,ad2);
								if(c/="000") then
									if(c="001") then
										donem<='1';
									else	
										donem<='0';
										state<=ismul;
									end if;
									a2<=ad2(0);
									c2:=std_logic_vector(unsigned(c2)+1);
								end if;
							end if;
							end if;
							
				when ismul=> if(c2<c and stall_lw='0') then
								a2<=ad2(to_integer(unsigned(c2)));
								c2:=std_logic_vector(unsigned(c2)+1);								
							end if;
							if(c2=c) then
								donem<='1';
								state<=idle;
							end if;				
			end case;
			end if;
		end if;	
	end process;							

-----gives the address of reg for destination 	
a3_proc:process(clk,rst) is
	variable c,c2:std_logic_vector(2 downto 0);
	variable ad2:complex;
	
	begin
		if(rising_edge(clk)) then
			if(rst='1') then
				donem2<='1';
				state2<=idle;
				c2:="000";
				a3<=rc;
			else 
				
			case state2 is
				when idle=> --a3<=rb;
							if(stall_lw='0') then
							donem2<='1';
							c2:="000";
							if((opcode="0000" or opcode="0010") and done_mul='1') then
								a3<= rc;
							
							elsif(opcode="0110") then
								genadr(imm9(7 downto 0),c,ad2);
								if(c/="000") then
									if(c="001") then
										donem2<='1';
									else	
										donem2<='0';
										state2<=ismul;
									end if;
									a3<=ad2(0);
									c2:=std_logic_vector(unsigned(c2)+1);
								end if;
							else
								a3<=ra;
							end if;
							end if;
							
				when ismul=> if(c2<c and stall_lw='0') then
								a3<=ad2(to_integer(unsigned(c2)));
								c2:=std_logic_vector(unsigned(c2)+1);								
							end if;
							if(c2=c) then
								donem2<='1';
								state2<=idle;
							end if;				
			end case;
			end if;
		end if;	
	end process;					
							
end;
			