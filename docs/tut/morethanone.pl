	use Win32::GUI;
	
	$W1 = new Win32::GUI::Window(
		-name  => "W1",
		-title => "Main Window",
		-pos   => [ 100, 100 ],
		-size  => [ 300, 200 ],
	);
	$W1->AddButton(
		-name => "Button1",
		-text => "Open popup window",
		-pos  => [ 10, 10 ],
	);
	
	$W2 = new Win32::GUI::Window(
		-name  => "W2",
		-title => "Popup Window",
		-pos   => [ 150, 150 ],
		-size  => [ 300, 200 ],
	);

	$W2->AddButton(
		-name => "Button2",
		-text => "Close this window",
		-pos  => [ 10, 10 ],
	);
	
	$W1->Show();
	
	Win32::GUI::Dialog();

	sub Button1_Click { $W2->Show(); }
	sub Button2_Click { $W2->Hide(); }

	sub W1_Terminate { return -1; }

	sub W2_Terminate {
		$W2->Hide();
		return 0;
	}
