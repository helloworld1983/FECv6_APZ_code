----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:40:38 09/16/2010 
-- Design Name: 
-- Module Name:    udpEventBuild2 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity udpEventBuild2 is
    Port ( clk : in  STD_LOGIC;
           rstn : in  STD_LOGIC;
			  mode: in std_logic_vector(7 downto 0);
           rReady : in  STD_LOGIC_VECTOR (15 downto 0);
			  timestamp : in  STD_LOGIC_VECTOR (23 downto 0);
           ren : out  STD_LOGIC_VECTOR (15 downto 0);
           data0 : in  STD_LOGIC_VECTOR (7 downto 0);
           data1 : in  STD_LOGIC_VECTOR (7 downto 0);
           data2 : in  STD_LOGIC_VECTOR (7 downto 0);
           data3 : in  STD_LOGIC_VECTOR (7 downto 0);
           data4 : in  STD_LOGIC_VECTOR (7 downto 0);
           data5 : in  STD_LOGIC_VECTOR (7 downto 0);
           data6 : in  STD_LOGIC_VECTOR (7 downto 0);
           data7 : in  STD_LOGIC_VECTOR (7 downto 0);
           data8 : in  STD_LOGIC_VECTOR (7 downto 0);
           data9 : in  STD_LOGIC_VECTOR (7 downto 0);
           data10: in  STD_LOGIC_VECTOR (7 downto 0);
           data11: in  STD_LOGIC_VECTOR (7 downto 0);
           data12: in  STD_LOGIC_VECTOR (7 downto 0);
           data13: in  STD_LOGIC_VECTOR (7 downto 0);
           data14: in  STD_LOGIC_VECTOR (7 downto 0);
           data15: in  STD_LOGIC_VECTOR (7 downto 0);
			  rAddr : out  STD_LOGIC_VECTOR (12 downto 0);
			  txreq, txdone : out std_logic;
			  txack : in std_logic;
			  frameCounterOut: out STD_LOGIC_VECTOR (31 downto 0);
           datalength : in  STD_LOGIC_VECTOR (15 downto 0);
           eventInfoType : in  STD_LOGIC_VECTOR (7 downto 0);
           eventInfoData : in  STD_LOGIC_VECTOR (31 downto 0);
           dataout : out  STD_LOGIC_VECTOR (7 downto 0);
           udpLength : out  STD_LOGIC_VECTOR (15 downto 0);
           udpPauseData, frameEndEvent : in  STD_LOGIC;
           udpStartTx : out  STD_LOGIC;
           udpStopTx : out  STD_LOGIC;
           chmask : in  STD_LOGIC_VECTOR (15 downto 0));
end udpEventBuild2;

architecture Behavioral of udpEventBuild2 is
   type state_type is (stIdle, stTxReq, stFindFirstCh, stStartTx, stWaitRdy, stHeader, stData, stWaitEndFrame, stEndFrame); 
   signal state, next_state : state_type; 
	signal counter, counter2 : std_logic_vector(15 downto 0);
	signal chcounter : std_logic_vector(3 downto 0);
	signal countrst, counten, chcountrst, chcounten: std_logic;
	signal readyall, ren_i, ren_ii: std_logic;
	signal header: std_logic_vector(23 downto 0);
	signal chId: std_logic_vector(7 downto 0);
	signal wdCounter: std_logic_vector(23 downto 0);
	signal frameCounter, frameId : std_logic_vector(31 downto 0);
	signal useFrameCounter, useTimestamp: std_logic;
	signal bitCounter, chPointer, nextChPointer : std_logic_vector(3 downto 0);
	signal lastch, bitSel, udpPauseData_i: std_logic;
	signal dataout_i : std_logic_vector(7 downto 0);
begin
	
	frameCounterOut <= frameCounter;
	useFrameCounter <= mode(0);
	useTimestamp    <= mode(1);
	
	rAddr <= counter2(12 downto 0);
	
