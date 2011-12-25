use v6;

class Header {
    has Str $.file_type;                       # 2bytes
    has Int $.file_size;                       # 4bytes
    has Int $.reserved_1;                      # 2bytes
    has Int $.reserved_2;                      # 2bytes
    has Int $.image_data_offset;               # 4bytes
    has Int $.header_size;                     # 4bytes
    has Int $.width;                           # 4bytes
    has Int $.height;                          # 4bytes
    has Int $.plane;                           # 2bytes
    has Int $.bits_per_pixel;                  # 2bytes
    has Int $.compress_type;                   # 4bytes
    has Int $.image_data_size;                 # 4bytes
    has Int $.horizontal_pixels_per_meter;     # 4bytes
    has Int $.vertical_pixels_per_meter;       # 4bytes
    has Int $.color_index;                     # 4bytes
    has Int $.important_index;                 # 4bytes

    multi method new (Int $width, Int $height) {
        my $size = $width * 3 * $height;
        if (my $remainder = ($width * 3) % 4) {
            $size += (4 - $remainder) * $height;
        }

        self.bless(*,
                   file_type => "BM",
                   file_size => 14 + 40 + $size,
                   reserved_1 => 0,
                   reserved_2 => 0,
                   image_data_offset => 14 + 40,
                   header_size => 40,
                   width => $width,
                   height => $height,
                   plane => 1,
                   bits_per_pixel => 24,
                   compress_type => 0,
                   image_data_size => $size,
                   horizontal_pixels_per_meter => 0,
                   vertical_pixels_per_meter => 0,
                   color_index => 0,
                   important_index => 0);
    }

    multi method pack (Int $i, Int $size) {
        return $i.fmt("%0" ~ $size*2 ~ "x").flip.comb(/../).map({("0x"~$_.flip).Int});
    }

    multi method pack (Str $s) {
        return $s.comb.map({.ord});
    }

    method dump () {
        return Buf.new((self.pack($!file_type),
                        self.pack($!file_size, 4),
                        self.pack($!reserved_1, 2),
                        self.pack($!reserved_2, 2),
                        self.pack($!image_data_offset, 4),
                        self.pack($!header_size, 4),
                        self.pack($!width, 4),
                        self.pack($!height, 4),
                        self.pack($!plane, 2),
                        self.pack($!bits_per_pixel, 2),
                        self.pack($!compress_type, 4),
                        self.pack($!image_data_size, 4),
                        self.pack($!horizontal_pixels_per_meter, 4),
                        self.pack($!vertical_pixels_per_meter, 4),
                        self.pack($!color_index, 4),
                        self.pack($!important_index, 4)).flat
                    );
    }
}

class Bitmap:auth<VienosNotes>:version<1.01> {

    has @.pixels;
    has Header $.header;

    method new (Int $width where { $_ > 0 } , Int $height where { $_ != 0 }) {
        my @pixels;
        @pixels.push([]) for ^$height;
        self.bless(*, pixels => @pixels, header => Header.new($width, $height));
    }

    method write (Str $file) {
        my $target = open $file, :w, :bin;
        $target.write($!header.dump);

        for @!pixels -> @line {
            my $buf = Buf.new(@line.map({$_.flat}));
            $target.write($buf);
            my $remainder = ($!header.width * 3) % 4;
            if ($remainder != 0) {
                $target.write(Buf.new(0)) for ^(4-$remainder);
            }
        }
        $target.close;
    }

    method getpixel (Int $x where { 0 <= $_ < $!header.width }, Int $y where { 0 <= $_ < $!header.height.abs } ) {
        return @!pixels[$y][$x];
    }

    method setpixel (Int $x where { 0 <= $_ < $!header.width }, Int $y where { 0 <= $_ < $!header.height.abs },
                     Int $b where { $_ ~~ 0..255 } , Int $g where { $_ ~~ 0..255 }, Int $r where { $_ ~~ 0..255 }) {
        @!pixels[$y][$x] = ($b, $g, $r);
    }

    multi method fill (Int $b where { $_ ~~ 0..255 }, Int $g where { $_ ~~ 0..255 }, Int $r where { $_ ~~ 0..255 }) {
        for (^$!header.height) -> $y {
            for (^$!header.width) -> $x {
                @!pixels[$y][$x] = ($b, $g, $r);
            }
        }
    }

    multi method fill () {
        for (^$!header.height) -> $y {
            for (^$!header.width) -> $x {
                @!pixels[$y][$x] = (0, 0, 0);
            }
        }
    }
}
