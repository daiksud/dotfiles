#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Basename qw(dirname);
use JSON::PP qw(decode_json);
use FindBin;
require "$FindBin::Bin/sync.pl";

sub pane {
    my (%args) = @_;
    return { tab_id => 'w1:t1', cwd => '/home/tester/code', agent_status => 'idle', %args };
}

sub fixture {
    my (%args) = @_;
    my $root = tempdir(CLEANUP => 1);
    my $state_dir = "$root/state/daiksud.tab-agent-status";
    my $config_dir = "$root/config/daiksud.tab-agent-status";
    make_path($state_dir, $config_dir);
    my $state = {
        tabs => $args{tabs} // [{ tab_id => 'w1:t1', label => '1' }],
        panes => $args{panes} // [],
        commands => [],
    };
    my $herdr = sub {
        my (@cmd) = @_;
        push @{$state->{commands}}, [@cmd];
        my $name = join(' ', @cmd[0, 1]);
        return { workspaces => [{ workspace_id => 'w1' }] } if $name eq 'workspace list';
        return { tabs => $state->{tabs} } if $name eq 'tab list';
        return { panes => $state->{panes} } if $name eq 'pane list';
        if ($name eq 'tab rename') {
            for my $tab (@{$state->{tabs}}) {
                if ($tab->{tab_id} eq $cmd[2]) {
                    $tab->{label} = $cmd[3];
                    return {};
                }
            }
            die "unknown tab $cmd[2]";
        }
        die "unexpected invocation: @cmd";
    };
    return {
        root => $root, state => $state, state_dir => $state_dir,
        config_dir => $config_dir,
        sync => sub { HerdrTabStatus::synchronize(herdr => $herdr,
            state_dir => $state_dir, config_dir => $config_dir, home => '/home/tester') },
    };
}

sub label { return $_[0]{state}{tabs}[0]{label} }
sub renames {
    return scalar grep { $_->[0] eq 'tab' && $_->[1] eq 'rename' } @{$_[0]{state}{commands}};
}
sub read_file {
    open my $fh, '<:raw', $_[0] or die $!;
    local $/;
    return <$fh>;
}
sub write_file {
    my ($file, $data) = @_;
    open my $fh, '>:raw', $file or die $!;
    print {$fh} $data;
    close $fh or die $!;
}

subtest 'focused pane directory; no Agent means no marker' => sub {
    my $fx = fixture(panes => [
        pane(cwd => '/home/tester/unused'),
        pane(focused => 1, foreground_cwd => '/projects/gh-settings'),
    ]);
    $fx->{sync}->();
    is(label($fx), 'gh-settings', 'focused foreground cwd');
    $fx->{sync}->();
    is(renames($fx), 1, 'idempotent updates');
    ok(decode_json(read_file("$fx->{state_dir}/labels.json"))->{'w1:t1'}{automatic}, 'own auto-name');
};

subtest 'Agent status priority across panes' => sub {
    my $fx = fixture(panes => [
        pane(agent => 'codex', focused => 1, agent_status => 'working', cwd => '/repo/gh-settings'),
        pane(agent => 'claude', agent_status => 'blocked'),
        pane(agent => 'codex', agent_status => 'done'),
    ]);
    $fx->{sync}->();
    is(label($fx), '🔴 gh-settings', 'blocked wins');
    $fx->{state}{panes}[1]{agent_status} = 'idle';
    $fx->{sync}->();
    is(label($fx), '🟢 gh-settings', 'done wins');
    $fx->{state}{panes}[2]{agent_status} = 'working';
    $fx->{sync}->();
    is(label($fx), '⚪ gh-settings', 'idle above working');
    $fx->{state}{panes}[1]{agent_status} = 'working';
    $fx->{sync}->();
    is(label($fx), '🟡 gh-settings', 'all working');
    $fx->{state}{panes}[1]{agent_status} = 'unknown';
    $fx->{sync}->();
    is(label($fx), '⚪ gh-settings', 'unknown above working');
    $fx->{state}{panes} = [pane(cwd => '/repo/gh-settings')];
    $fx->{sync}->();
    is(label($fx), 'gh-settings', 'cleared when no Agents');
};

