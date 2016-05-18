-------------------------------------------------------------------------------
-- Title: Ethernet Receiver
-- Project: Gigabit Ethernet Link
-------------------------------------------------------------------------------
-- File: ethernetReceiver.vhd
-- Author: Alfonso Tarazona Martinez (ATM)
-- Company: NEXT Experiment (Universidad Politecnica de Valencia)
-- Last update: 2010/02/01
-- Description: 
-------------------------------------------------------------------------------
-- Revisions:
-- Date                	Version  	Author  	Description
--
-------------------------------------------------------------------------------
-- More Information:
-------------------------------------------------------------------------------
--
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

entity ethernetReceiver is
  port (
    clk           : in  std_logic;   									-- Clock (125 Mhz)
    rst           : in  std_logic;   									-- Asynchronous reset
	 fpga_mac: in std_logic_vector(47 downto 0);
--	 fpga_ip: in std_logic_vector(31 downto 0);
    data_in       : in  std_logic_vector(7 downto 0);	-- Input data
    sof_in_n      : in  std_logic;   									-- Indicates the beginning of a frame an the data_in bus
    eof_in_n      : in  std_logic;   									-- Indicates the end of a frame transfer an data_in bus
    src_rdy_in_n  : in  std_logic;   									-- Input source ready
    dst_rdy_out_n : out std_logic;   									-- Output destination ready
    frameType     : out std_logic;   									-- Indicates kind of frame, 1 for IP and 0 for ARP
    newByte       : out std_logic;   									-- Signal to write data to the IP layer
    frameByte     : out std_logic_vector(7 downto 0);	-- Byte to write to the IP layer
    newFrame      : out std_logic;   									-- New frame signal to the next layer
    endFrame      : out std_logic    								  -- End of frame signal to the next layer
  );                                                                    
end ethernetReceiver;                   

architecture ethernetReceiver_arch of ethernetReceiver is

-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------
  -- counter signals
  signal cntBytes               : std_logic_vector(13 downto 0) := (others => '0');

  -- indicates the destination MAC has been received
  signal receivedDestinationMAC : std_logic;
  -- stores the received destination MAC
  signal destinationMAC         : std_logic_vector(47 downto 0);

  type state is (s_idle, s_receiveFrame);
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
  process (currentState, sof_in_n, src_rdy_in_n, eof_in_n, receivedDestinationMAC, destinationMAC, fpga_mac)
  begin
    case currentState is
      when s_idle =>
        if sof_in_n = '0' and src_rdy_in_n = '0' then
          nextState <= s_receiveFrame;
        else
          nextState <= s_idle;
        end if;

      when s_receiveFrame =>
        -- checks if the frame is for us or broadcast, if not the frame is ignored
        if receivedDestinationMAC = '1' and (destinationMAC /= FPGA_MAC and  destinationMAC /= X"FFFFFFFFFFFF") then
          nextState <= s_idle;
        -- detects end of frame
        elsif eof_in_n = '0' and src_rdy_in_n = '0' then
          nextState <= s_idle;
        -- there are still data to be received 
        else
          nextState <= s_receiveFrame;
        end if;
               
      when others =>                                            
        nextState <= s_idle;
    end case;
  end process;

  -- purpose: set ouputs of the module and internal signals 
  process (clk, rst)
  begin
    if rst = '1' then                   
      receivedDestinationMAC <= '0';
      destinationMAC         <= (others => '0');
			frameType              <= '0';
			newByte                <= '0';
			frameByte              <= (others => '0');
			newFrame               <= '0';
			endFrame               <= '0';
			dst_rdy_out_n          <= '1';
      
    elsif clk'event and clk = '1' then  
      -- default siganls
      receivedDestinationMAC <= '0';
			newByte                <= '0';
			frameByte              <= data_in;
			newFrame               <= '0';
			endFrame               <= '0';
      dst_rdy_out_n          <= '0';

      case currentState is
        when s_idle =>
          cntBytes <= (others => '0');
					if sof_in_n = '0' and src_rdy_in_n = '0' then
						destinationMAC <= destinationMAC(39 downto 0) & data_in;
						-- cntBytes = 1 because the zero bit (first bit) has just been received
						cntBytes <= conv_std_logic_vector(1, 14);
          end if;
        
        when s_receiveFrame =>
          if src_rdy_in_n = '0' then
						if cntBytes >= 14 then
							newByte <= '1';
						end if;
            -- increase the bytes counter
            cntBytes <= cntBytes + 1; 
            -- gets the destination MAC and activates a signal to indicate the destination MAC has been received 
            if cntBytes = 1 or cntBytes = 2 or cntBytes = 3 or cntBytes = 4 or cntBytes = 5 then
              destinationMAC <= destinationMAC(39 downto 0) & data_in;
              if cntBytes = 5 then
                receivedDestinationMAC <= '1';
              end if;
            end if;
            -- ckecks the kind of frame (IP or ARP) 
            if cntBytes = 13 and data_in = X"00" then
              frameType <= '1';
            elsif cntBytes = 13 and data_in = X"06" then
              frameType <= '0';
            end if;
            -- indicates new frame when the MAC header has been received
            if cntBytes = 14 then
              newFrame <= '1';
            end if;
						-- indicates end of frame to the uppper layer
						if eof_in_n = '0' then
							endFrame <= '1';
						end if;
          end if;
                        
        when others =>                                            
          -- nothing
      end case;
    end if;
  end process;
-------------------------------------------------------------------------------
-- End of three-process FSM
-------------------------------------------------------------------------------

end ethernetReceiver_arch;



