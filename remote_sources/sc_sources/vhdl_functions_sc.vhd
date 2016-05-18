--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package vhdl_functions_sc is

--@ functions used in register mapping
	--@ 1-bit register (base -> 32-bit register index, pos -> bit index (0 to 31))
    function ireg1(  constant base : INTEGER;  constant pos : INTEGER;  constant registers : std_logic_vector )  return std_logic ;
	 --@ 8-bit register mapped to lsb part of 32-bit register (base -> 32-bit register index)
    function ireg8(  constant base : INTEGER;  constant registers : std_logic_vector )  return std_logic_vector ;
	 --@ 8-bit register mapped to any part of 32-bit register (base -> 32-bit register index, pos -> byte index (0 to 3))
    function ireg8_any(  constant base : INTEGER;  constant pos : INTEGER;  constant registers : std_logic_vector )  return std_logic_vector ;
	 --@ 16-bit register mapped to lsb part of 32-bit register (base -> 32-bit register index)
    function ireg12(  constant base : INTEGER;  constant registers : std_logic_vector )  return std_logic_vector ;
	 --@ 32-bit register mapped to lsb part of 32-bit register (base -> 32-bit register index)
    function ireg16(  constant base : INTEGER;  constant registers : std_logic_vector )  return std_logic_vector ;
	 --@ 24-bit register mapped to lsb part of 32-bit register (base -> 32-bit register index)
    function ireg24(  constant base : INTEGER;  constant registers : std_logic_vector )  return std_logic_vector ;
	 --@ 32-bit register mapped to lsb part of 32-bit register (base -> 32-bit register index)
    function ireg32(  constant base : INTEGER;  constant registers : std_logic_vector )  return std_logic_vector ;

end vhdl_functions_sc;

package body vhdl_functions_sc is
 
	 function ireg1(  constant base : INTEGER;  constant pos : INTEGER;  constant registers : std_logic_vector )  return std_logic is 
        variable ireg1_return_dummy_var : std_logic;
    begin
        ireg1_return_dummy_var  := registers(( ( base * 32  )  + pos ) );
         return ireg1_return_dummy_var;
    end;
	 
    function ireg8(  constant base : INTEGER;  constant registers : std_logic_vector )  return std_logic_vector  is 
        variable ireg8_return_dummy_var : std_logic_vector( 7  downto 0  );
    begin
        ireg8_return_dummy_var  := registers(( ( base * 32  )  + 7  )  downto ( base * 32  ) );
         return ireg8_return_dummy_var;
    end;
	 
    function ireg8_any(  constant base : INTEGER;  constant pos : INTEGER;  constant registers : std_logic_vector )  return std_logic_vector  is 
        variable ireg8_any_return_dummy_var : std_logic_vector( 7  downto 0  );
    begin
        ireg8_any_return_dummy_var  := registers(( ( base * 32  )  + ( pos * 8  )  + 7  )  downto ( ( ( base * 32  )  + ( pos * 8  )  )  ) );
         return ireg8_any_return_dummy_var;
    end;
	 
    function ireg12(  constant base : INTEGER;  constant registers : std_logic_vector )  return std_logic_vector is 
        variable ireg12_return_dummy_var : std_logic_vector( 11  downto 0  );
    begin
        ireg12_return_dummy_var  := registers(( ( base * 32  )  + 11  )  downto ( base * 32  ) );
         return ireg12_return_dummy_var;
    end;
	 
    function ireg16(  constant base : INTEGER;  constant registers : std_logic_vector )  return std_logic_vector is 
        variable ireg16_return_dummy_var : std_logic_vector( 15  downto 0  );
    begin
        ireg16_return_dummy_var  := registers(( ( base * 32  )  + 15  )  downto ( base * 32  ) );
         return ireg16_return_dummy_var;
    end;
	 
    function ireg24(  constant base : INTEGER;  constant registers : std_logic_vector )  return std_logic_vector is 
        variable ireg24_return_dummy_var : std_logic_vector( 23  downto 0  );
    begin
        ireg24_return_dummy_var  := registers(( ( base * 32  )  + 23  )  downto ( base * 32  ) );
         return ireg24_return_dummy_var;
    end;
	 
    function ireg32(  constant base : INTEGER;  constant registers : std_logic_vector )  return std_logic_vector is 
        variable ireg32_return_dummy_var : std_logic_vector( 31  downto 0  );
    begin
        ireg32_return_dummy_var  := registers(( ( base * 32  )  + 31  )  downto ( base * 32  ) );
         return ireg32_return_dummy_var;
    end;

end vhdl_functions_sc;
