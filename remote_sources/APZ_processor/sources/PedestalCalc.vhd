----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it
-- 
-- Create Date:    15:53:09 03/21/2011 
-- Design Name: 
-- Module Name:    PedestalCalculatorRegister - Behavioral 
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
--use IEEE.NUMERIC_STD.ALL;
use work.api_pack.all;


entity PedestalCalculator is
       Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  
			  watchdog_flag : out std_logic;
			  
			  -- pedestal calculator signals
			  start_calib : in  STD_LOGIC;                               -- start pedestal calculation
			  chan : in std_logic_vector(6 downto 0);              -- chan in, the calculator expects the data 
			                                                       -- to come interleaved, ch 0 to 127
			  datain : in  STD_LOGIC_VECTOR (11 downto 0);         -- data in
			  datavalid_in : in  STD_LOGIC;                        -- data in strobe
			  busy : out STD_LOGIC;                                -- busy flag           
			  
			  -- fileregister control signals, works after a calculation
			  chan_out : out std_logic_vector(6 downto 0);
			  write_out : out  STD_LOGIC;                               -- set pedestal with value specified in pedestal_in 
			  pedestal_out : out  STD_LOGIC_VECTOR (11 downto 0);  -- the current value of the pedestal, with 1 clock cycle latency
			  sigma_out: out  STD_LOGIC_VECTOR (11 downto 0));     -- the current value of the pedestal sigma, with 1 clock cycle latency
			                                
			  
end PedestalCalculator;

architecture Behavioral of PedestalCalculator is
	
	component sqrt
	port (
	x_in: in std_logic_vector(22 downto 0);
	x_out: out std_logic_vector(11 downto 0);
	clk: in std_logic);
	end component;

constant size : integer := 9;
constant NUM_OF_SAMPLES : integer := 2**size;
constant NUM_OF_CHANNELS : integer := 128;
constant APV_WORD_SIZE : integer := 12;
constant APV_LOG2_CHANNELS : integer := 7;

