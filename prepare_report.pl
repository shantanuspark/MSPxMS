use strict;
use warnings;

my $longfile = $ARGV[0];
my $shortfile = $ARGV[1];
my $threshold1 = $ARGV[2];
my $threshold2 = $ARGV[3];
my $threshold3 = $ARGV[4];
my $threshold4 = $ARGV[5];
my $outfile = $ARGV[6];

my %longrecord = ();
my %shortrecord = ();

my %origin = ();
my %uniquerecord = ();
my %necintensity = ();

my @timepoints = ();
open(IN, $longfile) or die "Cannot open $longfile\n";
my $line = <IN>;

#Process the first line of the Long File, & retrieve time points
#of the experiments in minutes, e.g. 15, 60, and 240 minutes

if($line =~ /^The\s+order\s+of\s+the\s+timepoints/)
{
	my @record = split("/", $line);
	my @matches = grep { /_(\d+)\s+/ } @record;
	foreach my $match (@matches)
	{
		$match =~ /_(\d+)\s+/;
		my $time = $1;
		$time =~ s/^0+//;
		push(@timepoints, $time);
	}
}
else
{
	print "Format of long file is not accepted\n";
	exit(0);
}

# This while loop processes LONG File to identify all peptides, which
# were cleaved at least twice

my @doubly_cleaved = ();
my $counter = 0;
while ($line = <IN>)
{
    $counter = $counter+1;
	next if $line =~ /^$/;  #skip empty lines
	next if $line !~ /TDP/; #skip lines that do not start with TDP

	my @record = split("\t", $line);

        # get the number of cleaved bonds in a peptide, i.e. count ^ character
        # in each entry of the second column, & keep all that have been cleaved
        # 2 or more times
	my @matches = $record[1] =~ /\^/g; 
	if(scalar(@matches) > 1)
	{
		push(@doubly_cleaved, $line);
		next;
	}

	# those peptides that have NO value in column "Earliest Appearance"
        # are processed here ------ HOW? Description NOT Done yet
	if($record[3] ne ''){
		my $id = $record[0] . $record[2] . $record[3];
		my $uniqueid = $record[0] . $record[1];

		if(!exists $longrecord{$id})
		{
			$longrecord{$id} = $line;
			$uniquerecord{$uniqueid} = $record[2];
			$origin{$record[2]} = $record[1];
		}else{
			my @oldfields = split("\t", $longrecord{$id});
			my @oldintensities = split("-", $oldfields[4]);

			my $oldintensity = 0;
			foreach my $value (@oldintensities)
			{
				if ($value > 0) {
					$oldintensity = $value;
				}
			}

			my @newfields = split("\t", $line);
            my @newintensities = split("-", $newfields[4]);

            my $newintensity = 0;
            foreach my $value (@newintensities)
            {
                if ($value > 0) {
                    $newintensity = $value;
                }
            }
			if($newintensity > $oldintensity) {
				$longrecord{$id} = $line;
			}
		}
	}

        # this is the case, when the search in the second column, returned
        # 0 or 1 matches for the ^ character
	else
	{
		my @intensities = split("-", $record[7]);
		#changed on 8/25
		#if((!exists $necintensity{$record[2]}) && ($intensities[2] !=0 ))
		#{
		#	$necintensity{$record[2]} = $intensities[2];
		#}
		if(!exists $necintensity{$record[1]})
		{
	#changed on 9/18/14 $intensities[2] to $intensities[0]
		$necintensity{$record[1]} = $intensities[0];
		}
		elsif($necintensity{$record[1]} < $intensities[0])
		{
			$necintensity{$record[1]} = $intensities[0];
		}

	}
}
close(IN);

foreach my $d (@doubly_cleaved){
	my @record = split("\t", $d);
        if($record[3] ne ''){
                my $id = $record[0] . $record[2] . $record[3];
                my $uniqueid = $record[0] . $record[1];

                if(!exists $longrecord{$id})
                {
                        $longrecord{$id} = $d;
                        $uniquerecord{$uniqueid} = $record[2];
                        $origin{$record[2]} = $record[1];
                }
	}
	else
	{
		my @intensities = split("-", $record[7]);
                #changed on 8/25
                #if((!exists $necintensity{$record[2]}) && ($intensities[2] !=0 ))
                #{
                #       $necintensity{$record[2]} = $intensities[2];
                #}
                if(!exists $necintensity{$record[1]})
                {
			#changed intensities[2] to intensities[0]
                       $necintensity{$record[1]} = $intensities[0];
                }
                elsif($necintensity{$record[1]} < $intensities[0])
                {
                        $necintensity{$record[1]} = $intensities[0];
                }

	}
}
my $eol = $/;

