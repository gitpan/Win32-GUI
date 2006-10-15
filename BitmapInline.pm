package Win32::GUI::BitmapInline;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(inline);

$VERSION = "0.02";
$VERSION = eval $VERSION;

$Counter = 1;

require Win32::GUI;
require MIME::Base64;

sub new {
    my($class, $data) = @_;
    open(BMP, ">~$$.tmp") or return undef;
    binmode(BMP);
    print BMP MIME::Base64::decode($data);
    close(BMP); 
    my $B = new Win32::GUI::Bitmap("~$$.tmp");
    unlink("~$$.tmp");
    return $B;  
}

sub newCursor {
    my($class, $data) = @_;
    open(BMP, ">~$$.tmp") or return undef;
    binmode(BMP);
    print BMP MIME::Base64::decode($data);
    close(BMP); 
    my $B = new Win32::GUI::Cursor("~$$.tmp");
    unlink("~$$.tmp");
    return $B;  
}

sub newIcon {
    my($class, $data) = @_;
    open(BMP, ">~$$.tmp") or return undef;
    binmode(BMP);
    print BMP MIME::Base64::decode($data);
    close(BMP); 
    my $B = new Win32::GUI::Icon("~$$.tmp");
    unlink("~$$.tmp");
    return $B;  
}

sub inline {
    my ($file, $name) = @_;

    $name = "Bitmap" . $Win32::GUI::BitmapInline::Counter++ unless $name;

    my $type = "";
    $file =~ /\.ico$/i and $type = "Icon";
    $file =~ /\.cur$/i and $type = "Cursor";


    open(BMP, $file) or
        $! = "Bitmap file '$file' not found",
        return undef;
    my $oldsep = $/;
    undef $/;
    binmode(BMP);
    my $ret = "";
    $ret .= "\$$name = new$type Win32::GUI::BitmapInline( q(\n";
    $ret .= MIME::Base64::encode( <BMP> );
    $ret .= ") );\n";
    close(BMP);
    $/ = $oldsep;
    print $ret;
    return length($ret);
}

1;

__END__

=head1 NAME

Win32::GUI::BitmapInline - Inline bitmap support for Win32::GUI

=head1 SYNOPSIS

To create a BitmapInline:

    perl -MWin32::GUI::BitmapInline -e inline('image.bmp') >>script.pl

To use a BitmapInline (in script.pl):

    use Win32::GUI;
    use Win32::GUI::BitmapInline ();
    
    $Bitmap1 = new Win32::GUI::BitmapInline( q(
    Qk32AAAAAAAAAHYAAAAoAAAAEAAAABAAAAABAAQAAAAAAIAAAAAAAAAAAAAAABAAAAAQAAAAAAAA
    AACcnABjzs4A9/f3AJzO/wCc//8Azv//AP///wD///8A////AP///wD///8A////AP///wD///8A
    ////AHd3d3d3d3d3d3d3d3d3d3dwAAAAAAAABxIiIiIiIiIHFkVFRUVEQgcWVVRUVFRCBxZVVVVF
    RUIHFlVVVFRUUgcWVVVVVUVCBxZVVVVUVFIHFlVVVVVVQgcWZmZmZmZSBxIiIiIRERF3cTZlUQd3
    d3d3EREQd3d3d3d3d3d3d3d3
    ) );

=head1 DESCRIPTION

This module can be used to "inline" a bitmap file in your script, so
that it doesn't need to be accompained by several external files 
(less hassle when you need to redistribute your script or move it 
to another location).

The C<inline> function is used to create an inlined bitmap resource; it
will print on STDOUT the packed data including the lines of Perl  
needed to use the inlined bitmap resource; it is intended to be used as 
a one-liner whose output is appended to your script.

The function takes the name of the bitmap file to inline as its first
parameter; an additional, optional parameter can be given which will be 
the name of the bitmap object in the resulting scriptlet, eg:

    perl -MWin32::GUI::BitmapInline -e inline('image.bmp','IMAGE')
    
    $IMAGE = new Win32::GUI::BitmapInline( q( ...

If no name is given, the resulting object name will be $Bitmap1 
(the next ones $Bitmap2 , $Bitmap3 and so on).

Note that the object returned by C<new Win32::GUI::BitmapInline> is
a regular Win32::GUI::Bitmap object.

With version 0.02 you can inline icons and cursors too. Nothing changes
in the inlining process, just the file extension:

    perl -MWin32::GUI::BitmapInline -e inline('harrow.cur','Cursor1') >>script.pl
    perl -MWin32::GUI::BitmapInline -e inline('guiperl.ico','Icon1') >>script.pl

The module recognizes from the extension the type of object that it
should recreate, so it will add these lines to F<script.pl>:

    $Cursor1 = newCursor Win32::GUI::BitmapInline( q( ...
    $Icon1 = newIcon Win32::GUI::BitmapInline( q( ...
   
C<newCursor> or C<newIcon> are used in place of just C<new>. As above,
the returned objects are regular Win32::GUI objects (respectively,
Win32::GUI::Cursor and Win32::GUI::Icon).

=head1 WARNINGS

=over 4

=item * 

B<Requires MIME::Base64>

...and, of course, Win32::GUI :-)

=for html <P>

=item * 

B<Don't use it on large bitmap files!>

BitmapInline was designed for small bitmaps, such as
toolbar items, icons, et alia; it is not at all 
performant.
Inlined data takes approximatively the size of your
bitmap file plus a 30%; thus, if you inline a 100k bitmap 
you're adding about 130k of bad-looking data to your script...

=for html <P>

=item * 

B<Your script must have write access to its current directory>

When inlined data are used in your script (with 
C<new Win32::GUI::BitmapInline...>)
a temporary file is created, then loaded as a regular
bitmap and then immediately deleted.
This will fail if your script is not able to create and delete
files in the current directory at the moment of the call.
One workaround could be to change directory to a safer place
before constructing the bitmap:

    chdir("c:\\temp");
    $Bitmap1 = new Win32::GUI::BitmapInline( ... );

A better solution could pop up in some future release...

=for html <P>

=item *

B<The package exports C<inline> by default>

For practical reasons (see one-liners above), C<inline> is 
exported by default into your C<main> namespace; to avoid
this side-effect is recommended to use the module in your
production scripts as follows:

    use Win32::GUI::BitmapInline ();

=back

=head1 VERSION

Win32::GUI::BitmapInline version 0.02, 24 January 2001.

=head1 AUTHOR

Aldo Calpini ( C<dada@perl.it> ).

=cut
