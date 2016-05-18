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
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.api_pack.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Data_sorter is
    Port ( clk : in  STD_LOGIC;
	        wclk : in  STD_LOGIC;
			  
			  -- synch on wclk
			  reset : in  STD_LOGIC; -- need a reset each time n_samples is changed
			  trigger_in : in STD_LOGIC;
           data_in : in  STD_LOGIC_VECTOR (APV_WORD_SIZE-1 downto 0);
           dvalid_in : in  STD_LOGIC;
			  n_samples : in std_logic_vector(LOG2_MAX_SAMPLES-1 downto 0);
           chan_in : in  STD_LOGIC_VECTOR (APV_LOG2_CHANNELS-1 downto 0);
           -- synch on clk
           buf_double : in std_logic;
			  buf_released_in : in std_logic;
			  buf_mode_in : in std_logic;
			  buf_addr_in : in std_logic_vector(APV_LOG2_CHANNELS + LOG2_MAX_SAMPLES - 1 downto 0);

			  data_out : out  STD_LOGIC_VECTOR (APV_WORD_SIZE-1 downto 0);
           sample_out : out  STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  chan_out : out  STD_LOGIC_VECTOR (APV_LOG2_CHANNELS-1 downto 0);
			  dvalid_out : out  STD_LOGIC);
end Data_sorter;

architecture Behavioral of Data_sorter is

	component dualport_ram is
	 generic(M: natural);
    Port ( we 		  : in std_logic;						 -- write enable
           datain	  : in std_logic_vector(11 downto 0);   -- data input
           wclk 	  : in std_logic;						 -- writing clock
           rclk 	  : in std_logic;						 -- read clock
           
           wr_addr  : in std_logic_vector(M-1 downto 0);   -- write address 
           rd_addr  : in std_logic_vector(M-1 downto 0);   -- read address 
           dataout  : out std_logic_vector(11 downto 0)   -- data out 
           ); -- data out B
	end component;

	COMPONENT syncronizer
	PORT(
		clk : IN std_logic;
		async_in : IN std_logic;          
		sync_out : OUT std_logic
		);
	END COMPONENT;

---- For double buffering
---- 2^13 words => 2 bufs x 0.6 us @ 40 MHz
--constant LOG2_BUFFER_DEPTH : integer := 1+chan_in'length+sample_out'length;

-- For single buffering
-- 2^13 words => 1 bufs x 1.2 us @ 40 MHz
constant LOG2_BUFFER_DEPTH : integer := APV_LOG2_CHANNELS + LOG2_MAX_SAMPLES;

	 
signal delta : std_logic_vector(15 downto 0);
signal rd_addr,wr_addr : std_logic_vector(LOG2_BUFFER_DEPTH-1 downto 0);
signal rd_addr_msb_single_buf : std_logic;
signal rd_bank, wr_bank : std_logic;

