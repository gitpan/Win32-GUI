
use Pod::Html;

my %pod;
my %apply;
my %aka;
my %see;
my %opt;
my %def;
my %met;
my %evt;
my %type;
my %opt_name;
my %met_name;

@files = qw( packages events methods options );

foreach $file (@files) { preprocess($file); }

foreach $item (sort keys %{$pod{'options'}}) {
	$name = $item;
	$name =~ s/\s*=>.*$//;
	$name =~ s/^\s+//;
	$name =~ s/\s+$//;
	$opt_name{$name} = $item;
}

foreach $item (sort keys %{$pod{'methods'}}) {
	$name = $item;
	$name =~ s/\(.*$//;
	$met_name{$name."()"} = $item;
}

foreach $item (sort keys %{$pod{'events'}}) {
	$name = $item;
	$name =~ s/\(.*$//;
	$evt_name{$name."()"} = $item;
}

foreach $item (sort keys %{$apply{'options'}}) {
	$newapp = "";
	$comma = 0;
	foreach $option (split /\s*,\s*/, $apply{'options'}{$item}) {
		if($option =~ /\[(.)\]/) {
			$type = $1;
			foreach $package (sort keys %{$type{'packages'}}) {
				if( $type{'packages'}{$package} =~ /$type/) {
					$newapp .= ", " if $comma;
					$newapp .= $package;
					$comma = 1;
				}
			}
		} else {
			$newapp .= ", " if $comma;
			$newapp .= $option;
			$comma = 1;
		}
	}
	$apply{'options'}{$item} = $newapp;
}


# cross-refencing methods-options...
foreach $item (sort keys %{$pod{'methods'}}) {
	if(exists $opt{'methods'}{$item}) {
		$method = $item;
		$method =~ s/\([^)]+\)/()/;
		foreach $other (split /\s*,\s*/, $opt{'methods'}{$item}) {
			$other =~ s/^\s+//;
			$other =~ s/\s+$//;			
			if(exists $opt_name{$other}) {
				$option = $opt_name{$other};
				if(not grep(/$method/, $apply{'options'}{$option})) {
#					print "cross_ref: ADDING $method to APPLY_LIST of $option\n";
					$apply{'options'}{$option} .= ", " if $apply{'options'}{$option};
					$apply{'options'}{$option} .= $method;
				}
			}
		}
	}
}


# cross-refencing packages-options...
foreach $item (sort keys %{$pod{'options'}}) {
	if(exists $apply{'options'}{$item}) {
		foreach $other (split /\s*,\s*/, $apply{'options'}{$item}) {			
			# print "cross_ref: OPTION: '$item' APPLY_TO: '$other'\n";
			$item_name = $item;
			$item_name =~ s/\s*=>.*$//;
			$item_name =~ s/^\s+//;
			$item_name =~ s/\s+$//;
			if(not grep(/$item_name/, $opt{'packages'}{$other})) {
#				print "cross_ref: ADDING $item to APPLY_LIST of $other\n";
				$opt{'packages'}{$other} .= ", " if $opt{'packages'}{$other};
				$opt{'packages'}{$other} .= $item_name;
			}
		}
	}
}

# cross-refencing packages-methods...
foreach $item (sort keys %{$pod{'methods'}}) {
	$method = $item;
	$method =~ s/\([^)]+\)/()/;
	foreach $package (split(", ", $apply{'methods'}{$item})) {
		if(not grep(/$method/, $met{'packages'}{$package})) {
#			print "cross_ref: ADDING $method to METHODS of $package\n";
			$met{'packages'}{$package} .= ", " if $met{'packages'}{$package};
			$met{'packages'}{$package} .= $method;
		}
	}	
}


foreach $file (@files) { spit_out($file); }

