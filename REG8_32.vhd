library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.all;

entity REG8_32 is
	port(
		CLK			: in std_logic;
		RES			: in std_logic;

		rd			: in std_logic;
		wr			: in std_logic_vector(3 downto 0);

		Din			: in std_logic_vector(31 downto 0);
		Dout		: out std_logic_vector(31 downto 0);
		D			: out std_logic_vector(31 downto 0)
	);
end entity;

architecture a of REG8_32 is
	signal Dout0	: std_logic_vector(7 downto 0);
	signal Dout1	: std_logic_vector(7 downto 0);
	signal Dout2	: std_logic_vector(7 downto 0);
	signal Dout3	: std_logic_vector(7 downto 0);
	signal D0		: std_logic_vector(7 downto 0);
	signal D1		: std_logic_vector(7 downto 0);
	signal D2		: std_logic_vector(7 downto 0);
	signal D3		: std_logic_vector(7 downto 0);
begin

	D <= D3 & D2 & D1 & D0;
	Dout <= Dout3 & Dout2 & Dout1 & Dout0;

	e_R0 : entity REG8(a)
		port map(CLK, RES, rd, wr(0), Din(7 downto 0), Dout0, D0);
	e_R1 : entity REG8(a)
		port map(CLK, RES, rd, wr(1), Din(15 downto 8), Dout1, D1);
	e_R2 : entity REG8(a)
		port map(CLK, RES, rd, wr(2), Din(23 downto 16), Dout2, D2);
	e_R3 : entity REG8(a)
		port map(CLK, RES, rd, wr(3), Din(31 downto 24), Dout3, D3);

end architecture;
