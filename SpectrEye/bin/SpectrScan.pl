#!/usr/bin/perl
use 5.016;

use strict;
use warnings;
use DDP;

our %elmnts = (
    'N2+' => {'391.4' => 0, '427.8' => 0,},
     N2 => {'380.5' => 0, '337.1' => 0,},
     N => {'648.4' => 0,},
     'N+' => {'566.6' => 0,},
     'Ar+' => {'488.0' => 0, },
     Ar => {'696.4' => 0, },
);

our $countel = 8; # Количество линий

my $folderpath = $ARGV[0];
die "USAGE:\n$0 filepath\n"  unless $folderpath;
die "Way '$folderpath' not found\n" unless -d $folderpath;

my $parsed_data = parse_files($folderpath);
report($parsed_data);

exit;

sub parse_files {
    my $folder = shift;
    my $width_pick = 2; #nm
    my ($Wave, $Sample, $Dark, $Reference);

    my $result;    # Ссылка на хеш

    for ( my $i = 0; $i <= 10; $i++ ) {
      for (my $j = 1; $j <= 3; $j++) {
        my $way = "$folder/$i" . "0_151016$j" . "U1.TXT";


        open my $fd, "<", "$way" or die "Can't open '$way': $!";

        my $k = 0;

        while ( my $log_line = <$fd> ) {
          $k++;
          #say "$log_line";
          next if ($k < 9);
          next unless $log_line =~ /^ (\d{3}),(\d{2});\s+(-?\d+?),(\d+?);.+$/;
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
                      }}
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

    my $head1 = "ratio";
    my $headu = "%\t%";
    for (1..$countel) {
        $head1 .= "\tInt";
        $headu .= "\ta.e.";
    }
    say $head1;
    say $headu;

    say $fo $head1;
    say $fo $headu;

    my $head2 = "Ar\tN2";
    for my $key (sort keys %elmnts) {
      for my $subkey (sort keys %{$elmnts{$key}}) {
        $head2 .= "\t$key ($subkey)";
      }
    }
    say $head2;
    say $fo $head2;

    for my $rat (sort {$a <=> $b} keys %{$result}) {
      my $body = "$rat\t" . (100-$rat);
      for my $el (sort keys %elmnts) {
        for my $wav (sort keys %{$elmnts{$el}}) {
          $body .= "\t";
          $body .= $result->{$rat}{$el}{"$wav"};
        }
      }
      say $body;
      $body =~ s/\./\,/g;
      say $fo $body;
    }
    close $fo;
}
