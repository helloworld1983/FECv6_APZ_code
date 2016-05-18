-------------------------------------------------------------------------------
-- Title: Ethernet Sender
-- Project: Gigabit Ethernet Link
-------------------------------------------------------------------------------
-- File: ethernetSender.vhd
-- Author: Alfonso Tarazona Martinez (ATM)
-- Company: NEXT Experiment (Universidad Politecnica de Valencia)
-- Last update: 2010/03/24
-- Description: 
-------------------------------------------------------------------------------
-- Revisions:
-- Date                	Version  	Author  	Description
-- 
-------------------------------------------------------------------------------
-- More Information:
-------------------------------------------------------------------------------

-- MAC Header Format
--
-- ----------------------------------------------------------------------------
-- |  Destination MAC Address  |    Source MAC Address    |     EtherType     |
-- |				(6 bytes)					 |				(6 bytes)					|			(2 bytes)			|
-- ----------------------------------------------------------------------------
--
-- EtherType, only the following ones are used:
--
-- 0x0800 -> Internet Protocol, Version 4 (IPv4)
-- 0x0806 -> Adress Resolution Protocol (ARP) 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;
use work.ethernet_pkg.all;

entity ethernetSender is
  port (
    clk           : in  std_logic;   								  	-- Clock (125 Mhz)
    rst           : in  std_logic;   								 		-- Asynchronous reset
	 fpga_mac: in std_logic_vector(47 downto 0);
--	 fpga_ip: in std_logic_vector(31 downto 0);
		canSend       : in  std_logic;
		sentEvent			: in  std_logic;											-- Input from udp sender layer to indicate the event has been sent
		newFrame			: in  std_logic;											-- Frame ready to send
    frameType			: in	std_logic;										  -- Indicates type of frame, 1 for IP and 0 for ARP
		frameSize			: in  std_logic_vector(15 downto 0);	-- Length of the frame to send
		dstMAC        : in  std_logic_vector(47 downto 0); 	-- Target MAC of the frame
		rdData				: in  std_logic_vector(7 downto 0);  	-- Read data bus from the RAM
		
		totFrames     : in  std_logic_vector(11 downto 0);
		
		dst_rdy_in_n  : in  std_logic;   										-- Input destination ready
		synRdWrTxRAM  : out std_logic;											-- Asserts to synchronize the reading and writting operations in the Tx RAM
		sendingFrame  : out std_logic;                      -- Indicates upper layers that a frame is being sent
		sof_out_n     : out std_logic;   										-- Indicates the beginning of a frame an the data_out bus
    eof_out_n     : out std_logic;   										-- Indicates the end of a frame transfer an data_out bus
    src_rdy_out_n : out std_logic;   										-- Output source ready
    data_out      : out std_logic_vector(7 downto 0);		-- Output data
		rdRAM					: out std_logic;											-- Read RAM signal
		rdAddr				: out std_logic_vector(13 downto 0)		-- Read address bus to the RAM
  );                                                                    
end ethernetSender;                   

architecture ethernetSender_arch of ethernetSender is

-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------
  -- counter signals
  signal cntDelay         : std_logic_vector(13 downto 0);
	signal cntBytes         : std_logic_vector(13 downto 0);
	
	signal frameType_i 			: std_logic;
	signal frameSize_i 			: std_logic_vector(15 downto 0);
	signal dstMAC_i : std_logic_vector(47 downto 0);
	
	signal totFrames_i : std_logic_vector(11 downto 0);

  type state is (s_idle, s_waitOKFromDATE, s_sof, s_sendFrame, s_eof);
  signal currentState, nextState : state;

begin
-------------------------------------------------------------------------------
-- Three-process FSM
-------------------------------------------------------------------------------
  -- purpose: state machine driver
  process (clk, rst)
  begin 
    if rst = '1' then                   
      currentState <= s_idle;
    elsif clk'event and clk = '1' then 
      currentState <= nextState;
    end if;
  end process;

  -- purpose: set next state 
  process (currentState, newFrame, dst_rdy_in_n, cntBytes, canSend, sentEvent, cntDelay, totFrames_i)
  begin
    case currentState is
      when s_idle =>
        if newFrame = '1' then
					if sentEvent = '1' then
						nextState <= s_waitOKFromDATE;
					else
						nextState <= s_sof;
					end if;
				else
					nextState <= s_idle;
				end if;
			
			when s_waitOKFromDATE =>
				if totframes_i = 3728 then
					if canSend = '1' then
						nextState <= s_sof;
					else
						nextState <= s_waitOKFromDATE;
					end if;
				else
					nextState <= s_sof;
				end if;
			
			when s_sof =>