open(IN, $shortfile) or die "Cannot open $shortfile\n";
my $header = <IN>;
$/ = "\n\n";
while(my $record = <IN>)
{



        my @parts = split("--------", $record);

        my @lines = split("\n", $parts[0]);

        foreach my $line (@lines)
        {
        	next if ($line =~ /^$/);
		    my @tokens = split("\t", $line);
		    my $id = $tokens[0] . $tokens[1];
		    $shortrecord{$id} = $line;
	    }
}
close(IN);

$/ = $eol;
open(IN, $shortfile) or die "Cannot open $shortfile\n";
$header = <IN>;
open(OUT, ">", $outfile);
$/ = "\n\n";
while(my $record = <IN>)
{
	&process_record($record);
}
close(IN);
close(OUT);
print "\n";
$/ = $eol;
print "\n";
exit(0);

sub process_record
{
	my $peptide = $_[0];
    my @parts = split("--------", $peptide);
    my @lines = split("\n", $parts[0]);
	foreach my $line (@lines)
	{
		if(&process_line($line))
		{
			print OUT "$line\n";
		}
	}
}

sub process_line
{
	my $line = $_[0];
	my $nec = 0;
	my $lasttime = 0;
	my $occurrences = 0;

	if($line =~ /^$/)
	{

		return 0;
	}
	my @record = split("\t", $line);
	$nec = &check_nec($line);


	$lasttime = &check_last_time_point($line);
	$occurrences = &check_number_of_occurrences($line);

	#case 0-0-1
	if ( !$nec && $lasttime && ($occurrences == 1))
	{
		return 1;
	}

	if( !$nec && $lasttime && ($occurrences == 2))
	{
		my @record = split("\t", $line);
      		my @times = split("-", $record[2]);
            	my $zeroes = join("", @times);
              	my $time = index($zeroes, '0');

		#case 0-1-1
		if($time == 0)
		{
			my $time = &check_ratios($line);
			if(!$time || &exception_one($line, $time))
			{
				return 1;
			}
		}
		#case 1-0-1
		else
		{
			my $time = &check_ratios($line);
			# new added on 8/25
                        if(!$time || &exception_one($line, $time))
                        {
                                return 1;
                        }
			# stop here 8/25
			#return 1;
		}
	}

	# case 1-1-0
	if( !$nec && !$lasttime && ($occurrences == 2))
        {
        	my $time = &check_ratios($line);
#             	if(!$time || &exception_one($line, $time))
		if(!$time && &exception_one($line, $time))
              	{
			return 1;
             	}
    	}

	#case 1-1-1
	if(!$nec && $lasttime && $occurrences == 3)
	{
		my $time = &check_ratios($line);
		if(!$time || &exception_one($line, $time))
              	{
			return 1;
             	}
	}

	#case 1-0-0
	#case 0-1-0
	if(!$nec && !$lasttime && $occurrences == 1)
      	{
		my @record = split("\t", $line);
        	my @times = split("-", $record[2]);
        	my $zeroes = join("", @times);
        	my $time = index($zeroes, '0');

             	if (&exception_one($line, $time))
		{
			return 1;
		}
     	}

	#case 0-0-1
	if($nec && $lasttime && ($occurrences == 1))
        #this is Exception 3: cleavage only occurs in the last time point
        #must not occur in experimentally matched NEC
       	{
        	my @record = split("\t", $line);

                my $id = '';
                if(exists $origin{$record[1]})
		{
			$id = $origin{$record[1]};
			my $count = ($id =~ tr/\^//);
			my $uniqueid = $record[0] . $id;
			if(($count == 2) && (exists $uniquerecord{$uniqueid}) && (!exists $necintensity{$id}))
			{
				return 0;
			}
			if((!exists $necintensity{$id}) || ($necintensity{$id} == 0)){
				return 1;
			}

		}
       	}

	if($nec && $lasttime && ($occurrences == 2))
	{
		my @record = split("\t", $line);
               	my @times = split("-", $record[2]);
              	my $zeroes = join("", @times);
               	my $timepoint = index($zeroes, '0');

               	#case 0-1-1
               	if($timepoint == 0)
                {
			my $time = &check_ratios($line);

			if(!$time)
			#if(!$time || &exception_one($line, $time))
			{
				return 1;
			}
		}
	}

	if($nec && $lasttime && ($occurrences == 3))
       	{
		my $time = &check_ratios($line);
		if($time == 5)
		{
			return 0;
		}
		if(!$time || &exception_one($line, $time))
                {
			return 1;
               	}
	}
	return 0;
}

sub check_nec
{
	my @record = split("\t", $_[0]);
	my $returnvalue = $record[4] eq '' ? 0 : 1;

	return $returnvalue;
}

sub check_last_time_point
{
	my @record = split("\t", $_[0]);
	my @times = split("-", $record[2]);
        my $returnvalue = $times[$#times] != 0 ? 1 : 0;

	return $returnvalue;
}

sub check_number_of_occurrences
{
	my @record = split("\t", $_[0]);
        my @times = split("-", $record[2]);
	my $number_of_cleavages = 0;
	foreach my $time (@times)
	{
		if ($time != 0) {
			$number_of_cleavages++;
		}
	}
        return $number_of_cleavages;
}

sub is_consecutive
{
	my @record = split("\t", $_[0]);
        my @times = split("-", $record[2]);
	my $zeroes = join("", @times);
	my $index = index($zeroes, '0');
	if($index == -1)
	{
		return 1;
	}

	return (($index > 0) || ($index < $#times)) ? 0 : 1;
}

sub check_ratios
{
        my $id = '';
	my $returnvalue = 0;

	my $threshold02 = 0;
        my $threshold03 = 0;

	my $nec = &check_nec($_[0]);
	if(!$nec) {

		$threshold02 = $threshold1;
		$threshold03 = $threshold2;
	}

	else{
		$threshold02 = $threshold3;
                $threshold03 = $threshold4;
	}

        my @record = split("\t", $_[0]);
        my @times = split("-", $record[2]);


        for (my $i = 0; $i < scalar(@times) - 1; $i++)
        {
		if(($times[$i] != 0) && ($times[$i+1] != 0))
                {
        		my $timepoint = $i+1;
                	$id = $record[0] . $record[1] . "0$timepoint";

			if(!exists $longrecord{$id}) { return 4; }
                	my @fields = split("\t", $longrecord{$id});
                	my @intensities = split("-", $fields[4]);
                	my $firstintensity = $intensities[$i];

                	$timepoint = $i+2;
                	$id = $record[0] . $record[1] . "0$timepoint";
			return 4 if(!exists $longrecord{$id});

			@fields = split("\t", $longrecord{$id});
                	@intensities = split("-", $fields[4]);
                	my $secondintensity = $intensities[$i+1];

			my $ratio = $secondintensity/$firstintensity;
                	if(($timepoint == 2) && ($ratio < $threshold02))
                	{
                		$returnvalue += 2;
                	}

			if(($timepoint == 3) && ($ratio < $threshold03))
                        {
                                $returnvalue += 3;
                        }
		}

        }
	if(!$nec && $times[1] == 0)
	{
			my $timepoint = 1;
			my $i = 0;
                        my $id = $record[0] . $record[1] . "0$timepoint";

                        if(!exists $longrecord{$id}) { return 4; }
                        my @fields = split("\t", $longrecord{$id});
                        my @intensities = split("-", $fields[4]);
                        my $firstintensity = $intensities[$i];

                        $timepoint = 3;
                        $id = $record[0] . $record[1] . "0$timepoint";
                        return 4 if(!exists $longrecord{$id});

                        @fields = split("\t", $longrecord{$id});
                        @intensities = split("-", $fields[4]);
                        my $secondintensity = $intensities[$i+2];

                        my $ratio = $secondintensity/$firstintensity;
                        if($ratio < $threshold02)
                        {
                                $returnvalue += 2;
                        }
	}
        return $returnvalue;
}

sub exception_one
{
        my @record = split("\t", $_[0]);

	my $origin_id = $origin{$record[1]};

	if(exists $origin{$record[1]}){
		my $caret = index($origin_id, "^");
		if($caret != -1){
			  $origin_id =~ s/\^//;
			  if(substr($origin_id, 0, $caret) eq lc(substr($origin_id, 0, $caret)))
			  {
				for(my $i = 1; $i < 3; $i++){
				   unless(($caret + $i) >= length($origin_id)){
                                      my $cleavage = lc(substr($origin_id, 0, $caret + $i)) . "^" . uc(substr($origin_id, $caret + $i));
                                      my $uniqueid = $record[0] . $cleavage ;
				      next if (!exists $uniquerecord{$uniqueid});
				      my $id = $record[0] . $uniquerecord{$uniqueid};
				      if(exists $shortrecord{$id})
				      {
					my $time = &process_line($shortrecord{$id});
					if($time)
					{
						return 1;
					}
					else{
					}
				       }
				      }
			         }
			} #end of if
		 	else {
				for(my $i = 1; $i < 3; $i++){
				   unless(($caret - $i) < 0){
				   	my $cleavage = uc(substr($origin_id, 0, $caret - $i)) . "^" . lc(substr($origin_id, $caret - $i));
				   	my $uniqueid = $record[0] . $cleavage ;
                                   	next if (!exists $uniquerecord{$uniqueid});
                                   	my $id = $record[0] . $uniquerecord{$uniqueid};
                                   	if(exists $shortrecord{$id})
                                  	{
                                   		my $time = &process_line($shortrecord{$id});
                                        	if($time)
                                        	{
                                                	return 1;
                                        	}
						else{
						}
                     			}
                                     }
                                 }
                        } #end of else
		}
	   #}
	else{
	}
	}
	else{
	}
	return 0;
}