signal chan_out_i: std_logic_vector(chan_in'length-1 downto 0);
signal sample_in,sample_out_i : std_logic_vector(n_samples'length-1 downto 0);

signal is_flushing, dvalid_out_i : std_logic;
signal write_enable : std_logic;

-- internal reset
signal reset_q : std_logic;
signal reset_rd : std_logic;
--signal reset_wr : std_logic;

-- Buffer management signals
signal write_enable_ctrl, read_enable_ctrl, write_enable_ctrl_s40 : std_logic;
signal wr_sample_reset, rd_sample_reset : std_logic;
signal buf_released_s40, buffer_analyzed, buffer_filled,  buffer_filled_s125 : std_logic;
signal buf_released_in_ris_edge, buf_released_in_last : std_logic;
signal trigger_in_s125 : std_logic;
signal trigger_enable_ctrl_s40, trigger_enable_ctrl : std_logic;
type state_type is (st_idle, st_filling, st_flushing, st_suppressing); 
signal state : state_type;


constant TIME_OUT_1_ms : integer := 125000 ;  -- @125MHz
signal reset_timer, fill_time_out : std_logic;
signal timer : std_logic_vector(19 downto 0);
	
begin



   -- outputs latency compensators	
   outpipes : process(clk)
	begin
		if rising_edge(clk) then
			chan_out <= rd_addr(chan_in'length-1 downto 0); -- chan_out_i
			if (buf_double = '1') then
				sample_out(sample_out'length - 2 downto 0) <= rd_addr(rd_addr'length - 2 downto chan_in'length); -- sample_out_i;
			   sample_out(sample_out'length - 1) <= '0';
			else
			   sample_out <= rd_addr(rd_addr'length - 1 downto chan_in'length); -- sample_out_i;
			end if;
			dvalid_out <=  read_enable_ctrl and not buffer_analyzed; -- looks ahead
	   end if;
	end process;
  
   -- double buffer, it is capable to store 2^13 12-bit words 
   -- 2^12 words per buffer => 2^5 samples x 128 channels
   data_buffer: dualport_ram
	generic map (LOG2_BUFFER_DEPTH)--, data_in'length)
   port map (we => write_enable,
				 datain => data_in,
				 wclk => wclk,
				 rclk => clk, 
				 wr_addr => wr_addr,
				 rd_addr => rd_addr,
				 dataout => data_out );
		
	    -- MUST not write if the content of the previous has not been sent out
		 write_enable <= dvalid_in and write_enable_ctrl_s40;
		 
		 -- can read only if the read bank is not equal to write bank and the buffer is released
		 -- !!! DISABLE FOR TEST ONLY!!!
		 -- this line caused the simulator to hang
		 --read_enable <= '0' when (rd_bank = wr_bank and buf_double='1') else read_enable_ctrl;
		 -- 
		 
		 --read_enable <= '1' when ((rd_bank /= wr_bank) and (read_enable_ctrl='1')) else '0';
		 
		 --read_enable <= '1' when read_enable_ctrl='1' else '0';
		 
		 -- read/write address mixing
    	 -- rd address is incorrect in single buffering 
		 rd_addr(rd_addr'length - 2 downto 0) <= sample_out_i(sample_out_i'length - 2 downto 0) & chan_out_i when buf_mode_in = '0' else buf_addr_in(buf_addr_in'length - 2 downto 0);
	    
		 ---- CHECK ?
		 rd_addr_msb_single_buf <= sample_out_i(sample_out_i'length - 1) when buf_mode_in = '0' else buf_addr_in(buf_addr_in'length - 1);
		 
		 
		 rd_addr(rd_addr'length - 1) <= rd_addr_msb_single_buf when buf_double = '0' else rd_bank;
		 
		 wr_addr(rd_addr'length - 2 downto 0) <= sample_in(sample_in'length - 2 downto 0) & chan_in;
       wr_addr(rd_addr'length - 1) <= sample_in(sample_in'length - 1) when buf_double = '0' else wr_bank;
	

	read_logic : process(clk)
	begin
		if rising_edge(clk) then
		
		   reset_q <= reset;
         reset_rd <= reset_q;
			
			if reset_rd = '1' or rd_sample_reset='1' then
				chan_out_i <= (others => '0');
				sample_out_i <= (others => '0');
				rd_bank <= '0';
				buffer_analyzed <= '0'; 
				--dvalid_out_i <= '0';
			else
				buffer_analyzed <= '0'; 
				--dvalid_out_i <= '0';
				
				-- read ptr logic
				if read_enable_ctrl = '1' and buffer_analyzed='0' then
				   if sample_out_i < n_samples - 1 then
					
					   sample_out_i <= sample_out_i + 1 ;
						--dvalid_out_i <= '1';
					
					else 
						sample_out_i <= (others =>'0');
						
						if chan_out_i < 127 then
						
						   chan_out_i <= chan_out_i + 1;
							--dvalid_out_i <= '1';
						
						else
						  
							buffer_analyzed <= '1';
							rd_bank <= not rd_bank;
							
							chan_out_i <= (others =>'0');
							--dvalid_out_i <= '0';
							
						end if;
					end if;
	         end if;
			end if;
		end if;
	end process;
	

  	Inst_syncronizer: syncronizer PORT MAP(
		clk => wclk,
		async_in => buf_released_in,
		sync_out => buf_released_s40 
	);	
	
	
	
	wr_sample_counter : process(wclk)
	begin
		if rising_edge(wclk) then
			
			if reset = '1' or wr_sample_reset='1' then
				sample_in <=  (others => '0');
				wr_bank <= '0';
				buffer_filled <= '0';
			else
			   buffer_filled <= '0';
				
			   -- on a trigger, change writing buffer, if the read_bank has been released
				if trigger_in = '1' and trigger_enable_ctrl_s40='1'  then
					sample_in <= (others => '0');

					if buf_released_s40 = '1' then
							wr_bank <= not wr_bank;
					end if;
							
				else
					
					-- sample counter 
					if dvalid_in='1' and chan_in=127 then
						if sample_in < n_samples - 1 then
							sample_in  <= sample_in + 1 ;
						else 
						   buffer_filled <= '1';
							sample_in <= (others =>'0');
						end if;
					end if;
					
            end if;
				
			end if;
		end if;
	end process;
	
	triggerin_synch_on_fast_clock: syncronizer PORT MAP(
		clk => clk,
		async_in => trigger_in,
		sync_out => trigger_in_s125 
	);	
	
	buffer_filled_synch_on_fast_clock: syncronizer PORT MAP(
		clk => clk,
		async_in => buffer_filled,
		sync_out => buffer_filled_s125 
	);	
	
	wen_synch_on_slow_clock: syncronizer PORT MAP(
		clk => wclk,
		async_in => write_enable_ctrl,
		sync_out => write_enable_ctrl_s40 
	);	
	
	
	trigger_enable_on_slow_clock: syncronizer PORT MAP(
		clk => wclk,
		async_in => trigger_enable_ctrl,
		sync_out => trigger_enable_ctrl_s40 
	);	
	
	
	buf_released_ris_edge_det: process(clk)
	begin
		if rising_edge(clk) then
		  buf_released_in_last <= buf_released_in;
		end if;
		
	end process;
	buf_released_in_ris_edge <= buf_released_in and not buf_released_in_last;



timer_proc : process (clk) 
begin
   if rising_edge(clk) then
      if reset_timer='1' then 
         timer <= (others => '0');
      else
         timer <= timer + 1;
      end if;
   end if;
end process; 

--min_time_after_trigger <= '1' when timer > TIME_OUT_1_us else '0';
fill_time_out <= '1' when timer > TIME_OUT_1_ms else '0';


--			     write_enable_ctrl <= '1';
--				  read_enable_ctrl <= buf_released_in; 
--				  trigger_enable_ctrl <= '1';	  
--				  reset_timer <= '1';

	-- works on the fast clock (125 MHz)
	readwrite_ctrl_fsm: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then

			     write_enable_ctrl <= '1';
				  read_enable_ctrl <= '0'; 
				  trigger_enable_ctrl <= '1';	  
				  reset_timer <= '1';
				  is_flushing <= '0';
				  
				  wr_sample_reset <= '1';
				  rd_sample_reset <= '1';

			else
			   
				 	  case (state) is 
					  							
					  when st_idle => 
                     
					      write_enable_ctrl <= '0';
					     	read_enable_ctrl <= '0';
							trigger_enable_ctrl <= '1';
							reset_timer <= '1';
							is_flushing <= '0';
							wr_sample_reset <= '1';
							rd_sample_reset <= '1';
							
							if trigger_in_s125 = '1' then
							   state <= st_filling;
							end if;
					  
					  when st_filling => 
					      
							-- enables writing
					      write_enable_ctrl <= '1';
					     	wr_sample_reset <= '0';
							
							-- locks reading
							read_enable_ctrl <= '0'; 
							rd_sample_reset <= '1';
							
							trigger_enable_ctrl <= '0';
							reset_timer <= '0';
							is_flushing <= '0';
							
							if buffer_filled_s125 = '1' then
							   state <= st_flushing;
							elsif fill_time_out = '1' then
					         state <= st_idle;
							elsif trigger_in_s125 = '1' then
							  state <= st_filling;
							  -- resets read and write logic
							  wr_sample_reset <= '1';
							  rd_sample_reset <= '1';
							end if;

					  when st_flushing => 
					  
					      write_enable_ctrl <= '0';
					     	read_enable_ctrl <= '1';
							trigger_enable_ctrl <= '0';
							reset_timer <= '1';
							is_flushing <= '1';
							
							
							wr_sample_reset <= '0';
							rd_sample_reset <= '0';
							
							if buffer_analyzed = '1' then
								state <= st_suppressing;
								-- stops immediately
								read_enable_ctrl <= '0';
							end if;
							
							
					  when st_suppressing => 

					      write_enable_ctrl <= '0';
					     	read_enable_ctrl <= '0';
							trigger_enable_ctrl <= '0';
							reset_timer <= '1';
							is_flushing <= '0';
							
							wr_sample_reset <= '0';
							rd_sample_reset <= '1';
							
							if buf_released_in_ris_edge = '1' then
							   state <= st_idle;
							end if;

					  when others =>
							state <= st_idle;
 				     end case;
--				     


				end if; -- reset 
			end if; -- rising_edge
	end process;
--	
	
	
	
	
 end Behavioral;

