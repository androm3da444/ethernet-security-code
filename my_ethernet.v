module my_ethernet( // module and port declaration: fill the gaps
	// Clock
	input clk_clk,
	
	// KEY (reset)
	input   KEY,
	
	//LED
	output led,
	 
	//Switch
	input switch,
	
	// Ethernet : the signals used are: the RGMII transmit clock, the MDC reference, the MDIO, the hardware reset, the RGMII receive clock, the receive data, the receive data valid, the transmit data and the transmit enable (check the manual)
	output   ENET_GTX_CLK,
	output  ENET_MDC     ,
	inout   ENET_MDIO,
	output  ENET_RST_N     ,
	input  ENET_RX_CLK       ,
	input  [3: 0] ENET_RX_DATA,
	input   ENET_RX_DV      ,
	output [3: 0] ENET_TX_DATA,
	output  ENET_TX_EN      
);
	// Defining the varibales 
	wire sys_clk, clk_125, clk_25, clk_2p5, tx_clk,clk_125_90, clk_25_90, clk_2p5_90;
	wire core_reset_n;
	wire mdc, mdio_in, mdio_oen, mdio_out;
	wire eth_mode, ena_10;


	// Assign MDIO and MDC signals
	
	assign mdio_in   = ENET_MDIO;
	assign ENET_MDC  = mdc;
	assign ENET_MDIO = mdio_oen ? 1'bz : mdio_out;
	
	//Assign reset
	
	assign ENET_RST_N = core_reset_n;
	
	//PLL instance
	
	my_pll pll_inst(
		.areset	(~KEY),
		.inclk0	(clk_clk),
		.c0		(sys_clk),
		.c1		(clk_125),
		.c2		(clk_25),
		.c3		(clk_2p5),
		.locked	(core_reset_n)
	); 
	
	
	// New PLL instance for 90deg phase shift in the clocks
	
	my_new_pll pll_clocks_PHY(
	.inclk0 (clk_clk),
	.c0 (clk_125_90),
	.c1 (clk_25_90),
	.c2 (clk_2p5_90)
	);
	
	
	
	// Clock for transmission
	
	//assign tx_clk  as per operation mode      
	assign tx_clk =  eth_mode ?   clk_125 : ena_10 ? clk_2p5 : clk_25; // GbE Mode   = 125MHz clock
	                          
	// Assigning the appropriate clocks to 	ENET_GTX_CLK as per operation mode
	assign ENET_GTX_CLK = eth_mode ? clk_125_90 : // GbE Mode=125MHz clock
	ena_10 ? clk_2p5_90 : // 10Mb Mode=2.5MHz clock
	clk_25_90; // 100Mb Mode=25MHz clock

	
	
	
	// Nios II system instance
	
    my_nios system_inst (
        .clk_clk (sys_clk),                                            					//  system clock (input)
        .reset_reset_n  (core_reset_n),                      				      			//  system reset (input)
	.led_export (led),										// led (output)
	.switch_export (switch),										// swicht button (input)
        .tse_pcs_mac_tx_clock_connection_clk 	(tx_clk), 			//  transmit clock (input)
        .tse_pcs_mac_rx_clock_connection_clk 	(ENET_RX_CLK),		 		//  receive clock (input)
        .tse_mac_mdio_connection_mdc               (mdc),             		//  mdc (output)
        .tse_mac_mdio_connection_mdio_in         (mdio_in),           	//  mdio_in (input)
        .tse_mac_mdio_connection_mdio_out       (mdio_out),          	//  mdio_out (output)
        .tse_mac_mdio_connection_mdio_oen      (mdio_oen),     	     	//  mdio_oen (output)
        .tse_mac_rgmii_connection_rgmii_in         (ENET_RX_DATA),      			//  rgmii_in (rx data, input)
        .tse_mac_rgmii_connection_rgmii_out       (ENET_TX_DATA),	     			//  gmii_out (tx data, output)
        .tse_mac_rgmii_connection_rx_control      (ENET_RX_DV),      			//  rx_control (receive data valid, input)
        .tse_mac_rgmii_connection_tx_control      (ENET_TX_EN),      			//  tx_control (tx enable, output)
        .tse_mac_status_connection_eth_mode    (eth_mode),	                         //  eth_mode (output)
        .tse_mac_status_connection_ena_10        (ena_10),          	                //   ena_10	  (output)
    );	
    
    

endmodule 