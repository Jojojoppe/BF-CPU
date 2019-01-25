library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity REG32 is
	port(
		CLK			: in std_logic;
		RES			: in std_logic;

		rd			: in std_logic;
		wr			: in std_logic;

		Din			: in std_logic_vector(31 downto 0);
		Dout		: out std_logic_vector(31 downto 0);
		D			: out std_logic_vector(31 downto 0)
	);
end entity;

architecture a of REG32 is
	signal DATA		: std_logic_vector(31 downto 0);
begin

	D <= DATA;
	process(CLK, RES)
	begin
		-- RESET
		if RES='1' then
			DATA <= x"00000000";
		-- CLK pulse
		elsif rising_edge(CLK) then
			if wr='1' then
				DATA <= Din;
			end if;
		end if;
	end process;
	
	Dout <= DATA when (rd='1') else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

end architecture;
