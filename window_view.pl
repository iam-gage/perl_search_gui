use FindBin;
use File::Basename;
use Tk;
use Tk::DialogBox;
use Tk::LabEntry;
use warnings;   
use strict;  
use sigtrap 'handler', \&exit_clean, 'normal-signals';
use List::Util qw(max);
package screen;
	chdir $FindBin::Bin;
	
	our ($mw,$top,$left_frame,$top_frame,$top_frame2,$top_frame3,$top_frame4,$label,$search_entry,
	$list,$cb_dash,$cb_checked_dash,$cb_check_env_prod,
	$cb_env_prod,$cb_check_env_uat,$cb_check_env_dev,$cb_env_uat,$cb_env_dev,$reset_checked,
	$cb_reset_checked,$cb_hot,$hot_checked,$cb_dr,$dr_checked,$cb_gte,$gte_checked,$backppc_buton,$nagios_buton,$deb_dr_button,$list_scroll); 	
	$top = MainWindow->new(); 

sub draw_popup{
  my $message=shift;
  my ($pw,$dialog,$response);
  $dialog=$top->DialogBox('-title' => $message,
						 '-buttons' => ['Ok - Save','Cancel'],
						 '-default_button' => 'Ok - Save');
						 
	
  $dialog->add('LabEntry', '-textvariable'=>\$pw,-width=>50,
			    '-label'=> 'password',
				'-show'=> '*',
				'-labelPack'=> [-side => 'left'])->pack;
 
 $response=$dialog->Show( );
 						
 if($response eq "Ok - Save") {
	if($pw) {
		return $pw;
	}
		return "NO_KEY_FOUND";
	}
 }
 
sub draw_dash_popup{
	  my ($user,$pw,$dialog,$response);
	  $dialog=$top->DialogBox('-title' => "Enter Dashboard Credentials",
						 '-buttons' => ['Ok'],
						 '-default_button' => 'Ok');
		 
		 $dialog->add('LabEntry', '-textvariable'=>\$user,-width=>50,
			    '-label'=> 'Username ',
				'-labelPack'=> [-side => 'left'])->pack;
				
		 $dialog->add('LabEntry', '-textvariable'=>\$pw,-width=>50,
			    '-label'=> 'Password ',
				'-show' => "*",
				'-labelPack'=> [-side => 'left'])->pack;
					 
	  $response=$dialog->Show();
	  
	  if ((defined $user)&&($user =~ /[a-z]$/)){
		if(defined $pw){
			return $user."|".$pw;
		} else {
			return $user."|NO_PASSWORD";
		}
	  } else {
		return "NO_CREDS";
	  }

}

