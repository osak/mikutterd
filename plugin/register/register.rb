Plugin.create(:register) do
  on_start_register do
    tw = MikuTwitter.new
    tw.consumer_key = Environment::TWITTER_CONSUMER_KEY
    tw.consumer_secret = Environment::TWITTER_CONSUMER_SECRET
    cnt = 0
    begin
      reqt = tw.request_oauth_token
      puts "Authorize URL: #{reqt.authorize_url}"
      print "Enter PIN Code: "
      $stdout.flush
      access_token = reqt.get_access_token(oauth_token: reqt.token, oauth_verifier: gets.chomp)
      Service.add_service(access_token.token, access_token.secret)
      puts "Registeration succeeded!"
    rescue Net::HTTPResponse => e
      puts "Failed: Network error(#{e})"
    rescue OAuth::Unauthorized
      cnt += 1
      puts "OAuth error (PIN code may be wrong)."
      if cnt <= 5
        puts "Retry (#{cnt} / 5)."
        retry if cnt <= 5
      else
        puts "Registration aborted."
      end
    end
  end
end
