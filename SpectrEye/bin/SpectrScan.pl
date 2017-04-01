#!/usr/bin/perl
use 5.016;

use strict;
use warnings;
use DDP;

our $exp = 'Origin';
#our $exp = 'Exele';

our @need = [];

our %elmnts = (
    'N2+' => {'391.5' => 1, '427.8' => 1,},
     N2 => {'380.42' => 10, '337.1' => 100,},
     N => {'648.4' => 100,},
     'N+' => {'566.67' => 100,},
     'Ar+' => {'488.0' => 10, },
     Ar => {'696.4' => 1, },
);

our ($prg, $scg) = ('N2', 'Ar'); #primary and secondory gas

our $countel = 8; # Количество линий

my $folderpath = $ARGV[0];
die "USAGE:\n$0 filepath\n"  unless $folderpath;
die "Way '$folderpath' not found\n" unless -d $folderpath;

my $parsed_data = parse_files($folderpath);
report($parsed_data);

exit;

sub parse_files {
    my $folder = shift;
    my $width_pick = 1; #nm
    my ($Wave, $Sample, $Dark, $Reference);

    my $result;    # Ссылка на хеш

    # Пробегаем по процентному содержания $prg
    for ( my $i = 0; $i <= 10; $i++ ) {
      # Пробегаем по трём файла спектра
      for (my $j = 1; $j <= 3; $j++) {
        my $way = "$folder/$i" . "0_151016$j" . "U1.TXT";


        open my $fd, "<", "$way" or die "Can't open '$way': $!";

        my $k = 0;

        while ( my $log_line = <$fd> ) {
          $k++;
          #say "$log_line";
          next if ($k < 9);
          next unless $log_line =~ /^ (\d{3}),(\d{2});\s*(-?\d+?),(\d+?);.+$/;
    #      say $log_line;
          $Wave = $1 . "." . $2;
          $Sample = $3 . "." . $4;
    #      say "$Wave $Sample";
          $Wave = 0 + $Wave;
          $Sample = 0 + $Sample;

          for my $el (keys %elmnts) {
            for my $wav (keys %{$elmnts{$el}}) {
              if ($Wave < $wav + $width_pick
                  and $wav - $width_pick < $Wave) {
                    if (exists $result->{$i*10}{$el}{"$wav"}) {
                      if ($result->{$i*10}{$el}{"$wav"} < $Sample) {
                        $result->{$i*10}{$el}{"$wav"} = $Sample;
                      }
                    }
                    else {$result->{$i*10}{$el}{"$wav"} = $Sample;}

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

    open my $fo, ">$folderpath/output.txt"
      or die "Не создаётся файл вывода: $!\n";

    my $head1 = "ratio\tratio";
    my $headu = "$prg %\t$scg %";
    for (1..$countel) {
        $head1 .= "\tInt";
        $headu .= "\ta.e.";
    }
    say $head1;
    say $headu;

    say $fo $head1;
    say $fo $headu;

    my $head2 = "$prg\t$scg";
    for my $el (sort keys %elmnts) {
      for my $wav (sort keys %{$elmnts{$el}}) {
        $head2 .= "\t$el ($wav)";
        if ($elmnts{$el}{"$wav"} > 1) {
          $head2 .= "*" . $elmnts{$el}{"$wav"};
        }
      }
    }
    say $head2;
    say $fo $head2;

    for my $rat (sort {$a <=> $b} keys %{$result}) {
      my $body = "$rat\t" . (100-$rat);
      for my $el (sort keys %elmnts) {
        for my $wav (sort keys %{$elmnts{$el}}) {
          $body .= "\t";
          $body .= $result->{$rat}{$el}{"$wav"}
                    * $elmnts{$el}{"$wav"};
        }
      }
      say $body;
      if ($exp eq 'Exele') {$body =~ s/\./\,/g;}
      say $fo $body;
    }
    close $fo;
}
