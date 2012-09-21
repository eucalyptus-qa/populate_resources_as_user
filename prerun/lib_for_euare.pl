#!/usr/bin/perl
use strict;

########################## SUBROUTINES #####################################

sub get_user_credentials{
	my $account = shift @_;
	my $user = shift @_;

	my $zip_file = $account . "_" . $user . "_cred.zip"; 

	print "\n";
	print "########################### GET-CREDENTIALS  ##############################\n";

	### Generate user credentials
	print "$ENV{'QA_CLC_IP'} :: $ENV{'EUCALYPTUS'}/usr/sbin/euca_conf --get-credentials $zip_file --cred-account $account --cred-user $user\n";
	system("ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$ENV{'QA_CLC_IP'} \"cd /root; $ENV{'EUCALYPTUS'}/usr/sbin/euca_conf --get-credentials $zip_file --cred-account $account --cred-user $user\" ");

	### Download account credentials
	print "ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$ENV{'QA_CLC_IP'} \"ls /root/$zip_file\" \n";
	my $out = `ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$ENV{'QA_CLC_IP'} \"ls /root/$zip_file\" `;
	
	print "LOCATED on CLC:";
	print "$out\n";
	print "\n";

	if( $out =~ /$zip_file/ ){
		return 0;
	};
	
	return 1;
};

sub download_user_credentials{
	my $account = shift @_;
	my $user = shift @_;

	my $zip_file = $account . "_" . $user . "_cred.zip"; 

	print "\n";
	print "########################### DOWNLOAD CREDENTIALS  ##############################\n";

	### Download account credentials
	print "scp -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$ENV{'QA_CLC_IP'}:/root/$zip_file ../credentials/.";
	system("scp -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$ENV{'QA_CLC_IP'}:/root/$zip_file ../credentials/.");

	if( -e "../credentials/$zip_file" ){
		system("cd ../credentials; unzip -o $zip_file");
		return 0;
	};

	print "[TEST_REPORT]\tFAILED in downloading credentials $zip_file !!\n\n";

	return 1;
};

sub unzip_cred_on_clc{

	my $cred_name = shift @_;
	my $user_name = shift @_;

	my $zip_file = $cred_name . "_" . $user_name . "_cred.zip"; 

	print "\n";
	print "########################### UNZIP CREDENTIALS ##############################\n";

	### unzip credentials
	print("ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$ENV{'QA_CLC_IP'} \"mkdir -p /root/cred_depot/$cred_name/$user_name; mv /root/$zip_file /root/cred_depot/$cred_name/$user_name/.; cd /root/cred_depot/$cred_name/$user_name; unzip -o $zip_file\"\n");
	my $out =`ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$ENV{'QA_CLC_IP'} \"mkdir -p /root/cred_depot/$cred_name/$user_name; mv /root/$zip_file /root/cred_depot/$cred_name/$user_name/.; cd /root/cred_depot/$cred_name/$user_name; unzip -o $zip_file\" `;
	print "\n";

	print "$out\n";

	if( $out =~ /eucarc/ ){
		return 0;
	};

	print "[TEST_REPORT]\tFAILED in unzipping $zip_file!!\n\n";

	return 1;
};


sub create_account{
	my $account = shift @_;

	print "\n";
	print "########################### EUARE-ACCOUNTCREATE ##############################\n";

	### create test account
	print "$ENV{'QA_CLC_IP'} :: euare-accountcreate -a $account\n";
	system("ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$ENV{'QA_CLC_IP'} \"source /root/cred_depot/eucalyptus/admin/eucarc; euare-accountcreate -a $account\" ");
	sleep(3);

	print "\n";
	print "\n";
	print "########################### EUARE-ACCOUNTLIST ##############################\n";

	print "$ENV{'QA_CLC_IP'} :: euare-accountlist\n";
	my $out = `ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$ENV{'QA_CLC_IP'} \"source /root/cred_depot/eucalyptus/admin/eucarc; euare-accountlist\" `;
	print "\n";
	print $out . "\n";
	print "\n";
	
	if( $out =~ /$account/ ){
		print "[TEST_REPORT]\tSucceeded in creating account $account\n\n";
		return 0;
	};
	
	print "[TEST_REPORT]\tFAILED in creating account $account!!\n\n";	

	return 1;
};

