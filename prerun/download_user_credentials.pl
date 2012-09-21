#!/usr/bin/perl
use strict;
use Cwd;

require "./lib_for_euare.pl";

$ENV{'EUCALYPTUS'} = "/opt/eucalyptus";


################################################## DOWNLOAD USER CREDENTIALS . PL #########################################################


###
### check for arguments
###

my $given_account_name = "";
my $given_user_name = "";


if ( @ARGV > 0 ){
	$given_account_name = shift @ARGV;
};

if ( @ARGV > 0 ){
	$given_user_name = shift @ARGV;
};


###
### read the input list
###

print "\n";
print "########################### READ INPUT FILE  ##############################\n";

read_input_file();

my $clc_ip = $ENV{'QA_CLC_IP'};
my $source_lst = $ENV{'QA_SOURCE'};

if( $clc_ip eq "" ){
	print "[ERROR]\tCouldn't find CLC's IP !\n";
	exit(1);
};

if( $source_lst eq "PACKAGE" || $source_lst eq "REPO" ){
        $ENV{'EUCALYPTUS'} = "";
};



###
### check for TEST_ACCOUNT_NAME in MEMO
###

print "\n";
print "########################### GET ACCOUNT AND USER NAME  ##############################\n";

my $account_name = "default-qa-account";
my $user_name = "default-qa-user";

if( $given_account_name ne "" ){
	$account_name = $given_account_name;
}elsif( is_test_account_name_from_memo() ){
	$account_name = $ENV{'QA_MEMO_TEST_ACCOUNT_NAME'};
};

if( $given_user_name ne "" ){
	$user_name = $given_user_name;
}elsif( is_test_account_user_name_from_memo() ){
	$user_name = $ENV{'QA_MEMO_TEST_ACCOUNT_USER_NAME'};
};

print "\n";
print "TEST ACCOUNT NAME [$account_name]\n";
print "TEST USER NAME [$user_name]\n";
print "\n";



###
### clean up all the pre-existing credentials
###

print "\n";
print "########################### CLEAN UP CREDENTIALS  ##############################\n";

print "\n";
print "rm -f ../credentials/*\n";
system("rm -f ../credentials/*");

print "\n";
print("ssh -o StrictHostKeyChecking=no root\@$clc_ip \"cd /root; rm -f *_cred.zip\"\n");
system("ssh -o StrictHostKeyChecking=no root\@$clc_ip \"cd /root; rm -f *_cred.zip\" ");



###
### create test account crdentials
###

my $count = 1;
while( $count > 0 ){
	if( get_user_credentials($account_name, $user_name) == 0 ){
		$count = 0;
	}else{
		print "Trial $count\tCould Not Create Account \'$account_name\' User \'$user_name\' Credentials\n";
		$count++;
		if( $count > 60 ){
			print "[TEST_REPORT]\tFAILED to Create Account \'$account_name\' User \'$user_name\' Credentials !!!\n";
			exit(1);
		};
		sleep(1);
	};
};
print "\n";


download_user_credentials($account_name, $user_name);


###
### End of Script
###

print "\n";
print "[TEST_REPORT]\tDOWNLOAD USER CREDENTIAL HAS BEEN COMPLETED\n";
print "\n";

exit(0);

1;


