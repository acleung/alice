print "/------------------\\\n";
print "| A.L.I.C.E. v0.08 |\n";
print "\\------------------/\n\n";
print "MOBILE SUIT OPERATION SYSTEM\n";
print "[A] \n";
print "[L] \n";
print "[I] \n";
print "[C] \n";
print "[E] \n";

# This is the adb command we use to interact with the device.
# The default is adb.exe (Windows CMD is ok without the .exe) 
my $adb = "adb";

# Override this for Mac.
if ($^O =~/.*darwin.*/) {
 $adb = "./adb.mac";
}

# Override this for Linux.
if ($^O =~/.*linux.*/) {
 $adb = "./adb.linux";
}

my @commands = ();
my @devices = ();
my @lengths = ();
my @widths = ();
my $input;

sub long_die {
 local $message = @_[0];
 print "$message\n";
 sleep 10;
 die ":(";
}

if (not open($input, "battle_data.txt")) {
 long_die "Could not locate battle data!";
}

while (my $line = <$input>) {
 next if ($line =~/.*\#.*/);
 next if not length(chomp($line));
 push @commands, $line;
}

my $check = qx ($adb devices);
print "checking: $check\n";
foreach my $line (split /^/, $check) {
 push @devices, $1 if $line =~ /(.*) *device$/
}

if (not @devices) {
 long_die "No device found!";
}

# Skip all the devices where ggen is not running.
my @targets = ();
foreach my $device (@devices) {
 my $cmd = qx ($adb -s $device shell ps);
 foreach my $line (split /^/, $cmd) {
  if ($line =~/com.namcobandaigames.ggene.frontier/) {
   push @targets, $device;
  }
 }
}

my $numtargets = scalar @targets;
print "Found $numtargets device(s)!\n\n";

@devices = @targets;

my %L =();
my %w =();

foreach my $device (@devices) {
 my $cmd = qx ($adb -s $device shell dumpsys window);
 foreach my $line (split /^/, $cmd) {
  if ($line =~/mRestrictedScreen.* ([0-9]+)x([0-9]+)/) {
   $L->{$device} = $2;
   $W->{$device} = $1;
   print "Device ($device) resolution: $2 x $1\n";
  }
 }
}

sub compute_l {
 local $device = @_[0];
  local $L = $L->{$device};
  return int ($L * @_[1] / 100);
}

sub compute_w {
 local $device = @_[0];
  local $L = $L->{$device};
  local $W = $W->{$device};
  local $border = $W - ($L * 1.5);
  $border = 0 if $border < 0;
  return int ((($W - $border) * @_[1] / 100) + ($border / 2));
}

sub click_area {
 @param = @_;
 foreach my $device (@devices) {
  local $L_click = compute_l($device, @param[0]);
  local $W_click = compute_w($device, @param[1]);
  qx ($adb -s $device shell input touchscreen tap $W_click $L_click);
 }
}

sub swipe_area {
 @param = @_;
 foreach my $device (@devices) {
  local $L_start = compute_l($device, @param[0]);
  local $W_start = compute_w($device, @param[1]);
  local $L_end   = compute_l($device, @param[2]);
  local $W_end   = compute_w($device, @param[3]);
  qx ($adb -s $device shell input touchscreen swipe $W_start $L_start $W_end $L_end 2000);
 }
}

print "\nTrigger touch screen script.\n";
print "Close this window to stop.\n";

while (true) {
 foreach my $line (@commands) {
   if ($line =~/ *click_area +([0-9]+) +([0-9]+)/) {
     click_area ((int $1),(int $2));
   }
   if ($line =~/ *swipe_area +([0-9]+) +([0-9]+) +([0-9]+) +([0-9]+)/) {
     swipe_area ((int $1),(int $2),(int $3),(int $4));
   }
   if ($line =~/ *wait +([0-9]+)/) {
     sleep (int $1);
   }
 }
}
