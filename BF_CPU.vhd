library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.all;

entity BF_CPU is
	port(
		CLK			: in std_logic;
		RST			: in std_logic;

		HLT			: out std_logic;

		-- Debug output
		LED			: out std_logic_vector(7 downto 0)
	);
end entity;

architecture a of BF_CPU is
	-- Internal main signals
	signal nRST			: std_logic;		-- Inverted of RST (active high)
	signal sRST			: std_logic;		-- Software reset

	-- CPU lines
	signal CPU_D		: std_logic_vector(7 downto 0);
	signal CPU_A		: std_logic_vector(31 downto 0);

	-- RAM control lines
	signal RAM_wr		: std_logic;
	signal RAM_rd		: std_logic;

	-- Control lines registers
	signal AC_wr		: std_logic;	-- Accumulator
	signal AC_rd		: std_logic;
	signal AC_clr		: std_logic;
	signal IR_wr		: std_logic;	-- Instruction register
	signal IR_rd		: std_logic;

	-- Control lines pointer registers
	signal IP_wr		: std_logic;	-- Instruction pointer
	signal IP_rd		: std_logic;
	signal DP_wr		: std_logic;	-- Data pointer
	signal DP_rd		: std_logic;
	signal SP_wr		: std_logic;	-- Stack pointer
	signal SP_rd		: std_logic;
	signal BU_wr		: std_logic_vector(3 downto 0);	-- Buffer
	signal BU_rd		: std_logic;

	-- Direct data lines
	signal AC_d			: std_logic_vector(7 downto 0);
	signal IR_d			: std_logic_vector(7 downto 0);
	signal IP_d			: std_logic_vector(31 downto 0);
	signal DP_d			: std_logic_vector(31 downto 0);
	signal SP_d			: std_logic_vector(31 downto 0);
	signal BU_d			: std_logic_vector(31 downto 0);

	-- Arithmetic control lines
	signal DAR_inc		: std_logic;
	signal DAR_dec		: std_logic;
	signal AAR_inc		: std_logic;
	signal AAR_dec		: std_logic;
	signal AAR_adr		: std_logic_vector(31 downto 0);
	signal AAR_sel		: std_logic_vector(3 downto 0); -- Address arithmetic selector [IP, DP, SP, BU]

	-- Data->Address bridge
	signal DAB_sel		: std_logic_vector(3 downto 0);
	signal DAB_en		: std_logic;
	signal DAB_d0		: std_logic_vector(7 downto 0);
	signal DAB_d1		: std_logic_vector(7 downto 0);
	signal DAB_d2		: std_logic_vector(7 downto 0);
	signal DAB_d3		: std_logic_vector(7 downto 0);
	signal BU_Din		: std_logic_vector(31 downto 0);

	-- Address->Data bridge
	signal ADB_sel		: std_logic_vector(3 downto 0);
	signal ADB_d0		: std_logic_vector(7 downto 0);
	signal ADB_d1		: std_logic_vector(7 downto 0);
	signal ADB_d2		: std_logic_vector(7 downto 0);
	signal ADB_d3		: std_logic_vector(7 downto 0);

	signal state		: integer;