sub draw_main{
	
	$top->title (" PROD TOOL CLIENT ");
	
	$left_frame = $top->Frame();
	
	$top_frame = $top->Frame('-borderwidth'=>1, '-relief'=> 'flat');
	$top_frame2 = $top->Frame('-borderwidth'=>1, '-relief'=> 'flat');
	$top_frame3 = $top->Frame('-borderwidth'=>1, '-relief'=> 'flat');
	$top_frame4 = $top->Frame('-borderwidth'=>1, '-relief'=> 'flat');
	
	$top_frame -> pack('-side' => 'top',
						'-fill'=>'both');
	$top_frame2 -> pack('-side' => 'top',
						'-fill'=>'both');
	$top_frame3 -> pack('-side' => 'top',
						'-fill'=>'both');
	$top_frame4 -> pack('-side' => 'top',
						'-fill'=>'both');
	
	$left_frame -> pack('-side' => 'top',
						'-fill'=>'both');
	
	$label = $left_frame->Label('-text'=> 'Search',
						'-font'=>'-consolas-?-?-r-normal--17-140-75-75-p-82-iso8859-1') ->pack('-side' => 'left',
						'-padx' => 5 );

	$cb_dash = $top_frame->Checkbutton('-text' => 'Dashboard Search',
					    	'-variable' => \$cb_checked_dash)->pack('-side' => 'left');
										
	$reset_checked = $top_frame->Checkbutton('-text' => 'Change Password',
							'-variable' => \$cb_reset_checked)->pack('-side' => 'right');
	$cb_env_prod = $top_frame2->Checkbutton('-text' => 'PROD',
						'-variable' => \$cb_check_env_prod)->pack('-side' => 'left');
										
	$cb_env_uat = $top_frame2->Checkbutton('-text' => 'UAT',
						'-variable' => \$cb_check_env_uat)->pack('-side' => 'left');
	$cb_env_dev = $top_frame2->Checkbutton('-text' => 'DEV',
						'-variable' => \$cb_check_env_dev)->pack('-side' => 'left');
										
	$cb_hot = $top_frame3->Checkbutton('-text' =>'HOT ',
						    '-variable' => \$hot_checked)->pack('-side' => 'left');
	$cb_dr = $top_frame3->Checkbutton('-text' =>'DR ',
						    '-variable' => \$dr_checked)->pack('-side' => 'left','-padx' => 3);
	$cb_gte = $top_frame3->Checkbutton('-text' =>'GTE',
						    '-variable' => \$gte_checked)->pack('-side' => 'left');
	
	$backppc_buton = $top_frame4->Button('-command' => \&controls::launch_backuppc, '-text'=>"Backuppc") ->pack('-side'=>'right','-padx' => 20);
	$nagios_buton = $top_frame4->Button('-command' => \&controls::launch_nagios, '-text'=>"Nagios") ->pack('-side'=>'right','-padx' => 20);
	$deb_dr_button =  $top_frame4->Button('-command' => \&controls::launch_deb, '-text'=>"Deb DR") ->pack('-side'=>'right','-padx' => 20);									
	
	$search_entry = $left_frame->Entry()->pack('-side' => 'top',
							'-pady' => 10,
							'-padx' => 5,
							'-fill' => 'x') ; 
										
	$list = $top -> Listbox;
	$list_scroll = $top->Scrollbar();
	$list->configure('-width'=>90,
				'-height' => 3,
				'-selectmode' => 'multiple',
				'-setgrid' => 1,
				'-yscrollcommand'=> ['set' => $list_scroll]);
	$list_scroll->configure('-command' => ['yview' => $list]);
																		
	$list_scroll->pack('-side'=>'right','-fill'=>'y');
	$list->pack();	
	
	$search_entry->bind('<KeyPress-Return>', \&manage_list);
	$list->bind('<Button-3>', \&manage_selection);
	$search_entry->bind('<KeyPress-Up>', \&key_up);
	$search_entry->bind('<KeyPress-Down>', \&key_down);
	$top->protocol("WM_DELETE_WINDOW"=>\&exit_clean);
	$cb_dash->bind('<Button-1>',\&manage_checkboxes);
	$cb_hot->bind('<Button-1>',\&manage_checkboxes);
}

sub manage_checkboxes {
	my (@hot_results,@dr_results,@gte_results,@results);
	if ($hot_checked){
		@hot_results= grep (/HOT/,@_);
		$cb_check_env_prod = 0;
	}
	if ($dr_checked){
		@dr_results= grep (/DR/,@_);
		$cb_check_env_prod = 0;
	}
	if ($gte_checked){
		@gte_results= grep (/GTE/,@_);
		$cb_check_env_prod = 0;
	}
	while(@hot_results){
		push (@results,pop @hot_results);
	}
	while(@dr_results){
		push (@results,pop @dr_results);
	}
	while(@gte_results){
		push (@results,pop @gte_results);
	}
	
	if ((not $hot_checked) and (not $dr_checked) and (not $gte_checked)) {
		@hot_results= grep (!/HOT/,@_);	
		@dr_results=grep (!/DR/,@hot_results);
		@gte_results=grep (!/GTE/,@dr_results);
		@hot_results=();
		@dr_results=();
	}
	while(@hot_results){
		push (@results,pop @hot_results);
	}
	while(@dr_results){
		push (@results,pop @dr_results);
	}
	while(@gte_results){
		push (@results,pop @gte_results);
	}
	
	return @results;
}

