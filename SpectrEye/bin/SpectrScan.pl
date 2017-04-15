#!/usr/bin/perl
use 5.016;

use strict;
use warnings;
use DDP;

our @need = [];

our %elmnts = (
    'N2+' => { '391.5'  => 1,  '427.8' => 1, },
    N2    => { '380.42' => 10, '337.1' => 100, },
    N     => { '648.4'  => 100, },
    'N+'  => { '566.67' => 100, },
#    'Ar+' => { '488.0'  => 100, },
#    Ar    => { '696.4'  => 100, },
#    He => { '587.52' => 10, }
    Halpha => { '656.013' => 10, },
);

our $width_pick = 1;  #nm
our ( $prg, $scg ) = ( 'N2', 'H2' );    #primary and secondory gas

our $countel = 7;                       # Количество линий
our $min = 0;

my $folderpath = $ARGV[0];
die "USAGE:\n$0 filepath\n" unless $folderpath;
die "Way '$folderpath' not found\n" unless -d $folderpath;

my $parsed_data = parse_files($folderpath);
report($parsed_data);

exit;

sub parse_files {
    my $folder     = shift;
         #nm
    my ( $Wave, $Sample, $Dark, $Reference );

    my $result;               # Ссылка на хеш

    # Пробегаем по процентному содержания $prg
    for ( my $i = 0 ; $i <= 10 ; $i++ ) {

        # Пробегаем по трём файла спектра
        for ( my $j = 1 ; $j <= 3 ; $j++ ) {
            my $way = "$folder/$i" . "0_151016$j" . "U1.TXT";

            open my $fd, "<", "$way" or die "Can't open '$way': $!";

            my $k = 0;

            while ( my $log_line = <$fd> ) {
                $k++;

                #say "$log_line";
                next if ( $k < 9 );

                next
                  unless $log_line =~
                  /^ (\d{3}),(\d{2});\s*(-?\d+?),(\d+?);.+$/;

                #      say $log_line;
                $Wave   = $1 . "." . $2;
                $Sample = $3 . "." . $4;

                #      say "$Wave $Sample";
                $Wave   = 0 + $Wave;
                $Sample = 0 + $Sample;

                for my $el ( keys %elmnts ) {
                    for my $wav ( keys %{ $elmnts{$el} } ) {
                        if (    $Wave < $wav + $width_pick
                            and $wav - $width_pick < $Wave )
                        {
                            if ( exists $result->{ $i * 10 }{$el}{"$wav"} ) {
                                if ( $result->{ $i * 10 }{$el}{"$wav"} <
                                    $Sample )
                                {
                                    $result->{ $i * 10 }{$el}{"$wav"} = $Sample;

                                }
                            }
                            else {
                                $result->{ $i * 10 }{$el}{"$wav"} = $Sample;
                            }



                            #say $result->{$i*10}{$el}{"$wav"};
                        }
                    }
                }

            }

            close $fd;

        }
    }

    #  p %{$result};
    return $result;

}

sub report {
    my $result = shift;

    open my $foo, ">$folderpath/$prg+$scg($width_pick-nm)\_for_Origin.txt"
      or die "Не создаётся файл вывода: $!\n";

    open my $foe, ">$folderpath/$prg+$scg($width_pick-nm)\_for_Exele.txt"
      or die "Не создаётся файл вывода: $!\n";

    my $head1 = "ratio\tratio";
    my $headu = "$prg %\t$scg %";
    for ( 1 .. $countel ) {
        $head1 .= "\tInt";
        $headu .= "\ta.e.";
    }
    say $head1;
    say $headu;

    say $foo $head1;
    say $foo $headu;
    say $foe $head1;
    say $foe $headu;

    my $head2 = "$prg\t$scg";
    for my $el ( sort keys %elmnts ) {
        for my $wav ( sort keys %{ $elmnts{$el} } ) {
            $head2 .= "\t$el ($wav)";
            if ( $elmnts{$el}{"$wav"} > 1 ) {
                $head2 .= "*" . $elmnts{$el}{"$wav"};
            }
        }
    }
    say $head2;
    say $foo $head2;
    say $foe $head2;

    for my $rat ( keys %{$result} ) {
        for my $el ( keys %elmnts ) {
            for my $wav ( sort keys %{ $elmnts{$el} } ) {
                if ( $result->{$rat}{$el}{"$wav"} < $min ) {
                    $min = $result->{$rat}{$el}{"$wav"};
                }
            }
        }
    }

    for my $rat ( sort { $a <=> $b } keys %{$result} ) {
        my $body = "$rat\t" . ( 100 - $rat );
        for my $el ( sort keys %elmnts ) {
            for my $wav ( sort keys %{ $elmnts{$el} } ) {
                $body .= "\t";
                $body .= ( $result->{$rat}{$el}{"$wav"} - $min ) * $elmnts{$el}{"$wav"};
            }
        }
        say $body;
        say $foo $body;
        $body =~ s/\./\,/g;
        say $foe $body;
    }
    close $foo;
    close $foe;

    say "Файл заисан в файл $prg+$scg.txt $min";
}
