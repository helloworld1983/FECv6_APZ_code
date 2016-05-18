----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it
--
----------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

--library work;
use work.api_pack.all;

entity APV_Interface_multi is
Port (     
            -- clock at 40 MHz, for the front-end part   
           clk : in  STD_LOGIC; 
			  
			  -- clock at 125 MHz, for the back-end part
           clk125 : in  STD_LOGIC;
			  
			   -- clock at 10 MHz, for slow operations, currently unused
			  clk10 : in  STD_LOGIC; 
			  
			   -- synhcronous reset for the APV_processor
           reset : in  STD_LOGIC;
           
			  -- configuration register:
			  --  bits  
			  --  7:2  fractional part of the  threshold, ignored if threshold_mode flag ='0'
			  --  13:8 integer part of the threshold, ignored if threshold_mode flag ='0'
	        --  16   peak_find_enable  peak find mode enable 
	        --  18   force_pedestal    force pedestal to 0 for all the channels
			  --  19   force_signal      do not suppress signals
	        --  20   threshold_mode    -- '0' basic : threshold = n_samples * 1, '1' advanced: threshold set by SC
			  cfg_zs: in STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
           
			  -- select which APV to use for calibration
           apv_select : in std_logic_vector(3 downto 0);
			  
			  -- each bit corresponds to an APV, set it to one in order to 
			  -- disable if the APV is disconnected
			  apv_mask : in std_logic_vector(15 downto 0);
			  
			  -- apv 12-bit digitized data from 16 APVs
           apv_data : in  array16x12;
			  
			  -- system trigger, not the APV trigger
			  trigger_in : in std_logic;
			  
			  -- n.of time bins per trigger 
			  n_samples : in  STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  
			  -- processed data out
			  -- enable read from the suppressor
			  read_in        : in   STD_LOGIC_VECTOR (15 downto 0);  
			   
			  -- enable the output, read-out from the zero suppressor 
			  -- can be stopped on a per-cycle basis by driving this bit low.
			  output_enable  : in   STD_LOGIC_VECTOR (15 downto 0); 
			  
			   -- data from the suppressor, signed 16-bits as described in the 
			  -- SRS ZS Data Format
			  data_out       : out  array16x16; 
			  
			  -- data ready flag
			  ready_out      : out  STD_LOGIC_VECTOR (15 downto 0);  
           
           -- data descriptor, flags how many words will be read trough the data_out
			  -- output upon a read_in request			  
			  wordcount_out  : out  array16x16; 
			  			  
			  -- Calibration
			  -- flags the FEC logic to generate random triggers for calibration
  		     random_trigger : out  STD_LOGIC;
			  -- set high for 1 clock cycle, to start automatic measurement of
			  -- sigmas and pedestals
			  start_calib : in  STD_LOGIC;          
			  
			  -- flags that a calibration is running
			  busy : out  STD_LOGIC; 
			  pedestal_wd_flag : out std_logic;
			  
			 -- Pedestal file register access,
			 -- meant to be driven by Slow Control
			 
			 -- defines which APV is selected for pedestal and sigma IO
			 filereg_apvselect : in  STD_LOGIC_VECTOR (3 downto 0);
			 
			 -- load pedestal_in value into pedestal register of channel pedestal_addr
			 load_pedestal : in  STD_LOGIC;                       
         
			 -- channel to write to (or read from)
			 pedestal_addr : in  STD_LOGIC_VECTOR (6 downto 0);
			 
			 -- pedestal value to write
			 pedestal_in   : in  STD_LOGIC_VECTOR (11 downto 0);    
          
			 -- pedestal value retrieved from the register file
			 pedestal_out  : out  STD_LOGIC_VECTOR (11 downto 0);   
			  
			 -- load sigma_in value into pedestal st.dev. register of channel sigma_addr	 
			 load_sigma    : in  STD_LOGIC;
			 
			 -- ped.st.dev. value to write
			 sigma_in      : in  STD_LOGIC_VECTOR (11 downto 0);
			 
			 -- channel to write to (or read from)
			 sigma_addr    : in  STD_LOGIC_VECTOR (6 downto 0);			  
			 
			 -- ped.st.dev. value retrieved from the register file
			 sigma_out     : out  STD_LOGIC_VECTOR (11 downto 0);    
           
			 -- TPLL phase manging signals
			  
			 -- starts the phase alignment procedure
			 resync: in  STD_LOGIC;
			 -- flag, meant to be used by the FEC logic to inhibit the trigger 
			 -- during the optimization of the phase difference between the TPLL and the 
			 -- ADC
			 trigger_inhibit : out  STD_LOGIC;      
			 
			 -- flags that the phase alignment procedure has been completed
          phase_aligned : out  STD_LOGIC; 
			 
			 -- I2C signals for writing the desired phase to the TPLL
			 -- request to write to the TPLL via I2C
			 I2C_request : out  STD_LOGIC;
			 
          -- flags that the last I2C transaction has been completed
			 I2C_done : in  STD_LOGIC;
			 
          -- value to write to the ctr2 register
			 I2C_ctr2 : out  STD_LOGIC_VECTOR (4 downto 0)
			  
			  );
