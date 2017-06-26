package npg_qc::model::move_z;
use strict;
use warnings;
use base qw(npg_qc::model);
use English qw(-no_match_vars);
use Carp;
use Readonly;

our $VERSION = '0';

Readonly our $MOVE_Z_NORMAL    => 5000;
Readonly our $NUMBER_LANES     => 8;
Readonly our $MAX_COLOR_CODE   => 3;
Readonly our $NOT_APPLICABLE   => 0;
Readonly our $LESS_THAN_5K     => 1;
Readonly our $BETWEEN_5K_10K   => 2;
Readonly our $GREATER_THAN_10K => 3;

__PACKAGE__->mk_accessors(__PACKAGE__->fields());
__PACKAGE__->has_all();

sub fields {
  return qw(
            id_move_z
            id_run_tile
            cycle
            currentz
            targetz
            newz
            start
            stop
            move
          );
}

sub init {
  my $self = shift;

  if($self->{id_run_tile} &&
     $self->{cycle} &&
     !$self->{'id_move_z'}) {

    my $query = q(SELECT id_move_z
                  FROM   move_z
                  WHERE  id_run_tile = ?
                  AND    cycle = ?
                 );

    my $ref   = [];

    eval {
      $ref = $self->util->dbh->selectall_arrayref($query, {}, $self->id_run_tile(), $self->cycle());
      1;
    } or do {
      carp $EVAL_ERROR;
      return;
    };

    if(@{$ref}) {
      $self->{'id_move_z'} = $ref->[0]->[0];
    }
  }
  return 1;
}

sub cycle_count {
  my ($self) = @_;

  if (!$self->{cycle_count}) {
    my $id_run = $self->{id_run};
    my $dbh = $self->util->dbh();

    my $query = qq{SELECT max(m.cycle) FROM run_tile rt, move_z m WHERE rt.id_run = $id_run AND m.id_run_tile = rt.id_run_tile};
    my $sth = $dbh->prepare($query);
    $sth->execute();

    $self->{cycle_count} = $sth->fetchrow_array();
  }

  return $self->{cycle_count};
}

sub cycles_for_run{

  my ($self) = @_;

  my $util   = $self->util();

  my $id_run = $self->{id_run};

  my @rows;
  eval {
    my $dbh = $self->util->dbh();
    my $query = q{SELECT DISTINCT m.cycle from move_z m, run_tile r
                  WHERE r.id_run_tile = m.id_run_tile
                  AND r.id_run = ?
                  order by m.cycle};
    my $sth = $dbh->prepare($query);
    $sth->execute($id_run);

    while (my @row = $sth->fetchrow_array()) {
      push @rows, $row[0];
    }
    1;
  } or do {
    croak $EVAL_ERROR;
  };

  return \@rows;
}

#get all newz values different from the average for every tile but from one cycle
sub newz_by_cycle {
  my ($self, $id_run, $cycle) = @_;

  my $util   = $self->util();
  my $cgi    = $util->cgi();
  if(!$id_run){
    $id_run = $cgi->param('id_run');
  }
  if(!$cycle){
    $cycle  = $cgi->param('cycle');
  }
  my $end = 0;
  if($self->paired_read($id_run)){
    my $read1_cycle_range = $self->get_read_cycle_range_from_recipe($id_run, 1);
    my $read2_cycle_range = $self->get_read_cycle_range_from_recipe($id_run, 2);
    if($cycle <= $read1_cycle_range->[1] ){
      $end = 1;
    }elsif($cycle >= $read2_cycle_range->[0]){
      $end = 2;
    }
  }

  my $average_newz = $self->average_newz($id_run, $end);

  my $num_tiles_lane = $self->max_tiles_lane($id_run);
  my $return_dataset = [];
  my $lane;
  my $tile;

  for my $lane (0..$NUMBER_LANES -1){
    for my $tile (0 .. $num_tiles_lane -1){
      $return_dataset ->[$lane] -> [$tile] = 0;

    }
  }

  eval {
    my $dbh = $self->util->dbh();
    my $query = q{SELECT r.position, r.tile, m.newz
                  FROM run_tile r, move_z m
                  WHERE r.id_run = ?
                  AND r.id_run_tile = m.id_run_tile
                  AND m.cycle = ?
                  ORDER BY r.position, r.tile};

    my $sth = $dbh->prepare($query);
    $sth->execute($id_run, $cycle);

    while (my @row = $sth->fetchrow_array()) {

      my $position_index  = $row[0] - 1;
      my $tile_index = $row[1] - 1;

      my $diff;

      if(defined $row[2] ){
        $diff = $row[2] - $average_newz->{$row[0]}->{$row[1]};
        $diff = abs $diff;
        $diff =  $diff/$MOVE_Z_NORMAL;
        $diff = int $diff;
        $diff++;

        if($diff > $MAX_COLOR_CODE){
          $diff = $MAX_COLOR_CODE;
        }
      }else{
        $diff = 0;
      }

      $return_dataset->[$position_index]->[$tile_index] = $diff;

    }
    1;
  } or do {
    croak $EVAL_ERROR;
  };
  return $return_dataset;
}


