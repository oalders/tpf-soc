use strict;
use warnings;
use Test::More;

use FindBin;
use DateTime;
use Path::Class;
use DateTime;
use DateTime::Duration;
use DateTime::Format::Mail;

use TPF::SoC;
use aliased 'TPF::SoC::ReportingPeriod::Event::Timely', 'TimelyReportEvent';
use aliased 'TPF::SoC::ReportingPeriod::Event::Bonus', 'BonusReportEvent';
use aliased 'TPF::SoC::ReportingPeriod::Event::MissedDeadline', 'MissedDeadlineEvent';
use aliased 'TPF::SoC::ReportingPeriod::Event::MissedExpectedDeadline', 'MissedExpectedDeadlineEvent';

my $students_list = dir($FindBin::Bin)->parent->file('students');

my $c = TPF::SoC->new({
    students_fh            => $students_list->openr,
    reports_fh             => \*DATA,
    reporting_period_start => DateTime->new(
        year      => 2011,
        month     => 5,
        day       => 23,
        time_zone => 'UTC',
    ),
    reporting_period_end => DateTime->new(
        year      => 2011,
        month     => 8,
        day       => 22,
        time_zone => 'UTC',
    ),
    reporting_interval => DateTime::Duration->new(weeks => 1),
    analysis_time      => DateTime::Format::Mail->parse_datetime('Fri, 03 Jun 2011 06:39:45 +0200'),
});

my %reporting_periods = map {
    ($_ => $c->report_analyser->analyse(@{ $c->student_reports->{$_} }))
} keys %{ $c->students };

for my $nick (keys %reporting_periods) {
    is $reporting_periods{$nick}->n_periods, 2;
    isa_ok $_, 'TPF::SoC::ReportingPeriod'
        for $reporting_periods{$nick}->periods;

    for my $p ($reporting_periods{$nick}->nth_period(0)) {
        ok $p->finished( $c->analysis_time );
        ok $p->has_events, 'every finished period must have at least one event';
    }

    for my $p ($reporting_periods{$nick}->nth_period(1)) {
        ok !$p->finished( $c->analysis_time );
    }
}

subtest marcg => sub {
    my $marcs_analysis = $reporting_periods{marcg};

    for my $p ($marcs_analysis->nth_period(0)) {
        my @e = $p->events;
        is @e, 4;
        isa_ok $e[0], BonusReportEvent, 'event before reporting period';
        isa_ok $e[1], MissedExpectedDeadlineEvent, 'missed expected date';
        isa_ok $e[2], TimelyReportEvent, 'first report in reporting period';
        isa_ok $e[3], BonusReportEvent, 'second report in reporting period';

        ok $p->was_impolite;
        ok !$p->was_naughty;
    }

    for my $p ($marcs_analysis->nth_period(1)) {
        ok $p->has_events;

        my @e = $p->events;
        is @e, 1;
        isa_ok $e[0], MissedExpectedDeadlineEvent;

        ok $p->was_impolite;
        ok !$p->was_naughty;

        is $marcs_analysis->expected_next_date,
           $marcs_analysis->nth_period(0)->expected_next_date;

        cmp_ok $e[0]->date, '=', $marcs_analysis->expected_next_date;
    }
};

subtest gnusosa => sub {
    my $carlos_analysis = $reporting_periods{gnusosa};

    for my $p ($carlos_analysis->nth_period(0)) {
        my @e = $p->events;
        is @e, 1;
        isa_ok $e[0], TimelyReportEvent;
    }

    for my $p ($carlos_analysis->nth_period(1)) {
        ok $p->has_events;

        my @e = $p->events;
        is @e, 1;
        isa_ok $e[0], TimelyReportEvent;
    }
};

subtest andrewalker => sub {
    my $andres_analysis = $reporting_periods{andrewalker};

    for my $p ($andres_analysis->nth_period(0)) {
        my @e = $p->events;
        is @e, 1;
        isa_ok $e[0], TimelyReportEvent;
    }

    for my $p ($andres_analysis->nth_period(1)) {
        ok !$p->has_events;
    }

    cmp_ok $andres_analysis->expected_next_date, '>', $c->analysis_time;
};

