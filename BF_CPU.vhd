library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.all;

entity BF_CPU is
	port(
		CLK			: in std_logic;
		RST			: in std_logic;

		-- Debug output
		LED			: out std_logic_vector(7 downto 0)
	);
end entity;

architecture a of BF_CPU is
	signal nRST		: std_logic;
	signal D		: std_logic_vector(7 downto 0);
	signal A		: std_logic_vector(31 downto 0);
	signal RAM_wr	: std_logic;
	signal RAM_rd	: std_logic;
	signal IO_wr	: std_logic;
	signal IO_rd	: std_logic;
	signal HLT		: std_logic;

begin

	nRST <= not(RST);

	-- RAM
	e_RAM : entity RAM(a)
		port map(CLK, nRST, RAM_rd, RAM_wr, D, D, A);

	-- CPU
	e_CPU : entity CPU(a)
		port map(CLK, nRST, D, D, A, RAM_wr, RAM_rd, IO_wr, IO_rd, HLT);

	-- IO0
	e_IO0 : entity REG8(a)
		port map(CLK, nRST, IO_rd, IO_wr, D, D, LED);

end architecture;
