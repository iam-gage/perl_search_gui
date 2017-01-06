#Gaetjens Lezin
#20150513
#This will build a mongo database of all ullink client server and dashboard servers

package db;
use strict;
use warnings;
use MongoDB;
use MongoDB::OID;
use FindBin;
use File::Basename;
use Tk::widgets;
require "search_hosts.pl";
require "open_dash.pl";

chdir $FindBin::Bin;


our $client = MongoDB::MongoClient->new("host"=>"mongodb://10.107.7.27:27017");
our $db = $client->get_database( 'ULLINK' );
our $cs = $db->get_collection( 'clients_servers' );
our $cs_f= $db->get_collection ( 'failed_login' );
our $ds = $db->get_collection( 'dashboard_servers' );


our $HOST_FILE=".\\all_boxes\\ullink_hosts_file.csv";

our @HOST_DATA;
our @DOCUMENT_DATA;

sub get_deb_key {
	my $login = shift;
	my @fields =split(/@/,$login);
	my $address=pop @fields;
	my $user=pop @fields;
	
	my $db_cursor=$cs_f->find({'address' => $address, 'username' => $user});
	my $found = $db_cursor->count;
	if (not $found) {
		return "NO_KEY_FOUND";
	} else {
		my $doc = $db_cursor->next;
		return $doc -> {'new_key'};
	}
}

sub resetter_ds{
	print "Nothing happens now :-(. Search again \n";
	my ($env,$address,$app_name);
	while (@_){
		$env = pop @_;
		$address = pop @_;
		$app_name = pop @_;

		$env =~ s/\n//;
		$address =~ s/\n//;
		$app_name =~ s/\n//;
	}
	print "environment: " . $env . " \n";
	print "address: "  . $address . " \n";
	print "name: " . $app_name . " \n";
}

sub resetter_cs{
		my $address;
		my $app_name;
		my $env;
		my $user;
		my $found;
	while(@_){
		$address=pop @_;
		$app_name=pop @_;
		$env=pop @_;
		
		$env =~s/[\n ]//;
		$app_name =~s/[\n ]//;
		$address =~s/[ ]//;
		chomp $address;
	}
	
	my @addr_user=split(/\@/,$address);
	$address=pop @addr_user;
	$user=pop @addr_user;
	#print "Address ===" . $address. "====\n";
	#print "user ===" . $user. "====\n";
	

	my $db_cursor=$cs_f->find({'address'=>$address, 'username'=>$user});
	$found=$cs_f->count;
	if ($found==0){
		print "No entries to update \n";
	} else {
		update_missed_login($user."|".$address);
	}
}

sub set_nagios_user{
	my $nagios_user="$open_dash::dashboard_user";
	my $db_cursor=$cs->find({'app_name'=>"PROD_NAGIOS"});
	my $found=$cs->count;
	if ($found){
		$cs->insert({"username"=>$nagios_user});
		my $doc=$db_cursor->next;
	}
}

sub do_lookup_missed_logins {
	my ($user,$address,$db_csf_cursor,$found,$key);
	my $params_line = shift;
	my @params =  split(/\@/,$params_line);
	while (@params){
		 $user=shift @params;
		 $address=shift @params;
	}
	$address=~ s/\n//g;
	$user=~ s/\n//g;
	$db_csf_cursor=$cs_f->find({'username'=>$user,'address'=>$address});
	$found=$db_csf_cursor->count;
	if ($found){
		my $doc=$db_csf_cursor->next;
		$key=$doc->{'new_key'};
	}
	return $key;
}

sub show_db{
	my $all_entries = $ds->find();
	while (my $doc = $all_entries->next) {
		print $doc->{'search_tokens'}."\n";
	}
}

sub show_newly_updated{
	my @newly_found;
	my $all_entries = $cs_f->find();
	while (my $doc = $all_entries->next) {
		my  $user=$doc->{'username'};
		my  $address=$doc->{'address'};
		my $new_key=$doc->{'new_key'};
		push(@newly_found, "$user | $address | $new_key");
	}
	
	return @newly_found;
}

