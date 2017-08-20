#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PLN::PT::api;
PLN::PT::api->to_app;
