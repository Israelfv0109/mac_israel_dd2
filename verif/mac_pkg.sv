package mac_pkg;
    // Clase Base: Generador Random
    class random_gen;
        rand bit signed [15:0] a, b;
        constraint data_range { a inside {[-32768:32767]}; b inside {[-32768:32767]}; }
    endclass

    // Clase para Sanity (Test 1, 2, 3)
    class random_gen_small extends random_gen;
        constraint data_range { a inside {[-50:50]}; b inside {[-10:10]}; }
    endclass

    // Clase para Corners (Test 4, 5) Distribución Ponderada
    class random_gen_corners extends random_gen;
        constraint c_zeros { 
            a dist {0:=50, 32767:=10, -32768:=10, [-100:100]:=30};
            b dist {0:=50, 32767:=10, -32768:=10, [-100:100]:=30};
        }
    endclass
endpackage