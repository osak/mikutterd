# -*- coding: utf-8 -*-

Plugin.create :command do

  # define_command(:copy_selected_region,
  #                :name => 'コピー',
  #                :condition => lambda{ |m| true },
  #                :exec => lambda{ |opt|
  #                  Gtk::Clipboard.copy(opt.message.entity.to_s[opt.miraclepainter.textselector_range]) },
  #                :visible => true,
  #                :role => ROLE_MESSAGE_SELECTED )

  command(:copy_description,
          name: '本文をコピー',
          condition: lambda{ |opt| opt.messages.size == 1 },
          visible: true,
          role: :timeline) do |opt|
    Gtk::Clipboard.copy(opt.messages.first.to_show) end

  command(:reply,
          name: '返信',
          condition: lambda{ |opt| opt.messages.all? &:repliable? },
          visible: true,
          role: :timeline) do |opt|
    opt.widget.create_reply_postbox(opt.messages.first.message,
                                    subreplies: opt.messages.map(&:message)) end

  command(:reply_all,
          name: '全員に返信',
          condition: lambda{ |opt| opt.messages.all? &:repliable? },
          visible: true,
          role: :timeline) do |opt|
    opt.widget.create_reply_postbox(opt.messages.first.message,
                                    subreplies: opt.messages.map{ |m| m.message.ancestors }.flatten,
                                    exclude_myself: true) end

  command(:legacy_retweet,
          name: '引用',
          condition: lambda{ |opt| opt.messages.size == 1 && opt.messages.first.repliable? },
          visible: true,
          role: :timeline) do |opt|
    opt.widget.create_reply_postbox(opt.messages.first.message, retweet: true) end

  command(:retweet,
          name: 'リツイート',
          condition: lambda{ |opt|
            opt.messages.all? { |m|
              m.retweetable? and not m.retweeted_by_me? } },
          visible: true,
          role: :timeline) do |opt|
    opt.messages.select{ |x| not x.from_me? }.each(&:retweet) end

  command(:delete_retweet,
          name: 'リツイートをキャンセル',
          condition: lambda{ |opt|
            opt.messages.all? { |m|
              m.retweetable? and not m.retweeted_by_me? } },
          visible: true,
          role: :timeline) do |opt|
    opt.messages.each { |m|
      retweet = m.retweeted_statuses.find(&:from_me?)
      retweet.destroy if retweet and Gtk::Dialog.confirm("このつぶやきのリツイートをキャンセルしますか？\n\n#{m.to_show}") } end

  command(:favorite,
          name: 'ふぁぼふぁぼする',
          condition: lambda{ |opt|
            opt.messages.all?{ |m| m.favoritable? and not m.favorited_by_me? } },
          visible: true,
          role: :timeline) do |opt|
    opt.messages.each(&:favorite) end

  command(:delete_favorite,
          name: 'あんふぁぼ',
          condition: lambda{ |opt|
            opt.messages.all?(&:favorited_by_me?) },
          visible: true,
          role: :timeline) do |opt|
    opt.messages.each(&:unfavorite) end

  command(:delete,
          name: '削除',
          condition: lambda{ |opt|
            opt.messages.all?(&:from_me?) },
          visible: true,
          role: :timeline) do |opt|
    opt.messages.each { |m|
      m.destroy if Gtk::Dialog.confirm("失った信頼はもう戻ってきませんが、本当にこのつぶやきを削除しますか？\n\n#{m.to_show}") } end

  command(:select_prev,
          name: '一つ上のメッセージを選択',
          condition: ret_nth,
          visible: true,
          role: :timeline) do |opt|
    Plugin.call(:gui_timeline_move_cursor_to, opt.widget, :prev) end

  command(:select_next,
          name: '一つ下のメッセージを選択',
          condition: ret_nth,
          visible: true,
          role: :timeline) do |opt|
    Plugin.call(:gui_timeline_move_cursor_to, opt.widget, :next) end

  command(:post_it,
          name: '投稿する',
          condition: lambda{ |opt| opt.widget.editable? },
          visible: false,
          role: :postbox) do |opt|
    opt.widget.post_it! end

  # define_command(:google_search,
  #                :name => 'ggrks',
  #                :condition => lambda{ |m| true },
  #                :exec => lambda{ |opt|
  #                  kamiya_google_search_word = opt.message.entity.to_s[opt.miraclepainter.textselector_range]
  #                  Gtk::openurl("http://www.google.co.jp/search?q=" + URI.escape(kamiya_google_search_word).to_s) },
  #                :visible => true,
  #                :role => ROLE_MESSAGE_SELECTED )

  command(:open_link,
          name: 'リンクを開く',
          condition: lambda{ |opt|
            opt.messages.size == 1 && opt.messages[0].entity.to_a.any? {|u|
              u[:slug] == :urls } },
          visible: true,
          role: :timeline) do |opt|
    opt.messages[0].entity.to_a.each {|u|
      Gtk::TimeLine.openurl(u[:url]) if u[:slug] == :urls } end
end