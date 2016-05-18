----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:34:22 09/17/2010 
-- Design Name: 
-- Module Name:    dataCaptureCtrl - Behavioral 
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

entity dataCaptureCtrl is
    Port ( clk : in  STD_LOGIC;
           rstn : in  STD_LOGIC;
           trgin : in  STD_LOGIC;
			  enable : in std_logic := '1';
           datalength : in  STD_LOGIC_VECTOR (11 downto 0);
           totEvents : in  STD_LOGIC_VECTOR (15 downto 0);
			  resume: in std_logic;
           datalength_out : out  STD_LOGIC_VECTOR (11 downto 0);
           wen : out  STD_LOGIC;
           wAddr : out  STD_LOGIC_VECTOR (11 downto 0);
			  timestamp : out  STD_LOGIC_VECTOR (23 downto 0);
           rReady : out  STD_LOGIC;
           rBusy : out  STD_LOGIC;
           rDone : in  STD_LOGIC);
end dataCaptureCtrl;

architecture Behavioral of dataCaptureCtrl is
   type state_type is (stIdle, stCaptureData, stSendReady, stSending, stWaitResume); 
   signal state, next_state : state_type; 
	signal counter, datalength_i : std_logic_vector(11 downto 0);
	signal countrst, counten : std_logic;
	
	signal evcounter: std_logic_vector(15 downto 0);
	signal evcountcheck, evcountstop: std_logic;

	signal tscounter: STD_LOGIC_VECTOR (23 downto 0);
	signal tscounten: std_logic;
begin
	
	evcountcheck <= '0' when totevents = 0 else '1';
	evcountstop <= evcountcheck when evcounter = totevents else '0';
	
	process(clk, rstn)
	begin
		if rstn = '0' then
			state <= stIdle;
			counter <= (others => '0');
			evcounter <= (others => '0');
			datalength_i <= (others => '1');
		elsif clk'event and clk = '1' then
			if countrst = '1' then
				counter <= (others => '0');
			elsif counten = '1' then
				counter <= counter + 1;
			end if;
			if state = StIdle then
				datalength_i <= datalength;
			end if;
			state <= next_state;
			-- event counter
			if (state = stWaitResume) and (resume = '1') then
				evcounter <= (others => '0');
			elsif (evcountcheck = '1' ) and (state = stSending) and (rDone = '1') and (evcountstop = '0') then
				evcounter <= evcounter + 1;
			end if;
		end if;
	end process;
	
	datalength_out <= datalength_i;
	
	tsproc: process(clk, rstn)
	begin
		if rstn = '0' then
			tscounter <= x"000000";
			timestamp <= x"000000";
		elsif clk'event and clk = '1' then
			if tscounten = '0' then
				if (state = stIdle) and ((enable and trgin) = '1') then
					tscounten <= '1';
				end if;
				tscounter <= x"000000";
				timestamp <= x"000000";
			else
				tscounter <= tscounter + 1;
				if enable = '0' then
					tscounten <= '0';
					tscounter <= x"000000";
				elsif (state = stIdle) and ((enable and trgin)= '1') then
					timestamp <= tscounter;
				end if;
			end if;
		end if;
	end process;
	
	process(state, trgin, enable, counter, datalength_i, rDone, evcountstop, resume)
	begin	
		case state is
			when stIdle => 
				if (trgin and enable) = '1' then
					next_state <= stCaptureData;
				else
					next_state <= stIdle;
				end if;
			when stCaptureData =>
				if counter = datalength_i then
					next_state <= stSendReady;
				else
					next_state <= stCaptureData;
				end if;
			when stSendReady =>
				if rDone = '0' then
					next_state <= stSending;
				else
					next_state <= stSendReady;
				end if;
			when stSending =>
				if rDone = '1' then
					if evcountstop = '1' then
						next_state <= stWaitResume;
					else
						next_state <= stIdle;
					end if;
				else
					next_state <= stSending;
				end if;
			when stWaitResume =>
				if resume = '1' then
					next_state <= stIdle;
				else 
					next_state <= stWaitResume;
				end if;
			when others =>	
				next_state <= stIdle;
		end case;
	end process;
	
	wen 		<= '1' when state = stCaptureData else '0';
	counten 	<= '1' when state = stCaptureData else '0';
	countrst	<= '1' when state = stIdle else '0';
	rReady	<= '1' when state = stSendReady else '0';
	rBusy 	<= '0' when state = StIdle else '1';
	
	wAddr <= counter;
	
end Behavioral;