sub create_account_user{
	my $account = shift @_;
	my $user = shift @_;

	print "\n";
	print "########################### EUARE-USERCREATE ##############################\n";

	### create test account
	print "$ENV{'QA_CLC_IP'} :: euare-usercreate -u $user\n";
	system("ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$ENV{'QA_CLC_IP'} \"source /root/cred_depot/$account/admin/eucarc; euare-usercreate -u $user\" ");
	sleep(3);

	print "\n";
	print "\n";
	print "########################### EUARE-USERLISTBYPATH ##############################\n";

	print "$ENV{'QA_CLC_IP'} :: euare-userlistbypath\n";
	my $out = `ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$ENV{'QA_CLC_IP'} \"source /root/cred_depot/$account/admin/eucarc; euare-userlistbypath\" `;
	print "\n";
	print $out . "\n";
	print "\n";
	
	if( $out =~ /$user/ ){
		print "[TEST_REPORT]\tSucceeded in creating user $user under account $account\n\n";
		return 0;
	};

	print "[TEST_REPORT]\tFAILED in creating account $account!!\n\n";	

	return 1;
};


sub copy_all_policy_file{
	print "\n";
	print "########################### COPY-ALL-POLICY-FILE ##############################\n";

	### copy all policy file to CLC machine
	print "scp -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no ./all.policy root\@$ENV{'QA_CLC_IP'}:/root/.\n";
	system("scp -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no ./all.policy root\@$ENV{'QA_CLC_IP'}:/root/.");
	return 0;
};

sub allow_account_user_fullaccess{
	my $account = shift @_;
	my $user = shift @_;

	print "\n";
	print "########################### ALLOW-ACCOUNT-USER-FULLACCESS ##############################\n";

	### set account user policy
	print "$ENV{'QA_CLC_IP'} :: euare-useruploadpolicy -u $user -p fullaccess -f all.policy\n";
	system("ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$ENV{'QA_CLC_IP'} \"source /root/cred_depot/$account/admin/eucarc; euare-useruploadpolicy -u $user -p fullaccess -f all.policy\" ");
	print "\n";

	return 0;
};

sub is_test_account_name_from_memo{
	$ENV{'QA_MEMO_TEST_ACCOUNT_NAME'} = "";
        if( $ENV{'QA_MEMO'} =~ /^TEST_ACCOUNT_NAME=(.+)\n/m ){
                my $extra = $1;
                $extra =~ s/\r//g;
                print "FOUND in MEMO\n";
                print "TEST_ACCOUNT_NAME=$extra\n";
                $ENV{'QA_MEMO_TEST_ACCOUNT_NAME'} = $extra;
                return 1;
        };
        return 0;
};

sub is_test_account_user_name_from_memo{
	$ENV{'QA_MEMO_TEST_ACCOUNT_USER_NAME'} = "";
        if( $ENV{'QA_MEMO'} =~ /^TEST_ACCOUNT_USER_NAME=(.+)\n/m ){
                my $extra = $1;
                $extra =~ s/\r//g;
                print "FOUND in MEMO\n";
                print "TEST_ACCOUNT_USER_NAME=$extra\n";
                $ENV{'QA_MEMO_TEST_ACCOUNT_USER_NAME'} = $extra;
                return 1;
        };
        return 0;
};


# does_It_Have( $arg1, $arg2 )
# does the string $arg1 have $arg2 in it ??
sub does_It_Have{
	my ($string, $target) = @_;
	if( $string =~ /$target/ ){
		return 1;
	};
	return 0;
};


# Read input values from input.txt
sub read_input_file{

	my $is_memo = 0;
	my $memo = "";

	open( INPUT, "< ../input/2b_tested.lst" ) || die $!;

	$ENV{'QA_CLC_IP'} = "";
	my $line;
	while( $line = <INPUT> ){
		chomp($line);
		if( $is_memo ){
			if( $line ne "END_MEMO" ){
				$memo .= $line . "\n";
			};
		};

        	if( $line =~ /^([\d\.]+)\t(.+)\t(.+)\t(\d+)\t(.+)\t\[(.+)\]/ ){
			my $qa_ip = $1;
			my $qa_distro = $2;
			my $qa_distro_ver = $3;
			my $qa_arch = $4;
			my $qa_source = $5;
			my $qa_roll = $6;

			my $this_roll = lc($6);
			if( $this_roll =~ /clc/ && $ENV{'QA_CLC_IP'} eq "" ){
				print "\n";
				print "IP $qa_ip [Distro $qa_distro, Version $qa_distro_ver, ARCH $qa_arch] is built from $qa_source as Eucalyptus-$qa_roll\n\n";
				$ENV{'QA_CLC_IP'} = $qa_ip;
				$ENV{'QA_DISTRO'} = $qa_distro;
				$ENV{'QA_DISTRO_VER'} = $qa_distro_ver;
				$ENV{'QA_ARCH'} = $qa_arch;
				$ENV{'QA_SOURCE'} = $qa_source;
				$ENV{'QA_ROLL'} = $qa_roll;
			};
		}elsif( $line =~ /^MEMO/ ){
			$is_memo = 1;
		}elsif( $line =~ /^END_MEMO/ ){
			$is_memo = 0;
		};
	};	

	close(INPUT);

	$ENV{'QA_MEMO'} = $memo;

	return 0;
};

1;

