# frozen_string_literal: true

require 'active_support/all'

is_home = false
last_detected_at = nil

loop do
  results = `sudo arp-scan -l -r 3`
  found = results.include?('2a:53:e5:bd:22:26')

  if found
    last_detected_at = Time.now

    unless is_home
      `curl --location --request POST 'https://api.telegram.org/bot5074237332:AAEgl4rnBrqScOHcQV1gqNscmlgKBBrUOwo/sendMessage?chat_id=5033674135&text=davehome'`
      is_home = true
    end

    next
  end

  if Time.now > last_detected_at + 10.minutes && is_home
    `curl --location --request POST 'https://api.telegram.org/bot5074237332:AAEgl4rnBrqScOHcQV1gqNscmlgKBBrUOwo/sendMessage?chat_id=5033674135&text=daveout'`
    is_home = false
  end

  sleep 10
end
