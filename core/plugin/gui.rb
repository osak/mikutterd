# -*- coding:utf-8 -*-
# Plugin/GUI
#

miquire :core, 'utils'
miquire :plugin, 'plugin'
miquire :mui
miquire :core, 'configloader'

require 'gtk2'
require 'singleton'
require 'monitor'

module Plugin
  class GUI
    include ConfigLoader

    class TabButton < Gtk::Button
      include Comparable
      attr_accessor :pane, :label

      def ==(other)
        @label == other.to_s end

      def to_s
        @label end

      def <=>(other)
        @label <=> other.to_s end
    end

    @@mutex = Monitor.new

    def initialize
      @tab_log = ['Home Timeline']
      @memo_color = memoize{ |r,g,b|
        Gtk::Lock.synchronize do
          c = Gdk::Color.new(r*255,g*255,b*255)
          Gdk::Colormap.system.alloc_color(c, false, true)
          c
        end
      }
    end

    def onboot(watch)
      self._onboot(watch)
    end

    def _onboot(watch)
      Gtk::Lock.synchronize do
        self.statusbar.push(self.statusbar.get_context_id('hello'), "#{watch.user_by_cache}? みっくみくにしてやんよ")
        @window = self.gen_window()
        container = Gtk::VBox.new(false, 0)
        main = Gtk::HBox.new(false, 0)
        @pane = Gtk::HBox.new(true, 0)
        sidebar = Gtk::VBox.new(false, 0)
        mumbles = Gtk::VBox.new(false, 0)
        postbox = Gtk::PostBox.new(watch, :postboxstorage => mumbles, :delegate_other => true)
        mumbles.pack_start(postbox)
        @window.set_focus(postbox.post)
        @pane.pack_end(self.book)
        main.pack_start(@pane)
        sidebar.pack_start(self.tab, false)
        main.pack_start(sidebar, false)
        container.pack_start(mumbles, false)
        container.pack_start(main)
        container.pack_start(self.statusbar, false)
        @window.add(container)
        set_icon
        @window.show_all
      end
    end

    def set_icon
      @window.icon = Gdk::Pixbuf.new(File.expand_path(MUI::Skin.get('icon.png')), 256, 256)
    end

    def on_mui_tab_active(tab)
      index = get_tabindex(tab)
      self.book.set_page(index) if index
    end

    def statusbar
      if not defined? @statusbar then
        @statusbar = Gtk::Statusbar.new
        @statusbar.has_resize_grip = true
      end
      @statusbar
    end

    def get_tabindex(label)
      pane = get_tabpane(label)
      self.book.n_pages.times{ |index|
        return index if self.book.get_nth_page(index) == pane }
    end

    def get_tabpane(label)
      result = self.tab.children.find{ |w| w.label == label }
      result.pane if result
    end

    def gen_tabbutton(container, label, image=nil)
      widget =TabButton.new
      Gtk::Tooltips.new.set_tip(widget, label, nil)
      widget.pane = container
      widget.label = label
      if image
        widget.add(Gtk::WebIcon.new(image, 24, 24))
      else
        widget.add(gen_label(label)) end
      widget.signal_connect('clicked'){ |w|
        @tab_log.delete(w.label)
        @tab_log.unshift(w.label)
        index = get_tabindex(w.label)
        self.book.page = index if index
        false }
      widget.signal_connect('key_press_event'){ |w, event|
        Gtk::Lock.synchronize{
          case event.keyval
          when 65361:
              index = get_tabindex(w.label)
              if index then
                self.book.remove_page(index)
                @book_children.delete(w.label)
                @pane.pack_end(w.pane) end
          when 65363:
              if not @book_children.include?(w.label) then
                @pane.remove(w.pane)
                self.book.append_page(w.pane)
                @book_children << w.label end end }
        true }
      widget end

    def regist_tab(container, label, image=nil)
      default_active = 'Home Timeline'
      order = ['Home Timeline', 'Replies', 'Search', 'Settings']
      @@mutex.synchronize{
        @book_children = [] if not(@book_children)
        Gtk::Lock.synchronize{
          idx = where_should_insert_it(label, @book_children, order)
          self.book.insert_page(idx, container, gen_label(label))
          @book_children.insert(idx, label)
          @tab_log.push(label)
          self.tab.pack(gen_tabbutton(container, label, image).show_all, false)
          container.show_all } } end

    def focus_before_tab(label)
      @tab_log.delete(label)
      idx = get_tabindex(@tab_log.first)
      # self.book.get_nth_page(idx)
      self.book.set_page(idx)
    end

    def remove_tab(label)
      index = get_tabindex(label)
      if index
        focus_before_tab(label)
        w = self.tab.children.find{ |node| node.label == label }
        self.book.remove_page(index)
        @pane.remove(w.pane)
        self.tab.remove(w) end end

    def tab
      Gtk::Lock.synchronize do
        if not(defined? @tabbar) then
          order = ['Home Timeline', 'Replies', 'Search', 'Settings']
          @tabbar = Gtk::PriorityVBox.new(false, 0){ |w, tabbar|
           0 - (@book_children.index(w.label) or 0)
          } end end
      @tabbar end

    def book()
      @@mutex.synchronize{
        Gtk::Lock.synchronize do
          if not(@book) then
            @book = Gtk::Notebook.new
            @book.set_tab_pos(Gtk::POS_RIGHT)
            @book.set_show_tabs(false)
          end
        end
      }
      return @book
    end

    def gen_toolbar(posts, watch)
      Gtk::Lock.synchronize do
        toolbar = Gtk::Toolbar.new
        toolbar.append('つぶやく', nil, nil,
                       Gtk::Image.new(Gdk::Pixbuf.new('data/icon.png', 24, 24))){
          container = Gtk::PostBox.new(watch)
          posts.pack_start(container)
          posts.show_all
          @window.set_focus(container.post)
        }
        toolbar
      end
    end

    def gen_label(msg)
      Gtk::Lock.synchronize do
        label = Gtk::Label.new
        label.markup = msg
        label
      end
    end

    def background(window)
      Gtk::Lock.synchronize do
        draw = window.window
        #window.signal_connect("expose_event") do |win, evt|
        #  self.miracle_painting(draw, [64, 128, 255], [64, 224, 224])
        #end
      end
    end

    # miracle painting, miracle show time!
    def miracle_painting(draw, start, finish)
      Gtk::Lock.synchronize do
        gc = Gdk::GC.new(draw)
        geo = draw.geometry
        geo[3].times{ |y|
          c = [0, 1, 2].map{ |count|
            (finish[count] - start[count]) *([1, y].max) / geo[3] + start[count]
          }
          gc.set_foreground(color(*c))
          draw.draw_line(gc, 0, y, geo[2], y)
        }
      end
    end

    def gen_window()
      Gtk::Lock.synchronize do
        window = Gtk::Window.new
        window.title = Environment::NAME
        window.set_size_request(240, 240)
        size = at(:size, [Gdk.screen_width/3, Gdk.screen_height*4/5])
        position = at(:position, [Gdk.screen_width - size[0], Gdk.screen_height/2 - size[1]/2])
        window.set_default_size(*size)
        window.move(*position)
        #window.set_app_paintable(true)
        #window.realize
        #self.background(window)
        this = self
        window.signal_connect("destroy"){
          Gtk::Lock.synchronize do
            Gtk.main_quit
          end
          false
        }
        window.signal_connect("expose_event"){ |window, event|
          Gtk::Lock.synchronize do
            if(window.realized?) then
              new_size = window.window.geometry[2,2]
              if(size != new_size) then
                this.store(:size, new_size)
                size = new_size
              end
              new_position = window.position
              if(position != new_position) then
                this.store(:position, new_position)
                position = new_position
              end
            end
          end
          false
        }
        window
      end
    end

    def color(r, g, b)
      @memo_color.call(r, g, b)
    end
  end