#get average value of the last newz of each tile 
#accross the given cycles of the end
sub average_newz {
  my ($self, $id_run, $end) = @_;

  if(!$end){
    $end = 0;
  }

  if(!$self->{average_newz}->{$id_run}->{$end}){
    my $start_cycle = 2;
    my $end_cycle;

    if($end){
      my $cycle_range = $self->get_read_cycle_range_from_recipe($id_run, $end);
      $end_cycle = $cycle_range->[1];
      if($end == 2){
        $start_cycle = $cycle_range->[0] + 1;
      }
    }else{
      my $cycle_range = $self->get_read_cycle_range_from_recipe($id_run);
      $end_cycle = $cycle_range->[1];
    }

    my $return_dataset = {};
    eval {
      my $dbh = $self->util->dbh();
      my $query = q{SELECT r.position, r.tile, avg(m.newz) as avg
                  FROM run_tile r, move_z m
                  WHERE r.id_run = ?
                  AND r.id_run_tile = m.id_run_tile
                  AND m.cycle >= ?
                  AND m.cycle <= ?
                  group by r.position, r.tile
                  ORDER BY r.position, r.tile
                  };

      my $sth = $dbh->prepare($query);
      $sth->execute($id_run, $start_cycle, $end_cycle);

      while (my @row = $sth->fetchrow_array()) {

        my $position= $row[0];
        my $tile = $row[1];

        $return_dataset->{$position}->{$tile} = $row[2];

      }
      1;
    } or do {
      croak $EVAL_ERROR;
    };
    $self->{average_newz}->{$id_run}->{$end} = $return_dataset;
  }
  return $self->{average_newz}->{$id_run}->{$end};
}
#For each tile, get the difference between max and min of newz from all cycles
#except cycle 1 currently
sub variance_newz {
  my ($self, $id_run, $end) = @_;

  my $util   = $self->util();
  my $cgi    = $util->cgi();

  if(!$id_run){
    $id_run = $cgi->param('id_run');
  }
  my $num_tiles_lane = $self->max_tiles_lane($id_run);

  my $start_cycle = 2;
  my $end_cycle;

  if($end){
    my $cycle_range = $self->get_read_cycle_range_from_recipe($id_run, $end);
    $end_cycle = $cycle_range->[1];
    if($end == 2){
      $start_cycle = $cycle_range->[0] + 1;
    }
  }else{
    my $cycle_range = $self->get_read_cycle_range_from_recipe($id_run);
    $end_cycle = $cycle_range->[1];
  }

  my $return_dataset = [];


  for my $lane (0..$NUMBER_LANES-1){
    for my $tile (0..$num_tiles_lane-1){
      $return_dataset ->[$lane] -> [$tile] = 0;

    }
  }

  eval {
    my $dbh = $self->util->dbh();
    my $query = q{SELECT r.position, r.tile,  abs( max(m.newz)-min(m.newz)) as diff
                  FROM run_tile r, move_z m
                  WHERE r.id_run = ?
                  AND m.cycle >= ?
                  AND m.cycle <= ?
                  AND r.id_run_tile = m.id_run_tile
                  GROUP BY r.position, r.tile 
                  ORDER BY r.position, r.tile
                 };

    my $sth = $dbh->prepare($query);
    $sth->execute($id_run, $start_cycle, $end_cycle);

    while (my @row = $sth->fetchrow_array()) {

      my $position_index  = $row[0] - 1;
      my $tile_index = $row[1] - 1;

      my $vari;
      if(defined $row[2]){
        $vari = $row[2]/$MOVE_Z_NORMAL;
        $vari = int $vari;
        $vari++;
        if($vari > $MAX_COLOR_CODE){
          $vari = $MAX_COLOR_CODE;
        }
      }else{
        $vari = 0;
      }


      $return_dataset->[$position_index]->[$tile_index] = $vari;

    }
    1;
  } or do {
    croak $EVAL_ERROR;
  };
  $self->{variance_newz} = $return_dataset;
  return $return_dataset;
}

