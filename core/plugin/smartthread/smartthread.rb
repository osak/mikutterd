# -*- coding: utf-8 -*-

require 'set'

Plugin.create :smartthread do

  counter = gen_counter 1
  @timelines = {}                # slug => [message]

  # messagesの中で、タイムライン _slug_ に入れるべきものがあれば入れる
  # ==== Args
  # [slug] タイムラインスラッグ
  # [messages] 入れるMessageの配列
  def scan(slug, messages)
    messages.each{ |message|
      message.each_ancestors { |cur|
        if @timelines[slug].include? cur
          timeline(slug) << message end } } end

  command(:smartthread,
          name: '会話スレッドを表示',
          icon: MUI::Skin.get("list.png"),
          condition: lambda{ |opt| opt.messages.all? &:repliable? },
          visible: true,
          role: :timeline){ |opt|
    serial = counter.call
    slug = "conversation#{serial}".to_sym
    tab slug, "会話#{serial}" do
      set_deletable true
      set_icon MUI::Skin.get("list.png")
      timeline slug end
    @timelines[slug] = opt.messages.map(&:ancestor).uniq
    timeline(slug) << opt.messages.map(&:around).flatten
  }

  onappear do |messages|
    @timelines.keys.each{ |slug|
      scan slug, messages } end

  on_gui_destroy do |widget|
    if widget.is_a? Plugin::GUI::Timeline
      if @timelines.delete(widget.slug)
        notice "smartthread removed :#{widget.slug}" end end end

end
