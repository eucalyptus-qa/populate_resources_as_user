#!/usr/bin/perl

require "ec2ops.pl";

my $account = shift @ARGV || "eucalyptus";
my $user = shift @ARGV || "admin";

# need to add randomness, for now, until account/user group/keypair
# conflicts are resolved

$rando = int(rand(10)) . int(rand(10)) . int(rand(10));
if ($account ne "eucalyptus") {
#    $account .= "$rando";			### NOT NEEDED	092012
}
if ($user ne "admin") {
#    $user .= "$rando";				### NOT NEEDED	092012
}
$newgroup = "ebsgroup$rando";
$newkeyp = "ebskey$rando";

parse_input();
print "SUCCESS: parsed input\n";

setlibsleep(2);
print "SUCCESS: set sleep time for each lib call\n";

setremote($masters{"CLC"});
print "SUCCESS: set remote CLC: masterclc=$masters{CLC}\n";

discover_emis();
print "SUCCESS: discovered loaded image: current=$current_artifacts{instancestoreemi}, all=$static_artifacts{instancestoreemis}\n";

discover_zones();
print "SUCCESS: discovered available zone: current=$current_artifacts{availabilityzone}, all=$static_artifacts{availabilityzones}\n";

if ( ($account ne "eucalyptus") && ($user ne "admin") ) {
# create new account/user and get credentials
#    create_account_and_user($account, $user);
 #   print "SUCCESS: account/user $current_artifacts{account}/$current_artifacts{user}\n";
    
  #  grant_allpolicy($account, $user);
  #  print "SUCCESS: granted $account/$user all policy permissions\n";
    
    get_credentials($account, $user);
    print "SUCCESS: downloaded and unpacked credentials\n";
    
    source_credentials($account, $user);
    print "SUCCESS: will now act as account/user $account/$user\n";
}
# moving along

add_keypair("$newkeyp");
print "SUCCESS: added new keypair: $current_artifacts{keypair}, $current_artifacts{keypairfile}\n";

add_group("$newgroup");
print "SUCCESS: added group: $current_artifacts{group}\n";

authorize_ssh();
print "SUCCESS: authorized ssh access to VM\n";

run_instances(1);
print "SUCCESS: ran instance: $current_artifacts{instance}\n";

wait_for_instance();
print "SUCCESS: instance went to running: $current_artifacts{instancestate}\n";

wait_for_instance_ip();
print "SUCCESS: instance got public IP: $current_artifacts{instanceip}\n";

wait_for_instance_ip_private();
print "SUCCESS: instance got private IP: $current_artifacts{instanceprivateip}\n";

ping_instance_from_cc();
print "SUCCESS: instance private IP pingable from CC: instanceip=$current_artifacts{instanceprivateip} ccip=$current_artifacts{instancecc}\n";
sleep(30);

create_volume(1);
print "SUCCESS: created volume: vol=$current_artifacts{volume}\n";

wait_for_volume();
print "SUCCESS: volume became available: vol=$current_artifacts{volume}, volstate=$current_artifacts{volumestate}\n";

attach_volume();
print "SUCCESS: attached volume: volstate=$current_artifacts{volumestate}\n";
sleep(60);

wait_for_volume_attach();
print "SUCCESS: volume became attached: volstate=$current_artifacts{volumestate}\n";

find_instance_volume();
$idev = $current_artifacts{instancedevice};
print "SUCCESS: discovered instance local EBS dev name: $idev\n";

setrunat("runat 180");
run_instance_command("echo y | mkfs.ext3 $idev");
setrunat("runat 30");
run_instance_command("mkdir -p /tmp/testmount");
run_instance_command("mount $idev /tmp/testmount");
run_instance_command("dd if=/dev/zero of=/tmp/testmount/file bs=1M count=10");
run_instance_command("umount /tmp/testmount");
print "SUCCESS: formatted, mounted, copied data to, and unmounted volume\n";

detach_volume();
print "SUCCESS: detached volume\n";
wait_for_volume_detach();
print "SUCCESS: volume became detached: volstate=$current_artifacts{volumestate}\n";

attach_volume();
print "SUCCESS: attached volume: volstate=$current_artifacts{volumestate}\n";
wait_for_volume_attach();
print "SUCCESS: volume became attached: volstate=$current_artifacts{volumestate}\n";

find_instance_volume();
$idev = $current_artifacts{instancedevice};
print "SUCCESS: discovered instance local EBS dev name: $idev\n";

run_instance_command("mkdir -p /tmp/testmount");
run_instance_command("mount $idev /tmp/testmount");
run_instance_command("ls /tmp/testmount/file");
run_instance_command("umount /tmp/testmount");
print "SUCCESS: re-mounted, verified data, and unmounted volume\n";

#reboot_instance();
#print "SUCCESS: rebooted instance: $current_artifacts{instance}\n";

#wait_for_instance();
#print "SUCCESS: instance went to running: $current_artifacts{instancestate}\n";

#wait_for_instance_ip();
#print "SUCCESS: instance got public IP: $current_artifacts{instanceip}\n";

#wait_for_instance_ip_private();
#print "SUCCESS: instance got private IP: $current_artifacts{instanceprivateip}\n";

