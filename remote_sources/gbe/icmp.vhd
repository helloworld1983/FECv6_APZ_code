-------------------------------------------------------------------------------
-- Title: ICMP
-- Project: Gigabit Ethernet Link
-------------------------------------------------------------------------------
-- File: icmp.vhd
-- Author: Alfonso Tarazona Martinez (ATM)
-- Company: NEXT Experiment (Universidad Politecnica de Valencia)
-- Last update: 2010/03/12
-- Description: 
-------------------------------------------------------------------------------
-- Revisions:
-- Date                	Version  	Author  	Description
-- 
-------------------------------------------------------------------------------
-- More Information:
-------------------------------------------------------------------------------
--
-- Echo Request and Echo Reply
-- 
-- ICMP Header Format
--
--  0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 19 30 31
-- ---------------------------------------------------------------------------------------
-- |     Type      |        Code         |             ICMP Header Checksum              |
-- ---------------------------------------------------------------------------------------
-- |             Identifier              |                Sequence Number                |
-- ---------------------------------------------------------------------------------------
--
-- Data
--
-- ---------------------------------------------------------------------------------------
-- |                                       Data...                                       |
-- ---------------------------------------------------------------------------------------
--
-- Type (8 bits):                  0x08 (Request) or 0x00 (Reply)
-- Code (8 bits):                  Further qualifies the ICMP message (0x00)
-- ICMP Header Checksum (16 bits): Checksum that covers the ICMP message. This is the 
--                                 16-bit one's complement of the one's complement sum of 
--                                 the ICMP message starting with the Type field
-- Identifier (16 bits)
-- Sequence Number (16 bits) 
-- Data (variable length)
--
-- More details see http://www.networksorcery.com/enp/protocol/icmp.htm
--                  http://en.wikipedia.org/wiki/Ping 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;
use work.ethernet_pkg.all;

entity icmp is
   generic ( g_rxram_depth : natural := 14 );
	port (
		clk          : in  std_logic; 										-- Global clock
		rst          : in  std_logic;  										-- Global reset
		canRead			 : in  std_logic;											-- Indicates you can read data from the IP RAM
		datagramSize : in  std_logic_vector(15 downto 0);	-- Size of the arrived datagram
		protocol  	 : in  std_logic_vector(7 downto 0); 	-- Protocol type of the datagram
		sourceIP		 : in  std_logic_vector(31 downto 0); -- IP address that sent the frame
		rdData			 : in  std_logic_vector(7 downto 0); 	-- Read data bus from the IP RAM
		rdRAM				 : out std_logic;											-- Asserteds to tell the IP RAM to read
		rdAddr			 : out std_logic_vector(g_rxram_depth - 1 downto 0); -- Read address bus to the IP RAM
		wrRAM				 : out std_logic;											-- Asserteds to tell the RAM to write
		wrData			 : out std_logic_vector(7 downto 0); 	-- Write data bus to the RAM
		wrAddr			 : out std_logic_vector(13 downto 0); -- Write addres bus to the RAM
		sendICMP, abortICMP		 : out std_logic;											-- Tells the IP layer to send a datagram
		lengthICMP	 : out std_logic_vector(15 downto 0); -- Size of the ping to reply
		dstIP			   : out std_logic_vector(31 downto 0)	-- Target IP of the datagram
	);
end icmp;
                 
