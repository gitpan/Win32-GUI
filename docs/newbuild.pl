
use Pod::Html;

my %pod;
my %apply;
my %aka;
my %see;
my %opt;
my %def;
my %opt_name;
my %met_name;

@files = qw( packages methods options );

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

# cross-refencing options...
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

foreach $file (@files) { spit_out($file); }

sub preprocess {
	my($file) = @_;
	
	$pod{$file} = {};
	$apply{$file} = {};
	$aka{$file} = {};
	$see{$file} = {};
	$opt{$file} = {};
	$def{$file} = {};

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
						$this = $_;
						$def{$file}{$this} = $tdef if $tdef ne undef;

					}
				}
			} elsif($looking_for eq 'CONTENT') {
				$pod{$file}{$this} .= $_."\n";
			} elsif($looking_for eq 'APPLY') {
				$apply{$file}{$this} .= $_."\n";
			} elsif($looking_for eq 'AKA') {
				$aka{$file}{$this} .= $_."\n";
			} elsif($looking_for eq 'SEE_ALSO') {
				$see{$file}{$this} .= $_."\n";
			} elsif($looking_for eq 'OPTIONS') {
				$opt{$file}{$this} .= $_."\n";
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
	print POD "=over 4\n\n";

	foreach $item (sort keys %{$pod{$file}}) {
		print POD "=for HTML <HR><TT>\n\n";
		print POD "=head2 $item";
		if(exists $alias{$file}{$item}) {
			foreach $alias (@{$alias{$file}{$item}}) {
				print POD "\n\n=head2 $alias";

			}
		}
		print POD "\n\n";
		print POD "=for HTML </TT><BLOCKQUOTE>\n\n";
		if(exists $aka{$file}{$item}) {
			print POD "See L</$aka{$file}{$item}>\n\n";
		} else {
			if(exists $def{$file}{$item}) {
				print POD "B<Default value>: C<$def{$file}{$item}>\n\n";
			}
			print POD "$pod{$file}{$item}\n\n";
			if(exists $see{$file}{$item}) {
				print POD "B<See also>: ";
				$comma = 0;
				foreach $other (split /\s*,\s*/, $see{$file}{$item}) {
					$other =~ s/\s+$//;
					if(exists $opt_name{$other}) {
						$real_link = $opt_name{$other};
						$real_link =~ s/\s+$//;
						$real_link =~ s/[^a-zA-Z0-9]+/_/g;
						$link = "L<$other|options/$real_link>";
					} elsif(exists $met_name{$other}) {
						$real_link = $met_name{$other};
						$real_link =~ s/\s+$//;
						$real_link =~ s/[^a-zA-Z0-9]+/_/g;
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
			if(exists $apply{$file}{$item}) {
				print POD "B<Applies to>: ";
				$comma = 0;
				foreach $other (split /\s*,\s*/, $apply{$file}{$item}) {
					$other =~ s/\s+$//;
					if(exists $met_name{$other}) {
						$real_link = $met_name{$other};
						$real_link =~ s/\s+$//;
						$real_link =~ s/[^a-zA-Z0-9]+/_/g;
						$link = "L<$other|methods/$real_link>";
					} else {
						$link = "L<$other|packages/$other>";
					}
					print POD ", " if $comma;
					print POD $link;
					$comma = 1;
				}
				print POD "\n\n";
			}
			if(exists $opt{$file}{$item}) {
				print POD "B<Available options>: ";
				$comma = 0;
				foreach $other (split /\s*,\s*/, $opt{$file}{$item}) {
					$other =~ s/\s+$//;
					if(exists $opt_name{$other}) {
						$real_link = $opt_name{$other};
						$real_link =~ s/\s+$//;
						$real_link =~ s/[^a-zA-Z0-9]+/_/g;
						$link = "L<$other|options/$real_link>";
					} else {
						$link = "L<$other|options/$other>";
					}
					print POD ", " if $comma;
					print POD "$link";
					$comma = 1;
				}
				print POD "\n\n";
			}
		}
		print POD "=for HTML </BLOCKQUOTE>\n\n";
	}

	print POD "=back\n\n";

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