package mac_pkg;
    // Clase Base: Generador Random
    class random_gen;
        rand bit signed [`MAC_DATA_WIDTH-1:0] a, b;
        constraint data_range { 
            a inside {[`MAC_MAX_NEG : `MAC_MAX_POS]}; 
            b inside {[`MAC_MAX_NEG : `MAC_MAX_POS]}; 
        }
    endclass

    // Clase para Corners (Test 4, 5) Distribución Ponderada
    class random_gen_corners extends random_gen;
        constraint c_zeros { 
           a dist {0:=20, `MAC_MAX_POS:=20, `MAC_MAX_NEG:=20, [1:`MAC_MAX_POS-1]:/20, [`MAC_MAX_NEG+1:-1]:/20};
            b dist {0:=20, `MAC_MAX_POS:=20, `MAC_MAX_NEG:=20, [1:`MAC_MAX_POS-1]:/20, [`MAC_MAX_NEG+1:-1]:/20};
	    //el diagonal distribuye en partes iguales
        }
    endclass
endpackage
