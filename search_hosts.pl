use warnings;
use strict;
use Win32;
use Win32::Process;
use Win32::Registry;
use FindBin;
use File::Basename;

chdir $FindBin::Bin;
package search_hosts;

our $HOST_FILE=".\\all_boxes\\ullink_hosts_file.csv";
our $pass_file=".\\all_boxes\\pass_file.csv";
our $users_file=".\\all_boxes\\users_file.csv";
our $final_prod=".\\all_boxes\\final_prod.txt";
our $final_uat=".\\all_boxes\\final_uat.txt"; 
our $jeff_file=".\\all_boxes\\jeffries.txt";
our $tmx_prod=".\\all_boxes\\tmx_prod.txt";
our $l7_prod=".\\all_boxes\\l7_file.txt";
our (@HOST_DATA,@RESULTS,@P_DATA,@USER_DATA,@FINAL_PROD,@FINAL_UAT,@JEFF,@TMX_PROD,@L7_PROD);

our $done_searching=0;

sub get_key {
	
	my $FINAL_PROD_FOUND=0;
	my $FINAL_UAT_FOUND=0;
	my $JEFFRIES_FOUND=0;
	my $TMX_PROD_FOUND=0;
	my $L7_FOUND=0;
	my $login= shift @_;
	my $key="";
	my $user_group_E =  $USER_DATA[0];
	my $user_group_K = $USER_DATA[1];
	my $p_index=0;
	
	my ($jeffp,$utpass,$dvpass,$epass,$kpass,$finupass,$finppass,$findpass,$uluat,$ulpri,$bchil_dev,$mizpass,$expass,$no_pass);
	
	while (defined $p_index ){
	if ($p_index == 0) {$utpass = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 1) {$dvpass = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 2) {$epass = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 3) {$kpass = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 4) {$finupass = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 5) {$finppass = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 6) {$findpass = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 7) {$uluat = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 8) {$ulpri = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 9) {$bchil_dev = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 10) {$mizpass = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 11) {$expass = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 12) {$no_pass = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 13) {$no_pass = $P_DATA[$p_index]; $p_index++;  }
	if ($p_index == 14) {$jeffp = $P_DATA[$p_index]; $p_index++;  }
	undef $p_index;
	}

	if(defined $login) {
		$login =~ s/\n//g;
		my @all_users=split(/\@/,$login);
		my $user=shift @all_users;
		my $address=shift @all_users;
		
		$address =~ s/\n//g;
		$user =~ s/\///g;
	
		if( (not defined $address) || (not defined $user)){
			print "BAD ULLINK HOST FILE ENTRY !! \n";
			print $login;
			die "$!";
		}		
		
		my @found_final_prod=grep (/$address/,@FINAL_PROD);
		foreach my $iter(@found_final_prod){
			$FINAL_PROD_FOUND=1;
		}
		
		my @found_final_uat=grep (/$address/,@FINAL_UAT);
		foreach my $iter(@found_final_uat){
			$FINAL_UAT_FOUND=1;
		}
		
		my @found_jeffries=grep (/$address/,@JEFF);
		foreach my $iter(@found_jeffries){
			$JEFFRIES_FOUND=1;
		}
		
		my @found_tmx_prod=grep (/$address/,@TMX_PROD);
		foreach my $iter(@found_tmx_prod){
			$TMX_PROD_FOUND=1;
		}
		
		my @found_l7=grep (/$address/,@L7_PROD);
		foreach my $iter(@found_l7){
			$L7_FOUND=1;
		}
		
		my $num_found=$#found_final_prod;
		
		if ($user =~ /(marex\-ut)/){
			$key=$finupass;
		}elsif ($user =~ /(\-ut$)/) {
		   $key=$utpass;
		 } elsif ($user =~ /(\-dv$)/) {
		   $key=$dvpass;
		 } elsif ($TMX_PROD_FOUND) {
			$key=$kpass;
		 } elsif ($JEFFRIES_FOUND){
			$key=$jeffp;
		} elsif ($L7_FOUND){
			$key=$finppass;
		}  
		 #Check Final's addresses
			elsif ($FINAL_PROD_FOUND) {
			$key=$finppass;
		 }elsif ($FINAL_UAT_FOUND) {
			$key=$finupass;
		 }elsif($user_group_E =~ /($user\|)/) {
				$key= $epass;
		 } elsif ($user_group_K =~ /($user\|)/){
			$key=$kpass;
		#Check Capis addresses / Backuppc
		 } elsif (($login =~ /(192\.168\.18)/)||($login =~ "backuppc-prod.ullink.lan")) {
			if(($login =~ /(122)/) || ($login =~ "backuppc-prod.ullink.lan")){
					$key=$ulpri;
				} elsif ($login =~ /(140)/){
					$key=$uluat;
			}
		 }
		#Check Banchile Gold addresses
		elsif (($login =~ /(200\.10\.0)/)) {
			if ($login =~ /(14)/) {
				$key=$bchil_dev;
			} elsif ($login =~ /(11)/) {
				$key=$utpass;
			} elsif ($login =~ /(16)/) {
			$key="$finppass";
			} elsif ($login =~ /(17)/) {
				$key="$finppass";;
			}
		} elsif ($login =~ /(ulodisys\-lt\.exan\-gold\.ullink\.net)/) {
			$key="$expass";
		}
		#Check Mizuho Addresses
		 elsif (($login =~ /(12\.149\.39)/) || ($login =~ /(208\.85\.107)/)) {
				$mizpass=~ s/\n//g;
				$key=$mizpass; 
		 }
		 else{
			#UNMATCHED USERS END UP HERE
			#RETURN UNDEFINED AT THIS POINT
			undef $key;
			return undef;
		 }
	}
}