--	readyall <= rReady(0) and rReady(1);												-- !!!!
	readyall <= '1' when (rReady = x"FFFF") else '0';												
	udpLength <= datalength + 20;			-- udpheader(8) + packetheader(12)
	
	ren_ii <= ren_i and not udpPauseData_i;
	genren: for i in 0 to 15 generate
		ren(i) <= ren_ii when chPointer = i else '0';
	end generate;
	
	chId <= "0000" & chPointer;
	
	frameId <= 	frameCounter 							when useFrameCounter = '1' else 
					(timestamp & "0000" & chcounter)	when useTimestamp = '1' 	else
					(x"0000000" & chcounter);
	
	process(eventInfoType)
	begin
		case eventInfoType is
			when x"00" => header <= x"414443";
			when x"01" => header <= x"415056";
			when others => header <= x"554E4B";
		end case;
	end process;
	
	process(state, counter, header, chPointer, chId, eventInfoData, data0, data1, data2, data3, data4, data5, data6, data7, data8, data9, data10, data11, data12, data13, data14, data15, frameId)
	begin
		if state = stHeader then
			case conv_integer(counter) is
				when 0 => dataout_i <= frameId(31 downto 24);
				when 1 => dataout_i <= frameId(23 downto 16);
				when 2 => dataout_i <= frameId(15 downto  8);
				when 3 => dataout_i <= frameId( 7 downto  0);
				when 4 => dataout_i <= header(23 downto 16);
				when 5 => dataout_i <= header(15 downto 8);
				when 6 => dataout_i <= header(7 downto 0);
				when 7 => dataout_i <= chId;
				when 8 => dataout_i <= eventInfoData(31 downto 24);
				when 9 => dataout_i <= eventInfoData(23 downto 16);
				when 10 => dataout_i <= eventInfoData(15 downto 8);
				when 11 => dataout_i <= eventInfoData(7 downto 0);
				when others => dataout_i <= x"CA";
			end case;
		elsif state = stData then
			case conv_integer(chPointer) is
				when 0 => dataout_i <= data0;
				when 1 => dataout_i <= data1;
				when 2 => dataout_i <= data2;
				when 3 => dataout_i <= data3;
				when 4 => dataout_i <= data4;
				when 5 => dataout_i <= data5;
				when 6 => dataout_i <= data6;
				when 7 => dataout_i <= data7;
				when 8 => dataout_i <= data8;
				when 9 => dataout_i <= data9;
				when 10=> dataout_i <= data10;
				when 11=> dataout_i <= data11;
				when 12=> dataout_i <= data12;
				when 13=> dataout_i <= data13;
				when 14=> dataout_i <= data14;
				when 15=> dataout_i <= data15;
				when others => dataout_i <= x"CA";
			end case;
		else
			dataout_i <= x"CA";
		end if;
	end process;
	
	process (bitCounter, chmask)
	begin
		case bitCounter is
			when "0000" => bitSel <= chmask(0);
			when "0001" => bitSel <= chmask(1);
			when "0010" => bitSel <= chmask(2);
			when "0011" => bitSel <= chmask(3);
			when "0100" => bitSel <= chmask(4);
			when "0101" => bitSel <= chmask(5);
			when "0110" => bitSel <= chmask(6);
			when "0111" => bitSel <= chmask(7);
			when "1000" => bitSel <= chmask(8);
			when "1001" => bitSel <= chmask(9);
			when "1010" => bitSel <= chmask(10);
			when "1011" => bitSel <= chmask(11);
			when "1100" => bitSel <= chmask(12);
			when "1101" => bitSel <= chmask(13);
			when "1110" => bitSel <= chmask(14);
			when "1111" => bitSel <= chmask(15);
			when others => bitSel <= chmask(0);
		end case;
	end process;

	process(clk, rstn)
	begin
		if rstn = '0' then
			state <= stIdle;
			counter <= (others => '0');
			counter2 <= (others => '0');
			chcounter <= (others => '0');
			wdCounter <= (others => '0');
			frameCounter <= (others => '0');
			udpPauseData_i <= '0';
			dataout <= (others => '0');
		elsif clk'event and clk = '1' then
			udpPauseData_i <= udpPauseData;
			dataout <= dataout_i;
			if (state = stData) and (udpPauseData_i = '1') then
				frameCounter <= frameCounter + 1;
			end if;
--			if wdCounter > 12500000 then			-- 100ms
--				state <= stIdle;
--				counter <= (others => '0');
--				counter2 <= (others => '0');
--				chcounter <= (others => '0');
--				wdCounter <= (others => '0');
--			else	
				if ren_ii = '1' then
					counter2 <= counter2 + 1;
				elsif ren_i = '0' then
					counter2 <= (others => '0');
				end if;
--				if state /= stIdle then
--					wdCounter <= wdCounter + 1;
--				else
--					wdCounter <= (others => '0');
--				end if;
				if countrst = '1' then
					counter <= (others => '0');
				elsif counten = '1' then
					counter <= counter + 1;
				end if;
				if chcountrst = '1' then
					chcounter <= (others => '0');
				elsif chcounten = '1' then
					chcounter <= chcounter + 1;
				end if;
				state <= next_state;
