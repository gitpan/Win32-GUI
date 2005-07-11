use Win32::GUI;
use strict;

my ($width,$height);
my $mainwin;
 
#try to load the splash bitmap from the exe that is running
my $splashimage= new Win32::GUI::Bitmap('SPLASH');
unless ($splashimage) {
  #bitmap is not in exe, load from file
  $splashimage= new Win32::GUI::Bitmap('SPLASH.bmp');
  die 'could not find splash bitmap' unless $splashimage;
  #get the dimensions of the bitmap
  ($width,$height)       = $splashimage->Info();
  }
  
#create the splash window
my $splash     = new Win32::GUI::Window (
   -name       => "Splash",
   -text       => "Splash",
   -height     => $height, 
   -width      => $width,
   -left       => 100, 
   -top        => 100,
   -addstyle   => WS_POPUP,
   -popstyle   => WS_CAPTION | WS_THICKFRAME,
   -addexstyle => WS_EX_TOPMOST
);

#create a label in which the bitmap will be placed
my $bitmap    = $splash->AddLabel(
    -name     => "Bitmap",
    -left     => 0,
    -top      => 0,
    -width    => $width,
    -height   => $height,
    -bitmap   => $splashimage,
);  
$bitmap->SetImage( $splashimage );

#center the splash and show it
$splash->Center;
$splash->Show();
#call do events - not Dialog - this will display the window and let us 
#build the rest of the application.
Win32::GUI::DoEvents;

#A good way of building your application is to keep everything in packages, and eval those 
#into scope in this phase. In this case, we'll create the main window and sleep to simulate 
#some work.
my $string = q `
               $mainwin     = new Win32::GUI::Window (
               -name       => "Main",
               -text       => "Main window",
               -height     => 400, 
               -width      => 400,
                ); 
                sleep(2);
                $mainwin->Center();
                $mainwin->Show();
               `;
#eval the code and report any errors
eval $string;
if ($@) {
  my $message = $@;
  Win32::GUI::MessageBox($splash, $message ,"Build Error", MB_OK | MB_ICONWARNING);
  }
#hide the splash and enter the Dialog phase
$splash->Hide;
Win32::GUI::Dialog();