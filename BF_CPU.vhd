library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.all;

entity BF_CPU is
	port(
		CLK			: in std_logic;
		RST			: in std_logic;

		-- Debug output
		LED			: out std_logic_vector(7 downto 0);
		D_clk		: out std_logic;
		D_HLT		: out std_logic
	);
end entity;

architecture a of BF_CPU is
	signal nRST		: std_logic;
	
	signal A		: std_logic_vector(31 downto 0);
	signal D		: std_logic_vector(7 downto 0);

	signal RAM_Dout	: std_logic_vector(7 downto 0);

	signal RAM_wr	: std_logic;
	signal RAM_rd	: std_logic;
	signal IO_wr	: std_logic;
	signal IO_rd	: std_logic;

	signal sCLK		: std_logic;
	signal HLT		: std_logic;

begin

	D_clk <= sCLK;
	D_HLT <= not(HLT);
	nRST <= not(RST);

	e_FDIV : entity FDIV(a) generic map(100000000, 2)
		port map(CLK, sCLK, nRST);

	e_RAM : entity ip_RAM(ip_RAM_a)
		port map(CLK, nRST, RAM_rd or RAM_wr, "" & RAM_wr, A(15 downto 0), D, RAM_Dout);

	e_CPU : entity CPU(a)
		port map(sCLK, nRST, D, D, A, RAM_wr, RAM_rd, IO_wr, IO_rd, HLT);

	D <= RAM_Dout when (RAM_rd = '1') else "ZZZZZZZZ";

	LED <= D;

end architecture;
