library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity DEMUX8_4 is
	port(
		CLK			: in std_logic;
		RES			: in std_logic;

		sel			: in std_logic_vector(3 downto 0);

		Din			: in std_logic_vector(7 downto 0);
		Dout0		: out std_logic_vector(7 downto 0);
		Dout1		: out std_logic_vector(7 downto 0);
		Dout2		: out std_logic_vector(7 downto 0);
		Dout3		: out std_logic_vector(7 downto 0)
	);
end entity;

architecture a of DEMUX8_4 is
begin

--	Dout0 <= "LLLLLLLL";
--	Dout1 <= "LLLLLLLL";
--	Dout2 <= "LLLLLLLL";
--	Dout3 <= "LLLLLLLL";

	p_DEMUX : process(Din, sel)
	begin
		case sel is
			when "0001" => 
				Dout0 <= Din;
				Dout1 <= x"00";
				Dout2 <= x"00";
				Dout3 <= x"00";
			when "0010" => 
				Dout0 <= x"00";
				Dout1 <= Din;
				Dout2 <= x"00";
				Dout3 <= x"00";
			when "0100" => 
				Dout0 <= x"00";
				Dout1 <= x"00";
				Dout2 <= Din;
				Dout3 <= x"00";
			when "1000" => 
				Dout0 <= x"00";
				Dout1 <= x"00";
				Dout2 <= x"00";
				Dout3 <= Din;
			when others =>
				Dout0 <= x"00";
				Dout1 <= x"00";
				Dout2 <= x"00";
				Dout3 <= x"00";
		end case;
	end process;

end architecture;
