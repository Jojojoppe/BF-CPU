library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity RAM is
	port(
		CLK			: in std_logic;
		RES			: in std_logic;

		rd			: in std_logic;
		wr			: in std_logic;

		Din			: in std_logic_vector(7 downto 0);
		Dout		: out std_logic_vector(7 downto 0);
		ADR			: in std_logic_vector(31 downto 0)
	);
end entity;

architecture a of RAM is
	type RAM_ARRAY is array (0 to 127) of std_logic_vector (7 downto 0);
	signal RAM: RAM_ARRAY := (
		x"08",x"20",x"00",x"00",
		x"00",x"09",x"40",x"00",
		x"00",x"00",x"0b",x"08",
		x"05",x"04",x"0d",x"06",
		x"0f",x"00",x"00",x"00", -- 10
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00", -- 20
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00", -- 30
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00", -- 40
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00"
	);
begin
	p_RAM : process(CLK)
	begin
		if rising_edge(CLK) then
			if wr='1' then
				RAM(to_integer(unsigned(ADR(6 downto 0)))) <= Din;
			end if;
		end if;
	end process;

	Dout <= RAM(to_integer(unsigned(ADR(6 downto 0)))) when (rd='1') else "ZZZZZZZZ";
end architecture;