end APV_Interface_multi;

architecture Behavioral of APV_Interface_multi is


	component APV_Processor is
    Port ( clk : in  STD_LOGIC;
	        clk125 : in  STD_LOGIC;
			  clk10 : in  STD_LOGIC; -- unused 
           reset : in  STD_LOGIC;
           
			  cfg_zs: in STD_LOGIC_VECTOR (31 downto 0) := x"00000000";

			  -- apv 12-bit digitized data
			  apv_data : in  STD_LOGIC_VECTOR (11 downto 0);
           
			  -- system trigger, not the APV trigger
			  trigger_in : in std_logic;
			  
			  -- n.of time bins per trigger 
			  n_samples : in  STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  
			  -- zero suppressor output
			  read_in       : in   STD_LOGIC; 
			  output_enable : in std_logic;
			  data_out      : out  STD_LOGIC_VECTOR (15 downto 0); 
			  ready_out     : out  STD_LOGIC; 
           wordcount_out  : out  STD_LOGIC_VECTOR (15 downto 0); 
			  
           -- header threshold for the parser			  
           load_hdr_threshold : in std_logic;
			  hdr_threshold : in  STD_LOGIC_VECTOR (APV_WORD_SIZE-1 downto 0);
			  
			  -- auxiliary info from the parser
			  parsed_data : OUT std_logic_vector(APV_WORD_SIZE-1 downto 0);
			  parsed_datavalid : OUT std_logic;
			  parsed_chan : OUT std_logic_vector(APV_LOG2_CHANNELS-1 downto 0);
			  address : OUT std_logic_vector(7 downto 0);
   		  error : OUT std_logic;
			  
			  -- pedestal/sigma filereg access
			 load_pedestal : in  STD_LOGIC;                        -- load pedestal_in value into pedestal reg 
          pedestal_addr : in  STD_LOGIC_VECTOR (6 downto 0);
			 pedestal_in   : in  STD_LOGIC_VECTOR (11 downto 0);   -- external pedestal input 
          pedestal_out  : out  STD_LOGIC_VECTOR (11 downto 0);   -- current pedestal setting
			  
			 load_sigma    : in  STD_LOGIC;
			 sigma_in      : in  STD_LOGIC_VECTOR (11 downto 0);
			 sigma_addr    : in  STD_LOGIC_VECTOR (6 downto 0);			  
			 sigma_out     : out  STD_LOGIC_VECTOR (11 downto 0);   -- pedestal st.dev
		  
			  -- debug signals
			  dbg_sigma : out STD_LOGIC_VECTOR (11 downto 0);
			  dbg_pedestal : out STD_LOGIC_VECTOR (11 downto 0);
			  dbg_sample  : out STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  dbg_chan  : out STD_LOGIC_VECTOR (6 downto 0)
			  
			  );
	end component;

component PedestalCalculator is
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
			  
end component;


component PLL_PhaseAligner is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  start : in  STD_LOGIC;
			  threshold : out STD_LOGIC_VECTOR (11 downto 0);
           request : out  STD_LOGIC;
			  aligned : out std_logic;
           done : in  STD_LOGIC;
           ctr2 : out  STD_LOGIC_VECTOR (4 downto 0);
           apv_datain : in  STD_LOGIC_VECTOR (11 downto 0));
end component;

signal reset_vector : std_logic_vector(15 downto 0);

-- TPLL phase changer signals
signal PLL_phaseok : std_logic;
signal PLL_phaseok_r : std_logic;
signal load_hdr_threshold : std_logic_vector(15 downto 0);
signal hdr_threshold : std_logic_vector(11 downto 0);
signal load_threshold_from_FSM : std_logic;


-- parser signals
signal parsed_data : array16x12;
signal parsed_datavalid : std_logic_vector(15 downto 0);
signal parsed_chan : array16x7;


-- pedestal calculator signals
signal load_freg  : std_logic_vector(15 downto 0);
signal load_from_calc : std_logic;
signal addr_from_calc : std_logic_vector(6 downto 0);
signal pedestal_from_calc : std_logic_vector(11 downto 0);
signal sigma_from_calc : std_logic_vector(11 downto 0);
 
signal data_to_pedcal : std_logic_vector(11 downto 0);
signal datavalid_to_pedcal : std_logic;

 
signal pedestalcalculator_busy : std_logic;

-- IO interface
signal pedestal_load_from_SC_v : std_logic_vector(15 downto 0);
signal pedestal_load_v : std_logic_vector(15 downto 0);
signal pedestal_load_from_calc_v : std_logic_vector(15 downto 0);
signal pedestal_out_v :  array16x12;
signal pedestal_addr_to_apvproc : std_logic_vector(6 downto 0);
signal pedestal_in_to_apvproc : std_logic_vector(11 downto 0);

signal sigma_load_from_SC_v : std_logic_vector(15 downto 0);
signal sigma_load_v : std_logic_vector(15 downto 0);
signal sigma_load_from_calc_v : std_logic_vector(15 downto 0);
signal sigma_out_v :  array16x12;
signal sigma_addr_to_apvproc : std_logic_vector(6 downto 0);
signal sigma_in_to_apvproc : std_logic_vector(11 downto 0);

		
 
