library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity MUX8_4 is
	port(
		CLK			: in std_logic;
		RES			: in std_logic;

		sel			: in std_logic_vector(3 downto 0);

		Din0		: in std_logic_vector(7 downto 0);
		Din1		: in std_logic_vector(7 downto 0);
		Din2		: in std_logic_vector(7 downto 0);
		Din3		: in std_logic_vector(7 downto 0);

		Dout		: out std_logic_vector(7 downto 0)
	);
end entity;

architecture a of MUX8_4 is
begin

	p_MUX : process(Din0, Din1, Din2, Din3, sel)
	begin
		case sel is
			when "0001" => Dout <= Din0;
			when "0010" => Dout <= Din1;
			when "0100" => Dout <= Din2;
			when "1000" => Dout <= Din3;
			when others => Dout <= "ZZZZZZZZ";
		end case;
	end process;

end architecture;