#ping_instance_from_cc();
#print "SUCCESS: instance private IP pingable from CC: instanceip=$current_artifacts{instanceprivateip} ccip=$current_artifacts{instancecc}\n";
#sleep(30);

#find_instance_volume();
#$idev = $current_artifacts{instancedevice};
#print "SUCCESS: discovered instance local EBS dev name: $idev\n";
#print "Using local EBS dev name: $idev\n";

#run_instance_command("mkdir -p /tmp/testmount");
#run_instance_command("mount $idev /tmp/testmount");
#run_instance_command("ls /tmp/testmount/file");
#run_instance_command("umount /tmp/testmount");

#print "SUCCESS: re-mounted, verified data, and unmounted volume\n";

#detach_volume();
#print "SUCCESS: detached volume\n";

#wait_for_volume_detach();
#print "SUCCESS: volume became detached: volstate=$current_artifacts{volumestate}\n";

create_snapshot();
print "SUCCESS: created snapshot: snap=$current_artifacts{snapshot}\n";

settrycount(360);
wait_for_snapshot();
settrycount(180);
print "SUCCESS: snapshot became available: snap=$current_artifacts{snapshotstate}\n";

#run_command("euca-allocate-address");			###	ADDED TO POPULATE ADDRESS	092012

print "\n\n";
print "==========================================================";
print " POPULATED EBS ";
print "==========================================================";
print "\n\n";


exit(0);


delete_volume();
print "SUCCESS: volume deleted: vol=$current_artifacts{volume} state=$current_artifacts{volumestate}\n";

create_snapshot_volume();
print "SUCCESS: volume created from snapshot: vol=$current_artifacts{volume}\n";

wait_for_volume();
print "SUCCESS: volume became available: vol=$current_artifacts{volume}, volstate=$current_artifacts{volumestate}\n";

attach_volume();
print "SUCCESS: attached volume: volstate=$current_artifacts{volumestate}\n";

wait_for_volume_attach();
print "SUCCESS: volume became attached: volstate=$current_artifacts{volumestate}\n";

find_instance_volume();
$idev = $current_artifacts{instancedevice};
print "SUCCESS: discovered instance local EBS dev name: $idev\n";

setrunat("runat 180");
run_instance_command("echo y | mkfs.ext3 $idev");
setrunat("runat 30");
run_instance_command("mkdir -p /tmp/testmount");
run_instance_command("mount $idev /tmp/testmount");
run_instance_command("dd if=/dev/zero of=/tmp/testmount/file bs=1M count=10");
run_instance_command("umount /tmp/testmount");
print "SUCCESS: formatted, mounted, copied data to, and unmounted volume\n";

detach_volume();
print "SUCCESS: detached volume\n";
wait_for_volume_detach();
print "SUCCESS: volume became detached: volstate=$current_artifacts{volumestate}\n";

attach_volume();
print "SUCCESS: attached volume: volstate=$current_artifacts{volumestate}\n";
wait_for_volume_attach();
print "SUCCESS: volume became attached: volstate=$current_artifacts{volumestate}\n";

find_instance_volume();
$idev = $current_artifacts{instancedevice};
print "SUCCESS: discovered instance local EBS dev name: $idev\n";

run_instance_command("mkdir -p /tmp/testmount");
run_instance_command("mount $idev /tmp/testmount");
run_instance_command("ls /tmp/testmount/file");
run_instance_command("umount /tmp/testmount");
print "SUCCESS: re-mounted, verified data, and unmounted volume\n";

reboot_instance();

wait_for_instance();
print "SUCCESS: instance went to running: $current_artifacts{instancestate}\n";

wait_for_instance_ip();
print "SUCCESS: instance got public IP: $current_artifacts{instanceip}\n";

wait_for_instance_ip_private();
print "SUCCESS: instance got private IP: $current_artifacts{instanceprivateip}\n";

ping_instance_from_cc();
print "SUCCESS: instance private IP pingable from CC: instanceip=$current_artifacts{instanceprivateip} ccip=$current_artifacts{instancecc}\n";
sleep(30);

find_instance_volume();
$idev = $current_artifacts{instancedevice};
print "SUCCESS: discovered instance local EBS dev name: $idev\n";
print "Using local EBS dev name: $idev\n";

run_instance_command("mkdir -p /tmp/testmount");
run_instance_command("mount $idev /tmp/testmount");
run_instance_command("ls /tmp/testmount/file");
run_instance_command("umount /tmp/testmount");
print "SUCCESS: re-mounted, verified data, and unmounted volume\n";

detach_volume();
print "SUCCESS: detached volume\n";

wait_for_volume_detach();
print "SUCCESS: volume became detached: volstate=$current_artifacts{volumestate}\n";

doexit(0, "EXITING SUCCESS\n");

###	DO NOT DELETE !!

delete_volume();
print "SUCCESS: volume deleted: vol=$current_artifacts{volume} state=$current_artifacts{volumestate}\n";

delete_snapshot();
print "SUCCESS: snapshot deleted: snap=$current_artifacts{snapshot}, snapstate=$current_artifacts{snapshotstate}\n";

doexit(0, "EXITING SUCCESS\n");
