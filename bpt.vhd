---------BRANCH PREDICTION CODE---------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity bpredict is
port(
	clk, rst	: in std_logic;
	wr_c,en_pc		: in std_logic;
	--pc_i	: inout std_logic_vector(15 downto 0);	
	pc_c,pc_e	: in std_logic_vector(15 downto 0);	--flipflop at left to execute stage
	branchpc_e	: in std_logic_vector(15 downto 0);
	isjump,isjalr,isbeq,equal: in std_logic;
	hazard_flush: out std_logic;
	din_wb : in std_logic_vector(15 downto 0);
	branch_r7:in std_logic;	
	pc_out,pc_outp1	: inout std_logic_vector(15 downto 0)	
	);
end entity;

architecture behav of bpredict is

type bpt is record
	pc  : std_logic_vector(15 downto 0);                -- FIFO Full Flag
    target : std_logic_vector(15 downto 0);                -- FIFO Empty Flag
    hb    : std_logic_vector(1 downto 0);
  end record bpt;  
  
  --01=nt : nt-00 t-11
  --00=nt:	nt-00 t-01
  --10=t:	nt-00 t-11
  --11=t:	nt-10 t-11
  
type table is array (10 downto 0) of bpt;
signal t1:table;	----branch prediction table.

begin

pc_outp1<=std_logic_vector(unsigned(pc_out)+1);

process(clk,rst) 
variable found,branch,match:boolean;
variable pointer: integer;
variable a,b:std_logic;
begin
	if(rising_edge(clk)) then
		if(rst='1') then
			for i in 0 to 10 loop
				t1(i).pc<=(others=>'0');
				t1(i).target<=(others=>'0');
				t1(i).hb<="01";
			end loop;
			found:=false;
			pointer:=0;
			branch:=false;
			pc_out<=x"0001";
			hazard_flush<='0';	--if branch is changed then flush
			--pcplus1<=x"0002";
		elsif(branch_r7='1') then
			hazard_flush<='0';
			pc_out<=din_wb;
		elsif(en_pc='1') then
			found:=false;
			branch:=false;
			--pcplus1<=pc2;
			--write the pc address if it is beq or jal instruction--
			if(wr_c='1') then
				for j in 0 to 10 loop--
					if(t1(j).pc=pc_c) then
						found:=true;
					end if;
				end loop;
				if(found=false) then
					t1(pointer).pc<=pc_c;
					t1(pointer).target<=std_logic_vector(unsigned(pc_c) + 1);
					pointer:=pointer+1;
				end if;
			end if;
			
			----jalr--
			if(isjalr='1') then
				branch:=true;
			elsif(isbeq='1') then
				for k in 0 to 10 loop--
					if(t1(k).pc=pc_e) then
						a:=t1(k).hb(1);
						b:=t1(k).hb(0);
						t1(k).hb(1) <=(a and b) or ( a and equal) or (b and equal);
						t1(k).hb(0) <= equal;
						if(t1(k).hb(1)/=equal) then							
							t1(k).target<= branchpc_e;
							branch:=true;
						end if;
					end if;
				end loop;
			elsif(isjump='1') then
				for k in 0 to 10 loop--
					if(t1(k).pc=pc_e) then
						a:=t1(k).hb(1);
						b:=t1(k).hb(0);
						t1(k).hb <="11";
						if(t1(k).hb/="11") then							
							t1(k).target<= branchpc_e;
							branch:=true;
						end if;
					end if;
				end loop;
			end if;
			match:=false;
			if(branch) then	
				pc_out<=branchpc_e;
				hazard_flush<='1';
			else
				hazard_flush<='0';
				for j in 0 to 10 loop--------------
					if(t1(j).pc=pc_out) then
						match:=true;
						pc_out<=t1(j).target;
					end if;
				end loop;
				if(match=false) then
					--pc_out<=std_logic_vector(unsigned(pc_out)+1);
					pc_out<=pc_outp1;
				end if;
			end if;
			
		end if;
	end if;
end process;	
	
end;
  