--				if dst_rdy_in_n = '0' and cntDelay = 0 then
				if dst_rdy_in_n = '0' then
					nextState <= s_sendFrame;
				else
					nextState <= s_sof;
				end if;
			
      when s_sendFrame =>
				if dst_rdy_in_n = '0' and cntBytes = frameSize_i-2 then
					nextState <= s_eof;
				else
					nextState <= s_sendFrame;
				end if;
			
			when s_eof =>
				if dst_rdy_in_n = '0' then
					nextState <= s_idle;
				else
					nextState <= s_eof;
				end if;
               
      when others =>                                            
        nextState <= s_idle;
    end case;
  end process;

  -- purpose: set ouputs of the module and internal signals 
  process (clk, rst)
  begin
    if rst = '1' then                   
			cntDelay <= (others => '0');
			cntBytes <= (others => '0');
			frameType_i   <= '0';
			frameSize_i   <= (others => '0');
			dstMAC_i      <= (others => '0');
			synRdWrTxRAM <= '0';
			sendingFrame  <= '0';
			sof_out_n     <= '1';
			eof_out_n     <= '1';
      src_rdy_out_n <= '1';
			data_out      <= (others => '0');
			rdRAM         <= '0';
			rdAddr        <= (others => '0');
			
    elsif clk'event and clk = '1' then  
      -- default siganls
			synRdWrTxRAM <= '0';
			sof_out_n     <= '1';
			eof_out_n     <= '1';
			--data_out <= (others => '0');
			rdRAM         <= '0';

      case currentState is
        when s_idle =>
					cntDelay <= (others => '0');
          src_rdy_out_n <= '1';
					if newFrame = '1' then
						-- holds parameters come in from others modules
						frameType_i <= frameType;
						-- length total of the frame (included MAC header)
						frameSize_i <= frameSize + 14;
						dstMAC_i <= dstMAC;
						sendingFrame <= '1';
						totFrames_i <= totFrames;
          end if;
					
				when s_waitOKFromDATE =>
					-- nothing
        
				when s_sof =>
--					cntDelay <= cntDelay + 1;
--					if dst_rdy_in_n = '0' and cntDelay = 0 then
					if dst_rdy_in_n = '0' then
						cntBytes <= conv_std_logic_vector(1, 14);
						sof_out_n <= '0';
						src_rdy_out_n <= '0';
						-- sends the first byte of the frame (first byte of the destination MAC)
						data_out <= dstMAC_i(47 downto 40);
					end if;
				
				when s_sendFrame =>
					if dst_rdy_in_n = '0' and cntBytes <= frameSize_i-2 then
						cntBytes <= cntBytes + 1;
						
						case conv_integer(cntBytes) is
							-- send the rest of the destination MAC
							when 1 =>
								data_out <= dstMAC_i(39 downto 32);
							when 2 =>
								data_out <= dstMAC_i(31 downto 24);
							when 3 =>
								data_out <= dstMAC_i(23 downto 16);
							when 4 =>
								data_out <= dstMAC_i(15 downto 8);
							when 5 =>
								synRdWrTxRAM <= '1';
								data_out <= dstMAC_i(7 downto 0);
							-- source MAC
							when 6 =>
								data_out <= FPGA_MAC(47 downto 40);
							when 7 =>
								data_out <= FPGA_MAC(39 downto 32);
							when 8 =>
								data_out <= FPGA_MAC(31 downto 24);
							when 9 =>
								data_out <= FPGA_MAC(23 downto 16);
							when 10 =>
								data_out <= FPGA_MAC(15 downto 8);
							when 11 =>
								data_out <= FPGA_MAC(7 downto 0);
							-- ethertype
							when 12 =>
								data_out <= X"08";
							when 13 =>
								-- IP
								if frameType_i = '1' then
									data_out <= X"00";
								-- ARP
								else
									data_out <= X"06";
								end if;
							-- the rest of the data are got from the RAM
							when others =>
								data_out <= rdData;
						end case;
						
						if cntBytes >= 12 then
							rdRAM <= '1';
							rdAddr <= cntBytes - 12;
						end if;
					end if;
					
				when s_eof =>
					if dst_rdy_in_n = '0' then
						sendingFrame <= '0';
						eof_out_n <= '0';
						data_out <= rdData;
					end if;
					
        when others =>                                            
          -- nothing
      end case;
    end if;
  end process;
-------------------------------------------------------------------------------
-- End of three-process FSM
-------------------------------------------------------------------------------

end ethernetSender_arch;