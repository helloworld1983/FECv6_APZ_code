----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:07:11 09/15/2012 
-- Design Name: 
-- Module Name:    dtcSCFlowCtrl - Behavioral 
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

entity dtcSCFlowCtrl is
    Port ( clk : in  STD_LOGIC;
           rstn : in  STD_LOGIC;
           wrcntSCFIFO : in  STD_LOGIC_VECTOR (10 downto 0);
           eof_n : in  STD_LOGIC;
           dst_rdy_n : out  STD_LOGIC);
end dtcSCFlowCtrl;

--@ Blocks data transfer until the last frame was completely readout from the FIFO

architecture Behavioral of dtcSCFlowCtrl is

	type state_type is (stIDLE, stWaitFIFOEmpty, stWait);
	signal state : state_type;
	
	signal counter: std_logic_vector(3 downto 0);

begin
	
	process(clk, rstn)
	begin
		if rstn = '0' then
			state <= stIDLE;
			counter <= (others => '0');
		elsif clk'event and clk = '1' then
			if state = stIDLE then
				counter <= (others => '0');
				-- when the frame finishes ...
				if eof_n = '0' then
					state <= stWaitFIFOEmpty;
				end if;
			elsif state = stWaitFIFOEmpty then
				-- ... wait until dtc FIFO is empty
				if wrcntSCFIFO = 0 then
					state <= stWait;
				end if;
			elsif state = stWait then
				-- wait extra time
				if counter >= 7 then
					counter <= (others => '0');
					state <= stIDLE;
				else
					counter <= counter + 1;
				end if;
			end if;
		end if;
	end process;
	
	dst_rdy_n <= '0' when state = stIDLE else '1';
	

end Behavioral;

