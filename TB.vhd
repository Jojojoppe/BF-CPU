library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.all;

entity TB is
end entity;

architecture a of TB is
	signal CLK		: std_logic := '0';
	signal RST		: std_logic := '0';

	signal LED		: std_logic_vector(7 downto 0) := x"00";

	-- Constants
	constant CLK_PERIOD : time := 10 ns;	--100MHz clock
	constant RUNTIME	: time := 200 ns;
begin

	e_bfcpu : entity BF_CPU(a)
		port map(CLK, RST, LED);

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
	STOP_process : process
	begin
		wait for RUNTIME;
		report "Simulation finished successfully" severity FAILURE;
	end process;

end architecture;
