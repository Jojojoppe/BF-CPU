library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity REG8 is
	port(
		CLK			: in std_logic;
		RES			: in std_logic;

		rd			: in std_logic;
		wr			: in std_logic;

		Din			: in std_logic_vector(7 downto 0);
		Dout		: out std_logic_vector(7 downto 0);
		D			: out std_logic_vector(7 downto 0)
	);
end entity;

architecture a of REG8 is
	signal DATA		: std_logic_vector(8 downto 0);
begin

	D <= DATA;
	process(CLK, RES)
	begin
		-- RESET
		if RES='1' then
			DATA <= x"00";
		-- CLK pulse
		elsif rising_edge(CLK) then
			if wr='1' then
				DATA <= Din;
			end if;
		end if;
	end process;
	
	Dout <= DATA when (rd='1') else "ZZZZZZZZ";

end architecture;