sub set_remote_command{
	my ($command,$reg_file,$p,$remote_command_obj,%hash_vals,@vals,$value);
	while (@_)
	{
		my @first=pop @_;
		my @second=pop @_;
		while(@first){
			$command=pop @first;
		}
		while(@second){
			$reg_file=pop @second;
		}
	}
$p = "Software\\SimonTatham\\Putty\\Sessions\\$reg_file";
$main::HKEY_CURRENT_USER->Open($p, $remote_command_obj) || die "Failed Setting the remote command $!";

my $k="RemoteCommand";
$remote_command_obj->GetValues(\%hash_vals);
$remote_command_obj->SetValueEx($k,0,1,$command);
}


sub launch {
		my $host_info=shift @_;
		$host_info =~ s/\t//g;
		$host_info =~ s/ //g;
		my ($user,$host,$current_login,$process,$options,$current_env,$key,$port,$app_name,$home);
		my @launch_tokens_db =split(/\|/,$host_info);
		my $db_cursor=&db::do_lookup_app_name_address_cs(@launch_tokens_db);
	
		while (my $doc = $db_cursor->next) {
			$host			=$doc->{"app_address"   };
			$current_env	=$doc->{"environment"   };
			$user			=$doc->{"username"      };
			$key			=$doc->{"key"           };
			$port			=$doc->{"port"          };
			$app_name       =$doc->{"app_name"      };
			$home       	=$doc->{"home"      	};
		}
		
		if (not defined $key){
			$key="NO_KEY_FOUND";
		}

		 $current_login=$user."@".$host;
		
		if ($port =~ /(^\d+$)/) {			
			$current_login="$current_login -P $port";
		}

		my $login_fail=0;
		
		if ($key =~ /NO_KEY_FOUND/ ){
			#Check the missed login table
			$key=&db::do_lookup_missed_logins($current_login);
			if (not defined $key){
				$key="NO_KEY_FOUND";
				$login_fail=1;
			} else {
				$key=~ s/\n//g;
				$current_login="$current_login -pw $key";
			}
		} else {
			$current_login="$current_login -pw $key";
			$current_login =~ s/\n//g;
		}
		
		my ($command,$reg_key,@arguments);

		if ($current_env =~ /(PROD)/){
			$options=" -load PROD-Settings -ssh ".$current_login;
			$command="cd $home;bash"; 
			$reg_key="PROD-Settings";
			push(@arguments,$reg_key);
			push(@arguments,$command);
			set_remote_command(@arguments);
		}elsif ($current_env =~ /(UAT)/){
			$options=" -load \"Default Settings\" -ssh ".$current_login;
			$command="cd $home; bash";
			$reg_key="Default%20Settings";

			push(@arguments,$reg_key);
			push(@arguments,$command);
			set_remote_command(@arguments);
		} elsif ($current_env =~ /(DEV)/){;
			$options=" -load \"Default Settings\" -ssh ".$current_login;
			$command="cd $home; bash";
			$reg_key="Default%20Settings";
			push(@arguments,$reg_key);
			push(@arguments,$command);
			set_remote_command(@arguments);
		}
		
		#print "---".$options . "--";
		Win32::Process::Create($process,"putty.exe",$options,0,0,".") || die $!; 
		#Allow the process time to launch
		sleep(1);
		
		if ($login_fail){
			&db::update_missed_login("$user | $host");
		}
}

sub clear {
	my ($options,$command,$reg_key1,$reg_key2,@arguments);
	$command="bash";
	
	$reg_key1="Default%20Settings";
	$reg_key2="PROD-Settings";
	push(@arguments,$reg_key1);
	push(@arguments,$command);
	
	set_remote_command(@arguments);
	pop(@arguments);
	pop(@arguments);
	push(@arguments,$reg_key2);
	push(@arguments,$command);	
	set_remote_command(@arguments);
}

#Import files into memory for fast access 
sub import_hosts {

	open HF_HANDLE, $HOST_FILE or die "Problem with the list of hosts file: $!";
		@HOST_DATA=<HF_HANDLE>;
	close HF_HANDLE;
  
	open P_HANDLE, $pass_file or die "Problem with the pass file: $!";
		@P_DATA=<P_HANDLE>;
	close P_HANDLE;
  
	open UF_HANDLE, $users_file or die "Problem with the user data file: $!";
		@USER_DATA=<UF_HANDLE>;
	close UF_HANDLE;
	
	open FINAL_PROD_HANDLE, $final_prod or die "Could not open the final prod file: $!";
		@FINAL_PROD=<FINAL_PROD_HANDLE>;
	close FINAL_PROD;
	
	open FINAL_UAT_HANDLE, $final_uat or die "Could not open the final uat file: $!";
		@FINAL_UAT=<FINAL_UAT_HANDLE>;
	close FINAL_UAT_HANDLE;
	
	open JEFF_HANDLE, $jeff_file or die "Could not open the jeffries file: $!";
		@JEFF=<JEFF_HANDLE>;
	close JEFF_HANDLE;
	
	open TMXP_HANDLE, $tmx_prod or die "Could not open the TMX file: $!";
		@TMX_PROD=<TMXP_HANDLE>;
	close TMXP_HANDLE;
	
		open L7_HANDLE, $l7_prod or die "Could not open the TMX file: $!";
		@L7_PROD=<L7_HANDLE>;
	close L7_HANDLE;
}

sub get_host_data {
	return @HOST_DATA;
}

return 1;