library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.all;

entity REG32 is
	port(
		CLK			: in std_logic;
		RES			: in std_logic;

		rd			: in std_logic_vector(3 downto 0);
		wr			: in std_logic_vector(3 downto 0);

		Din			: in std_logic_vector(7 downto 0);
		Dout		: out std_logic_vector(7 downto 0);
		D			: out std_logic_vector(31 downto 0)
	);
end entity;

architecture a of REG32 is
begin

	e_R0 : entity REG8(a)
		port map(CLK, RES, rd(0), wr(0), Din, Dout, D(7 downto 0));
	e_R1 : entity REG8(a)
		port map(CLK, RES, rd(1), wr(1), Din, Dout, D(15 downto 8));
	e_R2 : entity REG8(a)
		port map(CLK, RES, rd(2), wr(2), Din, Dout, D(23 downto 16));
	e_R3 : entity REG8(a)
		port map(CLK, RES, rd(3), wr(3), Din, Dout, D(31 downto 24));

end architecture;