sub key_down {
	my $entry_widget=shift;
	my @index; 
	my ($new_index,$cur_index);
	my $last_select=0;

	
		if(defined $list->curselection()){
		
			@index = $list->curselection();
			$cur_index=$index[0];
			$list->selectionClear($cur_index);
			$new_index=$cur_index + 1;
		if ( $new_index <= ($list->size()) ){
			$list->selectionSet($new_index);
		}
	} else {
		$list->selectionSet(0);
	}
}

sub key_up {
	my $entry_widget=shift;
	my @index; 
	my ($new_index,$cur_index);
	my $last_select=0;
	
	
	if(defined $list->curselection()){
			@index = $list->curselection();
			$cur_index=$index[0];
			$list->selectionClear($cur_index);
			$new_index=$cur_index - 1;
		if ( $new_index >= 0 ){
			$list->selectionSet($new_index);
		}
	} else {
			$list->selectionSet('end');
	}
}

sub manage_list {
$list-> pack('-side'=>'bottom', '-fill'=>'x');
if ($list->curselection()){
	 &manage_selection
	}else {
		$list->delete(0,'end');
		my $input=$search_entry->get;
		if($input) {
			
			if($cb_checked_dash){
				my @received_output=&controls::search_dashboard_apps($input); 
				my @filter = ();
				my $size;
				if ($cb_check_env_prod){
					my @filter = grep (/PROD/,@received_output);
					$size = scalar (@filter);
					$list->insert('end',@filter);
				} 
				if ($cb_check_env_uat){
					@filter = grep (/UAT/,@received_output);
					$size += scalar (@filter) ;
					$list->insert('end',@filter);
				}
				if ($cb_check_env_dev){
					@filter = grep (/DEV/,@received_output);
					$size += scalar (@filter) ;
					$list->insert('end',@filter);
				}
				if (not $cb_check_env_prod and not $cb_check_env_uat and not $cb_check_env_dev){
					$size = scalar (@received_output);
					$list->insert('end',@received_output);
				}
				if ($size < 15){
					$list->configure('-height'=>$size);
				} else {
					$list->configure('-height'=> 15);
				}
			} else {
				my $size;
				my @received_output=&controls::search_client_servers($input);
				my @filtered_output = manage_checkboxes(@received_output);
				@received_output=();
				while(@filtered_output){
					push(@received_output,pop(@filtered_output));
				}
				my @filter = ();
				if ($cb_check_env_prod){
					my @filter = grep (/PROD/,@received_output);
					$size = scalar (@filter);
					$list->insert('end',@filter);
				} 
				if ($cb_check_env_uat){
					@filter = grep (/UAT/,@received_output);
					$size += scalar (@filter) ;
					$list->insert('end',@filter);
				}
				if ($cb_check_env_dev){
					@filter = grep (/DEV/,@received_output);
					$size += scalar (@filter) ;
					$list->insert('end',@filter);
				}
				if (not $cb_check_env_prod and not $cb_check_env_uat and not $cb_check_env_dev){
					
					$size = scalar (@received_output);
					$list->insert('end',@received_output);
				}
				
				
				if ($size < 15){
					$list->configure('-height'=>$size);
				} else {
					$list->configure('-height'=> 15);
				}
			}	
		} else {
			$list->delete(0,'end');
			$list->configure('-height'=>3);
		} 
	}
}

sub manage_selection{
	foreach ($list->curselection()){
		print $list->get($_);
		if ($cb_reset_checked){
			$cb_reset_checked=0;
			if (not $cb_checked_dash){
				&controls::update_cs($list->get($_));
			} else {
				&controls::update_ds($list->get($_));
			}
		}
		elsif($cb_checked_dash){
			&open_dash::launch($list->get($_));
			sleep (5);
		} else {
			&search_hosts::launch($list->get($_));
			&search_hosts::clear();
		}
	}
	$list->delete(0,'end');
}

sub do_loop {
	Tk::MainLoop();
}

sub exit_clean{
	exit;
}

return 1;
