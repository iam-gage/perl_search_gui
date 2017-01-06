package controls;
use warnings;   
use strict; 
use FindBin;
use File::Basename;
use Win32::Registry;
use Win32::Process;

our $reg_lib=".\\registry_lib";
our $mongo_lib=".\\mongo";
our $MONGO_PID;
our $NAGIOS_HOST="deb-nagios-uat";
chdir $FindBin::Bin;


sub check_reg {
	my ($p,$remote_command_obj,$reg_file_prod,$reg_file_uat);
	$reg_file_uat="Default%20Settings";
	$reg_file_prod="Prod-Settings";
	
	$p = "Software\\SimonTatham\\Putty\\Sessions\\$reg_file_prod";
	$main::HKEY_CURRENT_USER->Open($p, $remote_command_obj) || die "Prod registry session check fails! $!";
	
	$p = "Software\\SimonTatham\\Putty\\Sessions\\$reg_file_uat";
	$main::HKEY_CURRENT_USER->Open($p, $remote_command_obj) || die "UAT registry session check fails! $!";
}


sub load_reg{
	chdir $reg_lib;
	system ("start add_reg.bat ");
	chdir "../";
	
	check_reg;
}

sub do_requires{
	require "db_connect.pl";
	require "window_view.pl";
	require "open_dash.pl";
}



sub show_newly_updated {
	my @newly_updated=&db::show_newly_updated();
	return @newly_updated;
}

sub search_client_servers {
	my $search_arg = shift;
	my @search_hosts_results=&db::lookup_cs($search_arg);
	return @search_hosts_results;
}

sub search_dashboard_apps {
	my $search_arg = shift;
	my @search_hosts_results=&db::lookup_daps($search_arg);
	return @search_hosts_results;
}
sub launch_deb {
	my ($token,$process,$options,$key,$login,$remote_command_obj,$p,$home,$command,$reg_key,%hash_vals,$user,$deb_login);
	$user = $open_dash::dashboard_user;
	if ($user){
		my @found = &db::lookup_cs("DEB DR PARIS");
		my $deb_info = pop(@found);
		my @fields=split(/\|/,$deb_info);
		$deb_login = pop(@fields);
		$deb_login =~ s/.*@//; 
		$deb_login =~ s/\n//; 
		$deb_login = $user."@".$deb_login;
	
		my $key = &db::get_deb_key($deb_login);		
		if ($key =~ "NO_KEY_FOUND") {
			$deb_login =~ s/.*@//; 
			&db::update_missed_login("$user | $deb_login");	
		} else {
			$key=&db::do_lookup_missed_logins($deb_login);
			$home="/mnt/backup/archives";
			$command="";
        		$reg_key="PROD-Settings";
        
			$p = "Software\\SimonTatham\\Putty\\Sessions\\$reg_key";
		        $main::HKEY_CURRENT_USER->Open($p, $remote_command_obj) || die "Failed Setting the remote command $!";
							
			my $k="RemoteCommand";
			$remote_command_obj->GetValues(\%hash_vals);
			$remote_command_obj->SetValueEx($k,0,1,$command);
			$options=" -load Prod-Settings -ssh $deb_login -pw $key";
			Win32::Process::Create($process,"putty.exe",$options,0,0,".") || die $!; 
		}
	}	
}

sub launch_backuppc {
	my ($token,$process,$options,$key,$login,$remote_command_obj,$p,$home,$command,$reg_key,%hash_vals);
	$login="backuppc\@backuppc-prod.ullink.lan";
	$token="backuppc";
	$key=&db::lookup_backuppc_key($token);
	$key=~s/\n//g;
	$home="/etc/nagios3/ulconf/conf";
	$command="bash";
	$reg_key="PROD-Settings";
	
	$p = "Software\\SimonTatham\\Putty\\Sessions\\$reg_key";
	$main::HKEY_CURRENT_USER->Open($p, $remote_command_obj) || die "Failed Setting the remote command $!";

	my $k="RemoteCommand";
	$remote_command_obj->GetValues(\%hash_vals);
	$remote_command_obj->SetValueEx($k,0,1,$command);
	
	$options=" -load Prod-Settings -ssh $login -pw $key";
	Win32::Process::Create($process,"putty.exe",$options,0,0,".") || die $!; 
}

sub launch_nagios {
	my ($process,$options,$key,$login,$remote_command_obj,$p,$home,$command,$reg_key,%hash_vals);
	$login=$open_dash::dashboard_user."\@".$NAGIOS_HOST;
	$login=~s/\n//g;
	$key=&db::do_lookup_missed_logins($login);
	if (defined $key)
	{
	    $key=~s/\n//g;
		$options=" -load Prod-Settings -ssh $login -pw $key";
	}else{
		my $user=$open_dash::dashboard_user;
		$user=~s/\n//g;
		&db::update_missed_login("$user | ".$NAGIOS_HOST);
		$options=" -load Prod-Settings -ssh $login ";
	}
	
	$home="/etc/nagios/ulconf/conf";
	$command="cd $home; bash";
	$reg_key="PROD-Settings";
	
	$p = "Software\\SimonTatham\\Putty\\Sessions\\$reg_key";
	$main::HKEY_CURRENT_USER->Open($p, $remote_command_obj) || die "Failed Setting the remote command $!";

	my $k="RemoteCommand";
	$remote_command_obj->GetValues(\%hash_vals);
	$remote_command_obj->SetValueEx($k,0,1,$command);
	
	Win32::Process::Create($process,"putty.exe",$options,0,0,".") || die $!; 
}



sub update_cs{
	my @params = split(/\|/,pop @_);
	&db::resetter_cs(@params);
}

sub update_ds{
	my @params = split(/\|/,pop @_);
	&db::resetter_ds(@params);
}

#Display contents of the database
sub print_db{
	&db::show_db;
}

#Failed Login pop-up
#Enables user input for failed password lookups.
sub show_popup{
	my $msg_arg = shift;
	my $message= $msg_arg;
	&screen::draw_popup($message);
}

#Pop-up Display for default username and password to use for Dashboard Login
sub dash_user_popup{
	#return 1;
	my $dash_creds=&screen::draw_dash_popup();
	while($dash_creds =~ /NO_CREDS/){
		$dash_creds=&screen::draw_dash_popup();
	}
	my @creds=split(/\|/,$dash_creds);
	&open_dash::set_creds(@creds);
}

# Load all putty registry entries the program requires
# Verify Mongo is installed and running
# Import all source code required
# Display the GUI
# Obtain username and password data to use for connecting to Dashboard applications
# Initialize the database and load data 
# Listen for user input
sub start{
  print "Prod Tool Running in Client Mode \n";
  load_reg;
  do_requires;
  &screen::draw_main;
  dash_user_popup;
  &screen::do_loop;
}

start;