--			end if;
		end if;
	end process;
	
	process(clk, rstn)
	begin
		if rstn = '0' then
			bitCounter <= (others => '0');
			chPointer <= (others => '0');
			nextchPointer <= (others => '0');
			lastch <= '0';
		elsif clk'event and clk = '1' then
			if state = stIdle then
				bitcounter <= (others => '0');
				chPointer <= (others => '0');
				nextchPointer <= (others => '0');
				lastch <= '0';
			elsif state = stFindFirstCh then
				bitCounter <= bitcounter + 1;
				if bitSel = '1' then
					nextchPointer <= bitCounter;
				end if;
			elsif state = stData then
				if bitSel = '1' then
					nextchPointer <= bitCounter;
				end if;
				if (bitCounter /= "1111") and ((bitSel = '0') or (chCountEn = '1')) then
					bitCounter <= bitCounter + 1;
				end if;
				if nextchpointer = chpointer then
					lastch <= '1';
				else
					lastch <= '0';
				end if;
			end if;
			if (state = stStartTx) or (chCountEn = '1') then
				chPointer <= nextChPointer;
			end if;
		end if;
	end process;
	
	txreq <= '1' when state = stTxReq else '0';
	txdone <= '1' when state = stIdle else '0';
	
	process(state, readyall, txack, counter, chcounter, udpPauseData_i, frameEndEvent, bitSel, bitCounter, lastch)
	begin
		case state is
			when stIdle =>
				countrst <= '1';
				counten <= '0';
				chcountrst <= '1';
				chcounten <= '0';
				udpStartTx <= '0';
				udpStopTx <= '1';
				ren_i <= '0';
				if readyall = '1' then
					next_state <= stTxReq;
				else
					next_state <= stIdle;
				end if;
			when stTxReq => 
				countrst <= '1';
				counten <= '0';
				chcountrst <= '1';
				chcounten <= '0';
				udpStartTx <= '0';
				udpStopTx <= '1';
				ren_i <= '0';
				if txack = '1' then
					next_state <= stFindFirstCh;
				else
					next_state <= stTxReq;
				end if;
			when stFindFirstCh =>
				countrst <= '1';
				counten <= '0';
				chcountrst <= '1';
				chcounten <= '0';
				udpStartTx <= '0';
				udpStopTx <= '1';
				ren_i <= '0';
				if bitSel = '1' then
					next_state <= stStartTx;
				elsif bitCounter = "1111" then
					next_state <= stIdle;
				else
					next_state <= stFindFirstCh;
				end if;
			when stStartTx =>
				countrst <= '0';
				counten <= '0';
				chcountrst <= '0';
				chcounten <= '0';
				udpStartTx <= '1';
				udpStopTx <= '0';
				ren_i <= '0';
				next_state <= stWaitRdy;
			when stWaitRdy =>
				countrst <= '0';
				counten <= '0';
				chcountrst <= '0';
				chcounten <= '0';
				udpStartTx <= '0';
				udpStopTx <= '0';
				ren_i <= '0';
				if udpPauseData_i = '0' then
					next_state <= stHeader;
				else
					next_state <= stWaitRdy;
				end if;
			when stHeader =>
				countrst <= '0';
				counten <= '1';
				chcountrst <= '0';
				chcounten <= '0';
				udpStartTx <= '0';
				udpStopTx <= '0';
				ren_i <= '0';
				if counter = 11 then
					next_state <= stData;
					ren_i <= '1';
					countrst <= '1';
				else
					next_state <= stHeader;
				end if;
			when stData =>
				countrst <= '0';
				counten <= '1';
				chcountrst <= '0';
				chcounten <= '0';
				udpStartTx <= '0';
				udpStopTx <= '0';
				ren_i <= '1';
--				if counter = datalength-1 then
				if udpPauseData_i = '1' then
					countrst <= '1';
					if lastch = '1' then
						--chcountrst <= '1';
						next_state <= stWaitEndFrame;
					else
						chcounten <= '1';
						next_state <= stWaitRdy;
					end if;
				else
					next_state <= stData;
				end if;
			when stWaitEndFrame =>
				countrst <= '0';
				counten <= '0';
				chcountrst <= '0';
				chcounten <= '0';
				udpStartTx <= '0';
				udpStopTx <= '0';
				ren_i <= '0';
				if frameEndEvent = '1' then
					next_state <= stEndFrame;
				else
					next_state <= stWaitEndFrame;
				end if;
			when stEndFrame =>
				countrst <= '0';
				counten <= '0';
				chcountrst <= '0';
				chcounten <= '0';
				udpStartTx <= '0';
				udpStopTx <= '1';
				ren_i <= '0';
				if frameEndEvent = '0' then
					next_state <= stIdle;
				else
					next_state <= stEndFrame;
				end if;
			when others =>
				countrst <= '1';
				counten <= '0';
				chcountrst <= '1';
				chcounten <= '0';
				udpStartTx <= '0';
				udpStopTx <= '1';
				ren_i <= '0';
				next_state <= stIdle;
		end case;
	end process;
					
end Behavioral;