sub preprocess {
	my($file) = @_;
	
	$pod{$file} = {};
	$apply{$file} = {};
	$aka{$file} = {};
	$see{$file} = {};
	$opt{$file} = {};
	$def{$file} = {};
	$met{$file} = {};
	$evt{$file} = {};

	my $looking_for = 'NOTHING';

	open(IN, "<$file.txt");
	while(<IN>) {
		chomp;
	#	print  "$. $looking_for\n";

		if(/^=+$/) {  # separator
			$looking_for = 'NAME';
			$this = '';

		} elsif(/^=APPLY\s*(.*)$/) {
			if($1) {
				$apply{$file}{$this} = $1;
			} else {
				$looking_for = 'APPLY';
			}
		
		} elsif(/^=END_APPLY/) {
			if($looking_for eq 'APPLY') {
				$looking_for = 'NOTHING';
			} else {
				warn "unexpected =END_APPLY at line $. in file $file.txt\n";
			}

		} elsif(/^=SEE_ALSO\s*(.*)$/) {
			if($1) {
				$see{$file}{$this} = $1;
			} else {
				$looking_for = 'SEE_ALSO';
			}

		} elsif(/^=AKA\s*(.*)$/) {
			if($1) {
				$aka{$file}{$this} = $1;				
			} else {
				$looking_for = 'AKA';
			}
			$pod{$file}{$this} = '';
		
		} elsif(/^=OPTIONS\s*(.*)$/) {
			if($1) {
				$opt{$file}{$this} = $1;
			} else {
				$looking_for = 'OPTIONS';
			}
		
		} elsif(/^=END_OPTIONS/) {
			if($looking_for eq 'OPTIONS') {
				$looking_for = 'NOTHING';
			} else {
				warn "unexpected =END_OPTIONS at line $. in file $file.txt\n";
			}

		} elsif(/^=METHODS\s*(.*)$/) {
			if($1) {
				$met{$file}{$this} = $1;
			} else {
				$looking_for = 'METHODS';
			}
		
		} elsif(/^=END_METHODS/) {
			if($looking_for eq 'METHODS') {
				$looking_for = 'NOTHING';
			} else {
				warn "unexpected =END_METHODS at line $. in file $file.txt\n";
			}

		} elsif(/^=EVENTS\s*(.*)$/) {
			if($1) {
				$evt{$file}{$this} = $1;
			} else {
				$looking_for = 'EVENTS';
			}
		
		} elsif(/^=END_EVENTS/) {
			if($looking_for eq 'EVENTS') {
				$looking_for = 'NOTHING';
			} else {
				warn "unexpected =END_EVENTS at line $. in file $file.txt\n";
			}

		} elsif(/^=TYPE\s*(.*)$/) {
			if($1) {
				$type{$file}{$this} = $1;
			} else {
				warn "undefined =TYPE at line $. in file $file.txt\n";
			}

		#} elsif(/^=(APPLY, SEE_ALSO, ...)

		} else {

			if($looking_for eq 'NAME') {
				if(/^\s*$/) {
					$looking_for = 'CONTENT';
				} else {
					if($this) {
						$alias{$file}{$this} = [] unless exists $alias{$this};
						push(@{$alias{$file}{$this}}, $_);
					} else {
						if(s/\(default ([^)]+)\)//) {
							$tdef = $1;
						} else {
							$tdef = "";
						}
						s/^\s+//;
						s/\s+$//;
						$this = $_;
						$def{$file}{$this} = $tdef if $tdef ne undef;

					}
				}
			} elsif($looking_for eq 'CONTENT') {
				chomp;
				$pod{$file}{$this} .= $_."\n";
			} elsif($looking_for eq 'APPLY') {
				chomp;
				$apply{$file}{$this} .= " " if $apply{$file}{$this};
				s/^\s+//;
				s/\s+$//;
				$apply{$file}{$this} .= $_;
			} elsif($looking_for eq 'AKA') {
				chomp;
				$aka{$file}{$this} .= " " if $aka{$file}{$this};
				s/^\s+//;
				s/\s+$//;
				$aka{$file}{$this} .= $_;
			} elsif($looking_for eq 'SEE_ALSO') {
				chomp;
				$see{$file}{$this} .= " " if $see{$file}{$this};
				s/^\s+//;
				s/\s+$//;
				$see{$file}{$this} .= $_;
			} elsif($looking_for eq 'OPTIONS') {
				chomp;
				$opt{$file}{$this} .= " " if $opt{$file}{$this};
				s/^\s+//;
				s/\s+$//;
				$opt{$file}{$this} .= $_;
			} elsif($looking_for eq 'METHODS') {
				chomp;
				$met{$file}{$this} .= " " if $met{$file}{$this};
				s/^\s+//;
				s/\s+$//;
				$met{$file}{$this} .= $_;
			} elsif($looking_for eq 'EVENTS') {
				chomp;
				$evt{$file}{$this} .= " " if $evt{$file}{$this};
				s/^\s+//;
				s/\s+$//;
				$evt{$file}{$this} .= $_;
			} else {
				# print "skipping...\n";
			}
		}
	}
	close(IN);
}

