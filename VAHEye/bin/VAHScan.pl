 #!/usr/bin/perl
use 5.016;

use strict;
use warnings;
use DDP;

our $exp = 'Origin';

#our $exp = 'Exele';

our @need = [];

# Ключи это время, Значения -значения
# Ещё один ключ avg для среднего значения по всей осциллограмме
our %osc = ();

our ($ICH, $VCH) = (3, 1);
our $length = 100;

our ( $stALL, $finALL ) = ( 'ALL0015', 'ALL0015' );

my $folderpath = $ARGV[0];
die "USAGE:\n$0 filepath\n" unless $folderpath;
die "Way '$folderpath' not found\n" unless -d $folderpath;

my $parsed_data = parse_files($folderpath);
report($parsed_data);

exit;

sub parse_files {
    my $folder     = shift;
    #my $width_pick = 1;       #nm
    my ($Time, $deltamin, $I, $V, $cmin, $cmax);
    my $result;               # Ссылка на хеш

    for my $i ( $stALL .. $finALL ) {

        # Пробегаем по трём файла спектра
        for my $j ( $VCH, $ICH ) {
            my $way = "$folder/$i/" . "F0015CH$j.CSV";
            open my $fd, "<", "$way" or die "Can't open '$way': $!";

            my $k = 0;
            my $s = 0;

            $Time = 0;



            while ( my $log_line = <$fd> ) {

                #say "$log_line";
                next
                  unless $log_line =~
                  /^\w*,[\w+:]*,,\s*-?([.\d]*),\s*-?([.\d]*),$/;

                #      say $log_line;
                #      say "$Wave $Sample";
                $Time++;
                $osc{"$Time"} = $2;

                $k++;
                $s += $2;



            }

            $osc{avg} = $s / $Time;

            close $fd;

            my $avg100;
            my $sum100 = 0;

            for my $n (1..$Time) {

                if (undef $cmin
                      or $cmin > $osc{$n}) {
                    $cmin = $osc{$n};
                }

                if (undef $cmax
                      or $cmax < $osc{$n}) {
                    $cmax = $osc{$n};
                }

                my $csum100 += $osc{$n};

                if ($n > 100) {
                    $csum100 -= $osc{$n-100};
                }

                if ($cmin > $osc{avg}) {
                    if ($n == 100) {
                        $deltamin = $cmax - $cmin;
                    }
                    if ($n > 99 and $cmax - $cmin < $deltamin) {
                        $sum100 = $csum100;
                    }
                }


            }

            if ($j == $ICH) {
                $I = $sum100 / 100;
            }
            if ($j == $VCH) {
                $V = $sum100 / 100;
            }


        }

        $result->{$I} = $V;
    }

    #  p %{$result};
    return $result;

}

sub report {
    my $result = shift;

    open my $fo, ">$folderpath/output.txt"
      or die "Не создаётся файл вывода: $!\n";

    say "I\tV";
    say "mA\tV";

    say $fo "I\tV";
    say $fo "mA\tV";

    say "X\tY";
    say $fo "X\tY";

    for my $X ( sort { $a <=> $b } keys %{$result} ) {
        say "$X\t" . $result->{$X};
        say $fo "$X\t" . $result->{$X};
    }
    close $fo;
}
