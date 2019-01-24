library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity FDIV is
	generic(
		Fin			: integer;
		Fout			: integer
	);
	port(
		CLKin			: in std_logic;
		CLKout		: out std_logic;
		RST			: in std_logic
	);
end entity;

architecture a of FDIV is
	signal cnt : integer range 0 to Fin/(2*Fout) - 1 := 0;
	signal iclk : std_logic := '0';
begin
	CLKout <= iclk;
	process(CLKin, RST) begin
		if(RST='1') then
			cnt <= 0;
			iclk <= '0';
		elsif rising_edge(CLKin) then
			if (cnt=Fin/(2*Fout) - 1) then
				cnt <= 0;
				iclk <= not(iclk);
			else
				cnt <= cnt + 1;
			end if;
		end if;
	end process;
end architecture;
