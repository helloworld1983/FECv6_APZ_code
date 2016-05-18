`timescale 1ns / 1ps

module Des_DCH
	  #(
	  parameter [11:0]	SIGNAL_LEVEL1 	= 12'h7B7,	//1975
	  parameter [11:0]	SIGNAL_LEVEL2 	= 12'h81B, 	//2075
	  parameter 			IODELAY_GRP 	= "IODELAY_ADC"
	  )
	  (
		// Inputs
		rstb,
		//sclk,
		// ADC1
		FCO,
		DCO,
		//DCOn,
		DCH,
		
		rst_ISERDconf,
		rst_ISERD,
		// Ajuste automático de fase de DCO
		DCH_pttn,
		
		// Ajuste automático del retardo de los DLYs
		DLY_adj, 
		
		//DCH_adjpn,
		
		// Outputs
		// Canal deserializado
		des_DCH,
		
		// Ajuste automático de fase de DCO
		DCH_ok,
		// BITSLEEP
		BS_init, BS_confrun,
		
		ramp_ok
		);

	input				rstb;
	
	//	ADC
	input				FCO;
	input				DCO;
	//input				DCOn;
	input				DCH;
	
	input				rst_ISERDconf;
	input				rst_ISERD;
	
	// Ajuste automático de fase de DCO
	input	[11:0]	DCH_pttn;
	
	// Ajuste automático del retardo de los DLYs
	input				DLY_adj;
		
	//	Output
	output [11:0]	des_DCH;
	// Ajuste automático de fase de DCO
	output			DCH_ok;
	
	// Ajuste BITSLEEP
	input				BS_init;
	output			BS_confrun;
	
	// Comparación de RAMPA
	output			ramp_ok; 

	


//*************************************************************************************************************************************
// Declaración de señales

reg			DCH_okp, DCH_okn;

wire			DLY_inc, DLY_adjp, DLY_adjn;

wire			DCH, DCHn;

wire			rst_ISERDw;

assign		rst_ISERDw = !rstb | rst_ISERDconf | rst_ISERD;
assign		rst_IODw	  = !rstb | rst_ISERD;

reg [11:0]	ramp1, ramp2;		
wire			ramp_ok;

//*************************************************************************************************************************************
// Asignación de señales
assign	DLY_adjp = (DLY_adj & !DCH_okp); 
assign	DLY_adjn = (DLY_adj & !DCH_okn); 

assign	DLY_inc = DLY_adjp | DLY_adjn;


// Comparación de las señales de salida para el TEST de RAMPA
// Cada valor y el siguiente solo debe diferir en un valor
assign 	ramp_ok = (ramp2 == ramp1 + 12'h001) ? 1'b1:1'b0;  

//*************************************************************************************************************************************
//*************************************************************************************************************************************

//**************************************************************************************************
// Deserializador 
//**************************************************************************************************
// ISERDES P
// Bloque de retardo - P
	(* IODELAY_GROUP = IODELAY_GRP *)
	IODELAYE1 #(
      //.CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion ("TRUE"/"FALSE") 
      .DELAY_SRC("I"),                 // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
      .HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
      .IDELAY_TYPE("VARIABLE"),         // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
      .IDELAY_VALUE(0),                // Input delay tap setting (0-32)
      //.ODELAY_TYPE("FIXED"),           // "FIXED", "VARIABLE", or "VAR_LOADABLE" 
      //.ODELAY_VALUE(0),                // Output delay tap setting (0-32)
      .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz
      .SIGNAL_PATTERN("DATA")          // "DATA" or "CLOCK" input signal
   )
   IODELAYE1_DCHp (
      //.CNTVALUEOUT(CNTVALUEOUT), // 5-bit output - Counter value for monitoring purpose
      .DATAOUT(DCHpd),         		// 1-bit output - Delayed data output
      .C(FCO),                     // 1-bit input - Clock input
      .CE(DLY_adjp),                   // 1-bit input - Active high enable increment/decrement function
      //.CINVCTRL(CINVCTRL),       // 1-bit input - Dynamically inverts the Clock (C) polarity
      //.CLKIN(CLKIN),             // 1-bit input - Clock Access into the IODELAY
      //.CNTVALUEIN(CNTVALUEIN),   // 5-bit input - Counter value for loadable counter application
      //.DATAIN(DCH),          	 	// 1-bit input - Internal delay data
      .IDATAIN(DCH),         // 1-bit input - Delay data input
      .INC(DLY_inc),                 // 1-bit input - Increment / Decrement tap delay
      //.ODATAIN(ODATAIN),         // 1-bit input - Data input for the output datapath from the device
      .RST(rst_IODw)                 // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
                                 // ODELAY_VALUE tap. If no value is specified, the default is 0.
      //.T(T)                      // 1-bit input - 3-state input control. Tie high for input-only or internal delay or
                                 // tie low for output only.
   );

   (* IODELAY_GROUP = IODELAY_GRP *)
	ISERDESE1 #(
      .DATA_RATE("SDR"),           // "SDR" or "DDR" 
      .DATA_WIDTH(6),              // Parallel data width (2-8, 10)
      .DYN_CLKDIV_INV_EN("FALSE"), // Enable DYNCLKDIVINVSEL inversion (TRUE/FALSE)
      .DYN_CLK_INV_EN("FALSE"),    // Enable DYNCLKINVSEL inversion (TRUE/FALSE)
      // INIT_Q1 - INIT_Q4: Initial value on the Q outputs (0/1)
      .INIT_Q1(1'b0),
      .INIT_Q2(1'b0),
      .INIT_Q3(1'b0),
      .INIT_Q4(1'b0),
      .INTERFACE_TYPE("NETWORKING"),   // "MEMORY", "MEMORY_DDR3", "MEMORY_QDR", "NETWORKING", or "OVERSAMPLE" 
      .IOBDELAY("IFD"),           // "NONE", "IBUF", "IFD", "BOTH" 
      .NUM_CE(1),                  // Number of clock enables (1 or 2)
      .OFB_USED("FALSE"),          // Select OFB path (TRUE/FALSE)
      .SERDES_MODE("MASTER"),      // "MASTER" or "SLAVE" 
      // SRVAL_Q1 - SRVAL_Q4: Q output values when SR is used (0/1)
      .SRVAL_Q1(1'b0),
      .SRVAL_Q2(1'b0),
      .SRVAL_Q3(1'b0),
      .SRVAL_Q4(1'b0) 
   )
   ISERDESE1_DCHp (
      .O(DCHn),                       // 1-bit Combinatorial output
      // Q1 - Q6: 1-bit (each) Registered data outputs
		.Q1(des_DCH[10]),  //beh-2		// 1-bit registered SERDES output
		.Q2(des_DCH[8]),  //beh-0		// 1-bit registered SERDES output
		.Q3(des_DCH[6]),  //beh-10		// 1-bit registered SERDES output
		.Q4(des_DCH[4]), //beh-8		// 1-bit registered SERDES output
		.Q5(des_DCH[2]),  //beh-6		// 1-bit registered SERDES output
		.Q6(des_DCH[0]),  //beh-4		// 1-bit registered SERDES output
      // Width Expansion Ports: 1-bit (each) ISERDESE1 data width expansion connectivity
      //.SHIFTOUT1(SHIFTOUT1),
      //.SHIFTOUT2(SHIFTOUT2),
      .BITSLIP(bitsleepp),           // 1-bit Bitslip enable input
      // CE1, CE2: 1-bit (each) Data register clock enable inputs
      .CE1(1'b1),
      // Clocks: 1-bit (each) ISERDESE1 clock input ports
      .CLK(DCO),                   // 1-bit High-speed clock input
      //.CLKB(CLKB),                 // 1-bit High-speed secondary clock input
      .CLKDIV(FCO),             // 1-bit Divided clock input
      //.OCLK(OCLK),                 // 1-bit High speed output clock input used when INTERFACE_TYPE="MEMORY" 
      // Dynamic Clock Inversions: 1-bit (each) Dynamic clock inversion pins to switch clock polarity
      //.DYNCLKDIVSEL(DYNCLKDIVSEL), // 1-bit Dynamic CLKDIV inversion input
      //.DYNCLKSEL(DYNCLKSEL),       // 1-bit Dynamic CLK/CLKB inversion input
      // Input Data: 1-bit (each) ISERDESE1 data input ports
      .D(DCH),                       // 1-bit Data input
      .DDLY(DCHpd),                 // 1-bit Serial input data from IODELAYE1
      .RST(rst_ISERDw)             // 1-bit Active high asynchronous reset input
   );

// ISERDES N
   // Bloque de retardo - N
	(* IODELAY_GROUP = IODELAY_GRP *)
	IODELAYE1 #(
      //.CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion ("TRUE"/"FALSE") 
      .DELAY_SRC("DATAIN"),                 // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
      .HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
      .IDELAY_TYPE("VARIABLE"),         // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
      .IDELAY_VALUE(0),                // Input delay tap setting (0-32)
      //.ODELAY_TYPE("FIXED"),           // "FIXED", "VARIABLE", or "VAR_LOADABLE" 
      //.ODELAY_VALUE(0),                // Output delay tap setting (0-32)
      .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz
      .SIGNAL_PATTERN("DATA")          // "DATA" or "CLOCK" input signal
   )
   IODELAYE1_DCHn (
      //.CNTVALUEOUT(CNTVALUEOUT), // 5-bit output - Counter value for monitoring purpose
      .DATAOUT(DCHnd),         		// 1-bit output - Delayed data output
      .C(FCO),                     // 1-bit input - Clock input
      .CE(DLY_adjn),                   // 1-bit input - Active high enable increment/decrement function
      //.CINVCTRL(CINVCTRL),       // 1-bit input - Dynamically inverts the Clock (C) polarity
      //.CLKIN(CLKIN),             // 1-bit input - Clock Access into the IODELAY
      //.CNTVALUEIN(CNTVALUEIN),   // 5-bit input - Counter value for loadable counter application
      .DATAIN(DCHn),          	 	// 1-bit input - Internal delay data
      //.IDATAIN(DCH),         // 1-bit input - Delay data input
      .INC(DLY_inc),                 // 1-bit input - Increment / Decrement tap delay
      //.ODATAIN(ODATAIN),         // 1-bit input - Data input for the output datapath from the device
      .RST(rst_IODw)                 // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
                                 // ODELAY_VALUE tap. If no value is specified, the default is 0.
      //.T(T)                      // 1-bit input - 3-state input control. Tie high for input-only or internal delay or
                                 // tie low for output only.
   );

   (* IODELAY_GROUP = IODELAY_GRP *)
	ISERDESE1 #(
      .DATA_RATE("SDR"),           // "SDR" or "DDR" 
      .DATA_WIDTH(6),              // Parallel data width (2-8, 10)
      .DYN_CLKDIV_INV_EN("FALSE"), // Enable DYNCLKDIVINVSEL inversion (TRUE/FALSE)
      .DYN_CLK_INV_EN("FALSE"),    // Enable DYNCLKINVSEL inversion (TRUE/FALSE)
      // INIT_Q1 - INIT_Q4: Initial value on the Q outputs (0/1)
      .INIT_Q1(1'b0),
      .INIT_Q2(1'b0),
      .INIT_Q3(1'b0),
      .INIT_Q4(1'b0),
      .INTERFACE_TYPE("NETWORKING"),   // "MEMORY", "MEMORY_DDR3", "MEMORY_QDR", "NETWORKING", or "OVERSAMPLE" 
      .IOBDELAY("IFD"),           // "NONE", "IBUF", "IFD", "BOTH" 
      .NUM_CE(1),                  // Number of clock enables (1 or 2)
      .OFB_USED("FALSE"),          // Select OFB path (TRUE/FALSE)
      .SERDES_MODE("MASTER"),      // "MASTER" or "SLAVE" 
      // SRVAL_Q1 - SRVAL_Q4: Q output values when SR is used (0/1)
      .SRVAL_Q1(1'b0),
      .SRVAL_Q2(1'b0),
      .SRVAL_Q3(1'b0),
      .SRVAL_Q4(1'b0) 
   )
   ISERDESE1_DCHn (
      //.O(DCHn),                       // 1-bit Combinatorial output
      // Q1 - Q6: 1-bit (each) Registered data outputs
      .Q1(des_DCH[11]),  				// 1-bit registered SERDES output
      .Q2(des_DCH[9]),  				// 1-bit registered SERDES output
      .Q3(des_DCH[7]),  				// 1-bit registered SERDES output
      .Q4(des_DCH[5]), 					// 1-bit registered SERDES output
      .Q5(des_DCH[3]),  				// 1-bit registered SERDES output
      .Q6(des_DCH[1]),  				// 1-bit registered SERDES output
      // Width Expansion Ports: 1-bit (each) ISERDESE1 data width expansion connectivity
      //.SHIFTOUT1(SHIFTOUT1),
      //.SHIFTOUT2(SHIFTOUT2),
      .BITSLIP(bitsleepn),           // 1-bit Bitslip enable input
      // CE1, CE2: 1-bit (each) Data register clock enable inputs
      .CE1(1'b1),
      // Clocks: 1-bit (each) ISERDESE1 clock input ports
      .CLK(DCO),                   // 1-bit High-speed clock input
      //.CLKB(CLKB),                 // 1-bit High-speed secondary clock input
      .CLKDIV(FCO),             // 1-bit Divided clock input
      //.OCLK(OCLK),                 // 1-bit High speed output clock input used when INTERFACE_TYPE="MEMORY" 
      // Dynamic Clock Inversions: 1-bit (each) Dynamic clock inversion pins to switch clock polarity
      //.DYNCLKDIVSEL(DYNCLKDIVSEL), // 1-bit Dynamic CLKDIV inversion input
      //.DYNCLKSEL(DYNCLKSEL),       // 1-bit Dynamic CLK/CLKB inversion input
      // Input Data: 1-bit (each) ISERDESE1 data input ports
      //.D(D),                       // 1-bit Data input
      .DDLY(DCHnd),                 // 1-bit Serial input data from IODELAYE1
      .RST(rst_ISERDw)             // 1-bit Active high asynchronous reset input
   );

// Circuito monitorización de la captura de datos serie
// Compara la salida SHIFTOUT2 de cada ISERDES con un patrón y
// registra el resultado
wire		DCH_ok, DCHp_cmpout, DCHn_cmpout;

// Señales de comparación de patrones
assign 	DCHp_cmpout = ((des_DCH[0]  == DCH_pttn[0]) &
								(des_DCH[2]  == DCH_pttn[2]) &
								(des_DCH[4]  == DCH_pttn[4]) &
								(des_DCH[6]  == DCH_pttn[6]) &
								(des_DCH[8]  == DCH_pttn[8]) &
								(des_DCH[10] == DCH_pttn[10])) ? 1'b1:1'b0;
								
assign 	DCHn_cmpout = ((des_DCH[1]  == DCH_pttn[1]) &
								(des_DCH[3]  == DCH_pttn[3]) &
								(des_DCH[5]  == DCH_pttn[5]) &
								(des_DCH[7]  == DCH_pttn[7]) &
								(des_DCH[9]  == DCH_pttn[9]) &
								(des_DCH[11] == DCH_pttn[11])) ? 1'b1:1'b0;


assign 	DCH_ok = DCH_okp & DCH_okn;


always @(posedge FCO or negedge rstb)
	begin
		if (!rstb)
		begin
			DCH_okp 	<= 1'b0;
			DCH_okn 	<= 1'b0;
			
			ramp1	  	<= 12'h000;
			ramp2	  	<= 12'h000;
		end
		else
		begin
			DCH_okp 	<= DCHp_cmpout;
			DCH_okn 	<= DCHn_cmpout;
			
			ramp2		<= des_DCH;
			ramp1		<= ramp2;
		end
	end
	
// FSMs para el control de la función BITSLEEP de los ISERDES	
	Bitsleep_Ctrl Bitsleep_Ctrln (
		.init(BS_init), 
		.DCH_ok(DCH_okn), 
		.rstb(rstb),.clk(FCO), 
		.bitsleep(bitsleepn), 
		.run(BS_confrunn));
		
	Bitsleep_Ctrl Bitsleep_Ctrlp (
		.init(BS_init), 
		.DCH_ok(DCH_okp), 
		.rstb(rstb),.clk(FCO), 
		.bitsleep(bitsleepp), 
		.run(BS_confrunp));
		
	assign	BS_confrun =  BS_confrunp | BS_confrunn;

endmodule