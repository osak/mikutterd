# -*- coding: utf-8 -*-

miquire :core, 'messageconverters'
miquire :addon, 'addon'
miquire :addon, 'settings'
miquire :core, 'userconfig'

class Bitly < MessageConverters
  USER = 'mikutter'
  APIKEY = 'R_70170ccac1099f3ae1818af3fa7bb311'
  def user
    if UserConfig[:bitly_user] == '' or not UserConfig[:bitly_user]
      USER
    else
      UserConfig[:bitly_user]
    end end

  def apikey
    if UserConfig[:bitly_apikey] == '' or not UserConfig[:bitly_apikey]
      APIKEY
    else
      UserConfig[:bitly_apikey]
    end end

  def shrinked_url?(url)
    Regexp.new('http://(bit\\.ly|j\\.mp)/') === url end

  def shrink_url(urls)
    query = "version=2.0.1&login=#{user}&apiKey=#{apikey}&" + urls.map{ |url|
      "longUrl=#{Escape.query_segment(url).to_s}" }.join('&')
    3.times{
      result = begin
                 JSON.parse(Net::HTTP.get("api.bit.ly", "/shorten?#{query}"))
               rescue JSON::ParserError
                 nil
               end
      return Hash[ *result['results'].map{|pair| [pair[0], pair[1]['shortUrl']] }.flatten ] if result
      sleep(1) }
    nil end end

Module.new do
  USER = 'mikutter'
  APIKEY = 'R_70170ccac1099f3ae1818af3fa7bb311'
  NAVIGATION = <<EOM
設定しなくたって使えるけれど、設定するとbitlyのページからクリックされた回数とかわかるようになるよ。
Bit.lyにログインし、 http://bit.ly/a/your_api_key にアクセスすると表示されるbit.ly API key を、下のボタンをクリックして「APIキー」に入力して下さい。
EOM


  def self.boot
    plugin = Plugin::create(:bitly)
    plugin.add_event(:boot){ |service|
      Plugin.call(:regist_url_shrinker_setting, 'bit.ly', main(service)) } end

  def self.main(watch)
    ft = Mtk.accountdialog_button('bit.ly アカウント設定',
                                  :bitly_user, 'ユーザ名',
                                  :bitly_apikey, 'APIキー'){ |user, pass|
      if(pass == '' and user == '')
        true
      else
        query = "/v3/validate?x_login=#{user}&x_apiKey=#{pass}&apiKey=#{APIKEY}"+
          "&login=#{USER}&format=json"
        begin
          result = JSON.parse(Net::HTTP.get("api.bit.ly", query))
          notice result.inspect
          result['data']['valid'].to_i == 1
        rescue JSON::ParserError
          nil end end }
    Gtk::VBox.new(false, 8).closeup(Gtk::IntelligentTextview.new(NAVIGATION)).closeup(ft) end

  boot
end

# Plugin::Ring.push Addon::Bitly.new,[:boot]
