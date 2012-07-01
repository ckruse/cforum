#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'libxml'
require 'htmlentities'

require File.join(File.dirname(__FILE__), "..", "config", "boot")
require File.join(File.dirname(__FILE__), "..", "config", "environment")

directory = "/home/ckruse/dev/archiv/archiv/"
directory = ARGV[0] if ARGV.length >= 1

$ids = {}
$coder = HTMLEntities.new

def convert_content(txt)
  txt = txt.gsub(/<br ?\/?>/,"\n")
  txt = $coder.decode(txt)
  txt.gsub!(/\u007F/,"\u{ECF0}")

  txt
end


def handle_messages(cont, x_msg)
  the_date = Time.at(x_msg.find_first('./Header/Date')['longSec'].force_encoding('utf-8').to_i)

  msg = CfMessage.new(
    :author => CfAuthor.new(:name => x_msg.find_first('./Header/Author/Name').content.force_encoding('utf-8')),
    :subject => x_msg.find_first('./Header/Subject').content.force_encoding('utf-8'),
    :created_at => the_date,
    :updated_at => the_date,
    :flags => {
      :votingGood => x_msg['votingGood'].to_s,
      :votingBad => x_msg['votingBad'].to_s,
      :invisible => x_msg['invisible'] == '1' ? 'yes' : 'no'
    },
    :content => convert_content(x_msg.find_first('./MessageContent').content.force_encoding('utf-8')),
    :messages => []
  )

  msg.id = x_msg['id'].gsub(/^m/, '')

  cat      = x_msg.find_first('./Header/Category').content.force_encoding('utf-8')
  email    = x_msg.find_first('./Header/Author/Email').content.force_encoding('utf-8')
  homepage = x_msg.find_first('./Header/Author/HomepageUrl').content.force_encoding('utf-8')

  msg.category        = cat      unless cat.empty?
  msg.author.email    = email    unless email.empty?
  msg.author.homepage = homepage unless homepage.empty?

  x_msg.find('./Header/Flags/Flag').each do |f|
    if f['name'] == 'UserName' then
      uname = f.content.force_encoding('utf-8')

      usr = CfUser.find_by_username(uname)
      if !usr then
        usr = CfUser.new(:username => uname)
        usr.save!(validate: false)
      end

      msg.author.user_id = usr.id
    else
      msg.flags[f['name']] = f.content.force_encoding('utf-8')
    end
  end

  x_msg.find('./Message').each do |m|
    handle_messages(msg.messages, m)
  end

  cont.push(msg)
end

def handle_doc(doc)
  x_thread = doc.find_first('/Forum/Thread')

  thread = CfThread.new(
    :tid => x_thread['id'].force_encoding('utf-8')
  )

  messages = []
  x_thread.find('./Message').each do |m|
    handle_messages(messages, m)
  end
  thread.message = messages[0] # a thread can only contain one message

  thread
end

TO_URI_MAP = [
  {:rx => /[äÄ]/, :replacement => 'ae'},
  {:rx => /[öÖ]/, :replacement => 'oe'},
  {:rx => /[üÜ]/, :replacement => 'ue'},
  {:rx => /ß/,    :replacement => 'ss'},
  {:rx => /[ÀÁÂÃÅÆàáâãåæĀāĂăĄą]/, :replacement => 'a'},
  {:rx => /[ÇçĆćĈĉĊċČč]/, :replacement => 'c'},
  {:rx => /[ÐĎďĐđ]/, :replacement => 'd'},
  {:rx => /[ÈÉÊËèéêëĒēĔĕĖėĘęĚě]/, :replacement => 'e'},
  {:rx => /[ÌÍÎÏìíîï]/, :replacement => 'i'},
  {:rx => /[Ññ]/, :replacement => 'n'},
  {:rx => /[ÒÓÔÕ×Øòóôõø]/, :replacement => 'o'},
  {:rx => /[ÙÚÛùúû]/, :replacement => 'u'},
  {:rx => /[Ýýÿ]/, :replacement => 'y'}
]
def to_uri(s)
  s = s.tr(' ','-')
  s.downcase!

  TO_URI_MAP.each do |map|
    s.gsub!(map[:rx], map[:replacement])
  end


  s.gsub!(/[^a-zA-Z0-9.$%;,_*-]/,'-')

  s.gsub!(/-{2,}/,'-')
  s.gsub!(/-+$/,'')
  s.gsub!(/^-+/,'')

  s = s[0..120]+"..." if s.length > 120

  s
end

def thread_id(thread)
  dt = thread.message.created_at
  base_id = dt.strftime("/%Y/") + dt.strftime("%b").downcase + dt.strftime("/%d/")
  subj = to_uri(thread.message.subject)
  num = 0

  begin
    if num > 0 then
      id = base_id + num.to_s + "-" + subj
    else
      id = base_id + subj
    end

    num += 1
  end while $ids[id]

  $ids[id] = true

  id
end

def find_in_dir(dir)
  puts "Handling #{dir}"

  Dir.open(dir).each do |ent|
    next if ent[0] == '.' # ignore ., .. and dot files

    if File.directory?(dir + '/' + ent) then
      find_in_dir(dir + '/' + ent)
      next
    end

    next unless ent =~ /^t(\d+)\.xml$/
    tid = $1

    begin
      # do not use Parser.file since there seems to be a problem with open files
      parser = LibXML::XML::Parser.string(IO.read(dir + '/' + ent))
      doc = parser.parse
    rescue
      $stderr.puts "Error parsing thread #{dir + '/' + ent}!"
      next
    end

    begin
      thread = handle_doc(doc)
      thread.id = thread_id(thread)
      thread.archived = (dir =~ /messages/ ? false : true)

      puts "saving #{thread.id} from file #{dir + '/' + ent}"
      thread.save!(validate: false)
    rescue SystemStackError
      $stderr.puts "thread #{dir + '/' + ent} could not be saved!\n"
      $stderr.puts $!.message
      $stderr.puts $!.backtrace.join("\n")
    end

  end
end

find_in_dir(directory)

# eof
