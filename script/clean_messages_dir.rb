#!/usr/bin/env ruby
require 'libxml'

directory = '/home/ckruse/dev/archiv/archiv/'
directory = ARGV[0] if ARGV.length >= 1

parser = LibXML::XML::Parser.string(IO.read(directory + '/forum.xml'))
doc = parser.parse

ids = {}

threads = doc.find('/Forum/Thread')
threads.each do |t|
  ids[t['id']] = true
end

parser = nil
doc = nil

Dir.open(directory).each do |ent|
  next unless ent =~ /^(t\d+)\.xml$/
  File.unlink(directory + '/' + ent) unless ids[Regexp.last_match(1)]
end

# eof
