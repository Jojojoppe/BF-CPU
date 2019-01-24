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

	-- RAM control lines
	signal RAM_wr		: std_logic;
	signal RAM_rd		: std_logic;

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

	-- Arithmetic control lines
	signal DAR_inc		: std_logic;
	signal DAR_dec		: std_logic;
	signal AAR_inc		: std_logic;
	signal AAR_dec		: std_logic;
	signal AAR_adr		: std_logic_vector(31 downto 0);
	signal AAR_sel		: std_logic_vector(2 downto 0); -- Address arithmetic selector [IP, DP, SP]

	-- Data->Address bridge
	signal DAB_sel		: std_logic_vector(3 downto 0);
	signal DAB_en		: std_logic;
	signal DAB_d0		: std_logic_vector(7 downto 0);
	signal DAB_d1		: std_logic_vector(7 downto 0);
	signal DAB_d2		: std_logic_vector(7 downto 0);
	signal DAB_d3		: std_logic_vector(7 downto 0);

	signal state		: integer;

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

	-- Data arithmetic (add/sub)
	e_DAR : entity INC8(a)
		port map(CLK, nRST, DAR_inc, DAR_dec, AC_d, CPU_d);

	-- Address arithmetic (add/sub)
	e_AARMux : entity MUX32_3(a)
		port map(CLK, nRST, AAR_sel, IP_d, DP_d, SP_d, AAR_adr);
	e_AAR : entity INC32(a)
		port map(CLK, nRST, AAR_inc, AAR_dec, AAR_adr, CPU_A);

	-- Pointer registers
	e_IP : entity REG32(a)			-- Instruction pointer
		port map(CLK, nRST, IP_rd, IP_wr, CPU_A, CPU_A, IP_d);
	e_DP : entity REG32(a)			-- Data pointer
		port map(CLK, nRST, DP_rd, DP_wr, CPU_A, CPU_A, DP_d);
	e_SP : entity REG32(a)			-- Data pointer
		port map(CLK, nRST, SP_rd, SP_wr, CPU_A, CPU_A, SP_d);

	-- Data->Address bridge
	e_DAB : entity DEMUX8_4(a)
		port map(CLK, nRST, DAB_sel, CPU_D, DAB_d0, DAB_d1, DAB_d2, DAB_d3);
	CPU_A <= DAB_d3 & DAB_d2 & DAB_d1 & DAB_d0 when (DAB_en = '1') else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";


	-- CONROL
	-- ------
	p_control : process(CLK, nRST)
	begin
		if nRST='1' then
			state <= 0;	-- Reset the CPU

		-- Control loop
		elsif rising_edge(CLK) then
			AC_wr		<= '0';
			AC_rd		<= '0';
			IR_wr		<= '0';
			IR_rd		<= '0';
			IP_wr		<= "0000";
			IP_rd		<= "0000";
			DP_wr		<= "0000";
			DP_rd		<= "0000";
			SP_wr		<= "0000";
			SP_rd		<= "0000";

			DAR_inc		<= '0';
			DAR_dec		<= '0';
			AAR_inc		<= '0';
			AAR_dec		<= '0';
			AAR_sel		<= "000";

			DAB_sel		<= "0000";
			DAB_en		<= '0';

			RAM_wr		<= '0';
			RAM_rd		<= '0';

			case state is

				-- Reset CPU
				when 0 =>
					state		<= 1;

				-- Fetch opcode from memory
				when 1 =>
					-- IR = RAM[IP]
					RAM_rd		<= '1';
					IR_wr		<= '1';
					IP_rd		<= '1';

					state		<= 2;

				-- Increase IP and decode opcode
				when 2 =>
					-- IP++
					IP_wr		<= '1';
					AAR_inc		<= '1';
					AAR_sel		<= "001";

					-- Decode opcode
					case IR_d(3 downto 0) is
						-- " " NOP
						when x"0" => state <= 1;
						-- ">" DP++
						when x"1" => state <= 3;
						-- "<" DP--
						when x"2" => state <= 4;
					end case;

				-- Increase DP
				when 3 =>
					-- DP++
					DP_wr		<= '1';
					AAR_sel		<= "010";
					AAR_inc		<= '1';
					state		<= 1;

				-- Decrease DP
				when 4 =>
					-- DP--
					DP_wr		<= '1';
					AAR_sel		<= "010";
					AAR_dec		<= '1';
					state		<= 2;

				-- Unknown state -> reset CPU
				when others =>
					state <= 0;
			end case;
		end if;
	end process;

end architecture;