begin

	-- Internal main signals
	nRST <= not(RST) or sRST;

	-- DEBUG LEDS
	LED <= CPU_D;

	-- RAM
	e_RAM : entity RAM(a)
		port map(CLK, nRST, RAM_rd, RAM_wr, CPU_D, CPU_D, CPU_A);

	-- Registers
	e_AC : entity REG8(a)			-- Accumulator
		port map(CLK, nRST or AC_clr, AC_rd, AC_wr, CPU_D, CPU_D, AC_d);
	e_IR : entity REG8(a)			-- Instruction register
		port map(CLK, nRST, IR_rd, IR_wr, CPU_D, CPU_D, IR_d);

	-- Data arithmetic (add/sub))
	e_DAR : entity INC8(a)
		port map(CLK, nRST, DAR_inc, DAR_dec, AC_d, CPU_d);

	-- Address arithmetic (add/sub)
	e_AARMux : entity MUX32_4(a)
		port map(CLK, nRST, AAR_sel, IP_d, DP_d, SP_d, BU_d, AAR_adr);
	e_AAR : entity INC32(a)
		port map(CLK, nRST, AAR_inc, AAR_dec, AAR_adr, CPU_A);

	-- Pointer registers
	e_IP : entity REG32(a)			-- Instruction pointer
		port map(CLK, nRST, IP_rd, IP_wr, CPU_A, CPU_A, IP_d);
	e_DP : entity REG32(a)			-- Data pointer
		port map(CLK, nRST, DP_rd, DP_wr, CPU_A, CPU_A, DP_d);
	e_SP : entity REG32(a)			-- Data pointer
		port map(CLK, nRST, SP_rd, SP_wr, CPU_A, CPU_A, SP_d);
	e_BU : entity REG8_32(a)
		port map(CLK, nRST, BU_rd, BU_wr, BU_Din, CPU_A, BU_d);

	-- Data->Address bridge
	e_DAB : entity DEMUX8_4(a)
		port map(CLK, nRST, DAB_sel, CPU_D, DAB_d0, DAB_d1, DAB_d2, DAB_d3);
	BU_Din <= DAB_d3 & DAB_d2 & DAB_d1 & DAB_d0 when (DAB_en = '1') else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

	-- Address->Data bridge
	e_ADB : entity MUX8_4(a)
		port map(CLK, nRST, ADB_sel, ADB_d0, ADB_d1, ADB_d2, ADB_d3, CPU_D);
	ADB_d0 <= CPU_A(7 downto 0);
	ADB_d1 <= CPU_A(15 downto 8);
	ADB_d2 <= CPU_A(23 downto 16);
	ADB_d3 <= CPU_A(31 downto 24);

	-- CONROL
	-- ------
	p_control : process(CLK, nRST)
	begin
		if nRST='1' then
			state <= 0;	-- Reset the CPU

		-- Control loop
		elsif falling_edge(CLK) then
			sRST		<= '0';

			AC_wr		<= '0';
			AC_rd		<= '0';
			IR_wr		<= '0';
			IR_rd		<= '0';
			IP_wr		<= '0';
			IP_rd		<= '0';
			DP_wr		<= '0';
			DP_rd		<= '0';
			SP_wr		<= '0';
			SP_rd		<= '0';
			BU_wr		<= "0000";
			BU_rd		<= '0';

			AC_clr		<= '0';

			DAR_inc		<= '0';
			DAR_dec		<= '0';
			AAR_inc		<= '0';
			AAR_dec		<= '0';
			AAR_sel		<= "0000";

			DAB_sel		<= "0000";
			DAB_en		<= '0';

			ADB_sel		<= "0000";

			RAM_wr		<= '0';
			RAM_rd		<= '0';

			HLT			<= '0';

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
					AAR_sel		<= "0001";

					-- Decode opcode
					case IR_d(3 downto 0) is
						-- " " NOP
						when x"0" => state <= 1;
						-- ">" DP++
						when x"1" => state <= 3;
						-- "<" DP--
						when x"2" => state <= 4;
						-- "+" RAM[DP]++
						when x"3" => state <= 5;
						-- "-" RAM[DP] --
						when x"4" => state <= 7;
						-- "[" Conditional forward jump
						when x"5" => state <= 9;
						-- "]" Conditional backward jump
						when x"6" => state <= 24;
						-- "I" Load IP
						when x"7" => state <= 34;
						-- "D" Load DP
						when x"8" => state <= 42;
						-- "S" Load SP
						when x"9" => state <= 52;
						-- "C" Clear RAM[DP]
						when x"a" => state <= 61;
						-- "L" Save literal to RAM[DP]
						when x"b" => state <= 63;
						-- "H" Halt
						when x"f" => state <= 66;
						-- Unknown -> RESET CPU
						when others =>
							sRST <= '0';
							state <= 0;
					end case;

				-- Increase DP
				when 3 =>
					report ">";
					-- DP++
					DP_wr		<= '1';
					AAR_sel		<= "0010";
					AAR_inc		<= '1';
					state		<= 1;

				-- Decrease DP
				when 4 =>
					report "<";
					-- DP--
					DP_wr		<= '1';
					AAR_sel		<= "0010";
					AAR_dec		<= '1';
					state		<= 1;

				-- Increase RAM[DP]
				when 5 =>
					report "+";
					-- AC = RAM[DP]
					RAM_rd		<= '1';
					AC_wr		<= '1';
					DP_rd		<= '1';
					state		<= 6;
				when 6 =>
					-- RAM[DP] = AC+1
					RAM_wr		<= '1';
					DAR_inc		<= '1';
					DP_rd		<= '1';
					state		<= 1;

				-- Decrease RAM[DP]
				when 7 =>
					report "-";
					-- AC = RAM[DP]
					RAM_rd		<= '1';
					AC_wr		<= '1';
					DP_rd		<= '1';
					state		<= 8;
				when 8 =>
					-- RAM[DP] = AC-1
					RAM_wr		<= '1';
					DAR_dec		<= '1';
					DP_rd		<= '1';
					state		<= 1;

				-- Conditional forward jump
				when 9 =>
					report "[";
					-- AC = RAM[DP]
					RAM_rd		<= '1';
					AC_wr		<= '1';
					DP_rd		<= '1';
					state		<= 10;
				when 10 =>
					-- Condition check
					if AC_d = x"00" then
						-- AC = RAM[IP]
						RAM_rd		<= '1';
						IP_rd		<= '1';
						AC_wr		<= '1';
						state		<= 22;
					else
						-- AC = IP[0]
						AC_wr		<= '1';
						ADB_sel		<= "0001";
						IP_rd		<= '1';
						state		<= 11;
					end if;
				when 11 =>
					-- RAM[SP] = AC
					SP_rd		<= '1';
					RAM_wr		<= '1';
					AC_rd		<= '1';
					state		<= 12;
				when 12 =>
					-- SP--
					SP_wr		<= '1';
					AAR_sel		<= "0100";
					AAR_dec		<= '1';
					state		<= 13;
				when 13 =>
					-- AC = IP[1]
					AC_wr		<= '1';
					ADB_sel		<= "0010";
					IP_rd		<= '1';
					state		<= 14;
				when 14 =>
					-- RAM[SP] = AC
					SP_rd		<= '1';
					RAM_wr		<= '1';
					AC_rd		<= '1';
					state		<= 15;
				when 15 =>
					-- SP--
					SP_wr		<= '1';
					AAR_sel		<= "0100";
					AAR_dec		<= '1';
					state		<= 16;
				when 16 =>
					-- AC = IP[2]
					AC_wr		<= '1';
					ADB_sel		<= "0100";
					IP_rd		<= '1';
					state		<= 17;
				when 17 =>
					-- RAM[SP] = AC
					SP_rd		<= '1';
					RAM_wr		<= '1';
					AC_rd		<= '1';
					state		<= 18;
				when 18 =>
					-- SP--
					SP_wr		<= '1';
					AAR_sel		<= "0100";
					AAR_dec		<= '1';
					state		<= 19;
				when 19 =>
					-- AC = IP[3]
					AC_wr		<= '1';
					ADB_sel		<= "1000";
					IP_rd		<= '1';
					state		<= 20;
				when 20 =>
					-- RAM[SP] = AC
					SP_rd		<= '1';
					RAM_wr		<= '1';
					AC_rd		<= '1';
					state		<= 21;
				when 21 =>
					-- SP--
					SP_wr		<= '1';
					AAR_sel		<= "0100";
					AAR_dec		<= '1';
					state		<= 1;
				when 22 =>
					-- Check for ]
					if AC_d(3 downto 0) = x"6" then
						-- Execute ] (which will be NOP)
						state		<= 1;
					else
						-- IP++
						IP_wr		<= '1';
						AAR_sel		<= "0001";
						AAR_inc		<= '1';
						state		<= 23;
					end if;
				when 23 =>
					-- AC = RAM[IP]
					AC_wr		<= '1';
					RAM_rd		<= '1';
					IP_rd		<= '1';
					state		<= 22;

				-- Conditional backwards jump
				when 24 =>
					report "]";
					-- AC = RAM[DP]
					AC_wr		<= '1';
					RAM_rd		<= '1';
					DP_rd		<= '1';
					state		<= 25;
				when 25 =>
					-- Condition check
					if AC_d = x"00" then
						-- Execute next instruction
						state		<= 1;
					else
						-- SP++
						SP_wr		<= '1';
						AAR_sel		<= "0100";
						AAR_inc		<= '1';
						state		<= 26;
					end if;
				when 26 =>
					-- BUF[3] = RAM[SP]
					SP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "1000";
					DAB_sel		<= "1000";
					DAB_en		<= '1';
					state		<= 27;
				when 27 =>
					-- SP++
					SP_wr		<= '1';
					AAR_sel		<= "0100";
					AAR_inc		<= '1';
					state		<= 28;
				when 28 =>
					-- BUF[2] = RAM[SP]
					SP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "0100";
					DAB_sel		<= "0100";
					DAB_en		<= '1';
					state		<= 29;
				when 29 =>
					-- SP++
					SP_wr		<= '1';
					AAR_sel		<= "0100";
					AAR_inc		<= '1';
					state		<= 30;
				when 30 =>
					-- BUF[1] = RAM[SP]
					SP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "0010";
					DAB_sel		<= "0010";
					DAB_en		<= '1';
					state		<= 31;
				when 31 =>
					-- SP++
					SP_wr		<= '1';
					AAR_sel		<= "0100";
					AAR_inc		<= '1';
					state		<= 32;
				when 32 =>
					-- BUF[0] = RAM[SP]
					SP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "0001";
					DAB_sel		<= "0001";
					DAB_en		<= '1';
					state		<= 33;
				when 33 =>
					-- IP = BUF-1
					IP_wr		<= '1';
					AAR_sel		<= "1000";
					AAR_dec		<= '1';
					state		<= 1;

				-- Load IP
				when 34 =>
					report "I";
					-- BUF[3] = RAM[IP]
					IP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "1000";
					DAB_sel		<= "1000";
					DAB_en		<= '1';
					state		<= 35;
				when 35 =>
					-- IP++
					IP_wr		<= '1';
					AAR_sel		<= "0001";
					AAR_inc		<= '1';
					state		<= 36;
				when 36 =>
					-- BUF[2] = RAM[IP]
					IP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "0100";
					DAB_sel		<= "0100";
					DAB_en		<= '1';
					state		<= 37;
				when 37 =>
					-- IP++
					IP_wr		<= '1';
					AAR_sel		<= "0001";
					AAR_inc		<= '1';
					state		<= 38;
				when 38 =>
					-- BUF[1] = RAM[IP]
					IP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "0010";
					DAB_sel		<= "0010";
					DAB_en		<= '1';
					state		<= 39;
				when 39 =>
					-- IP++
					IP_wr		<= '1';
					AAR_sel		<= "0001";
					AAR_inc		<= '1';
					state		<= 40;
				when 40 =>
					-- BUF[0] = RAM[IP]
					IP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "0001";
					DAB_sel		<= "0001";
					DAB_en		<= '1';
					state		<= 41;
				when 41 =>
					-- IP = BUF
					BU_rd		<= '1';
					IP_wr		<= '1';
					state		<= 51;
				when 51 =>
					-- IP++
					IP_wr		<= '1';
					AAR_sel		<= "0001";
					AAR_inc		<= '1';
					state		<= 1;


				-- Load DP
				when 42 =>
					report "D";
					-- BUF[3] = RAM[IP]
					IP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "1000";
					DAB_sel		<= "1000";
					DAB_en		<= '1';
					state		<= 43;
				when 43 =>
					-- IP++
					IP_wr		<= '1';
					AAR_sel		<= "0001";
					AAR_inc		<= '1';
					state		<= 44;
				when 44 =>
					-- BUF[2] = RAM[IP]
					IP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "0100";
					DAB_sel		<= "0100";
					DAB_en		<= '1';
					state		<= 45;
				when 45 =>
					-- IP++
					IP_wr		<= '1';
					AAR_sel		<= "0001";
					AAR_inc		<= '1';
					state		<= 46;
				when 46 =>
					-- BUF[1] = RAM[IP]
					IP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "0010";
					DAB_sel		<= "0010";
					DAB_en		<= '1';
					state		<= 47;
				when 47 =>
					-- IP++
					IP_wr		<= '1';
					AAR_sel		<= "0001";
					AAR_inc		<= '1';
					state		<= 48;
				when 48 =>
					-- BUF[0] = RAM[IP]
					IP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "0001";
					DAB_sel		<= "0001";
					DAB_en		<= '1';
					state		<= 49;
				when 49 =>
					-- DP = BUF
					BU_rd		<= '1';
					DP_wr		<= '1';
					state		<= 50;
				when 50 =>
					-- IP++
					IP_wr		<= '1';
					AAR_sel		<= "0001";
					AAR_inc		<= '1';
					state		<= 1;

				-- Load SP
				when 52 =>
					report "S";
					-- BUF[3] = RAM[IP]
					IP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "1000";
					DAB_sel		<= "1000";
					DAB_en		<= '1';
					state		<= 53;
				when 53 =>
					-- IP++
					IP_wr		<= '1';
					AAR_sel		<= "0001";
					AAR_inc		<= '1';
					state		<= 54;
				when 54 =>
					-- BUF[2] = RAM[IP]
					IP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "0100";
					DAB_sel		<= "0100";
					DAB_en		<= '1';
					state		<= 55;
				when 55 =>
					-- IP++
					IP_wr		<= '1';
					AAR_sel		<= "0001";
					AAR_inc		<= '1';
					state		<= 56;
				when 56 =>
					-- BUF[1] = RAM[IP]
					IP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "0010";
					DAB_sel		<= "0010";
					DAB_en		<= '1';
					state		<= 57;
				when 57 =>
					-- IP++
					IP_wr		<= '1';
					AAR_sel		<= "0001";
					AAR_inc		<= '1';
					state		<= 58;
				when 58 =>
					-- BUF[0] = RAM[IP]
					IP_rd		<= '1';
					RAM_rd		<= '1';
					BU_wr		<= "0001";
					DAB_sel		<= "0001";
					DAB_en		<= '1';
					state		<= 59;
				when 59 =>
					-- SP = BUF
					BU_rd		<= '1';
					SP_wr		<= '1';
					state		<= 60;
				when 60 =>
					-- IP++
					IP_wr		<= '1';
					AAR_sel		<= "0001";
					AAR_inc		<= '1';
					state		<= 1;

				-- Reset RAM[DP]
				when 61 =>
					report "C";
					-- AC = 0
					AC_clr		<= '1';
					state		<= 62;
				when 62 =>
					-- RAM[DP] = AC;
					RAM_wr		<= '1';
					DP_rd		<= '1';
					AC_rd		<= '1';
					state		<= 1;

				-- Save literal to RAM[DP]
				when 63 =>
					report "L";
					-- AC = RAM[IP]
					AC_wr		<= '1';
					RAM_rd		<= '1';
					IP_rd		<= '1';
					state		<= 64;
				when 64 =>
					-- IP++
					IP_wr		<= '1';
					AAR_inc		<= '1';
					AAR_sel		<= "0001";
					state		<= 65;
				when 65 =>
					-- RAM[DP] = AC
					RAM_wr		<= '1';
					AC_rd		<= '1';
					DP_rd		<= '1';
					state		<= 1;

				-- Halt
				when 66 =>
					HLT			<= '1';

				-- Unknown state -> reset CPU
				when others =>
					sRST		<= '1';
					state		<= 0;
			end case;
		end if;
	end process;

end architecture;
