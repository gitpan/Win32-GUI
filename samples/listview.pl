
use Win32::GUI;

$Window = new GUI::Window(
    -name   => "Window",
    -text   => "Win32::GUI::ListView test",
    -width  => 300,
    -height => 400,
    -left   => 100,
    -top    => 100,
);

$IL = new GUI::ImageList(16, 16, 24, 3, 10);
$IL->Add("one.bmp");
$IL->Add("two.bmp");
$IL->Add("three.bmp");

$Window->AddListView(
    -name      => "ListView",
    -text      => "hello world!",
    -left      => 10,
    -top       => 10,
    -width     => 280,
    -height    => 180,
    -imagelist => $IL,
    -style     => WS_CHILD | WS_VISIBLE | 1,
    -fullrowselect => 1,
    -gridlines => 1,
    -checkboxes => 1,
#    -hottrack   => 1,
);

$Window->AddButton(
    -name => "LV1",
    -text => "Big Icons",
    -left => 10,
    -top  => 200,
);

$Window->AddButton(
    -name => "LV2",
    -text => "Small Icons",
    -left => 10,
    -top  => 230,
);

$Window->AddButton(
    -name => "LV3",
    -text => "List",
    -left => 10,
    -top  => 260,
);

$Window->AddButton(
    -name => "LV4",
    -text => "Details",
    -left => 10,
    -top  => 290,
);

$width = $Window->ListView->ScaleWidth;

$Window->ListView->InsertColumn(
    -index => 0,
    -width => $width/2,
    -text  => "Name",
);
$Window->ListView->InsertColumn(
    -index   => 1,
    -subitem => 1,
    -width   => $width/2,
    -text    => "Description",
);

sub InsertListItem {
    my($image, $name, $description) = @_;
    my $item = $Window->ListView->InsertItem(
        -item  => $Window->ListView->Count(),
        -text  => $name,
        -image => $image,
        # -index => $Window->ListView->Count(),
    );
    $Window->ListView->SetItem(
        -item    => $item,
        -subitem => 1,
        -text    => $description,
    );
}

# InsertListItem(0, "ciao", "greetings");

$Window->ListView->InsertItem(-text => [ "abracadabra", "magic word" ] );

#InsertListItem(1, "abracadabra", "magic word");
InsertListItem(2, "John", "first name");

$Window->ListView->TextColor(hex("0000FF"));

$Window->Show();

$Window->Dialog();

# GUI::Show($Win32::GUI::hwnd);

sub LV1_Click {
    print "BIG Icons!\n";
    $Window->ListView->View(0);
}

sub LV2_Click {
    print "small Icons!\n";
    $Window->ListView->View(2);
}

sub LV3_Click {
    print "List!\n";
    $Window->ListView->View(3);
}

sub LV4_Click {
    print "Details!\n";
    $Window->ListView->View(1);
}

sub ListView_ItemClick {
	my($item) = @_;
	print "Item: $item\n";
	print "GetSelectionMark: ", $Window->ListView->SendMessage(0x1000+66, 0, 0), "\n";
	print "GetSelectionCount: ", $Window->ListView->SendMessage(0x1000+50, 0, 0), "\n";
}
