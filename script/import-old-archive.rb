#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'libxml'
require 'htmlentities'

require File.join(File.dirname(__FILE__), "..", "config", "boot")
require File.join(File.dirname(__FILE__), "..", "config", "environment")

ActiveRecord::Base.record_timestamps = false
Rails.logger = Logger.new('log/archive_import.log')
ActiveRecord::Base.logger = Rails.logger

directory = "/home/ckruse/dev/archiv/archiv/"
directory = ARGV[0] if ARGV.length >= 1

if ARGV[1] != 'forums'
  $forum = CfForum.find_by_slug 'default'

  $forum = CfForum.create!(
    :name => 'Default-Forum',
    :short_name => 'Default-Forum',
    :slug => 'default',
    :standard_permission => 'write',
    :created_at => DateTime.now,
    :updated_at => DateTime.now
  ) if $forum.blank?
end

$ids = {}
$coder = HTMLEntities.new

def convert_content(txt)
  txt = txt.gsub(/<br ?\/?>/,"\n")

  txt = txt.gsub(/<img([^>]+)>/) do |data|
    alt = ""
    src = ""

    src = $1 if data =~ /src="([^"]+)"/
    alt = $1 if data =~ /alt="([^"]+)"/

    alt = src if alt.blank?

    src = $coder.decode(src)
    alt = $coder.decode(alt)

    "![#{alt}](#{src})"
  end

  txt = txt.gsub(/\[image:\s*([^\]]+)\]/) do |data|
    href  = ""
    alt   = ""
    data  = $1

    href  = data.gsub(/@alt=.*/, '')
    alt   = $1 if data =~ /@alt=(.*)/

    alt   = href if alt.blank?

    alt   = $coder.decode(alt.strip)
    href  = $coder.decode(href.strip)

    "![#{alt}](#{href})"
  end

  txt = txt.gsub(/\[\s*link:\s*([^\]]+)\]/) do |data|
    href  = ""
    title = ""
    data  = $1

    href  = data.gsub(/@title=.*/, '')
    title = $1 if data =~ /@title=(.*)/

    title = href if title.blank?

    title = $coder.decode(title.strip)
    href  = $coder.decode(href.strip)

    "[#{title}](#{href})"
  end

  txt = txt.gsub(/\[pref:([^\]]+)\]/) do |data|
    href  = ""
    title = ""
    data  = $1

    href  = data.gsub(/@title=.*/, '')
    title = $1 if data =~ /@title=(.*)/

    t, m = href.split ';', 2

    if t.blank? or m.blank?
      lnk = '[pref]'
    else
      title = "?t=#{t}&m=#{m}" if title.blank?
      title = $coder.decode($title)

      lnk = "[#{title}](?t=#{t}&m=#{m})"
    end

    lnk
  end

  txt = txt.gsub(/\[code(?:\s+lang=(\w+))\](.*?)\[\/code\]/m) do |data|
    lang = $1
    code = $2

    lang = "html" if lang.blank?

    if code =~ /\n/
      "\n~~~ #{lang}\n#{code}\n~~~\n"
    else
      "`#{code}`"
    end
  end

  txt = $coder.decode(txt)
  txt.gsub!(/\u007F/,"> ")

  txt
end

def check_null_bytes(msg)
  msg.content.gsub!(/\0/, '')
  msg.subject.gsub!(/\0/, '')
  msg.author.gsub!(/\0/, '')
  msg.email.gsub!(/\0/, '') unless msg.email.blank?
  msg.homepage.gsub!(/\0/, '') unless msg.homepage.blank?
end

