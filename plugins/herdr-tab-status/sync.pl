#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use JSON::PP qw(decode_json encode_json);
use Time::HiRes qw(sleep);

package HerdrTabStatus;
use strict;
use warnings;
use utf8;

my %PRIORITY = (working => 1, idle => 2, unknown => 2, done => 3, blocked => 4);
my %MARKER = (blocked => '🔴', done => '🟢', working => '🟡', idle => '⚪', unknown => '⚪');

sub read_json {
    my ($file, $fallback) = @_;
    open my $fh, '<:raw', $file or do {
        return $fallback if $!{ENOENT};
        die "cannot open $file: $!\n";
    };
    local $/;
    my $bytes = <$fh>;
    close $fh or die "cannot close $file: $!\n";
    return JSON::PP::decode_json($bytes);
}

sub write_json_atomic {
    my ($file, $value) = @_;
    my $temp = "$file.$$.tmp";
    eval {
        open my $fh, '>:raw', $temp or die "cannot write $temp: $!\n";
        print {$fh} JSON::PP::encode_json($value), "\n";
        close $fh or die "cannot close $temp: $!\n";
        rename $temp, $file or die "cannot replace $file: $!\n";
        1;
    } or do {
        my $error = $@;
        unlink $temp;
        die $error;
    };
}

# Concurrent Herdr event hooks must not race on the label ownership state.
sub with_lock {
    my ($dir, $action) = @_;
    File::Path::make_path($dir);
    my $lock = "$dir/.sync-lock";
    my $acquired;
    for my $attempt (0 .. 59) {
        if (mkdir $lock) {
            $acquired = 1;
            last;
        }
        die "cannot acquire $lock: $!\n" unless $!{EEXIST};
        my @stat = stat $lock;
        if (@stat && time - $stat[9] > 30) {
            rmdir $lock;  # Stale lock from a failed invocation.
        }
        Time::HiRes::sleep(0.05);
    }
    die "timed out waiting for tab name synchronization\n" unless $acquired;
    my $ok = eval { $action->(); 1 };
    my $error = $@;
    rmdir $lock or warn "cannot release $lock: $!\n";
    die $error unless $ok;
}

sub directory_label {
    my ($cwd, $home, $max_length) = @_;
    return undef unless defined $cwd && length $cwd;
    my $label = $cwd eq $home ? '~' : (File::Basename::basename($cwd) || $cwd);
    if ($max_length && length($label) > $max_length) {
        $label = substr($label, 0, $max_length - 1) . '…';
    }
    return $label;
}

sub focused_cwd {
    my ($panes) = @_;
    my ($focused) = grep { $_->{focused} } @$panes;
    my $pane = $focused // $panes->[0];
    return undef unless $pane;
    return $pane->{foreground_cwd} || $pane->{cwd};
}

sub has_agent {
    my ($pane) = @_;
    for my $key (qw(agent display_agent)) {
        return 1 if defined $pane->{$key} && !ref($pane->{$key}) && $pane->{$key} =~ /\S/;
    }
    return defined($pane->{agent_session});
}

sub most_urgent_status {
    my ($panes) = @_;
    my $status;
    for my $pane (@$panes) {
        next unless has_agent($pane);
        my $candidate = $pane->{agent_status} // 'unknown';
        $candidate = 'unknown' unless exists $PRIORITY{$candidate};
        $status = $candidate if !defined($status) || $PRIORITY{$candidate} > $PRIORITY{$status};
    }
    return $status;
}

sub next_tab_label {
    my ($tab, $panes, $previous, $legacy_owned_label, $config, $home) = @_;
    my $current = $tab->{label};
    my $cwd = directory_label(focused_cwd($panes), $home, $config->{max_length});
    my $previous_matches = defined($previous) && defined($previous->{lastLabel})
        && $previous->{lastLabel} eq $current;
    my $base = $previous_matches ? $previous->{base} : $current;
    $base =~ s/^(?:🔴|🟢|🟡|⚪) // unless $previous_matches;
    my $automatic = $config->{overwrite_manual} || ($previous_matches
        ? $previous->{automatic}
        : $current =~ /^\d+$/ || (!defined($previous)
            && ((defined($legacy_owned_label) && $legacy_owned_label eq $current)
                || (defined($cwd) && $cwd eq $base))));
    my $next_base = $automatic && defined($cwd) ? $cwd : $base;
    my $status = most_urgent_status($panes);
    my $label = defined $status ? "$MARKER{$status} $next_base" : $next_base;
    return ($label, { lastLabel => $label, base => $next_base,
                      automatic => $automatic ? JSON::PP::true : JSON::PP::false });
}

sub invoke_herdr {
    my (@args) = @_;
    my $binary = $ENV{HERDR_BIN_PATH} || 'herdr';
    open my $fh, '-|', $binary, @args or die "cannot execute $binary: $!\n";
    local $/;
    my $json = <$fh>;
    close $fh or die "herdr @args failed ($?)\n";
    my $response = JSON::PP::decode_json($json);
    die "herdr @args: $response->{error}{message}\n" if $response->{error};
    return $response->{result} // $response;
}

sub synchronize {
    my (%opts) = @_;
    my $herdr = $opts{herdr} || \&invoke_herdr;
    my $home = $opts{home} // $ENV{HOME} // '';
    my $state_dir = $opts{state_dir} // $ENV{HERDR_PLUGIN_STATE_DIR}
        // die "HERDR_PLUGIN_STATE_DIR is required\n";
    my $config_dir = $opts{config_dir} // $ENV{HERDR_PLUGIN_CONFIG_DIR};

    with_lock($state_dir, sub {
        my $legacy_config = defined $config_dir
            ? read_json(File::Basename::dirname($config_dir) . '/dev-shimada.auto-tab-name/config.json', {})
            : {};
        my $settings = defined $config_dir
            ? read_json("$config_dir/config.json", $legacy_config) : $legacy_config;
        my $max = $settings->{max_length};
        my $config = {
            overwrite_manual => $settings->{overwrite_manual} ? 1 : 0,
            max_length => defined($max) && !ref($max) && $max =~ /^\d+$/ && $max > 0 ? $max : 0,
        };
        my $previous = read_json("$state_dir/labels.json", {});
        my $legacy_state = read_json(File::Basename::dirname($state_dir)
            . '/dev-shimada.auto-tab-name/labels.json', {});
        my %next;
        my $workspaces = $herdr->('workspace', 'list')->{workspaces};
        die "invalid Herdr workspace list\n" unless ref $workspaces eq 'ARRAY';
        for my $workspace (@$workspaces) {
            my @target = ('--workspace', $workspace->{workspace_id});
            my $tabs = $herdr->('tab', 'list', @target)->{tabs};
            my $panes = $herdr->('pane', 'list', @target)->{panes};
            die "invalid Herdr tab/pane list\n"
                unless ref $tabs eq 'ARRAY' && ref $panes eq 'ARRAY';
            for my $tab (@$tabs) {
                my @tab_panes = grep { $_->{tab_id} eq $tab->{tab_id} } @$panes;
                my ($label, $record) = next_tab_label($tab, \@tab_panes,
                    $previous->{$tab->{tab_id}}, $legacy_state->{$tab->{tab_id}}, $config, $home);
                $herdr->('tab', 'rename', $tab->{tab_id}, $label) if $tab->{label} ne $label;
                $next{$tab->{tab_id}} = $record;
            }
        }
        write_json_atomic("$state_dir/labels.json", \%next);
    });
}

unless (caller) {
    eval { synchronize(); 1 } or do {
        warn "tab-agent-status: $@";
        exit 1;
    };
}
1;
