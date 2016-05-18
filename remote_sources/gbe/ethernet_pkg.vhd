-------------------------------------------------------------------------------
-- Title: Ethernet Constants
-- Project: Gigabit Ethernet Link
-------------------------------------------------------------------------------
-- File: ethernet_pkg.vhd
-- Author: Alfonso Tarazona Martinez (ATM)
-- Company: Next Group (Universidad Politcnica de Valencia)
-- Last update: 2010/02/15
-------------------------------------------------------------------------------
-- Description: Constants
-------------------------------------------------------------------------------
-- Revisions:
-- Date                	Version  	Author  	Description
--  
--------------------------------------------------------------------------------
-- More Information:
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

package ethernet_pkg is

--  constant FPGA_IP    : std_logic_vector(31 downto 0) := X"0A000002";
--  constant FPGA_MAC   : std_logic_vector(47 downto 0) := X"000A3501E321"; --X"000A3501E300";
	-- where the ARP frame is placed into the Tx RAM 
	constant offsetARP  : std_logic_vector(13 downto 0) := conv_std_logic_vector(14884, 14);
	-- where the ICMP frame is placed into the Tx RAM
	constant offsetICMP : std_logic_vector(13 downto 0) := conv_std_logic_vector(13384, 14);

-- Slow control ports (old style)
constant PORT_APVH_I2C: std_logic_vector(15 downto 0) := x"1877";
constant PORT_CCARD_I2C: std_logic_vector(15 downto 0) := x"1977";
constant PORT_FEC_BI2C: std_logic_vector(15 downto 0) := x"1787";
constant PORT_FEC_APVAPP: std_logic_vector(15 downto 0) := x"1797";

end ethernet_pkg;

