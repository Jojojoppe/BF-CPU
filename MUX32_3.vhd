library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity MUX32_3 is
	port(
		CLK			: in std_logic;
		RES			: in std_logic;

		sel			: in std_logic_vector(2 downto 0);

		Din0		: in std_logic_vector(31 downto 0);
		Din1		: in std_logic_vector(31 downto 0);
		Din2		: in std_logic_vector(31 downto 0);

		Dout		: out std_logic_vector(31 downto 0)
	);
end entity;

architecture a of MUX32_3 is
begin

	p_MUX : process(Din0, Din1, Din2, sel)
	begin
		case sel is
			when "001" => Dout <= Din0;
			when "010" => Dout <= Din1;
			when "100" => Dout <= Din2;
			when others => Dout <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
		end case;
	end process;

end architecture;
