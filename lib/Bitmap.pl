use v6;

class Bitmap:auth<VienosNotes>:version<0.01> {

    has IO $!file;
    has %!header;
    has $!w_count;
    has $!h_count;
    has $!remainder;
    has $!template;

    method new (Str $filename = "./output.bmp") {
        self.bless(*, w_count => 0, h_count => 0, file => open($filename, :w, :bin));
    }

    method make_header (Int $width, Int $height) {

        my $size = $width * 3 * $height;
        if ($!remainder = ($width * 3) % 4) {
            $size += (4 - $!remainder) * $height;
        }

        %!header = { filetype => "BM",
                     filesize => 14 + 40 + $size,
                     pre1 => 0,
                     pre2 => 0,
                     offset => 14 + 40,
                     header_size => 40,
                     width => $width,
                     height => -$height,
                     plane => 1,
                     bits_per_pixel => 24,
                     compress_type => 0,
                     image_data_size => $size,
                     horizontal_res => 0,
                     vertical_res => 0,
                     color_index => 0,
                     imp_index => 0
        };

        $!template = "C" x (%!header{"width"} * 3);
    }

    method print_header {
        $!file.write(pack "A2LSSLLLLSSLLLLLL", %!header.values);
    }

    method push_line (@line) {

        $!file.write(pack $!template, |@line);
        if ($!remainder != 0) {
            $!file.write(pack "C", 0) for ^(4-$!remainder);
        }

    }

    method close {
        $!file.close;
    }

}

