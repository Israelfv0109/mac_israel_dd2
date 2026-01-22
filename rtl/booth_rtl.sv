/*******************************************************************************
 * MODULO: booth_stage
 5*1245
 ******************************************************************************/
//  Bloque de hardware de estados
module booth_stage #(  // Lista de parametros
    parameter DATA_WIDTH = 9               //multiplicador de 4 bits              
)(
    // --- ENTRADAS ---
    // Signed = Permite operaciones con numeros negativos
    input logic signed [DATA_WIDTH:0]     acumulador_in,           // Acumulador con guarda de OVF
    input logic signed [DATA_WIDTH-1:0]   q_reg_in,                // 
    input logic                           q_minus_1_in,
    input logic signed [DATA_WIDTH-1:0]   multiplicando_in,        //Multiplicando que se va heredando y pasa en cada etapa

    // --- SALIDAS ---
    output logic signed [DATA_WIDTH:0]     acumulador_out,
    output logic signed [DATA_WIDTH-1:0]   q_reg_out,
    output logic                           q_minus_1_out
);

    // Variable interna para guardar el resultado de la operacion suma/resta
    logic signed [DATA_WIDTH:0] acumulador_operado;

    // Logica de decision de Booth
    always_comb begin   // Bloque de procedimientos combinacionales, cada cambio de señal a la derecha del "=", ejecuta todo el bloque de nuevo
        case ({q_reg_in[0], q_minus_1_in})                                          // Multiplexor que evalua el vector concatenado
            2'b01:   acumulador_operado = acumulador_in + multiplicando_in;
            2'b10:   acumulador_operado = acumulador_in - multiplicando_in;
            default: acumulador_operado = acumulador_in;                        // No hace nada pasa el acomulador tal como llegó
        endcase
    end

    // Desplazamiento aritmetico a la derecha ">>>", mediante asignacion continua, como es aritmetrico no rellena con 0, preservando signo
    assign {acumulador_out, q_reg_out, q_minus_1_out} = signed'({acumulador_operado, q_reg_in, q_minus_1_in}) >>> 1;
    // El resultado se pasa a la siguiente iteracion

endmodule

/*******************************************************************************
 * MODULO: booth_multiplier
 ******************************************************************************/
 
//  Bloque de hardware de estados
// Modulo de estructura, solo crea instancias y las copia y manda
module booth_multiplier #(
    parameter DATA_WIDTH = 4                                        // Multiplicador de N x N bit, parametrizado
)(
    // --- ENTRADAS ---
    input logic signed [DATA_WIDTH-1:0]   multiplicando_in,         // Multiplicando
    input logic signed [DATA_WIDTH-1:0]   multiplicador_in,         // Multiplicador

    // --- SALIDAS ---
    output logic signed [2*DATA_WIDTH-1:0] resultado_out,           // Resultado de multiplicacion
    output logic                           flag_out                 // Bandera simple que indica "listo"
);

    // --- CABLES INTERNOS ---
    // Arreglo de CABLES para conectar las N etapas en cascada.
    logic signed [DATA_WIDTH:0]     acumulador_wire [0:DATA_WIDTH]; //ex acumulador_wire[0] va a estacion 1, acumulador_wire[1] de estacion 1 a la 2
    logic signed [DATA_WIDTH-1:0]   q_wire [0:DATA_WIDTH];
    logic                           q_minus_1_wire [0:DATA_WIDTH];

    // --- LOGICA DE INICIALIZACION (CONEXIONES INICIALES)
    assign acumulador_wire[0] = '0;                                 // Se instancia el acumulador con 0 para iniciar el proceso
    assign q_wire[0]          = multiplicador_in;                   // Le hacemos una copia al multiplicador
    assign q_minus_1_wire[0]  = 1'b0;                               // A q-1, le instanciamos un 0 para iniciar el proceso

    // --- GENERACION DE LAS ETAPAS ---
    
    genvar i;                       // Variable para el bucle generate for
    generate
        // Cada iteracion por el for va a crear una copia del bloque por proceso
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin: STAGE_INSTANCE
            
            booth_stage #(                              // Modulo
                .DATA_WIDTH(DATA_WIDTH)                 // Parametro al modulo hijo (como herencia)
            ) stage_instance (                          // Nombre para copia en cada iteracion
            // Conexión por nombre. Conecta el puerto
            // (.puerto_hijo(cable_padre))
                .acumulador_in(acumulador_wire[i]),     // acumulador_in del booth_stage al cable acumulador_wire[i]
                .q_reg_in(q_wire[i]),                   
                .q_minus_1_in(q_minus_1_wire[i]),
                .multiplicando_in(multiplicando_in),    //Siempre mando el mismo M

                .acumulador_out(acumulador_wire[i+1]),
                .q_reg_out(q_wire[i+1]),
                .q_minus_1_out(q_minus_1_wire[i+1])
            );
        end
    endgenerate

    // --- ASIGNACION DE SALIDAS
    // El resultado final es la salida de la ultima etapa
    assign resultado_out = {acumulador_wire[DATA_WIDTH][DATA_WIDTH-1:0], q_wire[DATA_WIDTH]}; //mandamos el acumulador de la ultima estacion 
    assign flag_out      = 1'b1; // Como es combinacional, el resultado siempre esta listo.

endmodule