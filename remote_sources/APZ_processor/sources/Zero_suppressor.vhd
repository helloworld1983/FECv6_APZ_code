----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it
--
-- Create Date:    19:16:18 08/15/2011 
-- Design Name: 
-- Module Name:    Data_sorter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Revision 0.02 - AZ 30.10.2014: added explicit instantiation of Dual-Port RAM with delayed write acces to ensure operation on Virtex6 FPGA of FECv6. Also works on Virtex5 of FECv3
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.api_pack.all;

entity Zero_Suppressor is
    GENERIC (APV_ID : integer := 0);
	 Port ( clk : in  STD_LOGIC;
	        slowclk : in  STD_LOGIC;  -- not used yet 
	        reset : in  STD_LOGIC;   
           -- data
			  data_in : in  STD_LOGIC_VECTOR (APV_WORD_SIZE-1 downto 0);
			  dvalid_in : in  STD_LOGIC;
			  sigma_in : in STD_LOGIC_VECTOR (11 downto 0);
			  pedestal_in : in  STD_LOGIC_VECTOR (11 downto 0);
			  n_samples : in std_logic_vector(LOG2_MAX_SAMPLES-1 downto 0);
           chan_in : in  STD_LOGIC_VECTOR (APV_LOG2_CHANNELS-1 downto 0);
			  sample_in : in  STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  -- commands
			  start_reading : in std_logic;
			  output_enable : in std_logic;
			  --(SM)
			  cfg_reg: in STD_LOGIC_VECTOR (31  downto 0) := x"00000000";
			  -- outputs
			  ready : out std_logic;
			  data_out : out  STD_LOGIC_VECTOR (15  downto 0);
			  word_count : out std_logic_vector (15 downto 0);
			  -- buffer ctrl
			  buf_double : in std_logic;
			  buf_addr_out : out  STD_LOGIC_VECTOR (APV_LOG2_CHANNELS + LOG2_MAX_SAMPLES - 1 downto 0);
			  buf_read_out : out  STD_LOGIC;
			  buf_released_out : out  STD_LOGIC
           );
end Zero_Suppressor;