begin
  
  
  busy <= pedestalcalculator_busy;
  
  main_generate : for i in 15 downto 0 generate 
  reset_vector(i) <= apv_mask(i) or reset;
  
  load_hdr_threshold(i) <= load_threshold_from_FSM when apv_select = conv_std_logic_vector(i,apv_select'length) else '0';
    
	Inst_APV_Processor: APV_Processor PORT MAP(
		clk => clk,
		clk125 => clk125,
		clk10 => clk10,
		cfg_zs => cfg_zs,
		reset => reset_vector(i),
		apv_data => apv_data(i),
		trigger_in => trigger_in,
		n_samples => n_samples,
		
		-- zero suppressor output
	   read_in => read_in(i), 
		output_enable => output_enable(i),
	   data_out => data_out(i),
	   ready_out => ready_out(i),
      wordcount_out  => wordcount_out(i),
	   
		load_hdr_threshold => load_hdr_threshold(i),
		hdr_threshold => hdr_threshold,
		parsed_data => parsed_data(i),
		parsed_datavalid => parsed_datavalid(i),
		parsed_chan => parsed_chan(i),
		address => open ,
		error => open,
		
		-- pedestal/sigma IO bus
		load_pedestal => pedestal_load_v(i),
		pedestal_addr => pedestal_addr_to_apvproc,
		pedestal_in => pedestal_in_to_apvproc,
		pedestal_out => pedestal_out_v(i),
		
		load_sigma => sigma_load_v(i),
		sigma_addr => sigma_addr_to_apvproc,
		sigma_in => sigma_in_to_apvproc,
		sigma_out =>  sigma_out_v(i),
		
		dbg_sigma => dbg_sigma(i),
		dbg_pedestal => dbg_pedestal(i),
		dbg_sample => dbg_sample(i),
		dbg_chan => dbg_chan(i)
	);
	
	pedestal_load_from_calc_v(i) <= load_from_calc when apv_select = conv_std_logic_vector(i,apv_select'length) else '0';
	pedestal_load_from_SC_v(i) <= load_pedestal when filereg_apvselect = conv_std_logic_vector(i,filereg_apvselect'length) else '0'; 
	pedestal_load_v(i) <= pedestal_load_from_calc_v(i) when pedestalcalculator_busy = '1' else pedestal_load_from_SC_v(i);
	
	sigma_load_from_calc_v(i) <= load_from_calc when apv_select = conv_std_logic_vector(i,apv_select'length) else '0';
	sigma_load_from_SC_v(i) <= load_sigma when filereg_apvselect = conv_std_logic_vector(i,filereg_apvselect'length) else '0'; 
	sigma_load_v(i) <= sigma_load_from_calc_v(i) when pedestalcalculator_busy = '1' else sigma_load_from_SC_v(i);
	
		
   end generate;

   pedestal_addr_to_apvproc <= addr_from_calc when pedestalcalculator_busy='1' else pedestal_addr;
	pedestal_in_to_apvproc <= pedestal_from_calc when pedestalcalculator_busy='1' else pedestal_in;
	pedestal_out <= pedestal_out_v(conv_integer(filereg_apvselect));

   sigma_addr_to_apvproc <= addr_from_calc when pedestalcalculator_busy='1' else sigma_addr;
	sigma_in_to_apvproc <= sigma_from_calc when pedestalcalculator_busy='1' else sigma_in;
	sigma_out <= sigma_out_v(conv_integer(filereg_apvselect));


	Inst_PedestalCalculator: PedestalCalculator PORT MAP(
		clk => clk,
		reset => reset,
		watchdog_flag => pedestal_wd_flag,
		start_calib => start_calib,
		chan => (others => '0'), -- not needed anymore
		datain => data_to_pedcal,
		datavalid_in => datavalid_to_pedcal,
		busy => pedestalcalculator_busy,
		chan_out => addr_from_calc,
		write_out => load_from_calc,
		pedestal_out => pedestal_from_calc,
		sigma_out => sigma_from_calc
	);
   
	
	data_to_pedcal <= parsed_data(conv_integer(apv_select));
   datavalid_to_pedcal <= parsed_datavalid(conv_integer(apv_select));

	TPLL_phase_changer: PLL_PhaseAligner PORT MAP(
		clk => clk,
		reset => resync,
		start => '1',
		threshold => hdr_threshold,
		request => I2C_request,
		aligned => PLL_phaseok,
		done => I2C_done,
		ctr2 => I2C_ctr2,
		apv_datain => data_to_pedcal
	);
   
	process(clk)
	begin
		if rising_edge(clk) then
			PLL_phaseok_r <= PLL_phaseok; 
		end if;
   end process;
	 load_threshold_from_FSM <= PLL_phaseok and (not PLL_phaseok_r);
	
	trigger_inhibit <= (not PLL_phaseok) when resync = '0' else '0';
	random_trigger <= pedestalcalculator_busy;
   phase_aligned <= PLL_phaseok;
	
end Behavioral;


