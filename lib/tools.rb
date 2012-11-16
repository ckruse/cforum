# -*- coding: utf-8 -*-

module CForum
  module Tools
    def encode_entities(txt)
      map = {'&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;'}
      x = txt.gsub /([&<>"])/ do |r|
        map[r]
      end
    end

    module_function :encode_entities
  end
end

# end