# -*- coding: utf-8 -*-

module TrackerHelper
  def track_request
    return if controller_path.split('/').first == 'admin' || request.headers['HTTP_DNT'] == '1'

    image_tag 'https://www.browser-statistik.de/browser.png?style=0', alt: '', size: 1, style: 'border: 0px;'
  end
end