sub update_missed_login {
	my @params=split(/\|/,shift);
	my $user=shift @params;
	my $address=shift @params;

	my $response;
	
	my $db_cursor=$cs_f->find({'address'=>$address, 'username'=>$user});
	my $found=$db_cursor->count;
	
	$address=~ s/ //g;
	$user=~ s/ //g;
	
	my $message=$user."@".$address;	
		
	if ($found==0){
		print "Auto-login attempt failed. Enter a new password: \n";
		$response=&controls::show_popup($message);
		
		if($response){
		 $cs_f->insert({"new_key"=>$response,
						 "username"=>$user,
						 "address"=>$address});
		}	
	} elsif ($found==1){
		$response=&controls::show_popup($message);
		if($response){
		  print "Updating existing record with ****\n";
		  $cs_f->update({'username'=>$user, 'address'=>$address},
		  {'$set' => {'new_key'=>$response},}
		  ,);
		}	
	}
}

#client server app name,address query
sub do_lookup_app_name_address_cs {
  my ($app, $env,$address,$user);
  my $count=0;
  foreach my $item(@_){
		if($count==0){
			$env=$item;
		} elsif ($count==1){
			$app=$item;
		}elsif($count==2) {
			my @user_host=split(/@/,$item);
			$user=shift @user_host; 
			$address=shift @user_host;
		}
		$count++;
	}  

#Strip new line characters	
  $app=~ s/\n//g;
  $env=~ s/\n//g;
  $address=~ s/\n//g;
  $user=~ s/\n//g;
  
#exact match lookup
  my $db_cursor=$cs->find({"app_name"=>$app,"app_address"=>$address});
  return $db_cursor;
} 

sub lookup_backuppc_key {
my $found;
my $search_item=shift;
my $search_token_lookup_cursor=$cs->query({'search_tokens'=> qr/$search_item/i});
	while (my $document=$search_token_lookup_cursor->next)
		   {
		 	  $found=$document->{'key'};
		   }
		   return $found;
}

#Client Server query 
sub lookup_cs {
	 my @results=();
	 my @search_tokens=split(/ /,shift);
	 my @previous_tokens; 
	 while(@search_tokens){
		 my $search_item=shift(@search_tokens); 
		if ($#results==-1){
			#this is the initial search		 
		   my $search_token_lookup_cursor=$cs->query({'search_tokens'=> qr/$search_item/i});
		   while (my $document=$search_token_lookup_cursor->next)
		   {
		 	 my $found=$document->{'search_tokens'}."\n";
			 push (@results,$found);
		   }
		} else {
			#lookup only amongst the previously found tokens
			while(@results){
				push (@previous_tokens,pop @results);
			}
			@results=grep( /$search_item/i,@previous_tokens); 
			@previous_tokens=();
		}
	 }
	return @results;
}

#Dasbhboard name, address query
sub do_lookup_app_name_address_daps{
	my ($dashboard_name, $address,$db_cursor_dap);
	my $arg_received=shift;
	#print $arg_received. "======";
	#my  $stopnow = <>;
	my @params=split(/\|/,$arg_received);
	while(@params)
	{
		pop @params;
		$address=pop @params;
		$dashboard_name=pop @params;
	}
	
	$address=~s/ //g;
	$dashboard_name=~s/ //g;
	$dashboard_name=~s/\n//g;
	
	$db_cursor_dap=$ds->find({'app_name'=> $dashboard_name,'address'=> $address});
	return $db_cursor_dap;
}

#Dashboard query
sub lookup_daps {

	 my @results=();
	 my @search_tokens=split(/ /,shift);
	 my @previous_tokens; 
	 while(@search_tokens){
		 my $search_item=pop(@search_tokens); 
		if ($#results==-1){
			#this is the initial search		 
		   my $search_token_lookup_cursor=$ds->query({'search_tokens'=> qr/$search_item/i});
		   while (my $document=$search_token_lookup_cursor->next)
		   {
		 	 my $found=$document->{'search_tokens'}."\n";
			 push (@results,$found);
		   }
		} else {
			#lookup only amongst the previously found tokens
			while(@results){
				push (@previous_tokens,pop @results);
			}
			@results=grep( /$search_item/i,@previous_tokens); 
			@previous_tokens=();
		}
	 }
	 return @results;
}

return 1;
