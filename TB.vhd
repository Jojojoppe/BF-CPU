library IEEE;
use IEEE.STD_LOGIC_1164.all;
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
		port map(CLK, nRST, D, D, A, RAM_wr, RAM_rd, HLT);

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
