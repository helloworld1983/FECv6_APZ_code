----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it
--
-- Create Date:    14:50:27 03/25/2011 
-- Design Name:    
-- Module Name:    APV_Interface - Behavioral 
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
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity APV_Interface is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           
			  -- apv 12-bit digitized data
			  apv_data : in  STD_LOGIC_VECTOR (11 downto 0);
           
			  -- system trigger, not the APV trigger
			  trigger_in : in std_logic;
			  
			  -- n.of time bins per trigger 
			  n_samples : in  STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  
			  -- processed data out
			  data_out : out  STD_LOGIC_VECTOR (12 downto 0);
           data_valid : out  STD_LOGIC;                   -- high if the data_out bus is driven with valid data
			  			  
			  -- auxiliary info from the parser
			  address : OUT std_logic_vector(7 downto 0);
   		  error : OUT std_logic;
			  
			  -- pedestal removal
			  autoset_pedestal : in  STD_LOGIC;                     -- set high for 1 clock cycle, to start autoset    
           load_pedestal : in  STD_LOGIC;                        -- load pedestal_in value into pedestal reg 
           pedestal_addr : in  STD_LOGIC_VECTOR (6 downto 0);
			  pedestal_in : in  STD_LOGIC_VECTOR (11 downto 0);     -- external pedestal input 
           sigma_in : in  STD_LOGIC_VECTOR (11 downto 0); 
			  pedestal_out : out  STD_LOGIC_VECTOR (11 downto 0);   -- current pedestal setting
			  sigma_out : out  STD_LOGIC_VECTOR (11 downto 0);      -- pedestal st.dev
			  random_trigger : out  STD_LOGIC;
			  
			  -- TPLL phase manging signals
			  resync: in  STD_LOGIC;
			  trigger_inhibit : out  STD_LOGIC;      
           I2C_request : out  STD_LOGIC;
           I2C_done : in  STD_LOGIC;
           I2C_ctr2 : out  STD_LOGIC_VECTOR (4 downto 0);
			  
			  -- debug signals
			  dbg_sigma : out STD_LOGIC_VECTOR (11 downto 0);
			  dbg_pedestal : out STD_LOGIC_VECTOR (11 downto 0);
			  dbg_sample  : out STD_LOGIC_VECTOR (4 downto 0);
			  dbg_chan  : out STD_LOGIC_VECTOR (6 downto 0)
			  
			  );
end APV_Interface;

architecture Behavioral of APV_Interface is

  	COMPONENT APV_parser
	PORT(
		clk : IN std_logic;
		reset : IN std_logic;
			  threshold: in  STD_LOGIC_VECTOR (11 downto 0);
		datain : IN std_logic_vector(11 downto 0);          
		address : OUT std_logic_vector(7 downto 0);
		error : OUT std_logic;
		dataout : OUT std_logic_vector(11 downto 0);
		channel : out  STD_LOGIC_VECTOR (6 downto 0);
		datavalid : OUT std_logic
		);
	END COMPONENT;
	
	component PedestalCalculatorRegister 
       Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  
			  -- pedestal calculator signals
			  start_calib : in  STD_LOGIC;                               -- start pedestal calculation
			  chan : in std_logic_vector(6 downto 0);              -- chan in, the calculator expects the data 
			                                                       -- to come interleaved, ch 0 to 127
			  datain : in  STD_LOGIC_VECTOR (11 downto 0);         -- data in
			  datavalid_in : in  STD_LOGIC;                        -- data in strobe
			  busy : out STD_LOGIC;                                -- busy flag           
			  
			  -- Register section
			  pedestal_chan : in  STD_LOGIC_vector(6 downto 0);       -- pedestal_chan 
			  pedestal_out : out  STD_LOGIC_VECTOR (11 downto 0);     -- pedestal for pedestal_chan, 0 latency
			  
			  sigma_chan : in  STD_LOGIC_vector(6 downto 0);       -- sigma_chan 
			  sigma_out : out  STD_LOGIC_VECTOR (11 downto 0);     -- sigma for sigma_chan, 0 latency
           
			  -- fileregister R/W access, works only when the calculator is not busy
			  freg_chan : in std_logic_vector(6 downto 0);
			  freg_write : in  STD_LOGIC;                               -- set pedestal with value specified in pedestal_in 
			  freg_pedestal_in : in  STD_LOGIC_VECTOR (11 downto 0);    -- value to write in the pedestal register
			  freg_sigma_in : in  STD_LOGIC_VECTOR (11 downto 0);
			  freg_pedestal_out : out  STD_LOGIC_VECTOR (11 downto 0);  -- the current value of the pedestal, with 1 clock cycle latency
			  freg_sigma_out: out  STD_LOGIC_VECTOR (11 downto 0));     -- the current value of the pedestal sigma, with 1 clock cycle latency
			                                
			  
	end component;



	COMPONENT PLL_PhaseAligner
	PORT(
		clk : IN std_logic;
		reset : IN std_logic;
	   start : IN std_logic;
		threshold: out  STD_LOGIC_VECTOR (11 downto 0);
		done : IN std_logic;
		apv_datain : IN std_logic_vector(11 downto 0);          
		request : OUT std_logic;
		aligned : OUT std_logic;
		ctr2 : OUT std_logic_vector(4 downto 0)
		);
	END COMPONENT;	
	
	COMPONENT Zero_Suppressor is
		 Port ( clk : in  STD_LOGIC;
	        reset : in  STD_LOGIC;   
           data_in : in  STD_LOGIC_VECTOR (11 downto 0);
			  dvalid_in : in  STD_LOGIC;
			  sigma_in : in STD_LOGIC_VECTOR (11 downto 0);
			  pedestal_in : in  STD_LOGIC_VECTOR (11 downto 0);
			  n_samples : in std_logic_vector(LOG2_MAX_SAMPLES-1 downto 0);
           chan_in : in  STD_LOGIC_VECTOR (6 downto 0);
           data_out : out  STD_LOGIC_VECTOR (12  downto 0);
           dvalid_out : out  STD_LOGIC);
	end COMPONENT;
	
	
	COMPONENT Data_sorter
	    Port ( clk : in  STD_LOGIC;
	        reset : in  STD_LOGIC; -- need a reset each time n_samples is changed
			  trigger_in : in STD_LOGIC; -- resets the sample count at each trigger
           data_in : in  STD_LOGIC_VECTOR (11 downto 0);
           dvalid_in : in  STD_LOGIC;
			  n_samples : in std_logic_vector(LOG2_MAX_SAMPLES-1 downto 0);
           chan_in : in  STD_LOGIC_VECTOR (6 downto 0);
           data_out : out  STD_LOGIC_VECTOR (11 downto 0);
			  sample_out : out  STD_LOGIC_VECTOR (4 downto 0);
           chan_out : out  STD_LOGIC_VECTOR (6 downto 0);
           dvalid_out : out  STD_LOGIC);
	END COMPONENT;

   -- PLL phase aligner signals
	signal   PLL_phaseok : std_logic;
	signal   hdr_threshold : STD_LOGIC_VECTOR (11 downto 0);
	
	-- Parser signals
   signal   channel : STD_LOGIC_VECTOR (6 downto 0);
	signal   parsed_data : std_logic_vector(11 downto 0);
	signal   parsed_datavalid : std_logic;
	
	-- Sorter signals
	signal   sorted_data : std_logic_vector(11 downto 0);
	signal   sorted_datavalid : std_logic;
	signal   sorted_channel : STD_LOGIC_VECTOR (6 downto 0);
	signal   sorted_sample : STD_LOGIC_VECTOR (4 downto 0);
	
	-- Pedestal Calculator and filereg signals
	signal   pedestalcalculator_busy : std_logic;
	signal   sigma : std_logic_vector(11 downto 0);
	signal   pedestal : std_logic_vector(11 downto 0);
	signal   corrected_channel : STD_LOGIC_VECTOR (6 downto 0);
	
	-- Zero Suppressor signals  
	signal   suppression_threshold : std_logic_vector(17 downto 0);
	signal   suppressed_data : std_logic_vector(12 downto 0);
	signal	suppressed_datavalid :  std_logic;
   
