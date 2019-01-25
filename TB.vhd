library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.all;

entity TB is
end entity;

architecture a of TB is
	signal CLK		: std_logic := '0';
	signal RST		: std_logic := '0';

	signal nRST		: std_logic;
	signal D		: std_logic_vector(7 downto 0);
	signal A		: std_logic_vector(31 downto 0);
	signal RAM_wr	: std_logic;
	signal RAM_rd	: std_logic;
	signal IO_wr	: std_logic;
	signal IO_rd	: std_logic;
	signal HLT		: std_logic;

	-- Constants
	constant CLK_PERIOD : time := 10 ns;	--100MHz clock
begin

	nRST <= not(RST);

	-- RAM
	e_RAM : entity RAM(a)
		port map(CLK, nRST, RAM_rd, RAM_wr, D, D, A);

	-- CPU
	e_CPU : entity CPU(a)
		port map(CLK, nRST, D, D, A, RAM_wr, RAM_rd, IO_wr, IO_rd, HLT);

	-- IO
	p_IO : process (CLK, IO_wr, IO_rd)
	begin
		if rising_edge(IO_wr) then
			report "IO write [" & integer'image(to_integer(unsigned(A))) & "] = " & integer'image(to_integer(unsigned(D)));
		elsif rising_edge(IO_rd) then
			report "IO read [" & integer'image(to_integer(unsigned(A))) & "] = " & integer'image(to_integer(unsigned(D)));
		end if;
	end process;

	-- Clock generation
	CLK_process :process
	begin
		CLK <= '0';
		wait for CLK_PERIOD/2;
		CLK <= '1';
		wait for CLK_PERIOD/2;
	end process;

	-- Stimulus
	STIM_process :process
	begin
		RST <= '0';
		wait for CLK_PERIOD*4;
		RST <= '1';
		wait;
	end process;

	-- Stop process
	STOP_process : process(HLT)
	begin
		if rising_edge(HLT) then
			report "Simulation finished successfully" severity FAILURE;
		end if;
	end process;

end architecture;