sub max_tiles_lane{
  my ($self, $id_run) = @_;

  my $max_tile_num;
  if(!$self->{max_tile_num}){
    if(!$id_run){
      my $util   = $self->util();
      my $cgi    = $util->cgi();
      $id_run = $cgi->param('id_run');
    }

    my $id_run_pair = $self->id_run_pair($id_run);
    if(!$id_run_pair){
      $id_run_pair = $id_run;
    }
    my @rows;
    eval {
      my $dbh = $self->util->dbh();
      my $query = q{SELECT max(tile)
                    FROM run_tile
                    WHERE id_run = ?
                    OR id_run = ? };
      my $sth = $dbh->prepare($query);
      $sth->execute($id_run, $id_run_pair);

      while (my @row = $sth->fetchrow_array()) {
        $max_tile_num = $row[0];
      }

      1;
    } or do {
      croak $EVAL_ERROR;
    };
    $self->{max_tile_num} = $max_tile_num;
  }

  return $self->{max_tile_num};
}


sub run_alerts{
  my ($self) = @_;
  my $util   = $self->util();

  my %alerts = ();
  if(!$self->{run_alerts}){
    eval {
      my $dbh = $self->util->dbh();
      my $query = q{SELECT vari.id_run, COUNT(vari.tile)
                  AS num
                  FROM 
                  (SELECT r.id_run, r.position, r.tile,  abs( max(m.newz)-min(m.newz)) as diff
                  FROM run_tile r, move_z m
                  WHERE m.cycle >= 2
                   AND r.id_run_tile = m.id_run_tile
                  GROUP BY r.id_run, r.position, r.tile
                  HAVING  diff >=5000
                  #ORDER BY r.id_run, r.position, r.tile
                  )
                  AS vari
                  #WHERE diff>=5000
                  GROUP BY vari.id_run
                  #ORDER BY num DESC
                 };
      my $sth = $dbh->prepare($query);
      $sth->execute();

      while (my @row = $sth->fetchrow_array()) {
        $alerts{$row[0]} = $row[1];
      }
      1;
    } or do {
      croak $EVAL_ERROR;
    };
    $self->{run_alerts} = \%alerts;
  }
  return$self->{run_alerts};
}

1;
__END__
=head1 NAME

npg_qc::model::move_z

=head1 SYNOPSIS

  my $oMoveZ = npg_qc::model::move_z->new({util => $util});

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2  average_newz - query the database to get the average newz for each tile across the cycles (except cycle 1 currently)
=head2  init - override method, based on id_run_tile and cycle number to get the primary key of move_z, id_move_z 
=head2  cycles_for_run - query the database to check how many cycles for a given run
=head2  fields         - a list of fields
=head2  max_tiles_lane - check how many tiles for each lane
=head2  move_zlist
=head2  newz_by_cycle -  get all newz values different from the average for every tile but from one cycle
=head2  variance_newz  -For each tile, get the difference between max and min of newz from all cycles
except cycle 1 currently

=head2 run_alerts - get a hash ref, id_runs as keys and the number of tiles with high difference of z values 

=head2 cycle_count - returns the maximum cycle count found for the run

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

strict
warnings
npg_qc::model
Carp
Readonly

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Guoying Qi, E<lt>gq1@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 GRL

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
