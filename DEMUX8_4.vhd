library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity DEMUX8_4 is
	port(
		CLK			: in std_logic;
		RES			: in std_logic;

		sel			: in std_logic_vector(3 downto 0);

		Din			: in std_logic_vector(7 downto 0);
		Dout0		: out std_logic_vector(7 downto 0)
		Dout1		: out std_logic_vector(7 downto 0)
		Dout2		: out std_logic_vector(7 downto 0)
		Dout3		: out std_logic_vector(7 downto 0)
	);
end entity;

architecture a of DEMUX8_4 is
begin

	p_DEMUX : process(Din, sel)
	begin
		Dout0 <= "00000000";
		Dout1 <= "00000000";
		Dout2 <= "00000000";
		Dout3 <= "00000000";
		case sel is
			when "0001" => Dout0 <= Din;
			when "0010" => Dout1 <= Din;
			when "0100" => Dout2 <= Din;
			when "1000" => Dout3 <= Din;
		end case;
	end process;

end architecture;