architecture Behavioral of Zero_Suppressor is


	COMPONENT Peak_Finder is
	 Port ( clk : in  STD_LOGIC;
	        reset : in  STD_LOGIC;   
            -- data
 		     data_in : in  STD_LOGIC_VECTOR (APV_WORD_SIZE downto 0);
			  sample_in : in  STD_LOGIC_VECTOR(LOG2_MAX_SAMPLES-1 downto 0);
			   -- options
			  polarity : in  STD_LOGIC; --'0' negative, '1' positive
			  -- outputs
			  peak_value : out  STD_LOGIC_VECTOR (APV_WORD_SIZE  downto 0);
			  peak_time : out std_logic_vector (LOG2_MAX_SAMPLES-1 downto 0)
           );
	end COMPONENT;

	COMPONENT syncronizer
	PORT(
		clk : IN std_logic;
		async_in : IN std_logic;          
		sync_out : OUT std_logic
		);
	END COMPONENT;
	
	
    COMPONENT syncronizer_v is
	 generic (depth: positive := 3; wordsize : positive := 1);
    Port ( clk : in  STD_LOGIC;
           async_in : in  STD_LOGIC_VECTOR (wordsize - 1 downto 0); 
		   sync_out : out  STD_LOGIC_VECTOR(wordsize - 1 downto 0));
    end COMPONENT;


	COMPONENT Dual_Port_RAM_132x8 is
	PORT(
		clk : IN std_logic;
		we : IN std_logic;
		Awr : IN std_logic_vector(7 downto 0);
		Ard : IN std_logic_vector(7 downto 0);
		Din : IN std_logic_vector(7 downto 0);          
		Dout : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;


signal dvalid_in_q : std_logic;

--signal data_q : STD_LOGIC_VECTOR (data_in'length - 1 downto 0);

constant srl_length  : integer := 32;  -- set to 16, 32, 64 etc. 
constant WIDTH : integer := data_in'length + 1;

-- 1 bit more than data_in
type	 srl_array	is array ( srl_length - 1  downto 0 ) of STD_LOGIC_VECTOR ( WIDTH - 1 downto 0 );
signal pipeline : srl_array;

-- pedestal correction
signal corrected_data, corrected_data_i : STD_LOGIC_VECTOR ( WIDTH - 1 downto 0 );
 
-- flags
signal signal_present, signal_present_r : std_logic;

-- accumulator
signal reset_accu : std_logic;
signal sum : std_logic_vector( 6 + WIDTH - 1 downto 0);

-- can be 32times bigger than sigma
--signal suppression_threshold : std_logic_vector( 5 + WIDTH - 1 downto 0);
-- SM adding more bits to it
--signal suppression_threshold : std_logic_vector( 6 + WIDTH - 1 downto 0);
--signal suppression_threshold_int : std_logic_vector( 6 + WIDTH - 1 downto 0);
--signal suppression_threshold_half : std_logic_vector( 6 + WIDTH - 1 downto 0);

signal mean : std_logic_vector(WIDTH - 1 downto 0);

-- sample in counter
signal sample_in_count : std_logic_vector( n_samples'length-1 downto 0);
-- test signal
signal count_ovflw2, count_ovflw_r : std_logic;

-- generates a n_samples clock cycle long mark_channel
signal sample_out_count : std_logic_vector( n_samples'length-1 downto 0);
signal mark_channel : std_logic;

constant sigma_cut : std_logic_vector(11 downto 0) := conv_std_logic_vector(3,12);

signal start_suppression : std_logic;
signal suppression_done, suppressing : std_logic;


-- channel list
--type channel_list_type is array (130 downto 0) of std_logic_vector (7 downto 0);
--signal channel_list : channel_list_type;

signal w_channel_list_out : std_logic_vector(7 downto 0); --AZ 29.10.14
signal w_channel_list_in : std_logic_vector(7 downto 0); --AZ 29.10.14


--signal ptr : std_logic_vector(7 downto 0); -- xst needs one more bit?
signal ptr2 : std_logic_vector(7 downto 0); 
signal active_channel_counter : std_logic_vector(7 downto 0);
signal active_channel_counter_r : std_logic_vector(7 downto 0); --1 clock delay for RAM access...
attribute ram_style: string;
--attribute ram_style of channel_list : signal is "distributed";

-- peak finding signals 
type peak_list_type is array (130 downto 0) of std_logic_vector (LOG2_MAX_SAMPLES + WIDTH  - 1 downto 0);
signal peak_list : peak_list_type;
attribute ram_style of peak_list : signal is "distributed";
signal peak_find_mode : std_logic;
signal peak_value_from_list : std_logic_vector(WIDTH - 1 downto 0);
signal peak_time_from_list : std_logic_vector(LOG2_MAX_SAMPLES-1 downto 0);
signal peak_value_to_list, peak_value_to_list_r : std_logic_vector(WIDTH - 1 downto 0);
signal peak_time_to_list, peak_time_to_list_r : std_logic_vector(LOG2_MAX_SAMPLES-1 downto 0);
signal sample_pf : std_logic_vector(n_samples'length-1 downto 0);

-- chan_in pipeline
signal chan_in_r,chan_in_r2 : std_logic_vector(chan_in'length - 1 downto 0); 

signal header_count : std_logic_vector(1 downto 0);
signal chan : std_logic_vector(7 downto 0);
signal sample_count : std_logic_vector(n_samples'length-1 downto 0);
signal output_n_samples : std_logic_vector(n_samples'length-1 downto 0);

constant HEADER_SIZE : integer := 4;
constant ZS_ERROR : std_logic_vector(7 downto 0) := X"00";

-- output part
signal word_count_i : std_logic_vector(15 downto 0);
type state_type is (st_idle, st_suppress, st_suppress_done, st_send_header, st_send_chid, st_send_data, st_send_peaks); 
signal state : state_type;

-- threshold related
signal thr_reg: std_logic_vector(11 downto 0);
signal suppression_cut, suppression_cut_a, suppression_cut_r2, suppression_cut_r1, suppression_cut_r : std_logic_vector(17 downto 0);
signal force_pedestal_0, force_signal: std_logic;
signal threshold_mode : std_logic;
signal suppression_threshold_tmp : std_logic_vector(30 downto 0);
signal suppression_threshold : std_logic_vector(24 downto 0);

signal sigma_in_r,sigma_in_r2 : STD_LOGIC_VECTOR (11 downto 0);
 
begin

	--(SM) 
	-- (RG on SM mods)  
	thr_reg 				<= cfg_reg(13 downto 8) & cfg_reg(7 downto 2);
	peak_find_mode    <= cfg_reg(16);
	force_pedestal_0 	<= cfg_reg(18);
	force_signal		<= cfg_reg(19);
   threshold_mode    <= cfg_reg(20); -- '0' basic : threshold = n_samples * 1, '1' advanced: threshold set by SC
	
	
   process(clk)
   begin
		if rising_edge(clk) then
		   if peak_find_mode = '0' then
				output_n_samples <= n_samples;
			else 
				output_n_samples <= conv_std_logic_vector(2,LOG2_MAX_SAMPLES);
			end if;
		end if;
	end process;
   	
	Pedestal_remover : process(data_in,pedestal_in)
	variable tmp : integer ; 
	begin
	     
		  -- synthesis translate_off 
		  if pedestal_in = "UUUUUUUUUUUU" or data_in = "UUUUUUUUUUUU"  then
		     tmp :=  -1;
		  else
		  -- synthesis translate_on 
		     tmp := conv_integer(data_in) - conv_integer(pedestal_in);
		  -- synthesis translate_off 
		  end if;
		  -- synthesis translate_on			
		  
		  corrected_data_i <= conv_std_logic_vector(tmp,WIDTH);
		  
		  
	end process;
	
	--(SM) force pedestal 0
	corrected_data <= ("0" & data_in) when force_pedestal_0 = '1' else corrected_data_i;
	 
	Peak_Finder_0: Peak_Finder PORT MAP(
		clk => clk,
		reset => reset ,
		polarity => '0',
		data_in => corrected_data,
		sample_in => sample_in,
		peak_value => peak_value_to_list,
		peak_time => peak_time_to_list
	);

	accumulator: process (clk)
	begin
	  if (clk'event and clk='1') then
	    -- needed to correctly reset on channel 0
		 if (reset='1') or (dvalid_in = '0' ) then
			sum <= (others => '0');
		 elsif dvalid_in = '1' then
		   if reset_accu = '1' then
			   sum <= conv_std_logic_vector(signed(corrected_data),sum'length);
			else
				sum <= signed(sum) + signed(corrected_data);
			end if;
		 end if;
	  end if;
	end process;
	
	-- this could be performed slowly, e.g. at 10 MHz
	calculate_suppression_cut: process(clk)
	begin
		if rising_edge(clk) then
			if threshold_mode = '0' then
				suppression_cut <= conv_std_logic_vector(conv_integer((n_samples) & "000000"), suppression_cut'length); -- default is 1, 6 bits integer part, 6 bits fractional part
			else
			   -- result size = sign + samples + integer + fractional = 1 + 5 + 6 + 6 = 18
			   suppression_cut <= signed('0' & n_samples) * signed(thr_reg);  -- thr_reg is 6 bits integer part, 6 bits fractional part
			end if;
		end if;
	end process;
	
   suppression_threshold_tmp <= signed('0' & sigma_in_r2) * signed(suppression_cut_r);
	
	-- shift right 6 bits
	suppression_threshold <= suppression_threshold_tmp(suppression_threshold_tmp'left downto 6);
	signal_present <= '1' when ((-signed(sum) >= signed(suppression_threshold)) or (force_signal = '1')) else '0';
	
	mark_channel <= signal_present_r and count_ovflw_r;
	reset_accu <= count_ovflw_r;
	count_ovflw2 <= '1' when (sample_in_count = n_samples - 1) and (dvalid_in_q = '1') else '0';

	pipe: process(clk)
	begin
		if rising_edge(clk) then
			dvalid_in_q <= dvalid_in;
			chan_in_r <= chan_in;
			chan_in_r2 <= chan_in_r;
			sigma_in_r <= sigma_in;
			sigma_in_r2 <= sigma_in_r;
			suppression_cut_r <= suppression_cut;
			signal_present_r <= signal_present;
			count_ovflw_r <= count_ovflw2;
			peak_value_to_list_r <= peak_value_to_list;
			peak_time_to_list_r <= peak_time_to_list; -- quick and dirty patch
			active_channel_counter_r <= active_channel_counter; --1 clock cycle latency for RAM access
		end if;
	end process;
	
	start_suppression <= '1' when (dvalid_in='1') and (sample_in_count = 0) and (chan_in = 0) else '0';
   suppression_done  <= '1' when (count_ovflw_r='1') and (chan_in_r2 = 127) else '0';
	
	-- builds a list with non-zero channels
	channel_list_builder: process(clk)
	variable chunk_size : std_logic_vector(output_n_samples'length downto 0);
	begin
		if rising_edge(clk) then
			if reset = '1' or start_suppression = '1' then
--				ptr <= (others => '0');
				word_count_i <= conv_std_logic_vector(HEADER_SIZE, word_count_i'length); --4
				active_channel_counter <= (others => '0');
			
			-- inserts a signal in the list
			elsif mark_channel='1' then
					--channel_list(conv_integer(ptr)) <= '0' & chan_in_r2;    -- two clock cyles of latency wrt the input
					w_channel_list_in <= '0' & chan_in_r2;    -- two clock cyles of latency wrt the input
					peak_list(conv_integer(active_channel_counter)) <= peak_time_to_list_r & peak_value_to_list_r; -- two clock cycle of latency wrt the input
--					ptr <= ptr + 1;
					-- force implementation of a sufficiently long adder and
					-- avoid overflow
					chunk_size := ('0' & output_n_samples) + 1;
					word_count_i <= word_count_i + chunk_size;
					--word_count_i <= word_count_i + conv_integer(n_samples) + 1; -- works in simulation
					--word_count_i <= word_count_i + n_samples + 1; -- works in simulation
					active_channel_counter <= active_channel_counter + 1;
				else -- sets the end
					--channel_list(conv_integer(ptr)) <= conv_std_logic_vector(255,8);
					w_channel_list_in <= x"ff";
				end if;
		end if;
	end process;

	Inst_Dual_Port_RAM_132x8: Dual_Port_RAM_132x8 PORT MAP( --AZ 29.10.14 add dualport RAM for channel storage
		clk => clk,
		we => '1',
		Awr => active_channel_counter_r, --use the delayed signal!
		Ard => ptr2,
		Din => w_channel_list_in,
		Dout => w_channel_list_out
	);
	
	peak_value_from_list <= peak_list(conv_integer(ptr2))(12 downto 0);
	peak_time_from_list <= peak_list(conv_integer(ptr2))(17 downto 13);
	
	word_count <= word_count_i;
	
	buffer_reader_fsm: process(clk)
	variable tmp : integer ; 
	begin
		if rising_edge(clk) then
			if reset = '1' then
				state <= st_idle;
				ptr2 <= (others => '0');
				header_count <= (others => '0');
				sample_count <= (others => '0');
				buf_read_out <= '0';
				buf_released_out <= '1';
				ready <= '0';
				suppressing <= '0';
			else
			   
				 	  case (state) is 
					  when st_idle => 
					     buf_released_out <= '1';
						  
						  if start_suppression = '1' then
						    state <= st_suppress;	
						  end if;
					     
						  buf_read_out <= '0';
				        data_out <= (others => '0');
				        suppressing <= '0';
						  
					  when st_suppress => 
						 buf_released_out <= '1';
                     
						 ready <= '0';	-- SM
					    if suppression_done = '1' then
							 state <= st_suppress_done;	
						  end if;
                    buf_read_out <= '0';
				        data_out <= (others => '0');
						  suppressing <= '1';
						  
					  when st_suppress_done =>
					     buf_released_out <= '0';
						  ready <= '1';
						  if start_reading = '1' then
							 state <= st_send_header;	
							 header_count <= conv_std_logic_vector(0, header_count'length);
						  end if;
						  buf_read_out <= '0';
				        data_out <= (others => '0');
						  suppressing <= '0';
						  
					  when st_send_header =>  
					     
							if output_enable = '1' then
								ready <= '0';
								
								header_count <= header_count + 1;
								case (header_count) is 
								when "00" =>
									data_out <= "0000" & conv_std_logic_vector(APV_ID,4) & active_channel_counter(7 downto 0);
								when "01" =>
									data_out <= conv_std_logic_vector(conv_integer(output_n_samples),8) & ZS_ERROR;
								when "10" =>
									data_out <= "000000000000000" & peak_find_mode;
								when others =>
									data_out <= (others => '0');
								end case;
								
								if header_count = "11" then
									if active_channel_counter > 0 then 
										state <= st_send_chid;
									else
										state <= st_idle;
									end if;
								end if;
								
								ptr2 <= (others => '0');
								-- pre-fetch sample 0
								sample_count <= (others => '0');
								buf_read_out <= '1';
							end if;
							suppressing <= '0';
							
					  when st_send_chid =>  
							if output_enable = '1' then
--								data_out <= "00000000" & channel_list(conv_integer(ptr2)) ; 
								data_out <= "00000000" & w_channel_list_out ; --AZ 29.10.14
								-- pre-fetch sample 1
								sample_count <= conv_std_logic_vector(1, sample_count'length);
								
								-- channel 255 is a reserved one and marks the end 
								-- of the active channel list
								--if channel_list(conv_integer(ptr2)) = 255 then
								if w_channel_list_out = x"ff" then
									
									state <= st_idle;
									
								else
									if peak_find_mode = '0' then
										state <= st_send_data;
									else
										state <= st_send_peaks;
									end if;
								end if;
								buf_read_out <= '1';
							end if;
							suppressing <= '0';	
							
					  when st_send_data =>  
							
							if output_enable = '1' then
									buf_read_out <= '1';
									data_out <= conv_std_logic_vector(signed(corrected_data),data_out'length);
									
									-- count enabled
									-- counts one more, in order to give the time
									-- to datain to update on the last sample
									if sample_count < output_n_samples  then
										 sample_count <= sample_count + 1;
									else
										 -- prefetch next channel   
										 ptr2 <= ptr2 + 1;
										 -- pre-fetch sample 0
										 sample_count <= (others => '0');
										 state <= st_send_chid;
									end if;
					
							 end if;
							 suppressing <= '0';
							 
					   when st_send_peaks =>  
							
							if output_enable = '1' then
									
									if sample_count = 1 then
									   -- outpus peak value
										data_out <= conv_std_logic_vector(signed(peak_value_from_list),data_out'length);
										 
									else
									   -- outputs corresponding time 
									   data_out <= conv_std_logic_vector(signed(peak_time_from_list),data_out'length);
									end if;
									
									-- count enabled
									-- counts one more, in order to give the time
									-- to datain to update on the last sample
									if sample_count < output_n_samples  then
										 sample_count <= sample_count + 1;
									else
										 -- prefetch next channel   
										 ptr2 <= ptr2 + 1;
										 -- pre-fetch sample 0
										 sample_count <= (others => '0');
										 state <= st_send_chid;
									end if;
							 
								
							 end if;
                      suppressing <= '0';
  							 
					  when others =>
							state <= st_idle;
 				     end case;
				
				end if; -- reset 
			end if; -- rising_edge
	end process;
	
	-- sample & chan
--	chan <= channel_list(conv_integer(ptr2)) ; 
	chan <= w_channel_list_out; 
	-- limited to 7, bits uses only physical channels
	buf_addr_out <= sample_count & chan(6 downto 0);
	
	-- every n_samples resets the accumulator
	sample_in_counter : process (clk)
	begin
	  if (clk'event and clk='1') then
		if (reset='1') or (dvalid_in_q='0' and dvalid_in='1')  then
			  sample_in_count <= conv_std_logic_vector(0,sample_in_count'length);
		 
		 else 
			if dvalid_in = '1' then
				if sample_in_count < n_samples - 1 then
				   sample_in_count <= sample_in_count + 1;
			   else
					sample_in_count <= conv_std_logic_vector(0,sample_in_count'length);
				end if;
			 end if;
	    end if;
	  
	  end if;
	end process;
	
		

end Behavioral;

