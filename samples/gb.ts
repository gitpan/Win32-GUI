#!perl

use Win32::GUI;

$W = new Win32::GUI::DialogBox(
      -left   => 124,
      -top    => 239,
      -width  => 300,
      -height => 200,
      -name   => "W",
      -text   => ""
      );

$W->Show();

$W->AddAnimation(
       -text    => "",
       -name    => "Animation",
       -left    => 0,
       -top     => 0,
       -width   => 50,
       -height  => 30,
       -autoplay    => 1,
       -transparent    => 1,
      );

Win32::GUI::Dialog();

sub W_Terminate {
   return -1;
}