architecture icmp_arch of icmp is
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
  signal cntBytes       : std_logic_vector(g_rxram_depth - 1 downto 0);
	
	-- signals to calculate the checksum
	signal newChecksum_i  : std_logic;
	signal newByte_i      : std_logic;
	signal inByte_i       : std_logic_vector(7 downto 0);
	signal checksum_i     : std_logic_vector(15 downto 0);
	
	-- store the length (in bytes) of the IP datagram
	signal datagramSize_i : std_logic_vector(15 downto 0);
	
  type state is (s_idle, s_waitDataFromRxRAM, s_rdICMPByteWrICMPByte, s_wrChecksumUpperByte, s_wrChecksumLowerByte);
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
  process (currentState, canRead, protocol, cntBytes, rdData, datagramSize_i)
  begin
    case currentState is
      when s_idle =>
				if canRead = '1' and protocol = X"01" then
					nextState <= s_waitDataFromRxRAM;
				else
					nextState <= s_idle;
				end if;
			
			when s_waitDataFromRxRAM =>
				nextState <= s_rdICMPByteWrICMPByte;
				
			when s_rdICMPByteWrICMPByte =>
				-- checks if the frame is echo request
				if cntBytes = 0 and rdData /= X"08" then
					nextState <= s_idle;
				elsif cntBytes /= datagramSize_i then
					nextState <= s_rdICMPByteWrICMPByte;
				else
					nextState <= s_wrChecksumUpperByte;
				end if;
				
			when s_wrChecksumUpperByte =>
				nextState <= s_wrChecksumLowerByte;
				
			when s_wrChecksumLowerByte =>
				nextState <= s_idle;
					
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
			wrRAM         <= '0';
			wrData        <= (others => '0');
			wrAddr        <= (others => '0');
			sendICMP      <= '0';
			abortICMP       <= '0';
			lengthICMP    <= (others => '0');
			dstIP         <= (others => '0');
			rdRAM         <= '0';
			rdAddr        <= (others => '0');
			
    elsif clk'event and clk = '1' then 
      -- default signals
			newChecksum_i <= '0';
			newByte_i     <= '0';
			inByte_i      <= (others => '0');
		  rdRAM         <= '0';
			wrRAM         <= '0';
			sendICMP      <= '0';
			abortICMP     <= '0';
			
      case currentState is
        when s_idle =>
					cntBytes <= (others => '0');
					rdAddr <= (others => '0');
					if canRead = '1' and protocol = X"01" then
						rdRAM <= '1';
						newChecksum_i <= '1';
						-- size of the header ICMP + data
						datagramSize_i <= datagramSize;
						lengthICMP <= datagramSize;
						dstIP <= sourceIP;
					end if;
				
				when s_waitDataFromRxRAM =>
					rdRAM <= '1';
				
				when s_rdICMPByteWrICMPByte =>
					-- tell the TX FSM to abort
					if cntBytes = 0 and rdData /= X"08" then
						abortICMP <= '1';
						-- sets the signals to write data into the tx IP RAM  
						wrRAM <= '0';
					else
						-- sets the signals to write data into the tx IP RAM  
						wrRAM <= '1';
					end if;
					-- increases bytes counter
					cntBytes <= cntBytes + 1;
					-- indicates new bytes to the module that caultales the checksum
					-- of the ICMP field
					newByte_i <= '1';
					-- sets the signals to read data from the rx IP RAM  
					rdRAM <= '1';
					-- moves forward the reading operation with regard to writing pointer,
					-- so the read data is ready to be written when needed them
					rdAddr <= cntBytes + 2;
					-- free space into the RAM to store (after) the IP header
					-- IP header: 0x0 - 0x13
					wrAddr <= cntBytes + 20;
					-- set the ICMP data to send according the value of the bytes counter
					case conv_integer(cntBytes) is
						-- type
						when 0 =>
							wrData <= (others => '0');
						-- code
						when 1 =>
							wrData <= (others => '0');
						-- checksum upper byte, writes 0's for now
						when 2 =>
							wrData <= (others => '0');
						-- checksum lower byte, writes 0's for now
						when 3 =>
							wrData <= (others => '0');
						-- all other cases (identifier, sequence number and data)
						-- must be the same as what we received
						when others =>
							wrData   <= rdData;
							inByte_i <= rdData;
					end case;
				
				when s_wrChecksumUpperByte =>
					wrRAM  <= '1';
					wrAddr <= conv_std_logic_vector(22, 14);
					wrData <= checksum_i(15 downto 8);
					
				when s_wrChecksumLowerByte =>
					wrRAM    <= '1';
					wrAddr   <= conv_std_logic_vector(23, 14);
					wrData   <= checksum_i(7 downto 0);
					-- processed ICMP frame, ready to send out 
					sendICMP <= '1';
				
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

end icmp_arch;