def handle_messages(old_msg, x_msg, thread)
  the_date = Time.at(x_msg.find_first('./Header/Date')['longSec'].force_encoding('utf-8').to_i)
  the_date = DateTime.parse("1970-01-01 00:00:00").to_time if the_date.blank?

  msg = CfMessage.new(
    mid: x_msg['id'].gsub(/^m/, ''),
    author: x_msg.find_first('./Header/Author/Name').content.force_encoding('utf-8'),
    subject: x_msg.find_first('./Header/Subject').content.force_encoding('utf-8'),

    upvotes: x_msg['votingGood'].to_i,
    downvotes: x_msg['votingBad'].to_i,

    deleted: x_msg['invisible'] == '1',

    created_at: the_date,
    updated_at: the_date,

    content: convert_content(x_msg.find_first('./MessageContent').content.force_encoding('utf-8')),
    parent_id: old_msg ? old_msg.message_id : nil,
    thread_id: thread.thread_id,
    forum_id: thread.forum_id
  )

  # cat      = x_msg.find_first('./Header/Category').content.force_encoding('utf-8')
  email    = x_msg.find_first('./Header/Author/Email').content.force_encoding('utf-8')
  homepage = x_msg.find_first('./Header/Author/HomepageUrl').content.force_encoding('utf-8')

  # msg.category        = cat      unless cat.empty?
  msg.email    = email    unless email.blank?
  msg.homepage = homepage unless homepage.blank?

  check_null_bytes(msg)

  msg.save(validate: false)

  if ARGV[1] != 'forums'
    category = x_msg.find_first("./Header/Category").content.force_encoding('utf-8')

    if not category.blank?
      category = category.downcase.strip

      t = CfTag.find_by_forum_id_and_tag_name thread.forum_id, category
      t = CfTag.create!(:tag_name => category, forum_id: thread.forum_id) if t.blank?

      CfMessageTag.create!(
        tag_id: t.tag_id,
        message_id: msg.message_id
      )
    end
  end

  x_msg.find('./Header/Flags/Flag').each do |f|
    if f['name'] == 'UserName' then
      uname = f.content.force_encoding('utf-8')

      usr = CfUser.find_by_username(uname)
      if !usr then
        usr = CfUser.new(:username => uname, created_at: the_date, updated_at: the_date)
        usr.skip_confirmation!
        usr.save!(validate: false)
      end

      msg.user_id = usr.id
      msg.save
    else
      msg.flags[f['name']] = f.content.force_encoding('utf-8')
    end
  end

  x_msg.find('./Message').each do |m|
    handle_messages(msg, m, thread)
  end

  msg
end

def handle_doc(doc, opts = {})
  x_thread = doc.find_first('/Forum/Thread')

  forum_name = x_thread.find_first("./Message/Header/Category").content.force_encoding('utf-8')

  if ARGV[1] == 'forums'
    forum_name = "Default-Forum" if forum_name.blank?
    forum_slug = forum_name.downcase.gsub /\s+/, '-'

    forum_slug.gsub! /[^a-zA-Z0-9_-]/, '-'
    forum_slug.gsub! /-{2,}/, '-'

    forum_slug = 'default-forum' if forum_slug.empty? or forum_slug.length < 3
    forum_slug = forum_slug[0..19] if forum_slug.length > 20
  end

  the_date = Time.at(x_thread.find_first('./Message/Header/Date')['longSec'].force_encoding('utf-8').to_i)
  subject = x_thread.find_first('./Message/Header/Subject').content.force_encoding('utf-8')

  the_date = DateTime.parse("1970-01-01 00:00:00").to_time if the_date.blank?

  if ARGV[1] == 'forums'
    forum = CfForum.find_by_slug(forum_slug)
    unless forum
      forum = CfForum.create!(
        name: forum_name,
        short_name: forum_name,
        standard_permission: 'write',
        slug: forum_slug,
        created_at: the_date,
        updated_at: the_date
      )
    end
  else
    forum = $forum
  end

  thread = CfThread.new(
    tid: x_thread['id'].force_encoding('utf-8')[1..-1],
    archived: opts[:archived],
    forum_id: forum.forum_id,
    slug: thread_id(the_date, subject),
    created_at: the_date,
    updated_at: the_date,
    latest_message: the_date
  )

  i = 0
  while not CfThread.find_by_slug(thread.slug).blank?
    i += 1
    thread.slug = thread_id(the_date, subject, i)
  end

  thread.save

  msg = nil
  x_thread.find('./Message').each do |m|
    msg = handle_messages(nil, m, thread)
  end

  thread.message_id = msg.message_id # a thread can only contain one message
  thread.save!

  thread
end

def thread_id(dt, subject, num = 0)
  base_id = dt.strftime("/%Y/") + dt.strftime("%b").downcase + '/' + dt.strftime("%d").to_i.to_s + '/'
  subj = subject.parameterize

  if num > 0 then
    id = base_id + num.to_s + "-" + subj
  else
    id = base_id + subj
  end

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
      thread = handle_doc(doc, archived: (dir =~ /messages/ ? false : true))
      puts "saved #{thread.slug} from file #{dir + '/' + ent}"

    rescue SystemStackError
      $stderr.puts "thread #{dir + '/' + ent} could not be saved!\n"
      $stderr.puts $!.message
      $stderr.puts $!.backtrace.join("\n")
    end

  end
end

find_in_dir(directory)

# eof
