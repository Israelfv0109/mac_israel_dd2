`timescale 1ns/1ps

module tb_wishbone;

    localparam AW = 16;
    localparam DW = 32;

    logic clk;
    logic rst_n;

    // Señales de Control del Maestro
    logic [AW-1:0] m0_cmd_addr;
    logic [DW-1:0] m0_cmd_wdata;
    logic          m0_cmd_we;
    logic          m0_cmd_valid;
    logic          m0_cmd_ready;
    logic [DW-1:0] m0_rsp_rdata;
    logic          m0_rsp_valid;

    // Bus Wishbone
    logic [AW-1:0] wb_adr;
    logic [DW-1:0] wb_dat_m2s; // Data de Maestro a Esclavo (Master-to-Slave)
    logic [DW-1:0] wb_dat_s2m; // Data de Esclavo a Maestro (Slave-to-Master)
    logic          wb_we;
    logic [3:0]    wb_sel;
    logic          wb_stb;
    logic          wb_cyc;
    logic          wb_ack;
    logic          wb_err;

    logic [DW-1:0] reg_out;
    logic [DW-1:0] read_data; // Para guardar lo que leemos en el TB

    // Generación de Reloj
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Reloj de 100MHz (10ns periodo)
    end
 
    // ---- Master 0 ----
    wb_master #(.AW(AW), .DW(DW)) u_m0 (
        .clk         (clk),
        .rst_n       (rst_n),
        .cmd_addr    (m0_cmd_addr),
        .cmd_wdata   (m0_cmd_wdata),
        .cmd_we      (m0_cmd_we),
        .cmd_valid   (m0_cmd_valid),
        .cmd_ready   (m0_cmd_ready),
        .rsp_rdata   (m0_rsp_rdata),
        .rsp_valid   (m0_rsp_valid),
        // Conexión al Bus Wishbone
        .wbm_adr_o   (wb_adr),
        .wbm_dat_o   (wb_dat_m2s),
        .wbm_dat_i   (wb_dat_s2m),
        .wbm_we_o    (wb_we),
        .wbm_sel_o   (wb_sel),
        .wbm_stb_o   (wb_stb),
        .wbm_cyc_o   (wb_cyc),
        .wbm_ack_i   (wb_ack),
        .wbm_err_i   (wb_err)
    );
 
    // ---- Slave 0 — wb_reg ----
    wb_mac #(.AW(AW), .DW(DW)) u_mac_slave (
        .clk       (clk),
        .rst_n     (rst_n),
        // Conexión al Bus Wishbone
        .wbs_adr_i (wb_adr),
        .wbs_dat_i (wb_dat_m2s),
        .wbs_dat_o (wb_dat_s2m),
        .wbs_we_i  (wb_we),
        .wbs_sel_i (wb_sel),
        .wbs_stb_i (wb_stb),
        .wbs_cyc_i (wb_cyc),
        .wbs_ack_o (wb_ack),
        .wbs_err_o (wb_err)
    );
 
    // ---- M0 write ----
    task automatic m0_write(
        input logic [AW-1:0] addr,
        input logic [DW-1:0] data
    );
        $display("[%0t ns] M0 WR  addr=0x%04h  data=0x%08h  (sending command)",
                 $time, addr, data);
        @(posedge clk);
        while (!m0_cmd_ready) @(posedge clk);
        m0_cmd_addr  <= addr;
        m0_cmd_wdata <= data;
        m0_cmd_we    <= 1'b1;
        m0_cmd_valid <= 1'b1;
        @(posedge clk);
        m0_cmd_valid <= 1'b0;
        while (!m0_rsp_valid) @(posedge clk);
        $display("[%0t ns] M0 WR  addr=0x%04h  ACK received", $time, addr);
    endtask
 
    // ---- M0 read ----
    task automatic m0_read(
        input  logic [AW-1:0] addr,
        output logic [DW-1:0] data
    );
        $display("[%0t ns] M0 RD  addr=0x%04h  (sending command)", $time, addr);
        @(posedge clk);
        while (!m0_cmd_ready) @(posedge clk);
        m0_cmd_addr  <= addr;
        m0_cmd_wdata <= '0;
        m0_cmd_we    <= 1'b0;
        m0_cmd_valid <= 1'b1;
        @(posedge clk);
        m0_cmd_valid <= 1'b0;
        while (!m0_rsp_valid) @(posedge clk);
        data = m0_rsp_rdata;
        $display("[%0t ns] M0 RD  addr=0x%04h  data=0x%08h  ACK received",
                 $time, addr, data);
    endtask
 
    always @(posedge clk) begin
    // Slave 0
        if (wb_stb && wb_cyc)
            $display("[%0t ns]   BUS M0->S0 %-2s  adr=0x%04h  wdat=0x%08h  sel=%04b",
                     $time, wb_we ? "WR" : "RD", wb_adr, wb_dat_m2s, wb_sel);
        if (wb_ack)
            $display("[%0t ns]   BUS S0->M0 ACK  rdat=0x%08h", $time, wb_dat_s2m);
    end

// Secuencia de Simulación
initial begin
        $display(" Iniciando Simulación Wishbone");

        // Valores iniciales
        m0_cmd_valid = 0;
        m0_cmd_we    = 0;
        m0_cmd_addr  = '0;
        m0_cmd_wdata = '0;
        
        // Reset del sistema
        rst_n = 0;
        #20ns rst_n = 1;
        #10ns;

        // Escribir Operando M (15) en dirección 0x00
        m0_write(16'h0000, 32'd15);
        
        // Escribir Operando Q (10) en dirección 0x04
        m0_write(16'h0004, 32'd10);
        
        // Dar señal de Start escribiendo 1 en dirección 0x08
        m0_write(16'h0008, 32'd1);

        // Esperar a que la MAC termine (Polling al Ready en 0x0C)
        read_data = 0;
        while (read_data == 0) begin
            m0_read(16'h000C, read_data);
        end
        $display("MAC termino operacion");

        // Leer el resultado (Parte baja) en dirección 0x10
        m0_read(16'h0010, read_data);
        
        // Verificación Automática (15 * 10 = 150)
        if (read_data == 32'd150)
            $display("PASS: El resultado de la MAC es correcto (150).");
        else
            $error("FAIL: Esperaba 150, recibi %0d", read_data);
        $finish;
    end

endmodule