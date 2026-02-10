interface mac_if (
  input logic clk,
  input logic rst_n
);

  // --- Señales del Bus (Conectadas al DUT) ---
  // Inputs del DUT
  logic start;
  logic [DATA_WIDTH-1:0] m_in;
  logic [DATA_WIDTH-1:0] q_in;
  
  // Outputs del DUT
  logic [ACC_WIDTH-1:0]  product; 
  logic ready;

  // TAREA 1: Inicialización (Reset de bus)
  task automatic initialize();
    start = 1'b0;
    m_in  = '0;
    q_in  = '0;
    repeat (1) @(posedge clk);
  endtask

  // TAREA 2: Calcular (Driver)
  // Esta tarea pone los datos, da el start, y espera a que termine.
  task automatic compute(input logic [DATA_WIDTH-1:0] val_m, input logic [DATA_WIDTH-1:0] val_q);
    
    // 1. Poner datos y levantar start
    @(posedge clk); 
    start <= 1'b1;
    m_in  <= val_m;
    q_in  <= val_q;

    // 2. Bajar start al siguiente ciclo (Pulso de 1 ciclo)
    @(posedge clk);
    start <= 1'b0;

    // 3. Esperar a que el DUT termine (Polling de 'ready')
    wait(ready == 1'b1);
    
    // 4. Ciclo extra de cortesía
    repeat(2)
    @(posedge clk);
  endtask

endinterface