signal count : std_logic_vector(18 downto 0);
signal sample : std_logic_vector(count'length-8 downto 0);

-- file registers signals
-- IO buses
signal sum,stored_sum, stored_sumB : std_logic_vector(23 downto 0);
signal sum2,stored_sum2, stored_sum2B : std_logic_vector(33 downto 0);
-- write strobes and addresses
signal wr_sum, wr_sum2 : std_logic;
signal sum_wr_addr, sum2_wr_addr  : std_logic_vector(6 downto 0);
signal sum_rd_addr, sum2_rd_addr   : std_logic_vector(6 downto 0);

-- pedestal and sigma signals
signal stored_pedestal,stored_sigma,stored_pedestalB,stored_sigmaB : std_logic_vector(APV_WORD_SIZE - 1 downto 0);
--signal pedestal_i,sigma_i : std_logic_vector(APV_WORD_SIZE - 1 downto 0);

-- wait for sqrt machine
signal count_wait : std_logic_vector(3 downto 0);

-- sqrt signals
signal x : std_logic_vector(22 downto 0);
signal sqrt_x : std_logic_vector(11 downto 0);
signal sqrt_sigma_square : std_logic_vector(11 downto 0);

-- control state machine
type state_type is (st_idle, st_waitchan0, st_getmean, st_getstdev,st_wait, st_sqrt,st_waitchan0_2, st_sendresults); 
signal state : state_type; 

signal busy_i : std_logic;

signal freg_chan : std_logic_vector(6 downto 0);
signal freg_write : std_logic ;

-- internal chan counter
signal chan_r : std_logic_vector(6 downto 0);
signal datavalid_r : std_logic ;
signal datain_r : std_logic_vector(11 downto 0);

signal watchdog_reset: std_logic := '0';

begin
  
   busy_i <= '0' when state = st_idle else '1';
	busy <= busy_i;
	sample <= count(count'length - 1 downto 7);
	
	channel_counter : process(clk)
	begin
		if rising_edge(clk) then
			
			if reset = '1' or datavalid_in='0' then
				chan_r <= (others => '1');
			elsif datavalid_in='1' then
				chan_r <= chan_r + 1;			
	      end if;
			
			-- dvalid_pipe always
			datavalid_r <= datavalid_in;
			datain_r <= datain;
			
		end if;
	end process;
	
	--SM watchdog
	watchdog_process: process(clk)
	variable watchdog_counter: std_logic_vector(31 downto 0) := x"00000000";
	begin
		if clk'event and clk = '1' then
			if (reset = '1') or ((state = st_idle) and (start_calib = '1')) then
				watchdog_flag <= '0';
			elsif watchdog_reset = '1' then
				watchdog_flag <= '1';
			end if;
			if (reset = '1') or (state = st_idle) then
				watchdog_counter := x"00000000";
				watchdog_reset <= '0';
			elsif datavalid_in = datavalid_r then
				if watchdog_counter > 400000000 then 
					watchdog_reset <= '1';
					watchdog_counter := x"00000000";
				else
					watchdog_reset <= '0';
					watchdog_counter := watchdog_counter + 1;
				end if;
			else
				watchdog_counter := x"00000000";
				watchdog_reset <= '0';
			end if;
		end if;
	end process;
	
	
   pedestal_calculator_fsm: process(clk)
	variable residual : integer;
	begin
		if rising_edge(clk) then
--			if reset = '1' then
			if ((reset or watchdog_reset) = '1') then
				
				state <= st_idle;
				
				-- outputs
				count <= (others => '0');
				count_wait <= (others => '0');
				sum_wr_addr <= (others => '0');
				sum2_wr_addr <= (others => '0');
				sum <=  (others => '0');
				sum2 <=  (others => '0');
				freg_write <= '0';
				freg_chan <= (others => '0');
				
			else
			
			
			      -- default do not write to file registers
               wr_sum <= '0';
			      wr_sum2 <= '0';
					freg_write <= '0';
					
						case (state) is 
						when st_idle => 
							
							-- Force calculating a new pedestal
							if start_calib = '1' then 
								count <= (others => '0');
								sum <= (others => '0');
								state <= st_waitchan0;
							end if;

							-- outputs
							sum_wr_addr <= freg_chan;
							sum2_wr_addr <= freg_chan;
							
						when st_waitchan0 =>
							
							-- wait for the current reading to stop before porceeding
						   --if datavalid_in = '0' then
							if datavalid_r = '0' then
								state <= st_getmean;
							end if;
							
							-- outputs
							count <= (others => '0');
							count_wait <= (others => '0');
							sum_wr_addr <= (others => '0');
							sum2_wr_addr <= (others => '0');
							sum <=  (others => '0');
							sum2 <=  (others => '0');
				
						-- get_mean state
						when st_getmean =>
						
                     --if datavalid_in = '1' then 
                     if datavalid_r = '1' then    
								-- outputs
								sum_wr_addr <= chan_r;
								count <= count + 1;
								wr_sum <= '1'; 
								
								-- initialize sum
								if sample = 0 then
									sum <= conv_std_logic_vector(conv_integer(datain_r),sum'length);
								else
									-- stored_sumB is related to chan
									sum <= stored_sumB + datain_r;	
								end if;
								
								-- end of pedestal calculation for all channels
								if count = NUM_OF_SAMPLES * NUM_OF_CHANNELS - 1 then
									count <= (others => '0');
									state <= st_waitchan0_2 ;  -- all samples for all channels done, go getting the st.dev
								end if;
								
								
							end if;
							
					-- end of st_getmean state		
					when st_waitchan0_2 =>
							
							-- wait for the current reading to stop before porceeding
						   --if datavalid_in = '0' then
							if datavalid_r = '0' then
								state <= st_getstdev;
							end if;
							
							-- outputs
							count <= (others => '0');
							count_wait <= (others => '0');
							sum_wr_addr <= (others => '0');
							sum2_wr_addr <= (others => '0');
							sum <=  (others => '0');
							sum2 <=  (others => '0');
					
					
					when st_getstdev => 
							
							--if datavalid_in = '1' then
							if datavalid_r = '1' then --and chan = current_chan then	
													
								sum2_wr_addr <= chan_r;
								count <= count + 1;
								wr_sum2 <= '1';
								
								-- stored_pedestalB goes with datain, stored_pedestalB and stored_sum2B 
								-- are selected by chan with no latency, therefore they go with datain
								residual := conv_integer(datain_r) - conv_integer(stored_pedestalB);
																
								-- initialize sum, the multiplier here could be not placed in the DSP block, as it has to work at 40 MHz
								if sample = 0 then
									sum2 <= conv_std_logic_vector(residual*residual,sum2'length);
								else
								   sum2 <= stored_sum2B + residual*residual;
								end if;
								
								-- end of pedestal calculation for all channels
								if count=NUM_OF_SAMPLES*NUM_OF_CHANNELS - 1 then
									count <= (others => '0');
									state <= st_wait ;  -- all samples for all channels done, go getting the st.dev
								end if;
								
								
							end if;
							
					when st_wait =>
							
							sum2_wr_addr <= (others => '0');
							state <= st_sqrt;
							count_wait <= (others => '0');
							
					when st_sqrt => 
						
                  count_wait <= count_wait + 1;						
						
						-- this sum2=sqrt(s^2)
						sum2(11 downto 0) <= sqrt_sigma_square;
						
						if count_wait = 8 then
						
						   -- write sqrt into file register at the next clock cycle
							wr_sum2 <= '1';
						
						elsif count_wait = 9 then
								
								count_wait <= (others => '0');
								
								-- update write address
								sum2_wr_addr <= sum2_wr_addr + 1;
								
								-- Finished calculation for all channels?							
								if sum2_wr_addr = NUM_OF_CHANNELS - 1 then 
									state <= st_sendresults ;     -- all channels done, stop!
									sum2_wr_addr <= (others => '0');
									freg_chan <= (others => '0'); -- prepare the freg outputs
									freg_write <= '1';
								end if;
							
						 end if;
					-- add a state to output the results	
					when st_sendresults =>
					      
						   freg_chan <= freg_chan + 1 ;
							freg_write <= '1';
					     	
							if freg_chan = NUM_OF_CHANNELS - 1 then 
									state <= st_idle ;     -- all channels done, stop!
									freg_chan <= (others => '0');
									freg_write <= '0';
							end if;
						  
					when others =>
							
							state <= st_idle;
						
					end case;
					
				
				end if; -- reset 
			end if; -- rising_edge
	end process;
	
	
	sum_freg: file_register
	generic map (7, 24)
   port map (we => wr_sum,
				 dataIN => sum,
				 wclk => clk,
				 addrA => sum_wr_addr,
				 addrB => sum_rd_addr,
				 dataA => stored_sum,   -- 1 clock cycle latency
				 dataB => stored_sumB); -- 0 latency

   sum_rd_addr <= chan_r when freg_write='0' else freg_chan;

	-- pedestal = stored_sum / 2^size	
	stored_pedestal <= stored_sum(size + 11 downto size);
	stored_pedestalB <= stored_sumB(size + 11 downto size);
	pedestal_out <= stored_pedestalB; -- on read addr
	
	sum_squares_freg: file_register
	generic map (7, 34)
   port map (we => wr_sum2,
				 dataIN => sum2,
				 wclk => clk,
				 addrA => sum2_wr_addr,
				 addrB => sum2_rd_addr,            
				 dataA => stored_sum2,   -- 1 clock cycle latency
				 dataB => stored_sum2B); -- 0 latency
				 
   -- after the sqrt calculation, stored_sum2(11 downto 0) is sigma
	stored_sigma <= stored_sum2(11 downto 0);
	stored_sigmaB <= stored_sum2B(11 downto 0);
   sigma_out <= stored_sigmaB; -- on read addr
	
	sum2_rd_addr <= chan_r when freg_write='0' else freg_chan;
	
	 -- x = stored_sum2 / (2^size)
	x <= stored_sum2(size + 22 downto size);
	SQRT_unit : sqrt
		port map (
			x_in(22 downto 0) => x,
			x_out(11 downto 0) => sqrt_x,
			clk => clk);
			
	-- y = sqrt(x) = sqrt(stored_sum2/(N*4)) = sqrt(stored_sum2/N)/2
	-- sqrt_sigma_square = sqrt(stored_sum2/N)
	sqrt_sigma_square <= sqrt_x(11 downto 0);
	
	write_out <= freg_write;
	chan_out <= freg_chan;
				 
end Behavioral;