subtest Hugmeir => sub {
    my $brians_analysis = $reporting_periods{Hugmeir};

    for my $p ($brians_analysis->nth_period(0)) {
        my @e = $p->events;
        is @e, 1;
        isa_ok $e[0], TimelyReportEvent;
    }

    for my $p ($brians_analysis->nth_period(1)) {
        ok $p->has_events;

        my @e = $p->events;
        is @e, 1;
        isa_ok $e[0], TimelyReportEvent;
    }
};

subtest mo => sub {
    my $moritz_analysis = $reporting_periods{mo};

    for my $p ($moritz_analysis->nth_period(0)) {
        my @e = $p->events;
        is @e, 1;
        isa_ok $e[0], MissedDeadlineEvent;

        ok $p->was_impolite;
        ok $p->was_naughty;
    }

    for my $p ($moritz_analysis->nth_period(1)) {
        ok $p->has_events;

        my @e = $p->events;
        is @e, 2;
        isa_ok $e[0], TimelyReportEvent;
        isa_ok $e[1], BonusReportEvent;
    }
};

subtest tadzik => sub {
    my $tadeusz_analysis = $reporting_periods{tadzik};

    for my $p ($tadeusz_analysis->nth_period(0)) {
        my @e = $p->events;
        is @e, 1;
        isa_ok $e[0], MissedDeadlineEvent;

        ok $p->was_impolite;
        ok $p->was_naughty;
    }

    for my $p ($tadeusz_analysis->nth_period(1)) {
        ok $p->has_events;

        my @e = $p->events;
        is @e, 2;
        isa_ok $e[0], TimelyReportEvent;
        isa_ok $e[1], BonusReportEvent;
    }
};

done_testing;

__DATA__
# Even though this is based on the actual data as of June 3, this is fake data
# to trigger some corner cases

| marcg       | Tue, 17 May 2011 00:29:57 -0400 | http://groups.google.com/group/tpf-gsoc-students/browse_thread/thread/ce20c2a82d81baae# |
| gnusosa     | Tue, 24 May 2011 10:28:31 -0700 | http://groups.google.com/group/tpf-gsoc-students/browse_thread/thread/dd1407956d333e95# |
| marcg       | Thu, 26 May 2011 17:52:15 -0400 | http://groups.google.com/group/tpf-gsoc-students/browse_thread/thread/665d16ad938721c2# |
| marcg       | Thu, 26 May 2011 17:53:15 -0400 | http://groups.google.com/group/tpf-gsoc-students/browse_thread/thread/665d16ad938721c2# |
| andrewalker | Sat, 28 May 2011 11:44:30 -0300 | http://groups.google.com/group/tpf-gsoc-students/browse_thread/thread/feadee4d20b87a29# |
| Hugmeir     | Tue, 24 May 2011 15:52:56 -0300 | http://groups.google.com/group/tpf-gsoc-students/browse_thread/thread/8a709f906be321d5# |
| mo          | Mon, 30 May 2011 10:46:55 +0200 | http://groups.google.com/group/tpf-gsoc-students/browse_thread/thread/571df8d546362d85# |
| tadzik      | Mon, 30 May 2011 14:51:46 +0200 | http://groups.google.com/group/tpf-gsoc-students/browse_thread/thread/a63f7c9eddf12dd2# |
| Hugmeir     | Mon, 30 May 2011 18:12:35 -0300 | http://groups.google.com/group/tpf-gsoc-students/browse_thread/thread/50e6c5eae3752e75# |
| gnusosa     | Tue, 31 May 2011 01:23:13 -0700 | http://groups.google.com/group/tpf-gsoc-students/browse_thread/thread/d7f9828554e1cdfe# |
| tadzik      | Tue, 31 May 2011 22:52:40 +0200 | http://groups.google.com/group/tpf-gsoc-students/browse_thread/thread/3322531de06de289# |
| mo          | Fri, 03 Jun 2011 13:23:16 +0200 | http://groups.google.com/group/tpf-gsoc-students/browse_thread/thread/81134d1f15e8b851# |