begin


	-- debug signals
	dbg_sigma <= sigma;
	dbg_pedestal <= pedestal;
	dbg_sample <= sorted_sample;
	dbg_chan  <= sorted_channel;
   
	DataParse_unit: APV_parser PORT MAP(
		clk => clk,
		reset => reset,
		threshold => hdr_threshold,
		datain => apv_data,
		address => address,
		error => error,
		dataout => parsed_data,
		channel => channel, 
		datavalid => parsed_datavalid
	);
	
	PedestalCalcReg_unit : PedestalCalculatorRegister 
	PORT MAP(
		clk => clk,
		reset => reset,
		
		chan => channel,
		datain => parsed_data,
		datavalid_in => parsed_datavalid,
		
		pedestal_chan => sorted_channel,
		pedestal_out => pedestal,
		
		sigma_chan => sorted_channel,
		sigma_out => sigma,
		
		start_calib => autoset_pedestal,
		busy => pedestalcalculator_busy,
		
		-- fileregister IO, don't use in this implementation
		freg_write => load_pedestal,
		freg_pedestal_in => pedestal_in,
		freg_sigma_in => sigma_in,
		freg_chan => pedestal_addr,
		freg_pedestal_out => pedestal_out,
 	   freg_sigma_out => sigma_out
	);

	Sort_unit: Data_sorter PORT MAP(
		clk => clk,
		reset => reset,
		trigger_in => trigger_in,
		data_in => parsed_data,
		dvalid_in => parsed_datavalid,
		n_samples => n_samples,
		chan_in => channel,
		data_out => sorted_data,
		chan_out => sorted_channel,
		sample_out => sorted_sample,
		dvalid_out => sorted_datavalid
	);
   
	
	ZeroSuppression_unit: Zero_Suppressor PORT MAP(
		clk => clk,
		reset => reset,
		data_in => sorted_data,
		dvalid_in => sorted_datavalid,
		sigma_in => sigma,
		pedestal_in => pedestal,
		n_samples => n_samples,
		chan_in => sorted_channel, -- modify here? need a chan_in? perhaps not
		data_out => suppressed_data,
		dvalid_out => suppressed_datavalid
	);
   
	-- temp modification, just for debug
	data_out <= suppressed_data;
	data_valid <= suppressed_datavalid;
	
	--data_out <= '0' & parsed_data;
	--data_valid <= parsed_datavalid;
	
	

	TPLL_phase_changer: PLL_PhaseAligner PORT MAP(
		clk => clk,
		reset => resync,
		start => '1',
		threshold => hdr_threshold,
		request => I2C_request,
		aligned => PLL_phaseok,
		done => I2C_done,
		ctr2 => I2C_ctr2,
		apv_datain => apv_data
	);
   
	trigger_inhibit <= (not PLL_phaseok) when resync = '0' else '0';
	random_trigger <= pedestalcalculator_busy;

end Behavioral;

