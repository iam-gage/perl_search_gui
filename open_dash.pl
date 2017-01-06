# 2015-03-17 glezin
# Ullink Prod NYC 
# Dashboard finder tool - text search and launcher for Dashboards

package open_dash;
use warnings;
use strict;
use Term::ReadKey;
use Win32::Process;
use FindBin;
use File::Basename;
chdir $FindBin::Bin;

our $dashboard_lib="./dashboard_lib/";
our (@dashboard_list,$dashboard_user,$dash_pass);

sub launch {
	my $launch_address;
	my $db_cursor_dap=&db::do_lookup_app_name_address_daps;
	my $doc;
	 while($doc=$db_cursor_dap->next){
		$launch_address=$doc->{"address"};		
	 }

	chdir $dashboard_lib;

	system ("start ul-tools.net-applauncher-bootstrap.exe ".$dashboard_user.":".$dash_pass."@".$launch_address);
	chdir "../";
}

sub get_dashboard_data {
	return @dashboard_list;
}

sub set_creds {

	while (@_){
		$dashboard_user=shift @_;
		$dash_pass=shift @_;
	}
}


return 1;
