#!/usr/bin/env ruby
#
# Graphite-Cleanup
#
# Copyright 2013, Bryan Brandau <agent462@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'file/find'
require 'date'
require 'fileutils'
require 'logger'

whisper_path = '/opt/graphite/storage/whisper'
archive_path = "/opt/graphite/storage/whisper/archive"
log_file = '/var/log/graphite_cleanup.log'

log = Logger.new(log_file, 'daily')
log.level = Logger::INFO

#Find all of the whisper files
wsp_files = File::Find.new(
  :pattern => "*.wsp",
  :path    => [whisper_path]
)

#if the archive directory does not exist, create it
if File.directory?(archive_path) == false
  FileUtils.mkdir(archive_path)
end

wsp = Array.new
wsp_files.find{ |f|
  wsp = [f, File.mtime(f)]
  if wsp[0]
    d = Time.now.to_i - 604800 #this sets the time to consider for unmodified files in seconds
    if Integer(wsp[1].strftime("%s")) < d
      new_path = wsp[0].gsub(whisper_path, archive_path)
      log.info("I am moving #{wsp[0]} to #{new_path}")
      FileUtils.mkdir_p(File.dirname(new_path)) #ensure the directory the file needs to live in exists
      FileUtils.mv(wsp[0],new_path) #move the file to the newly created archive directory
      system("gzip -c #{new_path} > #{new_path}.gz" ) #system call to gzip the new file. 
      FileUtils.rm(new_path)     # remove the newly placed wsp file after gzip
    end
  end
}

# We need to walk the old directories to see if they are empty so that we can delete them
# Since we need to walk downwards to delete we'll sort by length 
dirs = Dir["#{whisper_path}/**/*/"].sort_by(&:length).reverse!.each do |directory|
  if (Dir.entries(directory) - %w[. ..]).size == 0 # excludes . .. and checks for size 
    Dir.delete(directory)
    log.info("I am deleting #{directory} as it is empty.")
  end
end

log.close