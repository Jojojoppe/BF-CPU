library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.all;

entity BF_CPU is
	port(
		CLK			: in std_logic;
		RST			: in std_logic;

		-- Debug output
		LED			: out std_logic_vector(7 downto 0)
	);
end entity;

architecture a of BF_CPU is
	-- Internal main signals
	signal nRST			: std_logic;		-- Inverted of RST (active high)

	-- CPU lines
	signal CPU_D		: std_logic_vector(7 downto 0);
	signal CPU_A		: std_logic_vector(31 downto 0);

	-- Control lines registers
	signal AC_wr		: std_logic;	-- Accumulator
	signal AC_rd		: std_logic;
	signal IR_wr		: std_logic;	-- Instruction register
	signal IR_rd		: std_logic;

	-- Control lines pointer registers
	signal IP_wr		: std_logic_vector(3 downto 0);	-- Instruction pointer
	signal IP_rd		: std_logic_vector(3 downto 0);
	signal DP_wr		: std_logic_vector(3 downto 0);	-- Data pointer
	signal DP_rd		: std_logic_vector(3 downto 0);
	signal SP_wr		: std_logic_vector(3 downto 0);	-- Stack pointer
	signal SP_rd		: std_logic_vector(3 downto 0);

	-- Direct data lines
	signal AC_d			: std_logic_vector(7 downto 0);
	signal IR_d			: std_logic_vector(7 downto 0);
	signal IP_d			: std_logic_vector(31 downto 0);
	signal DP_d			: std_logic_vector(31 downto 0);
	signal SP_d			: std_logic_vector(31 downto 0);

	signal ADR_sel		: std_logic_vector(2 downto 0);	-- Address selector [IP, DP, SP]

begin

	-- Internal main signals
	nRST <= not(RST);

	-- DEBUG LEDS
	LED <= CPU_D;

	-- Registers
	e_AC : entity REG8(a)			-- Accumulator
		port map(CLK, nRST, AC_rd, AC_wr, CPU_D, CPU_D, AC_d);
	e_IR : entity REG8(a)			-- Instruction register
		port map(CLK, nRST, IR_rd, IR_wr, CPU_D, CPU_D, IR_d);

	-- Pointer registers
	e_IP : entity REG32(a)			-- Instruction pointer
		port map(CLK, nRST, IP_rd, IP_wr, CPU_D, CPU_D, IP_d);
	e_DP : entity REG32(a)			-- Data pointer
		port map(CLK, nRST, DP_rd, DP_wr, CPU_D, CPU_D, DP_d);
	e_SP : entity REG32(a)			-- Data pointer
		port map(CLK, nRST, SP_rd, SP_wr, CPU_D, CPU_D, SP_d);

	-- Address selection
	e_AdrMux : entity MUX32_3(a)
		port map(CLK, nRST, ADR_sel, IP_d, DP_d, SP_d, CPU_A);

end architecture;
