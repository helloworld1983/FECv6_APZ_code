-------------------------------------------------------------------------------
-- Title: IP Sender
-- Project: Gigabit Ethernet Link
-------------------------------------------------------------------------------
-- File: ipSender.vhd
-- Author: Alfonso Tarazona Martinez (ATM)
-- Company: NEXT Group (Universidad Politcnica de Valencia)
-- Last update: 2010/03/22
-- Description: 
-------------------------------------------------------------------------------
-- Revisions:
-- Date                	Version  	Author  	Description
-- 
-------------------------------------------------------------------------------
-- More Information:
-------------------------------------------------------------------------------
--
-- IP Header Format
-- 
--  0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 19 30 31
-- ---------------------------------------------------------------------------------------
-- |Version|  IHL  |    Diff Services    |                 Total Length                  |
-- ---------------------------------------------------------------------------------------
-- |           Identification            | Flags  |           Fragment Offset            |
-- ---------------------------------------------------------------------------------------
-- |      TTL      |      Protocol       |                Header Checksum                |
-- ---------------------------------------------------------------------------------------
-- |                             Source IP Address                                       |
-- ---------------------------------------------------------------------------------------
-- |                           Destination IP Address                                    |
-- ---------------------------------------------------------------------------------------
--
-- Data
--
-- ---------------------------------------------------------------------------------------
-- |                                Options and Padding                                  |
-- ---------------------------------------------------------------------------------------
--
-- Version (4 bits):                 Specifies the format of the IP packet header
--                                   4 IP, Internet Protocol
-- IHL (4 bits):                     Specifies the length of the IP packet header in 32 
--                                   bit words. The minimum value for a valid header is 5
-- Differentiated Services (8 bits): Not used (0x00)
-- Total Length (8 bits):            Contains the length of the datagram
-- Identification (16 bits):         Used to identify the fragments of one datagram from 
--                                   those of another. Not used (0x0000)
-- Flags (3 bits)
-- Fragment Offset (13 bits):        Used to direct the reassembly of a fragmented 
--                                   datagram. Flags + Fragment Offset = 0x4000
-- TTL, Time To Live (8 bits):       A timer field used to track the lifetime of the 
--                                   datagram. When the TTL field is decremented down to 
--                                   zero, the datagram is discarded
--                                   Ignored, set as 0x40
-- Protocol (8 bits):                This field specifies the next encapsulated protocol
--                                   This field is set as 0x01 (ICMP) or 0x11 (UDP)
-- Header Checksum (16 bits):        A 16 bit one's complement checksum of the IP header 
--                                   and IP options
-- Options and Padding:              Not used
--
-- More details see http://www.networksorcery.com/enp/protocol/ip.htm

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;
use work.ethernet_pkg.all;

entity ipSender is
	port (
		clk          : in  std_logic; 										-- Global clock
		rst          : in  std_logic;  										-- Global reset
		fpga_ip : in std_logic_vector(31 downto 0);
		sendingFrame : in  std_logic;                     -- From ethernet sender layer is indicated a frame is being sent
		sendDatagram : in  std_logic;											-- Signal to send a datagram
		protocol		 : in  std_logic_vector(7 downto 0); 	-- Protocol of the datagram to be sent
		datagramSize : in  std_logic_vector(15 downto 0); -- Size of the datagram to transmit
		dstIP		     : in  std_logic_vector(31 downto 0);	-- IP to transmit datagram to
		OKRequest		 : in  std_logic;										  -- Input from arp reciver layer indicating it contains the requested MAC
		lookupMAC		 : in  std_logic_vector(47 downto 0); -- Input from arp receiver layer giving the requested MAC
		
		totFrames_in : in  std_logic_vector(11 downto 0);
		
		busyIPSender : out std_logic;											-- Tells upper layers ip sender laeyr cannot attend their request 
		request			 : out std_logic;                     -- Signal to request a MAC associated an IP of arp receiver layer
		requestIP		 : out std_logic_vector(31 downto 0);	-- IP that the arp receiver layer must look up
		wrRAM				 : out std_logic;											-- Asserted to tell the Tx RAM to write
		wrData			 : out std_logic_vector(7 downto 0); 	-- Write data bus to the Tx RAM
		wrAddr			 : out std_logic_vector(13 downto 0); -- Write addres bus to the Tx RAM
		sendIP			 : out std_logic; 									  -- Tells the ethernet sender layer to send a datagram
		ICMPUDPFrame : out std_logic;
		lengthIP		 : out std_logic_vector(15 downto 0); -- Tells the ethernet sender layer how long the frame is
		dstMAC			 : out std_logic_vector(47 downto 0);	-- MAC to transmit datagram to
		totFrames_out : out std_logic_vector(11 downto 0)
	);
