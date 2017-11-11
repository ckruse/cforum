#!/usr/bin/env ruby
require 'libxml'
require 'htmlentities'
require 'pg'

require File.join(File.dirname(__FILE__), '..', 'config', 'boot')
require File.join(File.dirname(__FILE__), '..', 'config', 'environment')

ActiveRecord::Base.record_timestamps = false
Rails.logger = Logger.new('/dev/null')
ActiveRecord::Base.logger = Rails.logger

$old_db = PG.connect(dbname: 'oldusers')

$default_forum = Forum.where(slug: 'self').first!
meta = Forum.where(slug: 'meta').first!
$map = {
  # meta forums
  'ZU DIESEM FORUM' => meta,
  'SELFHTML' => meta,
  'SELFHTML-WIKI' => meta
}

$ids = {}
$coder = HTMLEntities.new

def check_null_bytes(msg)
  msg.content.gsub!(/\0/, '')
  msg.subject.gsub!(/\0/, '')
  msg.author.gsub!(/\0/, '')
  msg.email.gsub!(/\0/, '') if msg.email.present?
  msg.homepage.gsub!(/\0/, '') if msg.homepage.present?
end

def handle_messages(old_msg, x_msg, thread)
  mid = x_msg['id'].gsub(/^m/, '')

  msg = Message
          .where(mid: mid,
                 thread_id: thread.thread_id)
          .first

  if msg.blank?
    warn 'NEW MESSAGE!'
    exit

    the_date = Time.at(x_msg.find_first('./Header/Date')['longSec'].force_encoding('utf-8').to_i)
    the_date = DateTime.parse('1970-01-01 00:00:00').to_time if the_date.blank?

    msg = Message.new(
      mid: mid,
      author: x_msg.find_first('./Header/Author/Name').content.force_encoding('utf-8'),
      subject: x_msg.find_first('./Header/Subject').content.force_encoding('utf-8'),

      upvotes: x_msg['votingGood'].to_i,
      downvotes: x_msg['votingBad'].to_i,

      deleted: x_msg['invisible'] == '1',

      created_at: the_date,
      updated_at: the_date,

      content: x_msg.find_first('./MessageContent').content.force_encoding('utf-8'),
      parent_id: old_msg ? old_msg.message_id : nil,
      thread_id: thread.thread_id,
      forum_id: thread.forum_id
    )

    # cat      = x_msg.find_first('./Header/Category').content.force_encoding('utf-8')
    email    = x_msg.find_first('./Header/Author/Email').content.force_encoding('utf-8')
    homepage = x_msg.find_first('./Header/Author/HomepageUrl').content.force_encoding('utf-8')

    # msg.category        = cat      unless cat.empty?
    msg.email    = email    if email.present?
    msg.homepage = homepage if homepage.present?

    check_null_bytes(msg)

    msg.save(validate: false)

    category = x_msg.find_first('./Header/Category').content.force_encoding('utf-8')

    if category.present?
      category = category.downcase.strip

      t = Tag.find_by forum_id: thread.forum_id, tag_name: category

      begin
        t = Tag.create!(tag_name: category, forum_id: thread.forum_id) if t.blank?
      rescue ActiveRecord::RecordNotUnique
        t = Tag.find_by! forum_id: thread.forum_id, tag_name: category
      end

      MessageTag.create!(
        tag_id: t.tag_id,
        message_id: msg.message_id
      )
    end

    x_msg.find('./Header/Flags/Flag').each do |f|
      if f['name'] == 'UserName'
        uname = f.content.force_encoding('utf-8')

        usr = User.find_by(username: uname)
        unless usr
          email = nil
          $old_db.exec("SELECT email FROM auth WHERE username = '" + uname + "'") do |result|
            result.each do |row|
              email = row.values_at('email').first
            end
          end

          usr = User.new(username: uname, created_at: the_date, updated_at: the_date, email: email)
          usr.skip_confirmation!

          begin
            usr.save!(validate: false)
          rescue ActiveRecord::RecordNotUnique
            usr = User.where(username: uname).first

            if usr.blank?
              usr.email = nil
              usr.save!(validate: false)
            end
          end
        end

        msg.user_id = usr.id
        msg.save
      else
        msg.flags[f['name']] = f.content.force_encoding('utf-8')
      end
    end

  else
    msg.content = x_msg.find_first('./MessageContent').content.force_encoding('utf-8')
    msg.format = 'cforum'
    msg.save
  end

  x_msg.find('./Message').each do |m|
    handle_messages(msg, m, thread)
  end

  msg
end

def handle_doc(doc, opts = {})
  x_thread = doc.find_first('/Forum/Thread')
  the_date = Time.at(x_thread.find_first('./Message/Header/Date')['longSec'].force_encoding('utf-8').to_i)
  the_date = DateTime.parse('1970-01-01 00:00:00').to_time if the_date.blank?

  thread = CfThread
             .where(tid: x_thread['id'].force_encoding('utf-8')[1..-1])
             .where("EXTRACT('year' FROM created_at) = ?", the_date.utc.year)
             .first

  if thread.blank?
    warn 'NEW THREAD!'
    exit
    forum_name = x_thread.find_first('./Message/Header/Category').content.force_encoding('utf-8')

    subject = x_thread.find_first('./Message/Header/Subject').content.force_encoding('utf-8')

    forum = $map[forum_name] || $default_forum

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
    until CfThread.find_by(slug: thread.slug).blank?
      i += 1
      thread.slug = thread_id(the_date, subject, i)
    end

    thread.save
  end

  msg = nil
  x_thread.find('./Message').each do |m|
    msg = handle_messages(nil, m, thread)
  end

  thread.message_id = msg.message_id # a thread can only contain one message
  thread.save!

  thread
end

def thread_id(dt, subject, num = 0)
  base_id = dt.strftime('/%Y/') + dt.strftime('%b').downcase + '/' + dt.strftime('%d').to_i.to_s + '/'
  subj = subject.parameterize

  id = if num > 0
         base_id + num.to_s + '-' + subj
       else
         base_id + subj
       end

  id
end

def find_in_dir(dir)
  puts "Handling #{dir}"
  entries = Dir.entries(dir).sort do |a, b|
    if a =~ /^\d+$/ && b =~ /^\d+$/
      a.to_i <=> b.to_i
    else
      a <=> b
    end
  end

  entries.each do |ent|
    next if ent[0] == '.' # ignore ., .. and dot files

    if File.directory?(dir + '/' + ent)
      find_in_dir(dir + '/' + ent)
      next
    end

    next unless ent.match?(/^t\d+\.xml$/)

    begin
      # do not use Parser.file since there seems to be a problem with open files
      parser = LibXML::XML::Parser.string(IO.read(dir + '/' + ent))
      doc = parser.parse
    rescue
      warn "Error parsing thread #{dir + '/' + ent}!"
      next
    end

    begin
      thread = handle_doc(doc, archived: (dir.match?(/messages/) ? false : true))
      puts "saved #{thread.slug} from file #{dir + '/' + ent}"
    rescue SystemStackError
      warn "thread #{dir + '/' + ent} could not be saved!\n"
      warn $ERROR_INFO.message
      warn $ERROR_INFO.backtrace.join("\n")
    end
  end
end

ARGV.each do |directory|
  find_in_dir(directory)
end

# eof
