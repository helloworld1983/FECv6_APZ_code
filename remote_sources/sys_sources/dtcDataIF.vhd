----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:53:58 09/13/2012 
-- Design Name: 
-- Module Name:    dtcDataIF - Behavioral 
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
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dtcDataIF is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
			  cfg : in std_logic_vector(31 downto 0);			-- config register, same as dtc control register; 3 msB used
																			-- default(ATLAS): x"DDAA12xx"
			  trgID :  in  STD_LOGIC_VECTOR (63 downto 0);
           txreq : in  STD_LOGIC;
           txdone : in  STD_LOGIC;
           txack : out  STD_LOGIC;
           txlength : in  STD_LOGIC_VECTOR (15 downto 0);
           txdata : in  STD_LOGIC_VECTOR (7 downto 0);
           txstart : in  STD_LOGIC;
           txstop : in  STD_LOGIC;
           txdata_rdy : out  STD_LOGIC;
           frameEndEvent : out  STD_LOGIC;
           numFramesEvent : in  STD_LOGIC_VECTOR (6 downto 0);
			  
		dtc_wrDataFIFO        : out  std_logic;								
		dtc_dataToDataFIFO    : out  std_logic_vector(7 downto 0);		
		dtc_fullDataFIFO      : in std_logic		
			  
			  );
end dtcDataIF;

architecture Behavioral of dtcDataIF is

	type state_type is (stIDLE, stWaitStart, stParams, stTRGID, stLEN, stDATA, stIFD, stEndFrame, stWaitDone);
	signal state : state_type;
	
	signal frameLength, byteCnt: std_logic_vector(15 downto 0);
	signal frameCnt: std_logic_vector(6 downto 0);
	signal counter: std_logic_vector(2 downto 0);
	
	alias cfg_trailerbyte: std_logic_vector(7 downto 0) is cfg(31 downto 24);
	alias cfg_paddingbyte: std_logic_vector(7 downto 0) is cfg(23 downto 16);
	alias cfg_trailerWordLength: std_logic_vector(3 downto 0) is cfg(15 downto 12);
	alias cfg_paddingEnable: std_logic is cfg(9);
	-- @TODO reserve cfg[9:8] for padding type switch (0 - none, 1 - 16bit, 2 - 32bit, ...).
	-- @TODO currently only 32 padding implemented
	alias cfg_trgIDEnable: std_logic is cfg(10);
	alias cfg_trgIDEnableAll: std_logic is cfg(11);
	
	signal trgid_reg: std_logic_vector(63 downto 0);

begin

	txack <= '0' when state = stIDLE else '1';
	
	process(clk, rst)
	begin
		if rst = '1' then
			state <= stIDLE;
			dtc_wrDataFIFO <= '0';
			dtc_dataToDataFIFO <= x"00";
			txdata_rdy <= '0';
			frameEndEvent <= '0';
			frameLength <= x"0000";
			trgid_reg <= (others => '0');
			frameCnt <= (others => '0');
			counter <= (others => '0');
			byteCnt <= x"0000";
		elsif clk'event and clk = '1' then
			dtc_wrDataFIFO <= '0';
			txdata_rdy <= '0';
			frameEndEvent <= '0';
			case state is
				when stIDLE =>
					byteCnt <= x"0000";
					frameCnt <= (others => '0');
					if txreq = '1' and dtc_fullDataFIFO = '0' then
						state <= stWaitStart;
					end if;
				when stWaitStart => 
					if txstart = '1' then
						state <= stParams;
					end if;
				when stParams => 

					frameLength <= txlength - 8;
					trgID_reg <= trgID;
					counter <= (others => '0');
					byteCnt <= x"0000";
					if (cfg_trgIDEnable = '1') and ((frameCnt = 0) or (cfg_trgIDEnableAll = '1')) then
						state <= stTRGID;
					else
						state <= stLEN;
					end if;

				when stTRGID =>
					
					counter <= counter + 1;
					dtc_wrDataFIFO <= '1';
					dtc_dataToDataFIFO <= trgID_reg(63 downto 56);
					trgID_reg <= trgID_reg(55 downto 0) & x"00";
					if counter >= 7 then
						state <= stLEN;
						counter <= (others => '0');
					end if;
				
				when stLEN =>

--					if dtc_fullDataFIFO = '0' then
						dtc_wrDataFIFO <= '1';
						counter <= counter + 1;
						txdata_rdy <= '1';
						if counter = 0 then
							dtc_dataToDataFIFO <= x"00";
--							txdata_rdy <= '0';
						elsif counter = 1 then
							dtc_dataToDataFIFO <= x"00";
--							txdata_rdy <= '0';
						elsif counter = 2 then
							dtc_dataToDataFIFO <= frameLength(15 downto 8);
--							txdata_rdy <= '1';
						elsif counter = 3 then
--							txdata_rdy <= '1';
							dtc_dataToDataFIFO <= frameLength(7 downto 0);
							state <= stDATA;
							counter <= (others => '0');
						end if;
						--					end if;
				when stDATA =>
--					if dtc_fullDataFIFO = '0' then
						
						if  byteCnt < frameLength - 4 then
							txdata_rdy <= '1';
						end if;
						if  byteCnt < frameLength then
							dtc_dataToDataFIFO <= txdata;
							state <= stDATA;
							byteCnt <= byteCnt + 1;
							dtc_wrDataFIFO <= '1';
						else
							-- if frameLength is not multiple of 32bit words and required to padd
							if (byteCnt(1 downto 0) /= 0) and (cfg_paddingEnable = '1') then
								byteCnt <= byteCnt + 1;
								dtc_wrDataFIFO <= '1';
								dtc_dataToDataFIFO <= cfg_paddingByte;
							else
								dtc_wrDataFIFO <= '0';
								byteCnt <= x"0000";
								state <= stIFD;
							end if;
						end if;
--					end if;

				when stIFD => 

					if counter >= 7 then
						counter <= "000";
						if frameCnt < numFramesEvent - 1 then
							frameCnt <= frameCnt + 1;
							state <= stParams;
						else
							frameCnt <= (others => '0');
							state <= stEndFrame;
						end if;
					else
						counter <= counter + 1;
					end if;

				when stEndFrame =>

					frameEndEvent <= '1';
					-- generate trailer if required
					if byteCnt(15 downto 2) < cfg_trailerWordLength then
						byteCnt <= byteCnt + 1;
						dtc_wrDataFIFO <= '1';
						dtc_dataToDataFIFO <= cfg_trailerByte;
--						if cntBytes < 3 then
--							dtc_dataToDataFIFO <= x"00";
--						elsif cntBytes = 3 then
--							dtc_dataToDataFIFO <= cfg_trailerLength;
--						else
--							dtc_dataToDataFIFO <= cfg_trailerByte;
--						end if;
					else		
						
						if txstop = '1' then
							byteCnt <= x"0000";
							state <= stWaitDone;
						end if;
						
					end if;

				when stWaitDone =>

					if txdone = '1' then
						state <= stIDLE;
					end if;

				when others =>
					state <= stIDLE;
			end case;
		end if;
	end process;


end Behavioral;

