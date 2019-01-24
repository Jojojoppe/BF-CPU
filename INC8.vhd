library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity INC8 is
	port(
		CLK			: in std_logic;
		RES			: in std_logic;

		inc			: in std_logic;
		dec			: in std_logic;

		Din			: in std_logic_vector(8 downto 0);
		Dout		: out std_logic_vector(8 downto 0)
	);
end entity;

architecture a of INC8 is
begin


	process(CLK, RES)
		variable DATA : integer;
	begin
		if RES='1' then
			DATA := 0;
		elsif rising_edge(CLK) then
			DATA := to_integer(unsigned(Din));

			if inc='1' then
				DATA := DATA + 1;
			elsif dec='1' then
				DATA := DATA - 1;
			end if;

			if inc='1' or dec='1' then
				Dout <= std_logic_vector(to_unsigned(DATA, Dout'length));
			else
				Dout <= "ZZZZZZZZ";
			end if;
		end if;
	end process;

end architecture;
