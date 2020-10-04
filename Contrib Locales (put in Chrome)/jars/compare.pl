#!/usr/bin/perl -s

die("usage: $0 -dir1=target -dir2=comparison_master find_dump_file\n")
	if (!length($dir1) || !length($dir2));

while(<>) {
	chomp;
	next if (-d "$dir2/$_");
	if (! -e "$dir1/$_") {
		print "-- warning: FILE NOT FOUND IN COPY: $_\n" ;
		next;
	}
	if (!/\.(dtd|properties)$/) {
		print "-- warning: skipping $_, not a file we search\n\n";
		next;
	}
	push(@files, $_);
}

print "\n\n=== checking individual files===\n\n";

foreach $thefile (@files) {
	print "-- $thefile\n";
	$isproperties = ($thefile =~ /\.properties$/) ? 1 : 0;

foreach $ext ($dir1, $dir2) {
	my %result = ();
	open(X, "$ext/$thefile") ||
		die("could not open: $ext/$thefile ($!)\n");
	$buf = '';
	while(<X>) {
		$buf .= $_;
	}
	close(X);
	if (length($buf)) {
		if ($isproperties) {
		# process JS props
			foreach $e (split(/[\r\n]+/s, $buf)) {
				next if ($e =~ /^\s*#/ || $e =~ /^\s*$/);
				if ($e =~ /^([^\s\=]+)\s*\=\s*(.*)$/) {
					$result{$1} = $2;
print "($ext) $1 <<< >>> $2\n" if ($showkeys);
				} else {
					print "($ext) PROPS MALFORMED: $e\n";
				}
			}
		} else {
		# process XML
	  	  while(length($buf)) {
			$buf =~ s/^\s+//;
			$tag = '';
			if (substr($buf, 0, 1) ne "<") {
	print "($ext) NOT A TAG: (@{[ length($buf) ]}) ".substr($buf, 0, 80)."\n";
				($tag, $buf) = split(/>\s*/, $buf, 2);
			} elsif ($buf =~ m#^<!?--#) {
				($tag, $buf) = split(/-->\s*/, $buf, 2);
			} elsif
		($buf =~ s#^<!?ENTITY\s+([^\s>]+)\s+"([^"]*)"\s*>\s*##i) {
				$result{$1} = $2;
print "($ext) $1 <<< >>> $2\n" if ($showkeys);
				$tag = "<!ENTITY $1 \"$2\">";
			} else {
	print "($ext) DTD MALFORMED: ".substr($buf, 0, 80)."\n";
				($tag, $buf) = split(/>\s*/, $buf, 2);
			}
		}
              }
	}
	push (@results, \%result);
}

%master = %{ $results[1] };
%copy = %{ $results[0] };

foreach $k (sort keys %copy) {
	if (!defined($master{$k})) {
		print "extraneous key in copy not in master: $k\n";
	}
}
foreach $k (sort keys %master) {
	if (!defined($copy{$k})) {
		print "KEY IN MASTER NOT IN COPY: $k $copy{$k}\n";
		next;
	}
}

undef @results;
}

