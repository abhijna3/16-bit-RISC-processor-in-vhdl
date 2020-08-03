library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity toplevel is
-- port(
-- clk,rst:in std_logic
-- );
end entity;

architecture behav of toplevel is

component bpredict is
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
end component;

component if_stage is
port(
	clk,rst,pcen:in std_logic;
	ir : out std_logic_vector(15 downto 0);
	empty: out std_logic;
	pcplus1,pcout: out std_logic_vector(15 downto 0);
	pcin,pcpin: in std_logic_vector(15 downto 0)
);	
end component;

component decode is
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

end component;

component regfile is
port ( adr_read1 : in std_logic_vector(2 downto 0);
		adr_read2 : in std_logic_vector(2 downto 0);
		a3_wb,a3in : in std_logic_vector(2 downto 0);
		dinwb : in std_logic_vector(15 downto 0);
		data_read1,data_read2: out std_logic_vector (15 downto 0);
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
end component;

component execute is
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
end component;

component memstage is
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
end component;

component wbstage is
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
end component;

signal clk,rst,rst_c,flush_cre,pcen_c:std_logic;
signal wr_c,isjalr_r,beq_r,isjump_r,equal_e,rst_ce,empty,flush_lw,flush_r,flush_r7,rst_f	:std_logic;
signal pc_f,pc_r,branchpc_e,pc_main,pcplus1_f,ir,pcplus1_c,pc_c,pcplus1_r,pcplus1_e,pcplus1_m	: std_logic_vector( 15 downto 0);
signal im_se_c,din_wb,d1_r,d2_r,imm6_r,agen_e,dtomem_e,aluout_e,aluout_m,dmem_m,pc_outp1	: std_logic_vector( 15 downto 0);
signal isjump_c,ismultiple_c,beq_c,isjalr_c,c_en_c,z_en_c,opc_c,opz_c,adi_lw_sw_c,lhi_c,rfwr_c,dmemr_c,dmemw_c,rfwr_wb,
		rfwr_r,cen_r,zen_r,opc_r,opz_r,adi_lw_sw_r,lhi_r,ismultiple_r,dmemr_r,dmemw_r,ismultiple_e,
		rfwr_e,dmemw_e,dmemr_e,rfwr_m:std_logic;
signal a1_c,a2_c,a3_c,a3_wb,a3_r,ra_r,rb_r,a3_e,a3_m: std_logic_vector( 2 downto 0);
signal aluop_c,wb_muxsel_c,wbsel_r,aluop_r,wbsel_e,wbsel_m: std_logic_vector( 1 downto 0);
--signal 

begin

process begin
	clk<='0';
	wait for 10 ns;
	clk<='1';
	wait for 10 ns;
end process;

process begin
	rst<='1';
	wait for 45 ns;
	rst<='0';
	wait;
end process;
	
	rst_f<=rst or flush_r7;
	rst_c<=rst or flush_cre or flush_r7;			---to flush execute stage
	rst_ce<=rst_c or empty ;				--- to flush control stage
	flush_r<=flush_cre or flush_lw or flush_r7;		--- to flush register_read stage
	pc_gen:	bpredict port map(clk=>clk,rst=>rst,wr_c=>wr_c,en_pc=>pcen_c,pc_c=>pc_f,pc_e=>pc_r,branchpc_e=>branchpc_e,
			isjalr=>isjalr_r,isbeq=>beq_r,isjump=>isjump_r,equal=>equal_e,hazard_flush=>flush_cre,pc_out=>pc_main,
			pc_outp1=>pc_outp1,din_wb=>din_wb,branch_r7=>flush_r7);
	
	inst_fetch:	if_stage port map(clk=>clk,rst=>rst_f,pcen=>pcen_c,empty=>empty,ir=>ir,pcpin=>pc_outp1,pcplus1=>pcplus1_f,
				pcout=>pc_f,pcin=>pc_main);

	inst_decode:	decode port map(clk=>clk,rst=>rst_ce,ir=>ir,pcplus1_i=>pcplus1_f,pc=>pc_f,a1=>a1_c,a2=>a2_c,a3=>a3_c,
			pcplus1_o=>pcplus1_c,pc_o=>pc_c,im_se=>im_se_c,isjump=>isjump_c,ismultiple=>ismultiple_c,beq=>beq_c,
			isjalr=>isjalr_c,c_en=>c_en_c,z_en=>z_en_c,opc=>opc_c,opz=>opz_c,adi_lw_sw=>adi_lw_sw_c,lhi=>lhi_c,rfwr=>rfwr_c,
			dmemr=>dmemr_c,dmemw=>dmemw_c,if_en=>pcen_c,wr_bpt=>wr_c,wb_muxsel=>wb_muxsel_c,aluop=>aluop_c,flush_reg=>flush_lw);
	
	register_read:	regfile port map(adr_read1=>a1_c,adr_read2=>a2_c,a3_wb=>a3_wb,a3in=>a3_c,dinwb=>din_wb,data_read1=>d1_r,
			data_read2=>d2_r,rst=>rst,flush=>flush_r,rfwrwb=>rfwr_wb,clk=>clk,rfwrin=>rfwr_c,pcplus1in=>pcplus1_c,pcin=>pc_c,
			imm6=>im_se_c,c_en=>c_en_c,z_en=>z_en_c,opc=>opc_c,opz=>opz_c,adi_lw_sw=>adi_lw_sw_c,lhiin=>lhi_c,isjump=>isjump_c,
			ismultiple=>ismultiple_c,beq=>beq_c,isjalr=>isjalr_c,memrin=>dmemr_c,memwin=>dmemw_c,wbselin=>wb_muxsel_c,
			aluin=>aluop_c,wbselout=>wbsel_r,aluout=>aluop_r,a3out=>a3_r,ra=>ra_r,rb=>rb_r,rfwrout=>rfwr_r,pcplus1out=>pcplus1_r,
			pcout=>pc_r,imm6out=>imm6_r,c_eno=>cen_r,z_eno=>zen_r,opco=>opc_r,opzo=>opz_r,adi_lw_swo=>adi_lw_sw_r,lhiout=>lhi_r,
			isjumpo=>isjump_r,ismultipleo=>ismultiple_r,beqo=>beq_r,isjalro=>isjalr_r,memrout=>dmemr_r,memwout=>dmemw_r);
	
	execute_stage:	execute port map (clk=>clk,rst=>rst_c,pcplus1in=>pcplus1_r,pcin=>pc_r,imm6in=>imm6_r,aluin=>aluop_r,
				d1=>d1_r,d2=>d2_r,a3in=>a3_r,ra=>ra_r,rb=>rb_r,a3_mem=>a3_e,a3_wb=>a3_wb,dwr_mem=>aluout_e,dwr_wb=>din_wb,
				rfwr_mem=>rfwr_e,rfwr_wb=>rfwr_m,pcplus1out=>pcplus1_e,aluout=>aluout_e,dtomem=>dtomem_e,agen=>agen_e,
				a3out=>a3_e,memrin=>dmemr_r,memwin=>dmemw_r,rfwrin=>rfwr_r,wbselin=>wbsel_r,memrout=>dmemr_e,memwout=>dmemw_e,
				rfwrout=>rfwr_e,ismul=>ismultiple_e,wbselout=>wbsel_e,c_en=>cen_r,z_en=>zen_r,opc=>opc_r,opz=>opz_r,
				adi_lw_sw=>adi_lw_sw_r,lhi=>lhi_r,isjump=>isjump_r,ismultiple=>ismultiple_r,beq=>beq_r,isjalr=>isjalr_r,
				equal=>equal_e,pcbranch=>branchpc_e);

	memory_stage:memstage port map(clk=>clk,rst=>rst_f,din=>dtomem_e,dout=>dmem_m,pcplus1out=>pcplus1_m,aluout=>aluout_m,
			memr=>dmemr_e,memw=>dmemw_e,rfwrin=>rfwr_e,ismul=>ismultiple_e,a3=>a3_e,pcplus1in=>pcplus1_e,aluin=>aluout_e,
			adr_gen=>agen_e,a3out=>a3_m,wbmuxin=>wbsel_e,wbmuxout=>wbsel_m,rfwrout=>rfwr_m);

	writeback_stage:wbstage port map(clk=>clk,rst=>rst,pcplus1=>pcplus1_m,memd=>dmem_m,aluo=>aluout_m,rfwr=>rfwr_m,a3=>a3_m,
			a3write=>a3_wb,dout=>din_wb,rfwro=>rfwr_wb,wbmux=>wbsel_m,flush_r7=>flush_r7);
			
end;	