sub spit_out {
	my($file) = @_;

	open(POD, ">$file.pod");

	print POD "=head1 Win32::GUI $file\n\n";
#	print POD "=over 4\n\n";

	foreach $item (sort keys %{$pod{$file}}) {
		if($] < 5.006) {
			print POD "=for HTML <TT>\n\n";
		} else {
			print POD "=for HTML <HR><TT>\n\n";
		}
		
		print POD "=head2 $item";
		if(exists $alias{$file}{$item}) {
			foreach $alias (@{$alias{$file}{$item}}) {
				print POD "\n\n=head2 $alias";

			}
		}
		print POD "\n\n";
		print POD "=for HTML </TT><BLOCKQUOTE>\n\n";
		if(exists $aka{$file}{$item}) {
			$real_link = Pod::Html::htmlify(0, $aka{$file}{$item});
			$link = "L<$other|methods/$real_link>";
			print POD "See L<$aka{$file}{$item}|methods/$real_link>\n\n";
		} else {
			if(exists $def{$file}{$item}) {
				print POD "B<Default value>: C<$def{$file}{$item}>\n\n";
			}
			$pod{$file}{$item} =~ s/(METHOD|EVENT|OPTION)_LINK<([^>]+)>/smart_link($1, $2)/ge;
			print POD "$pod{$file}{$item}\n\n";
			
			if(exists $see{$file}{$item}) {
				print POD "B<See also>: ";
				$comma = 0;
				foreach $other (split /\s*,\s*/, $see{$file}{$item}) {
					$other =~ s/\s+$//;
					if(exists $opt_name{$other}) {
						$real_link = Pod::Html::htmlify(0, $opt_name{$other});
						$link = "L<$other|options/$real_link>";
					} elsif(exists $met_name{$other}) {
						$real_link = Pod::Html::htmlify(0, $met_name{$other});
						$link = "L<$other|methods/$real_link>";
					} else {
						$link = "L</$other>";
					}
					print POD ", " if $comma;
					print POD $link;
					$comma = 1;
				}
				print POD "\n\n";
			}
			
			print_pod_list( \*POD, \%apply, \%met_name, $file, $item, ["methods", "packages"], "Applies to");		
			print_pod_list( \*POD, \%opt, \%opt_name, $file, $item, "options");
			print_pod_list( \*POD, \%met, \%met_name, $file, $item, "methods");
			print_pod_list( \*POD, \%evt, \%evt_name, $file, $item, "events");
		}
		print POD "=for HTML </BLOCKQUOTE>\n\n";
	}

#	print POD "=back\n\n\n";

	close(POD);

	pod2html( "--infile=$file.pod", "--outfile=$file.html", "--htmlroot=.", "--podpath=.");

	open(OLD, "<$file.html");
	open(NEW, ">$file.html.new");
	while(<OLD>) {
		s{</HEAD>}{<LINK REL="stylesheet" TYPE="text/css" HREF="style.css"></HEAD>};
		print NEW $_;
	}
	close(OLD);
	close(NEW);
	unlink("$file.html");
	rename("$file.html.new", "$file.html");
}


sub print_pod_list {

	my $OUTPUT = shift;
	my $hash = shift;
	my $namehash = shift;
	my $file = shift;
	my $item = shift;
	my $otherfile = shift;
	my $list_title = shift;
	my $comma = 0;

	$list_title = ucfirst($otherfile) unless defined $list_title;

	my @otherfiles;
	if(ref($otherfile)) 
		{ @otherfiles = @$otherfile;  }
	else
		{ @otherfiles = ($otherfile, $otherfile); }		

	#print "print_pod_list: OUTPUT=$OUTPUT\n";
	#print "print_pod_list: hash=", $hash, "\n";

	if(exists $$hash{$file}{$item}) {
		print $OUTPUT "B<$list_title>: ";
		foreach $other (sort smarty split /\s*,\s*/, $$hash{$file}{$item}) {
			$other =~ s/\s+$//;
			if(exists $$namehash{$other}) {
				$real_link = Pod::Html::htmlify(0, $$namehash{$other});
				$other =~ s/\(.*$// if $file ne "options";
				$link = "L<$other|$otherfiles[0]/$real_link>";
			} else {
				$link = "L<$other|$otherfiles[1]/$other>";
			}
			print $OUTPUT ", " if $comma;
			print $OUTPUT "$link";
			$comma = 1;
		}
		print $OUTPUT "\n\n";
	}
}

sub smarty {
	if($a =~ /\(/ and $b !~ /\(/) { return 1; }
	if($a !~ /\(/ and $b =~ /\(/) { return -1; }
	return lc($a) cmp lc($b);
}
	
	
sub smart_link {
	my($page, $item) = @_;
	my $real_link;
	my %pagemap = (
		METHOD => [qw( methods \%met_name )],
		EVENT  => [qw( events  \%evt_name )],
		OPTION => [qw( options \%opt_name )],
	);
	if(exists ${$pagemap{$page}[1]}{$item}) {
		$real_link = Pod::Html::htmlify(0, ${$pagemap{$page}[1]}{$item});
	} else {
		$real_link = $item;
	}
	return "L<$item|$pagemap{$page}[0]/$real_link>";
}