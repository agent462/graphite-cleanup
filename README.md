graphite-cleanup
================

A script that looks at wsp files to determine the last time they've been updated and will move them into an archive folder and gzip.


Usage
-----
Run this on cron or another schedular every day.  It will move inactive metrics/nodes to an archive directory that you specify.

A few gems will be needed
  > gem install logger
  > gem install file-find

Specify a couple directories at the top of the script