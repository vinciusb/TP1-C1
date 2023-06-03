class Point {
    x : Int;
    y : Int;

    init(x_init : Int, y_init : Int) : Point {
        {
            x <- x_init;
            y <- y_init;
            self
        }
    };

    getX() : Int {
        x
    };

    getY() : Int {
        y
    };

    setX(new_x : Int) : Point {
        {
            x <- new_x;
            self
        }
    };

    setY(new_y : Int) : Point {
        {
            y <- new_y;
            self
        }
    };
};

class Main {
    main() : Object {
        let p : Point <- Point(3, 4) in
        {
            out_string("Initial coordinates: (");
            out_int(p.getX());
            out_string(", ");
            out_int(p.getY());
            out_string(")\n");

            p.setX(5);
            p.setY(6);

            out_string("New coordinates: (");
            out_int(p.getX());
            out_string(", ");
            out_int(p.getY());
            out_string(")\n");
        }
    };
};