----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it
--
-- Create Date:    14:55:52 03/09/2011 
-- Design Name: 
-- Module Name:    APV_PhaseAligner - Behavioral 
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.std_logic_arith.all;

entity PLL_PhaseAligner is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  start : in  STD_LOGIC;
			  threshold : out STD_LOGIC_VECTOR (11 downto 0);
           request : out  STD_LOGIC;
			  aligned : out std_logic;
           done : in  STD_LOGIC;
           ctr2 : out  STD_LOGIC_VECTOR (4 downto 0);
           apv_datain : in  STD_LOGIC_VECTOR (11 downto 0));
end PLL_PhaseAligner;

architecture Behavioral of PLL_PhaseAligner is

constant NUM_OF_SAMPLES : integer := 1023 ;   -- check count bit size

type state_type is (st_start, st_change_phase, st_get_range, st_aligned, st_set_best_phase, st_waitI2c_best_phase ,st_waitI2c); 
signal state : state_type; 

signal count : std_logic_vector(15 downto 0);
--signal y,sync_error : std_logic;
signal phase,best_phase : std_logic_vector(4 downto 0);
signal max,min : std_logic_vector(11 downto 0);
signal best_max,best_min,best_range : std_logic_vector(11 downto 0);

begin

--	-- converts 12-bit voltage value to 1-bit
--	comparator : process (apv_datain)
--	begin
--		if apv_datain < threshold then
--			y <= '1';
--		else
--			y <= '0';
--		end if;
--	end process;
	
	
	
	phase_align_FSM : process (clk) 
	variable diff : std_logic_vector(11 downto 0);
	variable fine_phase : std_logic_vector(3 downto 0);
   variable coarse_phase : std_logic;
	
   begin
      if rising_edge(clk) then
			if reset = '1' then
				state <= st_start;
						
				-- internal registers clean up
				min <= (others => '0');
				max <= (others => '0');
				best_min <= (others => '0');
				best_max <= (others => '0');
				best_range <=  (others => '0');
				best_phase  <=  (others => '0');
				threshold <= (others => '0');
				
				-- outputs
				aligned <= '0';
				count <= (others => '0');
				phase <=  (others => '0');
				request <= '0';
			
			else
			   
				case (state) is
					when st_start =>
						
						-- must not start, immediately but wait for a start input
						if start = '1' then
							state <= st_change_phase;
						end if;
						
						-- internal registers clean up
						min <= (others => '0');
						max <= (others => '0');
						best_min <= (others => '0');
						best_max <= (others => '0');
						best_range <=  (others => '0');
				      best_phase  <=  (others => '0');
						threshold <= (others => '0');
						
						-- outputs
						aligned <= '0';
						count <= (others => '0');
						phase <= "11011"; -- so, at next clock cycle change phase will set 0
						request <= '0';
						
						
						
					when st_waitI2c =>

						-- wait for completion of I2C request
						if done = '1' then
							state <= st_get_range;
						end if;

						-- outputs
						aligned <= '0';
						-- hold request, as done in the PLL_phaseAligner 
						-- tested on the FEC
						-- request <= '1'; 
					
					when st_change_phase =>
						 
						 fine_phase := phase(3 downto 0);
						 coarse_phase := phase(4);

						 -- change phase according to the PLL 25 data sheet
						 if fine_phase = 11 then
							  fine_phase := "0000";
							  coarse_phase :=  not coarse_phase;
						 else 
							  fine_phase := fine_phase + 1;
						 end if;	 
						 
						 phase <= coarse_phase & fine_phase;
						 
						 -- outputs
						 aligned <= '0';
						 state <= st_waitI2c;
						 request <= '1';
						 
						 
					when st_get_range =>
                  count <= count +1;
						
						-- if it is the first sample
						-- initialize min and max
						if count = 0 then
							min <= apv_datain;
							max <= apv_datain;
						else	-- update min/max 
							if apv_datain < min then
								min <= apv_datain;
							end if;
							
							if apv_datain > max then
								max <= apv_datain;
							end if;
						end if;
						
						
						if count = NUM_OF_SAMPLES then
							count <= conv_std_logic_vector(0,count'length);
							
							-- updates the best range
							diff := max - min;
							
							if (diff > best_range) then
								best_range <= diff;
								best_max <= max;
								best_min <= min;
								best_phase <= phase;
							end if;
							
							-- if I tried all phases already go set the good phase
							-- otherwise try another one !!!
							if phase = "11011" then
								state <= st_set_best_phase;
							else
								state <= st_change_phase;
						   end if;
							
							
						end if;
						
						
						
						-- outputs
						aligned <= '0';
						request <= '0';
					
					when st_set_best_phase =>
						 
						 state <= st_waitI2c_best_phase;
						 
						 -- outputs
						 aligned <= '0';
						 phase <= best_phase;
						 request <= '1';
					
					when st_waitI2c_best_phase => 

						-- wait for completion of I2C request
						if done = '1' then
							state <= st_aligned;
						end if;

						  -- outputs
						 aligned <= '0';
						 phase <= best_phase;
						 request <= '1';
						
						
		         when st_aligned =>
					    
						 -- stay here forever
						 --state <= st_start;
						 
						 -- outputs
						 aligned <= '1';
					    request <= '0';
						 
						 threshold <= best_min + best_range(11 downto 3); -- best_range/8
						 
						 
					when others =>
						 -- shouldn't be here
						state <= st_start;
						
				end case;      
	  end if;
	end if;
   end process;

  ctr2 <= phase;


end Behavioral;

	
	

