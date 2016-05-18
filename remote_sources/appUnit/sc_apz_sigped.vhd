----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:30:23 01/13/2012 
-- Design Name: 
-- Module Name:    sc_apz_sigped - Behavioral 
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sc_apz_sigped is
	 Generic (
			gen_port : std_logic_vector(15 downto 0) := x"1798"
			);
    Port ( clk, clk40M : in  STD_LOGIC;
           rstn : in  STD_LOGIC;
           sc_port : in  STD_LOGIC_VECTOR (15 downto 0);
           sc_data : in  STD_LOGIC_VECTOR (31 downto 0);
           sc_addr : in  STD_LOGIC_VECTOR (31 downto 0);
           sc_subaddr : in  STD_LOGIC_VECTOR (31 downto 0);
           sc_op : in  STD_LOGIC;
           sc_frame : in  STD_LOGIC;
           sc_wr : in  STD_LOGIC;
           sc_ack : out  STD_LOGIC;
           sc_rply_data : out  STD_LOGIC_VECTOR (31 downto 0);
           sc_rply_error : out  STD_LOGIC_VECTOR (31 downto 0);
			  -- pedestal filereg access, meant to be driven by Slow Control
			 api_sigped_apv : out std_logic_vector(3 downto 0); 
			 
			 api_load_pedestal : out  STD_LOGIC;                        -- load pedestal_in value into pedestal reg 
          api_pedestal_addr : out  STD_LOGIC_VECTOR (6 downto 0);
			 api_pedestal_in   : out  STD_LOGIC_VECTOR (11 downto 0);   -- external pedestal input 
          api_pedestal_out  : in  STD_LOGIC_VECTOR (11 downto 0);   -- current pedestal setting
			  
			 api_load_sigma    : out  STD_LOGIC;
			 api_sigma_in      : out  STD_LOGIC_VECTOR (11 downto 0);
			 api_sigma_addr    : out  STD_LOGIC_VECTOR (6 downto 0);			  
			 api_sigma_out     : in  STD_LOGIC_VECTOR (11 downto 0)   -- pedestal st.dev
			  );
end sc_apz_sigped;

architecture Behavioral of sc_apz_sigped is
type state_type is (stIdle, stEx, stAck0, stAck1);
signal state: state_type;

signal api_sigped_addr : STD_LOGIC_VECTOR (6 downto 0);
signal api_sigped_in : STD_LOGIC_VECTOR (11 downto 0);

signal sync: std_logic;

begin

	api_pedestal_addr <= api_sigped_addr;
	api_sigma_addr <= api_sigped_addr;
	
	api_pedestal_in <= api_sigped_in;
	api_sigma_in <= api_sigped_in;
	
	sc_rply_error <=  x"00000001" when (sc_addr(30 downto 7) /= 0) else
							x"00000002" when (sc_data(31 downto 12) /= 0) else
							x"00000000";


	process(clk40M, rstn)
	begin	
		if rstn = '0' then
			api_load_pedestal <= '0';
			api_load_sigma <= '0';
			sync <= '0';
		elsif clk40M'event and clk40M = '1' then
			api_load_pedestal <= '0';
			api_load_sigma <= '0';
			if (state = stEx) and (sc_wr = '1') then
				if sync = '0' then
					if sc_addr(31) = '1' then
						api_load_sigma <= '1';
					else
						api_load_pedestal <= '1';
					end if;
				end if;
				sync <= '1';
			else
				sync <= '0';
			end if;
		end if;
	end process;
	
	process(clk, rstn)
	begin
		if rstn = '0' then
			state <= stIdle;
			sc_ack <= '0';
			sc_rply_data <= (others => '0');
			api_sigped_apv <= (others => '0');
			api_sigped_addr <= (others => '0');
			api_sigped_in <= (others => '0');
		elsif clk'event and clk = '1' then
			case state is
				when stIdle =>
					sc_ack <= '0';
					sc_rply_data <= (others => '0');
--					if ((sc_frame and sc_op) = '1') and (sc_port = gen_port) then
					if (sc_op = '1') and (sc_port = gen_port) then
						if (sc_addr(30 downto 7) /= 0) then
							state <= stAck0;
						elsif (sc_data(31 downto 12) /= 0) then
							state <= stAck0;
						else
							api_sigped_apv <= sc_subaddr(3 downto 0);
							api_sigped_addr <= sc_addr(6 downto 0);
							api_sigped_in <= sc_data(11 downto 0);
							state <= stEx;
						end if;
					end if;
				when stEx =>
					if sc_wr = '0' then
						if sc_addr(31) = '1' then
							sc_rply_data <= x"00000" & api_sigma_out;
						else
							sc_rply_data <= x"00000" & api_pedestal_out;
						end if;
						state <= stAck0;
					elsif sync = '1' then
						sc_rply_data <= sc_data;
						state <= stAck0;
					end if;
					sc_ack <= '1';
				when stAck0 =>
					sc_ack <= '1';
					if sc_op = '0' then
--						state <= stAck1;
						state <= stIdle;
						sc_ack <= '0';
					end if;
--				when stAck1 =>
--					sc_ack <= '0';
--					if sc_frame = '0' then
--						state <= stIdle;
--					elsif sc_op = '1' then
--						state <= stEx;
--					end if;
				when others =>
					state <= stIdle;
			end case;
		end if;
	end process;

end Behavioral;