end ipSender;
                 
architecture ipSender_arch of ipSender is
-------------------------------------------------------------------------------
-- Components
-------------------------------------------------------------------------------
	component calculateChecksum is
		port (
			clk         : in  std_logic;           					 -- Clock
			rst         : in  std_logic;           					 -- Asynchronous reset
			iniChecksum : in  std_logic_vector(15 downto 0); -- Default checksum
			newChecksum : in  std_logic;           					 -- Indicates new checksum
			newByte     : in  std_logic;           					 -- Indicates new byte
			inByte      : in  std_logic_vector(7 downto 0);  -- Byte to calculate
			checksum    : out std_logic_vector(15 downto 0)  -- Current checksum
		);
	end component;

-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------
	-- counter signals
  signal cntBytes       : std_logic_vector(13 downto 0);
	
	-- signals to calculate the checksum
	signal newChecksum_i  : std_logic;
	signal newByte_i      : std_logic;
	signal inByte_i       : std_logic_vector(7 downto 0);
	signal checksum_i     : std_logic_vector(15 downto 0);
	
	-- stores the type of the protocol indicated from the higher layer
	signal protocol_i     : std_logic_vector(7 downto 0);
	
	-- stores the length (in bytes) of the IP datagram
	signal datagramSize_i : std_logic_vector(15 downto 0);
	
	-- stores the destination IP
	signal dstIP_i        : std_logic_vector(31 downto 0);
	
	-- stores the destination MAC
	signal dstMAC_i        : std_logic_vector(47 downto 0);
	
	signal totFrames_in_i        : std_logic_vector(11 downto 0);
	
  type state is (s_idle, s_wrIPHeader, s_wrChecksumUpperByte, s_wrChecksumLowerByte, 
	               s_waitMAC, s_checkTxCh);
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
  process (currentState, sendDatagram, cntBytes, OKrequest, lookupMAC, sendingFrame)
  begin
    case currentState is
      when s_idle =>
				if sendDatagram = '1' then
					nextState <= s_wrIPHeader;
				else
					nextState <= s_idle;
				end if;
				
			when s_wrIPHeader =>
				-- If IP header has been written into the RAM, it writes the checksum
				if cntBytes = 20 then
					nextState <= s_wrChecksumUpperByte;
				-- writes the IP header into the RAM
				else
					nextState <= s_wrIPHeader;
				end if;
				
			when s_wrChecksumUpperByte =>
				nextState <= s_wrChecksumLowerByte;
				
			when s_wrChecksumLowerByte =>
				nextState <= s_waitMAC;
			
			when s_waitMAC =>
				if OKRequest = '1' and lookupMAC /= X"FFFFFFFFFFFF" then
					nextState <= s_checkTxCh;
				else
					nextState <= s_waitMAC;
				end if;
			
			when s_checkTxCh =>
				if sendingFrame = '0' then
					nextState <= s_idle;
				else
					nextState <= s_checkTxCh;
				end if;
					
      when others =>                                            
        nextState <= s_idle;
    end case;
  end process;

  -- purpose: set outputs of the module and internal signals
  process (clk, rst)
  begin
    if rst = '1' then                  
			newChecksum_i <= '0';
			newByte_i     <= '0';
			inByte_i      <= (others => '0');
			ICMPUDPFrame  <= '0';
			busyIPSender  <= '0';
			request       <= '0';
			requestIP     <= (others => '0');
			wrRAM         <= '0';
			wrData        <= (others => '0');
			wrAddr        <= (others => '0');
			sendIP        <= '0';
			ICMPUDPFrame <= '0';
			lengthIP      <= (others => '0');
			dstMAC        <= (others => '0');
			
			
    elsif clk'event and clk = '1' then 
      -- default signals
			newChecksum_i <= '0';
			newByte_i     <= '0';
			inByte_i      <= (others => '0');
			wrRAM         <= '0';
			sendIP        <= '0';
			dstMAC        <= (others => '0');
			
      case currentState is
				when s_idle =>
					ICMPUDPFrame <= '0';
					cntBytes <= (others => '0');
					if sendDatagram = '1' then
						busyIPSender   <= '1';
						newChecksum_i  <= '1';
						protocol_i     <= protocol;
						datagramSize_i <= datagramSize + 20;
						lengthIP       <= datagramSize + 20;
						dstIP_i        <= dstIP;
						totFrames_in_i <= totFrames_in;
						if protocol = X"01" then
							ICMPUDPFrame  <= '1';
						else
							ICMPUDPFrame  <= '0';
						end if;
					end if;
				
				when s_wrIPHeader =>
					-- indicates new bytes to the module that caultales the checksum
					-- of the IP header
					newByte_i <= '1';
					-- increases the bytes counter
					cntBytes  <= cntBytes + 1;
					-- sets the signals to write data into the tx IP RAM
					wrRAM     <= '1';
					wrAddr    <= cntBytes;
					-- writes one IP byte into the RAM according the value of the bytes counter
					case conv_integer(cntBytes) is
						-- version and header length
						when 0 =>
							wrData   <= X"45";
							inByte_i <= X"45";
						-- differentiated services
						when 1 =>
							wrData   <= X"00";
							inByte_i <= X"00";
						-- total length upper byte
						when 2 =>
							wrData   <= datagramSize_i(15 downto 8);
							inByte_i <= datagramSize_i(15 downto 8);
						-- total length lower byte
						when 3 =>
							wrData   <= datagramSize_i(7 downto 0);
							inByte_i <= datagramSize_i(7 downto 0);
						-- identification upper byte
						when 4 =>
							wrData   <= X"00";
							inByte_i <= X"00";
						-- identification lower byte
						when 5 =>
							wrData   <= X"00";
							inByte_i <= X"00";
						-- flag and fragment offset (2 bytes)
						-- do not fragment
						when 6 =>
							wrData   <= X"40";
							inByte_i <= X"40";
						when 7 =>
							wrData   <= X"00";
							inByte_i <= X"00";
						-- Time To Live
						when 8 =>
							wrData   <= X"40";
							inByte_i <= X"40";
						-- protocol
						when 9 =>
							wrData   <= protocol_i;
							inByte_i <= protocol_i;
						-- source IP address (4 bytes)
						when 12 =>
							wrData   <= FPGA_IP(31 downto 24);
							inByte_i <= FPGA_IP(31 downto 24);
						when 13 =>
							wrData   <= FPGA_IP(23 downto 16);
							inByte_i <= FPGA_IP(23 downto 16);
						when 14 =>
							wrData   <= FPGA_IP(15 downto 8);
							inByte_i <= FPGA_IP(15 downto 8);
						when 15 =>
							wrData   <= FPGA_IP(7 downto 0);
							inByte_i <= FPGA_IP(7 downto 0);
						-- destination IP address (4 bytes)
						when 16 =>
							wrData   <= dstIP_i(31 downto 24);
							inByte_i <= dstIP_i(31 downto 24);
						when 17 =>
							wrData   <= dstIP_i(23 downto 16);
							inByte_i <= dstIP_i(23 downto 16);
						when 18 =>
							wrData   <= dstIP_i(15 downto 8);
							inByte_i <= dstIP_i(15 downto 8);
						when 19 =>
							wrData   <= dstIP_i(7 downto 0);
							inByte_i <= dstIP_i(7 downto 0);
							
						when others =>
							wrRAM    <= '0';
							wrData   <= (others => '0');
							inByte_i <= (others => '0');
					end case;
				
				when s_wrChecksumUpperByte =>
					wrRAM  <= '1';
					wrAddr <= conv_std_logic_vector(10, 14);
					wrData <= checksum_i(15 downto 8);
					
				when s_wrChecksumLowerByte =>
					wrRAM     <= '1';
					wrAddr    <= conv_std_logic_vector(11, 14);
					wrData    <= checksum_i(7 downto 0);
					-- requests MAC for this dstIP, the arp sender need this MAC to send out
          -- the frame					
					request   <= '1';
					requestIP <= dstIP;
					
				when s_waitMAC =>
					if OKRequest = '1' and lookupMAC /= X"FFFFFFFFFFFF" then
						-- request attended, disables request
						request      <= '0';
						dstMAC       <= lookupMAC;
						sendIP       <= '1';
						dstMAC_i     <= lookupMAC;
						--busyIPSender <= '0';
					end if;
				
				-- if the sendIP and sendARP signals of arpSender and ipSender layer coincide,
				-- the IP frame would be discarded, since arpSender layer has priority over
				-- ipSender layer. So that does not happen if the tx channel was taken by 
				-- arpSender layer. If the tx channel was token by arpSender layer, ipSender 
				-- layer waits until the tx channel is released
				when s_checkTxCh =>
					if sendingFrame = '0' then
						busyIPSender <= '0';
						sendIP       <= '1';
						dstMAC       <= dstMAC_i;
						totFrames_out <= totFrames_in_i;
					end if;
				
				when others =>
					-- nothing
			end case;
    end if;
  end process;
-------------------------------------------------------------------------------
-- End of three-process FSM
-------------------------------------------------------------------------------
	
	CHECKSUM : component calculateChecksum 
		port map (
			clk         => clk,
			rst         => rst,
			iniChecksum => X"0000",
			newChecksum => newChecksum_i,
			newByte     => newByte_i,
			inByte      => inByte_i,
			checksum    => checksum_i
		);
	
end ipSender_arch;