end

# プラグインの登録
gui = Plugin::GUI.new
plugin = Plugin::create(:gui)
plugin.add_event(:boot, &gui.method(:onboot))

# タブを登録
# (Widget container, String label[, String iconpath])
plugin.add_event(:mui_tab_regist, &gui.method(:regist_tab))

plugin.add_event(:mui_tab_remove, &gui.method(:remove_tab))

plugin.add_event(:mui_tab_active, &gui.method(:on_mui_tab_active))

plugin.add_event(:apilimit){ |time|
  Plugin.call(:update, nil, Message.new(:message => "Twitter APIの制限数を超えたので、#{time.strftime('%H:%M')}までアクセスが制限されました。この間、タイムラインの更新などが出来ません。",
                                        :system => true))
  gui.statusbar.push(gui.statusbar.get_context_id('system'), "Twitter APIの制限数を超えました。#{time.strftime('%H:%M')}に復活します") }

plugin.add_event(:apifail){ |errmes|
  gui.statusbar.push(gui.statusbar.get_context_id('system'), "Twitter サーバが応答しません(#{errmes})") }

api_limit = {:ip_remain => '-', :ip_time => '-', :auth_remain => '-', :auth_time => '-'}
plugin.add_event(:apiremain){ |remain, time, transaction|
  api_limit[:auth_remain] = remain
  api_limit[:auth_time] = time.strftime('%H:%M')
  gui.statusbar.push(gui.statusbar.get_context_id('system'), "API auth#{api_limit[:auth_remain]}回くらい (#{api_limit[:auth_time]}まで) IP#{api_limit[:ip_remain]}回くらい (#{api_limit[:ip_time]}まで)") }

plugin.add_event(:ipapiremain){ |remain, time, transaction|
  api_limit[:ip_remain] = remain
  api_limit[:ip_time] = time.strftime('%H:%M')
  gui.statusbar.push(gui.statusbar.get_context_id('system'), "API auth#{api_limit[:auth_remain]}回くらい (#{api_limit[:auth_time]}まで) IP#{api_limit[:ip_remain]}回くらい (#{api_limit[:ip_time]}まで)") }

plugin.add_event(:rewindstatus){ |mes|
  gui.statusbar.push(gui.statusbar.get_context_id('system'), mes) }

miquire :addon, 'addon'
