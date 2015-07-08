# -*- coding: utf-8 -*-

module Peon
  module Tasks
    class ArchiveCitesTask < PeonTask
      def backup_file(cite, file)
        xml = <<-XML
<?xml encoding="utf-8"?>
<cite>
  <old_id>#{cite.old_id}</old_id>
  <user_id>#{cite.user_id}</user_id>
  <message_id>#{cite.message_id}</message_id>
  <url><![CDATA[#{cite.url}]]></url>
  <author><![CDATA[#{cite.author}]]></author>
  <creator><![CDATA[#{cite.creator}]]></creator>
  <cite><![CDATA[#{cite.cite}]]></cite>
  <created_at>#{cite.created_at}</created_at>
  <updated_at>#{cite.updated_at}</updated_at>
  <cite_date>#{cite.cite_date}</cite_date>
</cite>
        XML

        File.open(file, "w:utf-8") do |fd|
          fd.write(xml)
        end
      end

      def work_work(args)
        min_age = conf('cites_min_age_to_archive', nil).to_i
        cites = CfCite.
                preload(:votes).
                where('archived = false AND NOW() >= created_at + INTERVAL ?', min_age.to_s + ' weeks').
                all

        Rails.logger.info "Running cite archiver for #{cites.length} cites"

        cites.each do |cite|
          if cite.score > 0
            Rails.logger.info "Archiving cite #{cite.cite_id}"
            cite.archived = true
            cite.save
          else
            backup = (Rails.root + 'tmp/').to_s + cite.cite_id.to_s + '.xml'
            Rails.logger.info "Trashing cite #{cite.cite_id}, backup at #{backup}"

            backup_file cite, backup

            cite.destroy
          end
        end
      end
    end

    Peon::Grunt.instance.periodical(ArchiveCitesTask.new, 3600)
  end
end

# eof