subtest 'priority independent of pane order' => sub {
    my $working = pane(agent => 'codex', agent_status => 'working');
    my $idle = pane(agent => 'codex', agent_status => 'idle');
    my $unknown = pane(agent => 'codex', agent_status => 'unknown');
    my $done = pane(agent => 'codex', agent_status => 'done');
    my $blocked = pane(agent => 'codex', agent_status => 'blocked');
    is(HerdrTabStatus::most_urgent_status([$working, $idle]), 'idle', 'idle wins');
    is(HerdrTabStatus::most_urgent_status([$idle, $working]), 'idle', 'reverse');
    is(HerdrTabStatus::most_urgent_status([$working, $unknown]), 'unknown', 'unknown wins');
    is(HerdrTabStatus::most_urgent_status([$unknown, $working]), 'unknown', 'reverse unknown');
    is(HerdrTabStatus::most_urgent_status([$unknown, $working, $done]), 'done', 'done wins');
    is(HerdrTabStatus::most_urgent_status([$working, $idle, $done, $blocked]), 'blocked', 'blocked wins');
    is(HerdrTabStatus::most_urgent_status([pane(agent_status => 'blocked')]), undef, 'no Agent');
};

subtest 'manual names preserved even when Agent status changes' => sub {
    my $fx = fixture(tabs => [{ tab_id => 'w1:t1', label => 'customer-work' }], panes => [
        pane(agent => 'codex', agent_status => 'working', cwd => '/repo/first'),
    ]);
    $fx->{sync}->();
    is(label($fx), '🟡 customer-work', 'manual base');
    $fx->{state}{panes}[0]{cwd} = '/repo/second';
    $fx->{state}{panes}[0]{agent_status} = 'blocked';
    $fx->{sync}->();
    is(label($fx), '🔴 customer-work', 'manual survives cwd change');
    $fx->{state}{tabs}[0]{label} = 'another-manual';
    $fx->{state}{panes}[0]{agent_status} = 'done';
    $fx->{sync}->();
    is(label($fx), '🟢 another-manual', 'manual rename adopted');
    $fx->{state}{panes}[0]{agent} = undef;
    $fx->{sync}->();
    is(label($fx), 'another-manual', 'marker removed');
};

subtest 'override manual labels after first sync' => sub {
    my $fx = fixture(tabs => [{ tab_id => 'w1:t1', label => 'custom' }], panes => [
        pane(cwd => '/repo/selected-directory')
    ]);
    $fx->{sync}->();
    is(label($fx), 'custom', 'initially manual');
    write_file("$fx->{config_dir}/config.json", '{"overwrite_manual":true}');
    $fx->{sync}->();
    is(label($fx), 'selected-directory', 'enabled override applied');
};

subtest 'legacy title ownership is preserved across migration' => sub {
    my $fx = fixture(tabs => [{ tab_id => 'w1:t1', label => 'old-project' }], panes => [
        pane(agent => 'codex', agent_status => 'blocked', foreground_cwd => '/repo/new-project')
    ]);
    make_path("$fx->{root}/state/dev-shimada.auto-tab-name");
    write_file("$fx->{root}/state/dev-shimada.auto-tab-name/labels.json", '{"w1:t1":"old-project"}');
    $fx->{sync}->();
    is(label($fx), '🔴 new-project', 'old auto-label adopted');
};

subtest 'truncation and unknown statuses' => sub {
    my $fx = fixture(panes => [pane(agent => 'codex', agent_status => 'future', cwd => '/repo/language-tools')]);
    write_file("$fx->{config_dir}/config.json", '{"max_length":8}');
    $fx->{sync}->();
    is(label($fx), '⚪ languag…', 'unknown and truncated name');
};

subtest 'legacy configuration fallback' => sub {
    my $fx = fixture(panes => [pane(cwd => '/repo/abcdefghij')]);
    make_path("$fx->{root}/config/dev-shimada.auto-tab-name");
    write_file("$fx->{root}/config/dev-shimada.auto-tab-name/config.json", '{"max_length":4}');
    $fx->{sync}->();
    is(label($fx), 'abc…', 'legacy max_length used');
};

subtest 'auto name continues across Agent exit and cwd change' => sub {
    my $fx = fixture(panes => [pane(agent => 'codex', agent_status => 'blocked', cwd => '/repo/a')]);
    $fx->{sync}->();
    $fx->{state}{panes}[0]{agent} = undef;
    $fx->{state}{panes}[0]{cwd} = '/repo/b';
    $fx->{sync}->();
    is(label($fx), 'b', 'after Agent exits');
    $fx->{state}{panes}[0]{cwd} = '/repo/c';
    $fx->{sync}->();
    is(label($fx), 'c', 'still auto-naming');
};

subtest 'plain cwd helpers' => sub {
    is(HerdrTabStatus::directory_label('/home/tester', '/home/tester', 0), '~', 'home directory');
    is(HerdrTabStatus::directory_label('/', '/home/tester', 0), '/', 'root directory');
    is(HerdrTabStatus::directory_label('/repo/hello', '/home/tester', 1), '…', 'length one');
    is(HerdrTabStatus::focused_cwd([pane(cwd => '/repo/a'), pane(focused => 1, cwd => '/repo/b')]), '/repo/b', 'focused pane');
};

done_testing;
