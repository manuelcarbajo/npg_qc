
package npg_qc::Schema::Result::ChipSummary;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

##no critic(RequirePodAtEnd RequirePodLinksIncludeText ProhibitMagicNumbers ProhibitEmptyQuotes)

=head1 NAME

npg_qc::Schema::Result::ChipSummary

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 ADDITIONAL CLASSES USED

=over 4

=item * L<namespace::autoclean>

=back

=cut

use namespace::autoclean;

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components('InflateColumn::DateTime');

=head1 TABLE: C<chip_summary>

=cut

__PACKAGE__->table('chip_summary');

=head1 ACCESSORS

=head2 id_chip_summary

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 id_run

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 chip_id

  data_type: 'tinytext'
  is_nullable: 1

=head2 clusters

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 clusters_pf

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 yield_kb

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 paired

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 machine

  data_type: 'tinytext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  'id_chip_summary',
  {
    data_type => 'bigint',
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  'id_run',
  { data_type => 'bigint', extra => { unsigned => 1 }, is_nullable => 0 },
  'chip_id',
  { data_type => 'tinytext', is_nullable => 1 },
  'clusters',
  {
    data_type => 'bigint',
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  'clusters_pf',
  {
    data_type => 'bigint',
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  'yield_kb',
  { data_type => 'bigint', extra => { unsigned => 1 }, is_nullable => 1 },
  'paired',
  {
    data_type => 'tinyint',
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  'machine',
  { data_type => 'tinytext', is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id_chip_summary>

=back

=cut

__PACKAGE__->set_primary_key('id_chip_summary');

=head1 UNIQUE CONSTRAINTS

=head2 C<unq_idx_cs_idrun>

=over 4

=item * L</id_run>

=back

=cut

__PACKAGE__->add_unique_constraint('unq_idx_cs_idrun', ['id_run']);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-06-30 16:51:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ejQ1DFgVIc3pHZCywaCM3Q

our $VERSION = '0';

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

Result class definition in DBIx binding for npg-qc database.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 SUBROUTINES/METHODS

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Moose

=item namespace::autoclean

=item MooseX::NonMoose

=item MooseX::MarkAsMethods

=item DBIx::Class::Core

=item DBIx::Class::InflateColumn::DateTime

=item DBIx::Class::InflateColumn::Serializer

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL, by Marina Gourtovaia

This file is part of NPG.

NPG is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

